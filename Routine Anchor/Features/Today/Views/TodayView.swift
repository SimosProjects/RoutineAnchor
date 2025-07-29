//
//  TodayView.swift
//  Routine Anchor - Premium Version (iOS 17+ Optimized)
//
import SwiftUI
import SwiftData

struct PremiumTodayView: View {
    @Environment(\.modelContext) private var modelContext
    
    // iOS 17+ Pattern: Direct initialization with @State
    @State private var viewModel: TodayViewModel
    
    // MARK: - State
    @State private var showingSettings = false
    @State private var showingSummary = false
    @State private var selectedTimeBlock: TimeBlock?
    @State private var showingActionSheet = false
    @State private var headerOffset: CGFloat = 0
    @State private var scrollProgress: CGFloat = 0
    @State private var refreshTrigger = false
    
    // MARK: - Timer Management
    @State private var refreshTimer: Timer?
    
    // MARK: - Scroll Support State
    @State private var scrollProxy: ScrollViewProxy?
    @State private var highlightedBlockId: UUID?
    
    // MARK: - Initialization
    init() {
        // Initialize with a placeholder - will be configured in .task
        let placeholderDataManager = DataManager(modelContext: ModelContext(ModelContainer.shared))
        _viewModel = State(initialValue: TodayViewModel(dataManager: placeholderDataManager))
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
                            // Header section
                            TodayHeaderView(
                                viewModel: viewModel,
                                showingSettings: $showingSettings,
                                showingSummary: $showingSummary
                            )
                            .padding(.top, geometry.safeAreaInsets.top + 20)
                            
                            // Content based on state
                            if viewModel.hasScheduledBlocks {
                                mainContent(viewModel: viewModel)
                            } else {
                                PremiumTodayEmptyStateView(
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
                        updateScrollProgress(value, geometry: geometry)
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .task {
            // Configure ViewModel with actual dependencies
            await configureViewModel()
            startPeriodicUpdates()
            scrollToCurrentBlockIfNeeded()
        }
        .onDisappear {
            // Clean up timer to prevent memory leaks
            stopPeriodicUpdates()
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("Retry") {
                viewModel.retryLastOperation()
            }
            Button("Dismiss", role: .cancel) {
                viewModel.clearError()
            }
        } message: {
            Text(viewModel.errorMessage ?? "")
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
    }
    
    // MARK: - Main Content
    private func mainContent(viewModel: TodayViewModel) -> some View {
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
                .padding(.bottom, 100) // Space for tab bar
        }
        .padding(.top, 32)
    }
    
    // MARK: - Helper Methods
    
    private func configureViewModel() async {
        // Create proper DataManager with current context
        let dataManager = DataManager(modelContext: modelContext)
        
        // Reinitialize ViewModel with proper dependencies
        viewModel = TodayViewModel(dataManager: dataManager)
        
        // Load initial data
        viewModel.loadTodaysBlocks()
        
        // Setup refresh observer
        viewModel.setupRefreshObserver()
    }
    
    private func startPeriodicUpdates() {
        // Invalidate any existing timer
        refreshTimer?.invalidate()
        
        // Create new timer with weak self reference
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak viewModel] _ in
            Task { @MainActor in
                viewModel?.refreshData()
            }
        }
    }
    
    private func stopPeriodicUpdates() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }
    
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
        
        await MainActor.run {
            viewModel.refreshData()
            HapticManager.shared.lightImpact()
        }
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
        
        viewModel.markBlockCompleted(block)
    }
    
    private func handleTimeBlockSkip(_ notification: Notification) {
        guard let blockId = notification.userInfo?["blockId"] as? UUID,
              let block = viewModel.timeBlocks.first(where: { $0.id == blockId }) else {
            return
        }
        
        viewModel.markBlockSkipped(block)
    }
    
    private func handleShowTimeBlock(_ notification: Notification) {
        guard let blockIdString = notification.userInfo?["blockId"] as? String,
              let blockId = UUID(uuidString: blockIdString) else {
            return
        }
        
        // Scroll to the block and highlight it
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            scrollProxy?.scrollTo(blockId, anchor: .center)
        }
        
        highlightBlock(blockId)
    }
}
