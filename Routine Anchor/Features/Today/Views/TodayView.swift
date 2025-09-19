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

    // Own the VM here; build it after the environment is available.
    @State private var viewModel: TodayViewModel? = nil

    @State private var refreshTask: Task<Void, Never>?
    @State private var animationTask: Task<Void, Never>?
    @State private var showDatePicker = false
    @State private var tempDate = Date()
    
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
    
    var body: some View {
        Group {
            if let vm = viewModel {
                content(vm)
            } else {
                ZStack {
                    ThemedAnimatedBackground(kind: .hero).ignoresSafeArea()
                    ProgressView()
                }
            }
        }
        .onAppear {
            // Lazily build the VM once the environment is available
            if viewModel == nil {
                let dm = DataManager(modelContext: modelContext)
                viewModel = TodayViewModel(
                    dataManager: dm,
                    isUserPremium: { premiumManager?.userIsPremium ?? false }
                )
            }
        }
    }

    // MARK: - Split out the main content once VM exists
    @ViewBuilder
    private func content(_ vm: TodayViewModel) -> some View {
        ZStack {
            // Shared hero background
            ThemedAnimatedBackground(kind: .hero)
                .ignoresSafeArea()
            
            GeometryReader { geometry in
                ScrollViewReader { proxy in
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 0) {
                            // Header section
                            TodayHeaderView(
                                viewModel: vm,
                                showingSettings: $showingSettings,
                                showingSummary: $showingSummary,
                                showingQuickStats: $showingQuickStats
                            )
                            .padding(.top, geometry.safeAreaInsets.top + 20)

                            // Content based on state
                            if vm.hasScheduledBlocks {
                                mainContent(vm)
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
                    .refreshable { await refreshData(vm) }
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
                await vm.refreshData()
                vm.startPeriodicUpdates()
            }
        }
        .onDisappear {
            viewIsActive = false
            vm.stopPeriodicUpdates()
        }
        .alert("Error", isPresented: .constant(vm.errorMessage != nil)) {
            Button("Retry") {
                Task { await vm.retryLastOperation() }
            }
            Button("Dismiss", role: .cancel) {
                vm.clearError()
            }
        } message: {
            Text(vm.errorMessage ?? "")
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
            NavigationStack { QuickStatsView(viewModel: vm) }
                .environment(\.themeManager, themeManager)
                .presentationDetents([.fraction(0.7)])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showDatePicker) {
            NavigationStack {
                VStack(spacing: 16) {
                    DatePicker(
                        "Select a day",
                        selection: $tempDate,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.graphical)
                    .padding()

                    HStack {
                        Button("Cancel") { showDatePicker = false }
                        Spacer()
                        Button("Go") {
                            showDatePicker = false
                            Task { await vm.setSelectedDate(tempDate) }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 12)
                }
                .navigationTitle("Jump to date")
                .navigationBarTitleDisplayMode(.inline)
            }
        }

        .gesture(
            DragGesture(minimumDistance: 30, coordinateSpace: .local)
                .onEnded { value in
                    if abs(value.translation.height) < 40 {
                        if value.translation.width > 60 {
                            Task { await vm.goToPreviousDay() }
                        } else if value.translation.width < -60 {
                            Task { await vm.goToNextDay() }
                        }
                    }
                }
        )
        .onReceive(NotificationCenter.default.publisher(for: .showDatePicker)) { _ in
            tempDate = vm.selectedDate
            showDatePicker = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .showQuickStats)) { _ in
            showingQuickStats = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .showDailySummary)) { _ in
            showingSummary = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .timeBlockCompleted)) { notification in
            handleTimeBlockCompletion(notification, vm: vm)
        }
        .onReceive(NotificationCenter.default.publisher(for: .timeBlockSkipped)) { notification in
            handleTimeBlockSkip(notification, vm: vm)
        }
        .onReceive(NotificationCenter.default.publisher(for: .showTimeBlock)) { notification in
            handleShowTimeBlock(notification)
        }
        .onReceive(NotificationCenter.default.publisher(for: .refreshTodayView)) { _ in
            guard !isAboutToShowSheet && !justNavigatedToView else { return }
            Task { await vm.refreshData() }
        }
    }
    
    // MARK: - Main Content
    @ViewBuilder
    private func mainContent(_ vm: TodayViewModel) -> some View {
        VStack(spacing: 24) {
            // Focus section
            if let focusText = vm.getFocusModeText() {
                FocusCard(
                    text: focusText,
                    currentBlock: vm.getCurrentBlock(),
                    viewModel: vm
                )
                .padding(.horizontal, 24)
            }
            
            // Time blocks list
            TodayTimeBlocksList(
                viewModel: vm,
                selectedTimeBlock: $selectedTimeBlock,
                showingActionSheet: $showingActionSheet,
                highlightedBlockId: $highlightedBlockId,
                scrollProxy: scrollProxy
            )
            
            // Motivational section
            MotivationalCard(viewModel: vm)
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
            
            // Elegant loading animation — uses normal to match theme
            ZStack {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(scheme.normal.color.opacity(0.3))
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
    
    private func refreshData(_ vm: TodayViewModel) async {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            refreshTrigger.toggle()
        }
        // Small delay for visual feedback
        try? await Task.sleep(nanoseconds: 500_000_000)
        await vm.refreshData()
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
    
    private func scrollToCurrentBlockIfNeeded(_ vm: TodayViewModel) {
        guard let currentBlock = vm.getCurrentBlock() else { return }
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
    
    private func handleTimeBlockCompletion(_ notification: Notification, vm: TodayViewModel) {
        guard let blockId = notification.userInfo?["blockId"] as? UUID,
              let block = vm.timeBlocks.first(where: { $0.id == blockId }) else { return }
        Task { @MainActor in await vm.markBlockCompleted(block) }
    }
    
    private func handleTimeBlockSkip(_ notification: Notification, vm: TodayViewModel) {
        guard let blockId = notification.userInfo?["blockId"] as? UUID,
              let block = vm.timeBlocks.first(where: { $0.id == blockId }) else { return }
        Task { @MainActor in await vm.markBlockSkipped(block) }
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
    return TodayView()
        .environment(\.themeManager, tm)
        .modelContainer(container)
}
