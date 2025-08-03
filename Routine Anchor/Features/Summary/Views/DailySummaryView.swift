//
//  PremiumDailySummaryView.swift
//  Routine Anchor
//
import SwiftUI
import SwiftData

struct PremiumDailySummaryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: DailySummaryViewModel?
    
    // MARK: - Animation State
    @State private var animationPhase = 0
    @State private var particleSystem = ParticleSystem()
    @State private var isVisible = false
    @State private var showingShareSheet = false
    
    // MARK: - Form State
    @State private var selectedRating: Int = 0
    @State private var dayNotes = ""
    
    var body: some View {
        ZStack {
            // Premium animated background
            AnimatedGradientBackground()
                .ignoresSafeArea()
            
            AnimatedMeshBackground()
                .opacity(0.3)
                .allowsHitTesting(false)
            
            ParticleEffectView(system: particleSystem)
                .allowsHitTesting(false)
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 12) {
                    // Header
                    headerSection
                    
                    // Main content
                    if let viewModel = viewModel {
                        if viewModel.hasData {
                            VStack(spacing: 12) {
                                // Progress visualization
                                progressSection(viewModel)
                                
                                // Statistics cards
                                statisticsSection(viewModel)
                                
                                // Task breakdown
                                if !viewModel.sortedTimeBlocks.isEmpty {
                                    taskBreakdownSection(viewModel)
                                }
                                
                                // Performance insights
                                insightsSection(viewModel)
                                
                                // Rating and reflection
                                ratingSection(viewModel)
                                
                                // Actions
                                actionSection(viewModel)
                            }
                        } else {
                            emptyStateView
                        }
                    } else {
                        loadingView
                    }
                    
                    Spacer(minLength: 16)
                }
                .padding(.horizontal, 12)
                .padding(.top, 16)
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            if viewModel == nil {
                setupViewModel()
            }
            startAnimations()
        }
        .onReceive(NotificationCenter.default.publisher(for: .refreshSummaryView)) { _ in
            viewModel?.refreshData()
        }
        .onDisappear {
            saveDayRatingAndNotes()
        }
        .sheet(isPresented: $showingShareSheet) {
            if let viewModel = viewModel {
                ShareSummaryView(viewModel: viewModel)
            }
        }
        .onChange(of: selectedRating) { _, newValue in
            if newValue > 0 {
                HapticManager.shared.lightImpact()
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 16) {
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.8))
                        .frame(width: 36, height: 36)
                        .background(
                            Circle()
                                .fill(.ultraThinMaterial)
                                .background(
                                    Circle().fill(Color.white.opacity(0.1))
                                )
                        )
                        .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                }
                
                Spacer()
                
                Button(action: { showingShareSheet = true }) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Color.premiumBlue)
                        .frame(width: 36, height: 36)
                        .background(
                            Circle()
                                .fill(Color.premiumBlue.opacity(0.15))
                        )
                        .overlay(
                            Circle()
                                .stroke(Color.premiumBlue.opacity(0.3), lineWidth: 1)
                        )
                }
            }
            
            VStack(spacing: 12) {
                // Animated icon
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.premiumGreen.opacity(0.4),
                                    Color.premiumTeal.opacity(0.2),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 30,
                                endRadius: 80
                            )
                        )
                        .frame(width: 80, height: 80)
                        .blur(radius: 20)
                        .scaleEffect(animationPhase == 0 ? 1.0 : 1.3)
                    
                    Image(systemName: "chart.pie.fill")
                        .font(.system(size: 40, weight: .light))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.premiumGreen, Color.premiumTeal],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .scaleEffect(animationPhase == 0 ? 1.0 : 1.1)
                }
                
                VStack(spacing: 8) {
                    Text("Daily Summary")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.premiumGreen, Color.premiumTeal],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    
                    if let viewModel = viewModel, let progress = viewModel.dailyProgress {
                        Text(progress.formattedDate)
                            .font(.system(size: 18, weight: .medium, design: .rounded))
                            .foregroundStyle(Color.white.opacity(0.7))
                    }
                }
            }
        }
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : -20)
    }
    
    // MARK: - Progress Section
    private func progressSection(_ viewModel: DailySummaryViewModel) -> some View {
        VStack(spacing: 24) {
            if let progress = viewModel.dailyProgress {
                // Main progress circle
                ZStack {
                    // Background circles
                    ForEach(0..<3) { index in
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        progress.performanceLevel.color.opacity(0.3 - Double(index) * 0.1),
                                        progress.performanceLevel.color.opacity(0.1 - Double(index) * 0.03)
                                    ],
                                    startPoint: .topTrailing,
                                    endPoint: .bottomLeading
                                ),
                                lineWidth: 2
                            )
                            .frame(
                                width: 180 + CGFloat(index * 20),
                                height: 180 + CGFloat(index * 20)
                            )
                            .rotationEffect(.degrees(Double(index) * 30))
                    }
                    
                    // Main progress ring
                    Circle()
                        .stroke(Color.white.opacity(0.1), lineWidth: 16)
                        .frame(width: 160, height: 160)
                    
                    Circle()
                        .trim(from: 0, to: CGFloat(progress.completionPercentage))
                        .stroke(
                            LinearGradient(
                                colors: [
                                    progress.performanceLevel.color,
                                    progress.performanceLevel.color.opacity(0.6)
                                ],
                                startPoint: .topTrailing,
                                endPoint: .bottomLeading
                            ),
                            style: StrokeStyle(lineWidth: 16, lineCap: .round)
                        )
                        .frame(width: 160, height: 160)
                        .rotationEffect(.degrees(-90))
                        .animation(.spring(response: 1.2, dampingFraction: 0.8), value: progress.completionPercentage)
                    
                    // Center content
                    VStack(spacing: 8) {
                        Text(progress.performanceLevel.emoji)
                            .font(.system(size: 36))
                        
                        Text(progress.formattedCompletionPercentage)
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(progress.performanceLevel.color)
                        
                        Text("Complete")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Color.white.opacity(0.6))
                            .textCase(.uppercase)
                            .tracking(1)
                    }
                }
                
                // Motivational message
                Text(progress.motivationalMessage)
                    .font(.system(size: 18, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 20)
            }
        }
        .padding(24)
        .glassMorphism(cornerRadius: 24)
        .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
    }
    
    // MARK: - Statistics Section
    private func statisticsSection(_ viewModel: DailySummaryViewModel) -> some View {
        HStack(spacing: 12) {
            if let progress = viewModel.dailyProgress {
                StatCard(
                    title: "Completed",
                    value: "\(progress.completedBlocks)",
                    subtitle: progress.completedBlocks == 1 ? "block" : "blocks",
                    color: Color.premiumGreen,
                    icon: "checkmark.circle.fill"
                )
                
                StatCard(
                    title: "Time",
                    value: formatTime(progress.completedMinutes),
                    subtitle: "tracked",
                    color: Color.premiumBlue,
                    icon: "clock.fill"
                )
                
                StatCard(
                    title: "Skipped",
                    value: "\(progress.skippedBlocks)",
                    subtitle: progress.skippedBlocks == 1 ? "block" : "blocks",
                    color: Color.premiumWarning,
                    icon: "forward.circle.fill"
                )
            }
        }
    }
    
    // MARK: - Task Breakdown Section
    private func taskBreakdownSection(_ viewModel: DailySummaryViewModel) -> some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "list.bullet.circle")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(Color.premiumPurple)
                
                Text("Task Breakdown")
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                
                Spacer()
            }
            
            VStack(spacing: 8) {
                ForEach(viewModel.sortedTimeBlocks) { timeBlock in
                    TaskBreakdownRow(timeBlock: timeBlock)
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                }
            }
        }
        .padding(20)
        .glassMorphism(cornerRadius: 20)
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
    
    // MARK: - Insights Section
    private func insightsSection(_ viewModel: DailySummaryViewModel) -> some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "lightbulb.circle")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(Color.premiumWarning)
                
                Text("Insights & Suggestions")
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                
                Spacer()
            }
            
            VStack(spacing: 12) {
                ForEach(Array(viewModel.getPersonalizedInsights().enumerated()), id: \.offset) { index, insight in
                    InsightRow(text: insight, delay: Double(index) * 0.1)
                }
            }
        }
        .padding(20)
        .glassMorphism(cornerRadius: 20)
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
    
    // MARK: - Rating Section
    private func ratingSection(_ viewModel: DailySummaryViewModel) -> some View {
        VStack(spacing: 20) {
            HStack {
                Image(systemName: "star.circle")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(Color.premiumWarning)
                
                Text("Rate Your Day")
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                
                Spacer()
            }
            
            // Rating stars
            HStack(spacing: 12) {
                ForEach(1...5, id: \.self) { rating in
                    Button(action: {
                        selectedRating = rating
                        HapticManager.shared.premiumSelection()
                    }) {
                        Image(systemName: selectedRating >= rating ? "star.fill" : "star")
                            .font(.system(size: 32, weight: .medium))
                            .foregroundStyle(
                                selectedRating >= rating ?
                                LinearGradient(
                                    colors: [Color.premiumWarning, Color.premiumWarning.opacity(0.8)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                ) :
                                LinearGradient(
                                    colors: [Color.white.opacity(0.3), Color.white.opacity(0.3)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .scaleEffect(selectedRating == rating ? 1.2 : 1.0)
                            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: selectedRating)
                    }
                }
            }
            
            // Notes field
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "note.text")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.premiumTeal)
                    
                    Text("Reflection")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.white.opacity(0.8))
                }
                
                TextField("How did your day go?", text: $dayNotes, axis: .vertical)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.white)
                    .lineLimit(3...6)
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.1))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            }
        }
        .padding(20)
        .glassMorphism(cornerRadius: 20)
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        .onAppear {
            if let progress = viewModel.dailyProgress {
                selectedRating = progress.dayRating ?? 0
                dayNotes = progress.dayNotes ?? ""
            }
        }
    }
    
    // MARK: - Action Section
    private func actionSection(_ viewModel: DailySummaryViewModel) -> some View {
        VStack(spacing: 16) {
            if viewModel.isDayComplete {
                Text("🎉 Congratulations on completing your day!")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.premiumGreen)
                    .multilineTextAlignment(.center)
            }
            
            PremiumButton(
                title: "Plan Tomorrow",
                style: .gradient,
                action: planTomorrow
            )
            
            SecondaryActionButton(
                title: viewModel.isDayComplete ? "Done" : "Back to Today",
                icon: viewModel.isDayComplete ? "checkmark" : "arrow.left",
                action: { dismiss() }
            )
        }
    }
    
    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Illustration
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.premiumGreen.opacity(0.3),
                                Color.premiumTeal.opacity(0.1),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 50,
                            endRadius: 150
                        )
                    )
                    .frame(width: 200, height: 200)
                    .blur(radius: 30)
                
                Image(systemName: "chart.pie")
                    .font(.system(size: 80, weight: .thin))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.premiumGreen, Color.premiumTeal],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .premiumFloat()
            }
            
            VStack(spacing: 16) {
                Text("No Data Yet")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                
                Text("Complete some time blocks to see your daily summary")
                    .font(.system(size: 18, weight: .regular, design: .rounded))
                    .foregroundStyle(Color.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
            
            PremiumButton(
                title: "Start Your Day",
                action: {
                    // Navigate to Today tab
                    NotificationCenter.default.post(name: .navigateToToday, object: nil)
                }
            )
        }
        .padding(.horizontal, 40)
    }
    
    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            ZStack {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(Color.premiumGreen.opacity(0.3))
                        .frame(width: 12, height: 12)
                        .scaleEffect(animationPhase == 0 ? 0.8 : 1.2)
                        .animation(
                            .easeInOut(duration: 0.8)
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.2),
                            value: animationPhase
                        )
                        .offset(x: CGFloat(index - 1) * 20)
                }
            }
            
            Text("Loading your summary...")
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundStyle(Color.white.opacity(0.7))
            
            Spacer()
        }
    }
    
    // MARK: - Helper Methods
    
    private func setupViewModel() {
        if viewModel == nil {
            let dataManager = DataManager(modelContext: modelContext)
            viewModel = DailySummaryViewModel(dataManager: dataManager)
        } else {
            // Refresh data when returning to the view
            viewModel?.refreshData()
        }
    }
    
    private func startAnimations() {
        particleSystem.startEmitting()
        
        withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
            animationPhase = 1
        }
        
        withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.1)) {
            isVisible = true
        }
    }
    
    private func saveDayRatingAndNotes() {
        guard let viewModel = viewModel else { return }
        
        if selectedRating > 0 || !dayNotes.isEmpty {
            viewModel.saveDayRatingAndNotes(rating: selectedRating, notes: dayNotes)
            HapticManager.shared.lightImpact()
        }
    }
    
    private func planTomorrow() {
        HapticManager.shared.premiumImpact()
        // Navigate to schedule builder for tomorrow
        dismiss()
    }
    
    private func formatTime(_ minutes: Int) -> String {
        let hours = minutes / 60
        let mins = minutes % 60
        
        if hours > 0 && mins > 0 {
            return "\(hours)h \(mins)m"
        } else if hours > 0 {
            return "\(hours)h"
        } else {
            return "\(mins)m"
        }
    }
}

// MARK: - Supporting Components (kept in main file)

struct InsightRow: View {
    let text: String
    let delay: Double
    
    @State private var isVisible = false
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(Color.premiumWarning.opacity(0.3))
                .frame(width: 6, height: 6)
                .offset(y: 6)
            
            Text(text)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.white.opacity(0.8))
                .lineSpacing(2)
            
            Spacer()
        }
        .opacity(isVisible ? 1 : 0)
        .offset(x: isVisible ? 0 : -20)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(delay)) {
                isVisible = true
            }
        }
    }
}

// MARK: - Preview
#Preview("Empty State") {
    PremiumDailySummaryView()
        .modelContainer(for: [TimeBlock.self, DailyProgress.self], inMemory: true)
}

#Preview("With Data") {
    let container = try! ModelContainer(for: TimeBlock.self, DailyProgress.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    let context = container.mainContext
    
    // Create sample time blocks
    let calendar = Calendar.current
    let today = Date()
    
    let timeBlocks = [
        TimeBlock(
            title: "Morning Routine",
            startTime: calendar.date(bySettingHour: 7, minute: 0, second: 0, of: today)!,
            endTime: calendar.date(bySettingHour: 8, minute: 0, second: 0, of: today)!,
            icon: "☕",
            category: "Personal"
        ),
        TimeBlock(
            title: "Project Work",
            startTime: calendar.date(bySettingHour: 9, minute: 0, second: 0, of: today)!,
            endTime: calendar.date(bySettingHour: 12, minute: 0, second: 0, of: today)!,
            icon: "💼",
            category: "Work"
        ),
        TimeBlock(
            title: "Gym Session",
            startTime: calendar.date(bySettingHour: 17, minute: 0, second: 0, of: today)!,
            endTime: calendar.date(bySettingHour: 18, minute: 0, second: 0, of: today)!,
            icon: "🏋️",
            category: "Health"
        )
    ]
    
    // Set statuses
    timeBlocks[0].status = .completed
    timeBlocks[1].status = .completed
    timeBlocks[2].status = .skipped
    
    // Insert into context
    for block in timeBlocks {
        context.insert(block)
    }
    
    // Create daily progress
    let progress = DailyProgress(date: today)
    progress.totalBlocks = 3
    progress.completedBlocks = 2
    progress.skippedBlocks = 1
    progress.totalPlannedMinutes = 300
    progress.completedMinutes = 240
    progress.dayRating = 4
    progress.dayNotes = "Good productive day! Missed the gym but got important work done."
    
    context.insert(progress)
    
    // Save context
    try? context.save()
    
    return PremiumDailySummaryView()
        .modelContainer(container)
}
