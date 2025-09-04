//
//  DailySummaryView.swift
//  Routine Anchor
//
import SwiftUI
import SwiftData

struct DailySummaryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.premiumManager) private var premiumManager
    @Environment(\.themeManager) private var themeManager
    @State private var viewModel: DailySummaryViewModel
    @State private var showingPremiumUpgrade = false
    
    // MARK: - Animation State
    @State private var animationPhase = 0
    @State private var isVisible = false
    @State private var showingShareSheet = false
    
    // MARK: - Form State
    @State private var selectedRating: Int = 0
    @State private var dayNotes = ""
    
    // Theme color helpers
    private var themePrimaryText: Color {
        themeManager?.currentTheme.primaryTextColor ?? Theme.defaultTheme.primaryTextColor
    }
    
    private var themeSecondaryText: Color {
        themeManager?.currentTheme.secondaryTextColor ?? Theme.defaultTheme.secondaryTextColor
    }
    
    private var themeTertiaryText: Color {
        themeManager?.currentTheme.subtleTextColor ?? Theme.defaultTheme.subtleTextColor
    }
    
    private var cardShadowColor: Color {
        themeManager?.currentTheme.colorScheme.appBackground.color.opacity(0.1) ?? Theme.defaultTheme.colorScheme.appBackground.color.opacity(0.1)
    }
    
    init(modelContext: ModelContext, loadImmediately: Bool = true) {
        let dataManager = DataManager(modelContext: modelContext)
        let viewModel = DailySummaryViewModel(dataManager: dataManager, loadImmediately: loadImmediately)
        _viewModel = State(initialValue: viewModel)
    }
    
    var body: some View {
        ZStack {
            ThemedAnimatedBackground()
                .ignoresSafeArea()
            
            AnimatedMeshBackground()
                .opacity(0.3)
                .allowsHitTesting(false)
            
            ParticleEffectView()
                .allowsHitTesting(false)
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    headerSection
                    
                    // Main content
                    if viewModel.hasData {
                        VStack(spacing: 20) {
                            // Progress visualization
                            progressCircleSection(viewModel)
                            
                            // Statistics cards
                            statisticsSection(viewModel)
                            
                            // Task breakdown
                            if !viewModel.sortedTimeBlocks.isEmpty {
                                taskBreakdownSection(viewModel)
                            }
                            
                            // Performance insights
                            premiumGatedInsightsSection(viewModel)
                            
                            // Rating and reflection
                            ratingSection(viewModel)
                            
                            // Actions
                            actionSection(viewModel)
                        }
                    } else {
                        emptyStateView
                    }
                    
                    Spacer(minLength: 16)
                    
                    StyledAdBanner()
                }
                .padding(.horizontal, 12)
                .padding(.top, 16)
            }
        }
        .navigationBarHidden(true)
        .task {
            await setupInitialState()
        }
        .sheet(isPresented: $showingPremiumUpgrade) {
            if let premiumManager = premiumManager {
                PremiumUpgradeView(premiumManager: premiumManager)
            } else {
                // Fallback view when premium manager is unavailable
                ThemedCard {
                    VStack(spacing: 20) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(themeManager?.currentTheme.colorScheme.warningColor.color ?? Theme.defaultTheme.colorScheme.warningColor.color)
                        
                        Text("Premium Features")
                            .font(.title.bold())
                            .foregroundStyle(themePrimaryText)
                        
                        Text("Premium features are temporarily unavailable. Please try again later.")
                            .multilineTextAlignment(.center)
                            .foregroundStyle(themeSecondaryText)
                        
                        ThemedButton(title: "Close", style: .secondary) {
                            showingPremiumUpgrade = false
                        }
                    }
                }
                .padding()
                .presentationDetents([.medium])
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .refreshSummaryView)) { _ in
            Task { @MainActor in
                await viewModel.refreshData()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            // Refetch data when app becomes active (after ads)
            Task { @MainActor in
                await viewModel.refreshData()
            }
        }
        .onDisappear {
            Task { @MainActor in
                await saveDayRatingAndNotes()
                viewModel.cancelLoadTask()
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            ShareSummaryView(viewModel: viewModel)
                .environment(\.themeManager, themeManager)
        }
        .onChange(of: selectedRating) { _, newValue in
            if newValue > 0 {
                HapticManager.shared.lightImpact()
            }
        }
    }
    
    private func planTomorrow() {
        HapticManager.shared.impact()
        
        NotificationCenter.default.post(name: .navigateToSchedule, object: nil)
        
        // Small delay then dismiss
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            dismiss()
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 16) {
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(themeSecondaryText)
                        .frame(width: 36, height: 36)
                        .background(
                            Circle()
                                .fill(.ultraThinMaterial)
                                .background(
                                    Circle().fill(themeTertiaryText.opacity(0.1))
                                )
                        )
                        .shadow(color: cardShadowColor, radius: 8, x: 0, y: 4)
                }
                
                Spacer()
                
                Button(action: { showingShareSheet = true }) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(themeManager?.currentTheme.colorScheme.workflowPrimary.color ?? Theme.defaultTheme.colorScheme.workflowPrimary.color)
                        .frame(width: 36, height: 36)
                        .background(
                            Circle()
                                .fill(themeManager?.currentTheme.colorScheme.workflowPrimary.color ?? Theme.defaultTheme.colorScheme.workflowPrimary.color.opacity(0.15))
                        )
                        .overlay(
                            Circle()
                                .stroke(themeManager?.currentTheme.colorScheme.workflowPrimary.color ?? Theme.defaultTheme.colorScheme.workflowPrimary.color.opacity(0.3), lineWidth: 1)
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
                                    (themeManager?.currentTheme.colorScheme.actionSuccess.color ?? Theme.defaultTheme.colorScheme.actionSuccess.color)
                                        .opacity(themeManager?.currentTheme.colorScheme.glowIntensityPrimary ?? 0.15),
                                    (themeManager?.currentTheme.colorScheme.creativeSecondary.color ?? Theme.defaultTheme.colorScheme.creativeSecondary.color)
                                        .opacity(themeManager?.currentTheme.colorScheme.glowIntensitySecondary ?? 0.08),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: themeManager?.currentTheme.colorScheme.glowRadiusInner ?? 20,
                                endRadius: themeManager?.currentTheme.colorScheme.glowRadiusOuter ?? 60
                            )
                        )
                        .frame(width: 80, height: 80)
                        .blur(radius: themeManager?.currentTheme.colorScheme.glowBlurRadius ?? 10)
                        .scaleEffect(animationPhase == 0 ? 1.0 : (themeManager?.currentTheme.colorScheme.glowAnimationScale ?? 1.15))
                    
                    Image(systemName: "chart.pie.fill")
                        .font(.system(size: 40, weight: .light))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [themeManager?.currentTheme.colorScheme.actionSuccess.color ?? Theme.defaultTheme.colorScheme.actionSuccess.color, themeManager?.currentTheme.colorScheme.creativeSecondary.color ?? Theme.defaultTheme.colorScheme.creativeSecondary.color],
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
                                colors: [themeManager?.currentTheme.colorScheme.actionSuccess.color ?? Theme.defaultTheme.colorScheme.actionSuccess.color, themeManager?.currentTheme.colorScheme.creativeSecondary.color ?? Theme.defaultTheme.colorScheme.creativeSecondary.color],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    
                    if let progress = viewModel.safeDailyProgress {
                        Text(progress.formattedDate)
                            .font(.system(size: 18, weight: .medium, design: .rounded))
                            .foregroundStyle(themeSecondaryText)
                    }
                }
            }
        }
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : -20)
    }
    
    // MARK: - Progress Section (FIXED)
    private func progressCircleSection(_ viewModel: DailySummaryViewModel) -> some View {
        ThemedCard(cornerRadius: 24) {
            VStack(spacing: 0) {
                // Progress Circle Container
                VStack(spacing: 16) {
                    ZStack {
                        // Background circle
                        Circle()
                            .stroke(themeTertiaryText.opacity(0.2), lineWidth: 16)
                            .frame(width: 160, height: 160)
                        
                        // Use safe progress access
                        if let progress = viewModel.safeDailyProgress {
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
                                    .foregroundStyle(themeTertiaryText)
                                    .textCase(.uppercase)
                                    .tracking(1)
                            }
                        } else {
                            // Safe fallback when no progress available
                            VStack(spacing: 8) {
                                Text("📊")
                                    .font(.system(size: 36))
                                
                                Text("0%")
                                    .font(.system(size: 28, weight: .bold, design: .rounded))
                                    .foregroundStyle(themeTertiaryText)
                                
                                Text("Complete")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(themeTertiaryText)
                                    .textCase(.uppercase)
                                    .tracking(1)
                            }
                        }
                    }
                }
                
                // Motivational message in separate container to prevent overlap
                VStack(spacing: 0) {
                    if let progress = viewModel.safeDailyProgress {
                        Text(progress.motivationalMessage)
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundStyle(themeSecondaryText)
                            .multilineTextAlignment(.center)
                            .lineSpacing(3)
                            .padding(.horizontal, 24)
                            .padding(.top, 16)
                            .lineLimit(3)
                    } else {
                        Text("Ready to start your day?")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundStyle(themeSecondaryText)
                            .multilineTextAlignment(.center)
                            .lineSpacing(3)
                            .padding(.horizontal, 24)
                            .padding(.top, 16)
                    }
                }
            }
        }
        .shadow(color: cardShadowColor, radius: 20, x: 0, y: 10)
    }
    
    // MARK: - Statistics Section
    private func statisticsSection(_ viewModel: DailySummaryViewModel) -> some View {
        HStack(spacing: 12) {
            if let progress = viewModel.safeDailyProgress {
                StatCard(
                    title: "Completed",
                    value: "\(progress.completedBlocks)",
                    subtitle: progress.completedBlocks == 1 ? "block" : "blocks",
                    color: themeManager?.currentTheme.colorScheme.actionSuccess.color ?? Theme.defaultTheme.colorScheme.actionSuccess.color,
                    icon: "checkmark.circle.fill"
                )
                
                StatCard(
                    title: "Skipped",
                    value: "\(progress.skippedBlocks)",
                    subtitle: progress.skippedBlocks == 1 ? "block" : "blocks",
                    color: themeManager?.currentTheme.colorScheme.warningColor.color ?? Theme.defaultTheme.colorScheme.warningColor.color,
                    icon: "forward.fill"
                )
                
                StatCard(
                    title: "Time Used",
                    value: "\(progress.completedMinutes / 60)h \(progress.completedMinutes % 60)m",
                    subtitle: "planned",
                    color: themeManager?.currentTheme.colorScheme.workflowPrimary.color ?? Theme.defaultTheme.colorScheme.workflowPrimary.color,
                    icon: "clock.fill"
                )
            } else {
                // Safe fallback cards
                StatCard(
                    title: "Completed",
                    value: "0",
                    subtitle: "blocks",
                    color: themeManager?.currentTheme.colorScheme.actionSuccess.color ?? Theme.defaultTheme.colorScheme.actionSuccess.color,
                    icon: "checkmark.circle.fill"
                )
                
                StatCard(
                    title: "Skipped",
                    value: "0",
                    subtitle: "blocks",
                    color: themeManager?.currentTheme.colorScheme.warningColor.color ?? Theme.defaultTheme.colorScheme.warningColor.color,
                    icon: "forward.fill"
                )
                
                StatCard(
                    title: "Time Used",
                    value: "0h 0m",
                    subtitle: "planned",
                    color: themeManager?.currentTheme.colorScheme.workflowPrimary.color ?? Theme.defaultTheme.colorScheme.workflowPrimary.color,
                    icon: "clock.fill"
                )
            }
        }
    }
    
    // MARK: - Task Breakdown Section
    private func taskBreakdownSection(_ viewModel: DailySummaryViewModel) -> some View {
        ThemedCard(cornerRadius: 20) {
            VStack(spacing: 16) {
                HStack {
                    Image(systemName: "list.bullet.circle")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(themeManager?.currentTheme.colorScheme.organizationAccent.color ?? Theme.defaultTheme.colorScheme.organizationAccent.color)
                    
                    Text("Task Breakdown")
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .foregroundStyle(themePrimaryText)
                    
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
        }
        .shadow(color: cardShadowColor, radius: 10, x: 0, y: 5)
    }
    
    // MARK: - Insights Section
    private func premiumGatedInsightsSection(_ viewModel: DailySummaryViewModel) -> some View {
        ThemedCard(cornerRadius: 20) {
            VStack(spacing: 16) {
                HStack {
                    Image(systemName: "lightbulb.circle")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(themeManager?.currentTheme.colorScheme.warningColor.color ?? Theme.defaultTheme.colorScheme.warningColor.color)
                    
                    Text("Insights & Suggestions")
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .foregroundStyle(themePrimaryText)
                    
                    Spacer()
                    
                    // Show premium badge if user has premium
                    if premiumManager?.canAccessAdvancedAnalytics == true {
                        PremiumBadge()
                    }
                }
                
                if premiumManager?.canAccessAdvancedAnalytics == true {
                    // FULL INSIGHTS FOR PREMIUM USERS
                    VStack(spacing: 12) {
                        ForEach(Array(viewModel.getPersonalizedInsights().enumerated()), id: \.offset) { index, insight in
                            InsightRow(text: insight, delay: Double(index) * 0.1)
                        }
                        
                        // Show improvement suggestions for premium users
                        let suggestions = viewModel.getImprovementSuggestions()
                        if !suggestions.isEmpty {
                            Divider()
                                .background(themeTertiaryText.opacity(0.2))
                                .padding(.vertical, 8)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "brain.head.profile")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundStyle(themeManager?.currentTheme.colorScheme.creativeSecondary.color ?? Theme.defaultTheme.colorScheme.creativeSecondary.color)
                                    
                                    Text("AI Suggestions")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundStyle(themePrimaryText)
                                }
                                
                                ForEach(Array(suggestions.enumerated()), id: \.offset) { index, suggestion in
                                    HStack(alignment: .top, spacing: 8) {
                                        Text("•")
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundStyle(themeManager?.currentTheme.colorScheme.creativeSecondary.color ?? Theme.defaultTheme.colorScheme.creativeSecondary.color)
                                        
                                        Text(suggestion)
                                            .font(.system(size: 14))
                                            .foregroundStyle(themeSecondaryText)
                                            .lineLimit(nil)
                                    }
                                }
                            }
                        }
                    }
                } else {
                    // LIMITED INSIGHTS FOR FREE USERS
                    VStack(spacing: 16) {
                        // Show one basic insight
                        let basicInsight = generateBasicInsight(viewModel)
                        InsightRow(text: basicInsight, delay: 0.1)
                        
                        // Premium upgrade prompt
                        PremiumMiniPrompt(
                            title: "Unlock Advanced Insights",
                            subtitle: "Get AI-powered recommendations and detailed analysis"
                        ) {
                            showingPremiumUpgrade = true
                            HapticManager.shared.anchorSelection()
                        }
                        
                        // Show what premium users get
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "crown.fill")
                                    .font(.system(size: 12))
                                    .foregroundStyle(themeManager?.currentTheme.colorScheme.warningColor.color ?? Theme.defaultTheme.colorScheme.warningColor.color)
                                
                                Text("Premium insights include:")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(themeSecondaryText)
                            }
                            
                            let features = [
                                "🎯 Personalized productivity patterns",
                                "⏰ Time-of-day performance analysis",
                                "📊 Category-based recommendations",
                                "📈 Weekly progress trends",
                                "🧠 AI-powered improvement suggestions"
                            ]
                            
                            ForEach(features, id: \.self) { feature in
                                HStack(spacing: 8) {
                                    Text(feature)
                                        .font(.system(size: 12))
                                        .foregroundStyle(themeTertiaryText)
                                    
                                    Spacer()
                                }
                                .padding(.leading, 8)
                            }
                        }
                        .padding(.top, 8)
                    }
                }
            }
        }
        .shadow(color: cardShadowColor, radius: 10, x: 0, y: 5)
    }
    
    private func generateBasicInsight(_ viewModel: DailySummaryViewModel) -> String {
        guard let progress = viewModel.safeDailyProgress else {
            return "⭐ Create your first time block to start tracking progress!"
        }
        
        let completionRate = progress.completionPercentage
        
        if completionRate >= 0.8 {
            return "🎉 Excellent work! You're crushing your goals today with \(Int(completionRate * 100))% completion."
        } else if completionRate >= 0.6 {
            return "💪 Good progress! You're \(Int(completionRate * 100))% through your planned tasks."
        } else if completionRate >= 0.3 {
            return "📈 Building momentum! Every completed task is progress toward your goals."
        } else if progress.totalBlocks > 0 {
            return "🌱 Every journey starts with a single step. Keep going!"
        } else {
            return "⭐ Ready to start? Create your first time block to begin tracking progress!"
        }
    }
    
    // MARK: - Rating Section
    private func ratingSection(_ viewModel: DailySummaryViewModel) -> some View {
        ThemedCard(cornerRadius: 20) {
            VStack(spacing: 20) {
                HStack {
                    Image(systemName: "star.circle")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(themeManager?.currentTheme.colorScheme.warningColor.color ?? Theme.defaultTheme.colorScheme.warningColor.color)
                    
                    Text("Rate Your Day")
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .foregroundStyle(themePrimaryText)
                    
                    Spacer()
                }
                
                // Rating stars
                HStack(spacing: 12) {
                    ForEach(1...5, id: \.self) { rating in
                        Button(action: {
                            selectedRating = rating
                            HapticManager.shared.anchorSelection()
                        }) {
                            Image(systemName: selectedRating >= rating ? "star.fill" : "star")
                                .font(.system(size: 32, weight: .medium))
                                .foregroundStyle(
                                    selectedRating >= rating ?
                                    LinearGradient(
                                        colors: [themeManager?.currentTheme.colorScheme.warningColor.color ?? Theme.defaultTheme.colorScheme.warningColor.color, themeManager?.currentTheme.colorScheme.warningColor.color ?? Theme.defaultTheme.colorScheme.warningColor.color.opacity(0.8)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    ) :
                                    LinearGradient(
                                        colors: [themeTertiaryText, themeTertiaryText],
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
                            .foregroundStyle(themeManager?.currentTheme.colorScheme.creativeSecondary.color ?? Theme.defaultTheme.colorScheme.creativeSecondary.color)
                        
                        Text("Reflection")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(themeSecondaryText)
                    }
                    
                    TextField("How did your day go?", text: $dayNotes, axis: .vertical)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(themePrimaryText)
                        .lineLimit(3...6)
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(themeTertiaryText.opacity(0.1))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(themeTertiaryText.opacity(0.2), lineWidth: 1)
                        )
                }
            }
        }
        .shadow(color: cardShadowColor, radius: 10, x: 0, y: 5)
        .onAppear {
            if let progress = viewModel.safeDailyProgress {
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
                    .foregroundStyle(themeManager?.currentTheme.colorScheme.actionSuccess.color ?? Theme.defaultTheme.colorScheme.actionSuccess.color)
                    .multilineTextAlignment(.center)
            }
            
            ThemedButton(
                title: viewModel.isDayComplete ? "Plan Tomorrow" : "Back to Schedule",
                style: .primary
            ) {
                planTomorrow()
            }
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
                                themeManager?.currentTheme.colorScheme.actionSuccess.color ?? Theme.defaultTheme.colorScheme.actionSuccess.color.opacity(0.3),
                                themeManager?.currentTheme.colorScheme.creativeSecondary.color ?? Theme.defaultTheme.colorScheme.creativeSecondary.color.opacity(0.1),
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
                            colors: [themeManager?.currentTheme.colorScheme.actionSuccess.color ?? Theme.defaultTheme.colorScheme.actionSuccess.color, themeManager?.currentTheme.colorScheme.creativeSecondary.color ?? Theme.defaultTheme.colorScheme.creativeSecondary.color],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .floatModifier()
            }
            
            VStack(spacing: 16) {
                Text("No Data Yet")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(themePrimaryText)
                
                Text("Complete some time blocks to see your daily summary")
                    .font(.system(size: 18, weight: .regular, design: .rounded))
                    .foregroundStyle(themeSecondaryText)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
            
            ThemedButton(title: "Start Your Day", style: .primary) {
                // Navigate to Today tab
                NotificationCenter.default.post(name: .navigateToToday, object: nil)
            }
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
                        .fill(themeManager?.currentTheme.colorScheme.actionSuccess.color ?? Theme.defaultTheme.colorScheme.actionSuccess.color.opacity(0.3))
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
                .foregroundStyle(themeSecondaryText)
            
            Spacer()
        }
    }
    
    // MARK: - Helper Methods
    
    @MainActor
    private func setupInitialState() async {
        await viewModel.refreshData()
        startAnimations()
    }
    
    private func startAnimations() {
        withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
            animationPhase = 1
        }
        
        withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.1)) {
            isVisible = true
        }
    }
    
    private func saveDayRatingAndNotes() async {
        if selectedRating > 0 || !dayNotes.isEmpty {
            await viewModel.saveDayRatingAndNotes(rating: selectedRating, notes: dayNotes)
            HapticManager.shared.lightImpact()
        }
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

// MARK: - Supporting Components

struct InsightRow: View {
    let text: String
    let delay: Double
    
    @Environment(\.themeManager) private var themeManager
    @State private var isVisible = false
    
    private var themeSecondaryText: Color {
        themeManager?.currentTheme.secondaryTextColor ?? Theme.defaultTheme.secondaryTextColor
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(themeManager?.currentTheme.colorScheme.warningColor.color ?? Theme.defaultTheme.colorScheme.warningColor.color.opacity(0.3))
                .frame(width: 6, height: 6)
                .offset(y: 6)
            
            Text(text)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(themeSecondaryText)
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
    NavigationStack {
        DailySummaryView(
            modelContext: ModelContext(
                try! ModelContainer(
                    for: TimeBlock.self,
                    configurations: ModelConfiguration(isStoredInMemoryOnly: true)
                )
            ),
            loadImmediately: false
        )
    }
}

#Preview("With Data - Static") {
    NavigationStack {
        DailySummaryView(
            modelContext: ModelContext(
                try! ModelContainer(
                    for: Schema([TimeBlock.self, DailyProgress.self]),
                    configurations: ModelConfiguration(isStoredInMemoryOnly: true)
                )
            ),
            loadImmediately: false
        )
    }
}
