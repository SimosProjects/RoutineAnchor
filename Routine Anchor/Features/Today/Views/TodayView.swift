//
//  TodayView.swift
//  Routine Anchor
//
//  Root “Today” screen. Uses semantic theme tokens via ThemeManager and keeps
//  presentation logic thin—actual content lives in small subviews.
//

import SwiftUI
import SwiftData

struct TodayView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.themeManager) private var themeManager

    @Bindable var viewModel: TodayViewModel
    @State private var dataManager: DataManager

    // MARK: - Sheet / selection state
    @State private var showingSettings = false
    @State private var showingSummary = false
    @State private var showingQuickStats = false
    @State private var selectedTimeBlock: TimeBlock?
    @State private var showingActionSheet = false

    // MARK: - Scrolling helpers
    @State private var scrollProxy: ScrollViewProxy?
    @State private var highlightedBlockId: UUID?

    private var theme: AppTheme { themeManager?.currentTheme ?? PredefinedThemes.classic }

    init(modelContext: ModelContext) {
        let dataManager = DataManager(modelContext: modelContext)
        self.dataManager = dataManager
        self.viewModel = TodayViewModel(dataManager: dataManager)
    }

    var body: some View {
        ZStack {
            // Shared hero background
            ThemedAnimatedBackground()
                .ignoresSafeArea()

            GeometryReader { geometry in
                ScrollViewReader { proxy in
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 0) {
                            // Header
                            TodayHeaderView(
                                viewModel: viewModel,
                                showingSettings: $showingSettings,
                                showingSummary: $showingSummary,
                                showingQuickStats: $showingQuickStats
                            )
                            .padding(.top, geometry.safeAreaInsets.top + 20)

                            // Main content
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
            // Initial data load + periodic updates
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
                Task { await viewModel.retryLastOperation() }
            }
            Button("Dismiss", role: .cancel) {
                viewModel.clearError()
            }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        // Sheets — pass ThemeManager down the stack
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
        // Notification routing
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

    // MARK: - Helpers

    private func refreshData() async {
        // Subtle haptic to confirm pull-to-refresh
        try? await Task.sleep(nanoseconds: 300_000_000)
        await viewModel.refreshData()
        HapticManager.shared.lightImpact()
    }

    private func navigateToScheduleBuilder() {
        NotificationCenter.default.post(name: .navigateToSchedule, object: nil)
    }

    private func showTemplates() {
        NotificationCenter.default.post(name: .showTemplates, object: nil)
    }

    private func scrollToCurrentBlockIfNeeded() {
        guard let currentBlock = viewModel.getCurrentBlock() else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                scrollProxy?.scrollTo(currentBlock.id, anchor: .center)
            }
        }
    }

    private func highlightBlock(_ blockId: UUID) {
        highlightedBlockId = blockId
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
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            scrollProxy?.scrollTo(blockId, anchor: .center)
        }
        highlightBlock(blockId)
    }
}
