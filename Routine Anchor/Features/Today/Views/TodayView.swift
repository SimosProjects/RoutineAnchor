//
//  TodayView.swift
//  Routine Anchor
//

import SwiftUI
import SwiftData

struct TodayView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.premiumManager) private var premiumManager
    @Environment(\.themeManager) private var themeManager
    @Bindable var viewModel: TodayViewModel
    @State private var dataManager: DataManager
    @State private var refreshTask: Task<Void, Never>?
    @State private var animationTask: Task<Void, Never>?
    
    // MARK: - State
    @State private var isAboutToShowSheet = false
    @State private var showingSettings = false
    @State private var showingSummary = false
    @State private var showingQuickStats = false
    @State private var selectedTimeBlock: TimeBlock?
    @State private var showingActionSheet = false
    @State private var headerOffset: CGFloat = 0
    @State private var scrollProgress: CGFloat = 0
    @State private var refreshTrigger = false
    @State private var justNavigatedToView = false
    @State private var viewIsActive = false
    
    // MARK: - Scroll Support State
    @State private var scrollProxy: ScrollViewProxy?
    @State private var highlightedBlockId: UUID?
    
    init(modelContext: ModelContext) {
        let dataManager = DataManager(modelContext: modelContext)
        self.dataManager = dataManager
        self.viewModel = TodayViewModel(dataManager: dataManager)
    }
    
    var body: some View {
        // Pull the scheme once; if themeManager is missing (e.g., preview),
        // use the default theme to avoid crashes.
        let scheme = (themeManager?.currentTheme.colorScheme ?? Theme.defaultTheme.colorScheme)
        
        return ZStack {
            ZStack {
                LinearGradient(
                    colors: [scheme.todayHeroTop.color, scheme.todayHeroBottom.color],
                    startPoint: .top,
                    endPoint: .bottom
                )
                RadialGradient(
                    colors: [
                        scheme.todayHeroVignette.color.opacity(scheme.todayHeroVignetteOpacity),
                        .clear
                    ],
                    center: .center,
                    startRadius: 0,
                    endRadius: 520
                )
            }
            .ignoresSafeArea()
            
            GeometryReader { geometry in
                ScrollViewReader { proxy in
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 0) {
                            // Header section
                            TodayHeaderView(
                                viewModel: viewModel,
                                showingSettings: $showingSettings,
                                showingSummary: $showingSummary,
                                showingQuickStats: $showingQuickStats
                            )
                            .padding(.top, geometry.safeAreaInsets.top + 20)

                            // Content based on state
                            if viewModel.hasScheduledBlocks {
                                mainContent
                            } else {
                                TodayEmptyStateView(
                                    onCreateRoutine: navigateToScheduleBuilder,
                                    onUseTemplate: showTemplates
                                )
                            }
                            
                            Spacer()
                            
                            // Ad banner for free users
                            StyledAdBanner()
                        }
                    }
                    .onAppear { scrollProxy = proxy }
                    .refreshable { await refreshData() }
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            // Clear all sheet states
            showingSettings = false
            showingSummary = false
            showingQuickStats = false
            
            // Mark view as active after a delay to ensure hierarchy is ready
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                viewIsActive = true
            }
            
            Task { @MainActor in
                await viewModel.refreshData()
                viewModel.startPeriodicUpdates()
            }
        }
        .onDisappear {
            viewIsActive = false
            viewModel.stopPeriodicUpdates()
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("Retry") {
                Task { await viewModel.retryLastOperation() }
            }
            Button("Dismiss", role: .cancel) {
                viewModel.clearError()
            }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .sheet(isPresented: $showingSettings) {
            NavigationStack { SettingsView() }
                .environment(\.themeManager, themeManager)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingSummary) {
            NavigationStack { DailySummaryView(modelContext: modelContext) }
                .environment(\.themeManager, themeManager)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingQuickStats) {
            NavigationStack { QuickStatsView(viewModel: viewModel) }
                .environment(\.themeManager, themeManager)
                .presentationDetents([.fraction(0.7)])
                .presentationDragIndicator(.visible)
        }
        .onReceive(NotificationCenter.default.publisher(for: .showQuickStats)) { _ in
            showingQuickStats = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .showDailySummary)) { _ in
            showingSummary = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .timeBlockCompleted)) { notification in
            handleTimeBlockCompletion(notification)
        }
        .onReceive(NotificationCenter.default.publisher(for: .timeBlockSkipped)) { notification in
            handleTimeBlockSkip(notification)
        }
        .onReceive(NotificationCenter.default.publisher(for: .showTimeBlock)) { notification in
            handleShowTimeBlock(notification)
        }
        .onReceive(NotificationCenter.default.publisher(for: .refreshTodayView)) { _ in
            guard !isAboutToShowSheet && !justNavigatedToView else { return }
            Task { await viewModel.refreshData() }
        }
    }
    
    // MARK: - Main Content
    @ViewBuilder
    private var mainContent: some View {
        VStack(spacing: 24) {
            // Focus section
            if let focusText = viewModel.getFocusModeText() {
                FocusCard(
                    text: focusText,
                    currentBlock: viewModel.getCurrentBlock(),
                    viewModel: viewModel
                )
                .padding(.horizontal, 24)
            }
            
            // Time blocks list
            TodayTimeBlocksList(
                viewModel: viewModel,
                selectedTimeBlock: $selectedTimeBlock,
                showingActionSheet: $showingActionSheet,
                highlightedBlockId: $highlightedBlockId,
                scrollProxy: scrollProxy
            )
            
            // Motivational section
            MotivationalCard(viewModel: viewModel)
                .padding(.horizontal, 24)
                .padding(.bottom, 100)
        }
        .padding(.top, 32)
    }
    
    // MARK: - Loading State
    private var loadingState: some View {
        let scheme = (themeManager?.currentTheme.colorScheme ?? Theme.defaultTheme.colorScheme)
        
        return VStack(spacing: 20) {
            Spacer()
            
            // Elegant loading animation — uses workflowPrimary to match theme
            ZStack {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(scheme.workflowPrimary.color.opacity(0.3))
                        .frame(width: 12, height: 12)
                        .scaleEffect(refreshTrigger ? 1.5 : 1.0)
                        .offset(x: CGFloat(index - 1) * 25)
                        .animation(
                            .spring(response: 0.8, dampingFraction: 0.6)
                                .repeatForever()
                                .delay(Double(index) * 0.2),
                            value: refreshTrigger
                        )
                }
            }
            
            Text("Loading your day...")
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundStyle(scheme.secondaryText.color)
            
            Spacer()
        }
        .onAppear { refreshTrigger = true }
    }
    
    // MARK: - Helper Methods
    
    private func refreshData() async {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            refreshTrigger.toggle()
        }
        // Small delay for visual feedback
        try? await Task.sleep(nanoseconds: 500_000_000)
        await viewModel.refreshData()
        HapticManager.shared.lightImpact()
    }
    
    private func navigateToScheduleBuilder() {
        // Navigate to schedule tab through parent
        NotificationCenter.default.post(name: .navigateToSchedule, object: nil)
    }
    
    private func showTemplates() {
        // Show template selection
        NotificationCenter.default.post(name: .showTemplates, object: nil)
    }
    
    // MARK: - Scroll Support Methods
    
    private func scrollToCurrentBlockIfNeeded() {
        guard let currentBlock = viewModel.getCurrentBlock() else { return }
        // Delay slightly to ensure view is laid out
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                scrollProxy?.scrollTo(currentBlock.id, anchor: .center)
            }
        }
    }
    
    private func highlightBlock(_ blockId: UUID) {
        highlightedBlockId = blockId
        // Remove highlight after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation(.easeOut(duration: 0.3)) {
                if highlightedBlockId == blockId { highlightedBlockId = nil }
            }
        }
    }
    
    // MARK: - Notification Handlers
    
    private func handleTimeBlockCompletion(_ notification: Notification) {
        guard let blockId = notification.userInfo?["blockId"] as? UUID,
              let block = viewModel.timeBlocks.first(where: { $0.id == blockId }) else { return }
        Task { @MainActor in await viewModel.markBlockCompleted(block) }
    }
    
    private func handleTimeBlockSkip(_ notification: Notification) {
        guard let blockId = notification.userInfo?["blockId"] as? UUID,
              let block = viewModel.timeBlocks.first(where: { $0.id == blockId }) else { return }
        Task { @MainActor in await viewModel.markBlockSkipped(block) }
    }
    
    private func handleShowTimeBlock(_ notification: Notification) {
        guard let blockIdString = notification.userInfo?["blockId"] as? String,
              let blockId = UUID(uuidString: blockIdString) else {
            print("Invalid blockId in notification")
            return
        }
        // Scroll to the specified block
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            scrollProxy?.scrollTo(blockId, anchor: .center)
        }
        // Highlight the block
        highlightBlock(blockId)
    }
}

// MARK: - Preview
#Preview {
    let container = try! ModelContainer(
        for: TimeBlock.self, DailyProgress.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    let tm = ThemeManager.preview(with: Theme.defaultTheme)
    return TodayView(modelContext: container.mainContext)
        .environment(\.themeManager, tm)
        .modelContainer(container)
}
