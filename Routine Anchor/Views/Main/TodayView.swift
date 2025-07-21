//
//  TodayView.swift
//  Routine Anchor - Premium Version
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
                        headerSection
                            .padding(.top, geometry.safeAreaInsets.top + 20)
                        
                        // Content based on state
                        if let viewModel = viewModel {
                            if viewModel.hasScheduledBlocks {
                                mainContent(viewModel: viewModel)
                            } else {
                                PremiumTodayEmptyStateView(
                                    onCreateRoutine: {
                                        // Navigate to schedule builder
                                    },
                                    onUseTemplate: {
                                        // Show template picker
                                    }
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
            
            // Floating elements overlay
            floatingElements
        }
        .navigationBarHidden(true)
        .onAppear {
            setupViewModel()
            startPeriodicUpdates()
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
        .sheet(isPresented: $showingSummary) {
            PremiumDailySummaryView()
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
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 24) {
            // Top navigation bar
            HStack {
                // Date and greeting
                VStack(alignment: .leading, spacing: 4) {
                    Text(greetingText)
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundStyle(Color.white.opacity(0.8))
                    
                    Text(currentDateText)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }
                
                Spacer()
                
                // Action buttons
                HStack(spacing: 16) {
                    if viewModel?.shouldShowSummary == true {
                        NavigationButton(
                            icon: "chart.pie.fill",
                            gradient: [Color.premiumGreen, Color.premiumTeal]
                        ) {
                            showingSummary = true
                        }
                    }
                    
                    NavigationButton(
                        icon: "gearshape.fill",
                        gradient: [Color.premiumPurple, Color.premiumBlue]
                    ) {
                        showingSettings = true
                    }
                }
            }
            .padding(.horizontal, 24)
            
            // Progress overview (if has data)
            if let viewModel = viewModel, viewModel.hasScheduledBlocks {
                ProgressOverviewCard(viewModel: viewModel)
                    .padding(.horizontal, 24)
            }
        }
        .background(
            GeometryReader { geo in
                Color.clear
                    .preference(key: ScrollOffsetPreferenceKey.self, value: geo.frame(in: .named("scroll")).minY)
            }
        )
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
            timeBlocksSection(viewModel: viewModel)
            
            // Motivational section
            MotivationalCard(viewModel: viewModel)
                .padding(.horizontal, 24)
                .padding(.bottom, 100) // Space for tab bar
        }
        .padding(.top, 32)
    }
    
    // MARK: - Time Blocks Section
    private func timeBlocksSection(viewModel: TodayViewModel) -> some View {
        VStack(spacing: 16) {
            // Section header
            HStack {
                Text("Today's Schedule")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                
                Spacer()
                
                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                }
            }
            .padding(.horizontal, 24)
            
            // Time blocks
            LazyVStack(spacing: 12) {
                ForEach(viewModel.sortedTimeBlocks) { timeBlock in
                    PremiumTimeBlockRowView(
                        timeBlock: timeBlock,
                        onTap: {
                            handleTimeBlockTap(timeBlock)
                        },
                        onComplete: {
                            viewModel.markBlockCompleted(timeBlock)
                        },
                        onSkip: {
                            viewModel.markBlockSkipped(timeBlock)
                        }
                    )
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
                }
            }
            .padding(.horizontal, 24)
        }
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
                        .scaleEffect(refreshTrigger ? 1.2 : 0.8)
                        .animation(
                            .easeInOut(duration: 0.8)
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.2),
                            value: refreshTrigger
                        )
                        .offset(x: CGFloat(index - 1) * 20)
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
    
    // MARK: - Floating Elements
    private var floatingElements: some View {
        VStack {
            Spacer()
            
            // Quick insights or next action hint
            if let viewModel = viewModel,
               let nextBlock = viewModel.getNextUpcomingBlock() {
                QuickInsightCard(
                    title: "Up Next",
                    subtitle: nextBlock.title,
                    timeText: viewModel.timeUntilNextBlock() ?? "",
                    color: Color.premiumBlue
                )
                .padding(.horizontal, 24)
                .padding(.bottom, 120) // Above tab bar
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func setupViewModel() {
        let dataManager = DataManager(modelContext: modelContext)
        viewModel = TodayViewModel(dataManager: dataManager)
    }
    
    private func startPeriodicUpdates() {
        Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { _ in
            viewModel?.refreshData()
        }
    }
    
    private func refreshData() async {
        await viewModel?.pullToRefresh()
        
        // Add subtle haptic feedback
        HapticManager.shared.lightImpact()
    }
    
    private func updateScrollProgress(_ offset: CGFloat, geometry: GeometryProxy) {
        let progress = min(max(-offset / 100, 0), 1)
        
        withAnimation(.easeOut(duration: 0.1)) {
            scrollProgress = progress
            headerOffset = offset
        }
    }
    
    private func handleTimeBlockTap(_ timeBlock: TimeBlock) {
        HapticManager.shared.premiumSelection()
        
        selectedTimeBlock = timeBlock
        
        switch timeBlock.status {
        case .inProgress:
            showingActionSheet = true
        case .notStarted:
            if timeBlock.isCurrentlyActive {
                viewModel?.startTimeBlock(timeBlock)
            }
        case .completed, .skipped:
            // Could show details or allow undo
            break
        }
    }
    
    // MARK: - Computed Properties
    
    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        case 17..<22: return "Good evening"
        default: return "Good night"
        }
    }
    
    private var currentDateText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: Date())
    }
}

// MARK: - Time Indicator
struct TimeIndicator: View {
    let timeText: String
    let isActive: Bool
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(isActive ? Color.premiumGreen : Color.premiumBlue)
                .frame(width: 6, height: 6)
            
            Text(timeText)
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundStyle(isActive ? Color.premiumGreen : Color.premiumBlue)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill((isActive ? Color.premiumGreen : Color.premiumBlue).opacity(0.15))
        )
    }
}

// MARK: - Completion Actions
struct CompletionActions: View {
    let onViewSummary: () -> Void
    let onPlanTomorrow: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Button(action: onViewSummary) {
                HStack(spacing: 6) {
                    Image(systemName: "chart.pie.fill")
                        .font(.system(size: 14, weight: .medium))
                    Text("View Summary")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(
                        colors: [Color.premiumGreen, Color.premiumTeal],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(10)
            }
            
            Button(action: onPlanTomorrow) {
                HStack(spacing: 6) {
                    Image(systemName: "calendar.badge.plus")
                        .font(.system(size: 14, weight: .medium))
                    Text("Plan Tomorrow")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundStyle(Color.premiumBlue)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    Color.premiumBlue.opacity(0.15)
                )
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.premiumBlue.opacity(0.3), lineWidth: 1)
                )
            }
        }
    }
}

// MARK: - Scroll Offset Preference Key
struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
