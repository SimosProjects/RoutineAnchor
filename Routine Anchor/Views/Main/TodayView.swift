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
            PremiumSettingsView()
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

// MARK: - Progress Overview Card
struct ProgressOverviewCard: View {
    let viewModel: TodayViewModel
    @State private var animateProgress = false
    
    var body: some View {
        HStack(spacing: 20) {
            // Circular progress
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.2), lineWidth: 4)
                    .frame(width: 60, height: 60)
                
                Circle()
                    .trim(from: 0, to: animateProgress ? CGFloat(viewModel.progressPercentage) : 0)
                    .stroke(
                        LinearGradient(
                            colors: [Color.premiumGreen, Color.premiumTeal],
                            startPoint: .topTrailing,
                            endPoint: .bottomLeading
                        ),
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .frame(width: 60, height: 60)
                    .rotationEffect(.degrees(-90))
                
                Text(viewModel.formattedProgressPercentage)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }
            
            // Progress details
            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.completionSummary)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                
                Text(viewModel.timeSummary)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.7))
                
                // Performance indicator
                HStack(spacing: 6) {
                    Text(viewModel.performanceLevel.emoji)
                        .font(.system(size: 12))
                    
                    Text(viewModel.performanceLevel.displayName)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(viewModel.performanceLevel.color)
                }
            }
            
            Spacer()
        }
        .padding(20)
        .glassMorphism(cornerRadius: 16)
        .onAppear {
            withAnimation(.spring(response: 1.2, dampingFraction: 0.8).delay(0.3)) {
                animateProgress = true
            }
        }
    }
}

// MARK: - Focus Card
struct FocusCard: View {
    let text: String
    let currentBlock: TimeBlock?
    let viewModel: TodayViewModel
    
    @State private var pulseScale: CGFloat = 1.0
    @State private var progressAnimation: CGFloat = 0
    
    var body: some View {
        HStack(spacing: 16) {
            // Focus icon with pulse
            ZStack {
                Circle()
                    .fill(Color.premiumBlue.opacity(0.2))
                    .frame(width: 50, height: 50)
                    .scaleEffect(pulseScale)
                
                Image(systemName: "target")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(Color.premiumBlue)
            }
            
            // Focus content
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Focus Mode")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.white.opacity(0.6))
                        .textCase(.uppercase)
                        .tracking(1)
                    
                    Spacer()
                    
                    // Time indicator
                    if let currentBlock = currentBlock,
                       let remainingTime = viewModel.remainingTimeForCurrentBlock() {
                        TimeIndicator(
                            timeText: remainingTime,
                            isActive: true
                        )
                    } else if let nextTime = viewModel.timeUntilNextBlock() {
                        TimeIndicator(
                            timeText: "in \(nextTime)",
                            isActive: false
                        )
                    }
                }
                
                Text(text)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                
                // Progress bar for current block
                if let currentBlock = currentBlock, currentBlock.isCurrentlyActive {
                    ProgressBar(
                        progress: currentBlock.currentProgress,
                        color: Color.premiumBlue,
                        animated: true
                    )
                }
            }
        }
        .padding(20)
        .glassMorphism(cornerRadius: 16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.premiumBlue.opacity(0.4),
                            Color.premiumBlue.opacity(0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .onAppear {
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                pulseScale = 1.1
            }
        }
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

// MARK: - Progress Bar
struct ProgressBar: View {
    let progress: Double
    let color: Color
    let animated: Bool
    
    @State private var animatedProgress: CGFloat = 0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Track
                Capsule()
                    .fill(Color.white.opacity(0.1))
                    .frame(height: 4)
                
                // Progress
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [color, color.opacity(0.7)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(
                        width: geometry.size.width * animatedProgress,
                        height: 4
                    )
            }
        }
        .frame(height: 4)
        .onAppear {
            if animated {
                withAnimation(.spring(response: 1.0, dampingFraction: 0.8).delay(0.5)) {
                    animatedProgress = CGFloat(progress)
                }
            } else {
                animatedProgress = CGFloat(progress)
            }
        }
        .onChange(of: progress) { _, newValue in
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                animatedProgress = CGFloat(newValue)
            }
        }
    }
}

// MARK: - Motivational Card
struct MotivationalCard: View {
    let viewModel: TodayViewModel
    @State private var showConfetti = false
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text(viewModel.performanceLevel.emoji)
                    .font(.system(size: 32))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Daily Reflection")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.white.opacity(0.6))
                        .textCase(.uppercase)
                        .tracking(1)
                    
                    Text(viewModel.motivationalMessage)
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
            }
            
            if viewModel.isDayComplete {
                CompletionActions(onViewSummary: {
                    // Show summary
                }, onPlanTomorrow: {
                    // Plan tomorrow
                })
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .background(
                    LinearGradient(
                        colors: [
                            viewModel.performanceLevel.color.opacity(0.1),
                            Color.clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .cornerRadius(16)
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    LinearGradient(
                        colors: [
                            viewModel.performanceLevel.color.opacity(0.3),
                            viewModel.performanceLevel.color.opacity(0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .overlay(
            // Confetti overlay
            ConfettiView(isActive: $showConfetti)
                .allowsHitTesting(false)
        )
        .onAppear {
            if viewModel.isDayComplete && viewModel.progressPercentage >= 0.8 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showConfetti = true
                }
            }
        }
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

// MARK: - Quick Insight Card
struct QuickInsightCard: View {
    let title: String
    let subtitle: String
    let timeText: String
    let color: Color
    
    @State private var isVisible = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 36, height: 36)
                
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(color)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.6))
                
                Text(subtitle)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Time
            Text(timeText)
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundStyle(color)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(color.opacity(0.15))
                )
        }
        .padding(16)
        .glassMorphism(cornerRadius: 12)
        .scaleEffect(isVisible ? 1 : 0.8)
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : 20)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2)) {
                isVisible = true
            }
        }
    }
}

// MARK: - Navigation Button
struct NavigationButton: View {
    let icon: String
    let gradient: [Color]
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isPressed = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    isPressed = false
                }
                action()
            }
        }) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(.white)
                .frame(width: 40, height: 40)
                .background(
                    LinearGradient(
                        colors: gradient,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(12)
                .shadow(color: gradient.first?.opacity(0.3) ?? .clear, radius: 8, x: 0, y: 4)
                .scaleEffect(isPressed ? 0.95 : 1)
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
