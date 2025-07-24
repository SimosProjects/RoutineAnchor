//
//  TodayView.swift
//  Routine Anchor - Premium Version (Refactored)
//
import SwiftUI
import SwiftData

struct PremiumTodayView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: TodayViewModel?
    
    // MARK: - State
    @State private var showingSettings = false
    @State private var showingSummary = false
    @State private var selectedTimeBlock: TimeBlock?
    @State private var showingActionSheet = false
    @State private var headerOffset: CGFloat = 0
    @State private var scrollProgress: CGFloat = 0
    @State private var refreshTrigger = false
    
    var body: some View {
        ZStack {
            // Premium background
            AnimatedGradientBackground()
                .ignoresSafeArea()
            
            GeometryReader { geometry in
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 0) {
                        // Header section
                        if let viewModel = viewModel {
                            TodayHeaderView(
                                viewModel: viewModel,
                                showingSettings: $showingSettings,
                                showingSummary: $showingSummary
                            )
                            .padding(.top, geometry.safeAreaInsets.top + 20)
                        }
                        
                        // Content based on state
                        if let viewModel = viewModel {
                            if viewModel.hasScheduledBlocks {
                                mainContent(viewModel: viewModel)
                            } else {
                                PremiumTodayEmptyStateView(
                                    onCreateRoutine: navigateToScheduleBuilder,
                                    onUseTemplate: showTemplates
                                )
                            }
                        } else {
                            loadingState
                        }
                    }
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
        .navigationBarHidden(true)
        .onAppear {
            setupViewModel()
            startPeriodicUpdates()
            viewModel?.refreshData()
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
        .sheet(isPresented: $showingSummary) {
            if let viewModel = viewModel {
                PremiumDailySummaryView()
                    .environment(DataManager(modelContext: modelContext))
                    .onDisappear {
                        viewModel.markDayAsReviewed()
                    }
            }
        }
        .confirmationDialog(
            "Time Block Actions",
            isPresented: $showingActionSheet,
            titleVisibility: .visible,
            presenting: selectedTimeBlock
        ) { timeBlock in
            Button("Mark as Completed") {
                viewModel?.markBlockCompleted(timeBlock)
            }
            
            Button("Skip This Block", role: .destructive) {
                viewModel?.markBlockSkipped(timeBlock)
            }
            
            Button("Cancel", role: .cancel) {}
        } message: { timeBlock in
            Text("What would you like to do with '\(timeBlock.title)'?")
        }
        .alert("Error", isPresented: .constant(viewModel?.errorMessage != nil)) {
            Button("Retry") {
                viewModel?.retryLastOperation()
            }
            Button("Dismiss", role: .cancel) {
                viewModel?.clearError()
            }
        } message: {
            Text(viewModel?.errorMessage ?? "")
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
                showingActionSheet: $showingActionSheet
            )
            
            // Motivational section
            MotivationalCard(viewModel: viewModel)
                .padding(.horizontal, 24)
                .padding(.bottom, 100) // Space for tab bar
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
    
    private func setupViewModel() {
        if viewModel == nil {
            let dataManager = DataManager(modelContext: modelContext)
            viewModel = TodayViewModel(dataManager: dataManager)
        }
    }
    
    private func startPeriodicUpdates() {
        Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
            Task { @MainActor in
                viewModel?.refreshData()
            }
        }
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
            viewModel?.refreshData()
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
    
    // MARK: - Notification Handlers
    
    private func handleTimeBlockCompletion(_ notification: Notification) {
        guard let blockId = notification.userInfo?["blockId"] as? UUID,
              let block = viewModel?.timeBlocks.first(where: { $0.id == blockId }) else {
            return
        }
        
        viewModel?.markBlockCompleted(block)
    }
    
    private func handleTimeBlockSkip(_ notification: Notification) {
        guard let blockId = notification.userInfo?["blockId"] as? UUID,
              let block = viewModel?.timeBlocks.first(where: { $0.id == blockId }) else {
            return
        }
        
        viewModel?.markBlockSkipped(block)
    }
    
    private func handleShowTimeBlock(_ notification: Notification) {
        guard let blockIdString = notification.userInfo?["blockId"] as? String,
              let blockId = UUID(uuidString: blockIdString),
              let block = viewModel?.timeBlocks.first(where: { $0.id == blockId }) else {
            return
        }
        
        selectedTimeBlock = block
        
        // Scroll to the block if needed
        // This would require additional implementation
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let navigateToSchedule = Notification.Name("navigateToSchedule")
    static let showTemplates = Notification.Name("showTemplates")
}

// MARK: - Scroll Offset Preference Key
struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - Preview
#Preview {
    PremiumTodayView()
        .modelContainer(for: [TimeBlock.self, DailyProgress.self], inMemory: true)
}
