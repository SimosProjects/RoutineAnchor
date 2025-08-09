//
//  TodayView.swift
//  Routine Anchor
//
import SwiftUI
import SwiftData

struct TodayView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var viewModel: TodayViewModel
    
    // MARK: - State
    @State private var showingSettings = false
    @State private var showingSummary = false
    @State private var showingQuickStats = false
    @State private var selectedTimeBlock: TimeBlock?
    @State private var showingActionSheet = false
    @State private var headerOffset: CGFloat = 0
    @State private var scrollProgress: CGFloat = 0
    @State private var refreshTrigger = false
    
    // MARK: - Scroll Support State
    @State private var scrollProxy: ScrollViewProxy?
    @State private var highlightedBlockId: UUID?
    
    init(modelContext: ModelContext) {
        let dataManager = DataManager(modelContext: modelContext)
        self.viewModel = TodayViewModel(dataManager: dataManager)
    }
    
    var body: some View {
        ZStack {
            // Premium background
            AnimatedGradientBackground()
                .ignoresSafeArea()
            
            GeometryReader { geometry in
                ScrollViewReader { proxy in
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 0) {
                            OffsetObservingView() // Track scroll offset

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
                        }
                    }
                    .onAppear {
                        scrollProxy = proxy
                    }
                    .coordinateSpace(name: "scroll")
                    .refreshable {
                        await refreshData()
                    }
                    .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                        Task { @MainActor in
                            updateScrollProgress(value, geometry: geometry)
                        }
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            Task { @MainActor in
                await viewModel.refreshData()
                viewModel.startPeriodicUpdates()
            }
        }
        .onDisappear {
            viewModel.stopPeriodicUpdates()
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("Retry") {
                Task {
                    await viewModel.retryLastOperation()
                }
            }
            Button("Dismiss", role: .cancel) {
                viewModel.clearError()
            }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .sheet(isPresented: $showingSettings) {
            NavigationStack {
                SettingsView()
            }
        }
        .sheet(isPresented: $showingSummary) {
            NavigationStack {
                PremiumDailySummaryView()
            }
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
            Task {
                await viewModel.refreshData()
            }
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
        VStack(spacing: 20) {
            Spacer()
            
            // Elegant loading animation
            ZStack {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(Color.premiumBlue.opacity(0.3))
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
                .foregroundStyle(Color.white.opacity(0.7))
            
            Spacer()
        }
        .onAppear {
            refreshTrigger = true
        }
    }
    
    // MARK: - Helper Methods

    private func updateScrollProgress(_ offset: CGFloat, geometry: GeometryProxy) {
        let progress = min(max(offset / 100, 0), 1)
        if abs(scrollProgress - progress) > 0.01 {
            scrollProgress = progress
            headerOffset = -offset * 0.5
        }
    }
    
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
        guard let currentBlock = viewModel.getCurrentBlock() else {
            return
        }
        
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
                if highlightedBlockId == blockId {
                    highlightedBlockId = nil
                }
            }
        }
    }
    
    // MARK: - Notification Handlers
    
    private func handleTimeBlockCompletion(_ notification: Notification) {
        guard let blockId = notification.userInfo?["blockId"] as? UUID,
              let block = viewModel.timeBlocks.first(where: { $0.id == blockId }) else {
            return
        }
        
        Task { @MainActor in
            await viewModel.markBlockCompleted(block)
        }
    }
    
    private func handleTimeBlockSkip(_ notification: Notification) {
        guard let blockId = notification.userInfo?["blockId"] as? UUID,
              let block = viewModel.timeBlocks.first(where: { $0.id == blockId }) else {
            return
        }
        
        Task { @MainActor in
            await viewModel.markBlockSkipped(block)
        }
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

// MARK: - Preference Keys

struct ScrollOffsetPreferenceKey: PreferenceKey {
    static let defaultValue: CGFloat = 0
    
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct OffsetObservingView: View {
    var body: some View {
        GeometryReader { geo in
            Color.clear
                .preference(key: ScrollOffsetPreferenceKey.self,
                            value: geo.frame(in: .named("scroll")).minY)
        }
        .frame(height: 0)
    }
}

// MARK: - Preview
#Preview {
    let container = try! ModelContainer(for: TimeBlock.self, DailyProgress.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    return TodayView(modelContext: container.mainContext)
        .modelContainer(container)
}
