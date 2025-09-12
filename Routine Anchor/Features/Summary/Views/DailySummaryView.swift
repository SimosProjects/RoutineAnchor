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

    // Anim
    @State private var animationPhase = 0
    @State private var isVisible = false
    @State private var showingShareSheet = false

    // Form
    @State private var selectedRating: Int = 0
    @State private var dayNotes = ""

    // Quick theme handles
    private var theme: Theme { themeManager?.currentTheme ?? Theme.defaultTheme }
    private var scheme: ThemeColorScheme { theme.colorScheme }

    private var themePrimaryText: Color { theme.primaryTextColor }
    private var themeSecondaryText: Color { theme.secondaryTextColor }
    private var themeTertiaryText: Color { theme.subtleTextColor }
    private var cardShadowColor: Color { scheme.primaryBackground.color.opacity(0.12) }

    init(modelContext: ModelContext, loadImmediately: Bool = true) {
        let dataManager = DataManager(modelContext: modelContext)
        let vm = DailySummaryViewModel(dataManager: dataManager, loadImmediately: loadImmediately)
        _viewModel = State(initialValue: vm)
    }

    var body: some View {
        ZStack {
            // Consistent hero background (matches Today/Schedule/Add)
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

                    if viewModel.hasData {
                        VStack(spacing: 20) {
                            progressCircleSection(viewModel)
                            statisticsSection(viewModel)

                            if !viewModel.sortedTimeBlocks.isEmpty {
                                taskBreakdownSection(viewModel)
                            }

                            premiumGatedInsightsSection(viewModel)
                            ratingSection(viewModel)
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
        .task { await setupInitialState() }
        .sheet(isPresented: $showingPremiumUpgrade) {
            if premiumManager != nil {
                PremiumUpgradeView()
                    .environment(\.themeManager, themeManager)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            } else {
                ThemedCard {
                    VStack(spacing: 20) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(scheme.warning.color)

                        Text("Premium Features").font(.title.bold()).foregroundStyle(themePrimaryText)

                        Text("Premium features are temporarily unavailable. Please try again later.")
                            .multilineTextAlignment(.center)
                            .foregroundStyle(themeSecondaryText)

                        ThemedButton(title: "Close", style: .secondary) { showingPremiumUpgrade = false }
                    }
                }
                .padding()
                .presentationDetents([.medium])
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .refreshSummaryView)) { _ in
            Task { @MainActor in await viewModel.refreshData() }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            Task { @MainActor in await viewModel.refreshData() }
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
        .onChange(of: selectedRating) { _, newValue in if newValue > 0 { HapticManager.shared.lightImpact() } }
    }

    private func planTomorrow() {
        HapticManager.shared.impact()
        NotificationCenter.default.post(name: .navigateToSchedule, object: nil)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { dismiss() }
    }

    // MARK: - Header
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
                                .fill(scheme.primaryUIElement.color.opacity(0.65))
                                .overlay(Circle().stroke(scheme.border.color.opacity(0.85), lineWidth: 1))
                        )
                        .shadow(color: cardShadowColor, radius: 8, x: 0, y: 4)
                }

                Spacer()

                Button(action: { showingShareSheet = true }) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(scheme.normal.color)
                        .frame(width: 36, height: 36)
                        .background(Circle().fill(scheme.secondaryBackground.color))
                        .overlay(Circle().stroke(scheme.border.color.opacity(0.8), lineWidth: 1))
                }
            }

            VStack(spacing: 12) {
                // Animated icon glow
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    scheme.progressFillStart.color.opacity(scheme.glowIntensityPrimary),
                                    scheme.progressFillEnd.color.opacity(scheme.glowIntensitySecondary),
                                    .clear
                                ],
                                center: .center, startRadius: scheme.glowRadiusInner, endRadius: scheme.glowRadiusOuter
                            )
                        )
                        .frame(width: 80, height: 80)
                        .blur(radius: scheme.glowBlurRadius)
                        .scaleEffect(animationPhase == 0 ? 1.0 : scheme.glowAnimationScale)

                    Image(systemName: "chart.pie.fill")
                        .font(.system(size: 40, weight: .light))
                        .foregroundStyle(
                            LinearGradient(colors: [scheme.progressFillStart.color, scheme.progressFillEnd.color],
                                           startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .scaleEffect(animationPhase == 0 ? 1.0 : 1.1)
                }

                VStack(spacing: 8) {
                    Text("Daily Summary")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(colors: [scheme.normal.color, scheme.primaryAccent.color],
                                           startPoint: .leading, endPoint: .trailing)
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

    // MARK: - Progress
    private func progressCircleSection(_ vm: DailySummaryViewModel) -> some View {
        ThemedCard(cornerRadius: 24) {
            VStack(spacing: 0) {
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .stroke(scheme.progressTrack.color, lineWidth: 16)
                            .frame(width: 160, height: 160)

                        if let progress = vm.safeDailyProgress {
                            Circle()
                                .trim(from: 0, to: CGFloat(progress.completionPercentage))
                                .stroke(
                                    LinearGradient(colors: [scheme.progressFillStart.color, scheme.progressFillEnd.color],
                                                   startPoint: .topTrailing, endPoint: .bottomLeading),
                                    style: StrokeStyle(lineWidth: 16, lineCap: .round)
                                )
                                .frame(width: 160, height: 160)
                                .rotationEffect(.degrees(-90))
                                .animation(.spring(response: 1.2, dampingFraction: 0.8), value: progress.completionPercentage)

                            VStack(spacing: 8) {
                                Text(progress.performanceLevel.emoji).font(.system(size: 36))
                                Text(progress.formattedCompletionPercentage)
                                    .font(.system(size: 28, weight: .bold, design: .rounded))
                                    .foregroundStyle(scheme.progressFillStart.color)
                                Text("Complete")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(themeTertiaryText)
                                    .textCase(.uppercase).tracking(1)
                            }
                        } else {
                            VStack(spacing: 8) {
                                Text("📊").font(.system(size: 36))
                                Text("0%").font(.system(size: 28, weight: .bold, design: .rounded)).foregroundStyle(themeTertiaryText)
                                Text("Complete")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(themeTertiaryText)
                                    .textCase(.uppercase).tracking(1)
                            }
                        }
                    }
                }

                VStack(spacing: 0) {
                    if let progress = vm.safeDailyProgress {
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

    // MARK: - Stats
    private func statisticsSection(_ vm: DailySummaryViewModel) -> some View {
        HStack(spacing: 12) {
            if let p = vm.safeDailyProgress {
                StatCard(title: "Completed", value: "\(p.completedBlocks)", subtitle: p.completedBlocks == 1 ? "block" : "blocks",
                         color: scheme.success.color, icon: "checkmark.circle.fill")

                StatCard(title: "Skipped", value: "\(p.skippedBlocks)", subtitle: p.skippedBlocks == 1 ? "block" : "blocks",
                         color: scheme.warning.color, icon: "forward.fill")

                StatCard(title: "Time Used", value: "\(p.completedMinutes / 60)h \(p.completedMinutes % 60)m", subtitle: "planned",
                         color: scheme.normal.color, icon: "clock.fill")
            } else {
                StatCard(title: "Completed", value: "0", subtitle: "blocks",
                         color: scheme.success.color, icon: "checkmark.circle.fill")
                StatCard(title: "Skipped", value: "0", subtitle: "blocks",
                         color: scheme.warning.color, icon: "forward.fill")
                StatCard(title: "Time Used", value: "0h 0m", subtitle: "planned",
                         color: scheme.normal.color, icon: "clock.fill")
            }
        }
    }

    // MARK: - Breakdown
    private func taskBreakdownSection(_ vm: DailySummaryViewModel) -> some View {
        ThemedCard(cornerRadius: 20) {
            VStack(spacing: 16) {
                HStack {
                    Image(systemName: "list.bullet.circle")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(scheme.primaryAccent.color)

                    Text("Task Breakdown")
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .foregroundStyle(themePrimaryText)

                    Spacer()
                }

                VStack(spacing: 8) {
                    ForEach(vm.sortedTimeBlocks) { block in
                        TaskBreakdownRow(timeBlock: block)
                            .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity),
                                                    removal: .move(edge: .leading).combined(with: .opacity)))
                    }
                }
            }
        }
        .shadow(color: cardShadowColor, radius: 10, x: 0, y: 5)
    }

    // MARK: - Insights (gated)
    private func premiumGatedInsightsSection(_ vm: DailySummaryViewModel) -> some View {
        ThemedCard(cornerRadius: 20) {
            VStack(spacing: 16) {
                HStack {
                    Image(systemName: "lightbulb.circle")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(scheme.warning.color)

                    Text("Insights & Suggestions")
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .foregroundStyle(themePrimaryText)

                    Spacer()

                    if premiumManager?.canAccessAdvancedAnalytics == true {
                        PremiumBadge()
                    }
                }

                if premiumManager?.canAccessAdvancedAnalytics == true {
                    VStack(spacing: 12) {
                        ForEach(Array(vm.getPersonalizedInsights().enumerated()), id: \.offset) { idx, insight in
                            InsightRow(text: insight, delay: Double(idx) * 0.1)
                        }

                        let suggestions = vm.getImprovementSuggestions()
                        if !suggestions.isEmpty {
                            Divider().background(themeTertiaryText.opacity(0.2)).padding(.vertical, 8)

                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "brain.head.profile")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundStyle(scheme.secondaryUIElement.color)
                                    Text("AI Suggestions")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundStyle(themePrimaryText)
                                }

                                ForEach(Array(suggestions.enumerated()), id: \.offset) { _, suggestion in
                                    HStack(alignment: .top, spacing: 8) {
                                        Text("•")
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundStyle(scheme.secondaryUIElement.color)
                                        Text(suggestion)
                                            .font(.system(size: 14))
                                            .foregroundStyle(themeSecondaryText)
                                    }
                                }
                            }
                        }
                    }
                } else {
                    VStack(spacing: 16) {
                        let basic = generateBasicInsight(vm)
                        InsightRow(text: basic, delay: 0.1)

                        PremiumMiniPrompt(
                            title: "Unlock Advanced Insights",
                            subtitle: "Get AI-powered recommendations and detailed analysis"
                        ) {
                            showingPremiumUpgrade = true
                            HapticManager.shared.anchorSelection()
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "crown.fill")
                                    .font(.system(size: 12))
                                    .foregroundStyle(scheme.warning.color)
                                Text("Premium insights include:")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(themeSecondaryText)
                            }

                            let features = [
                                "🎯 Personalized productivity patterns",
                                "⏰ Time-of-day performance analysis",
                                "📊 Category-based recommendations",
                                "📈 Weekly progress trends"
                            ]

                            ForEach(features, id: \.self) { f in
                                HStack(spacing: 8) {
                                    Text(f)
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

    private func generateBasicInsight(_ vm: DailySummaryViewModel) -> String {
        guard let progress = vm.safeDailyProgress else {
            return "⭐ Create your first time block to start tracking progress!"
        }
        let rate = progress.completionPercentage
        if rate >= 0.8 { return "🎉 Excellent work! You're crushing your goals today with \(Int(rate * 100))% completion." }
        if rate >= 0.6 { return "💪 Good progress! You're \(Int(rate * 100))% through your planned tasks." }
        if rate >= 0.3 { return "📈 Building momentum! Every completed task is progress toward your goals." }
        if progress.totalBlocks > 0 { return "🌱 Every journey starts with a single step. Keep going!" }
        return "⭐ Ready to start? Create your first time block to begin tracking progress!"
    }

    // MARK: - Rating
    private func ratingSection(_ vm: DailySummaryViewModel) -> some View {
        ThemedCard(cornerRadius: 20) {
            VStack(spacing: 20) {
                HStack {
                    Image(systemName: "star.circle")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(scheme.warning.color)

                    Text("Rate Your Day")
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .foregroundStyle(themePrimaryText)

                    Spacer()
                }

                HStack(spacing: 12) {
                    ForEach(1...5, id: \.self) { rating in
                        Button {
                            selectedRating = rating
                            HapticManager.shared.anchorSelection()
                        } label: {
                            let filled = selectedRating >= rating
                            Image(systemName: filled ? "star.fill" : "star")
                                .font(.system(size: 32, weight: .medium))
                                .foregroundStyle(
                                    filled
                                    ? LinearGradient(colors: [scheme.warning.color, scheme.warning.color.opacity(0.85)],
                                                     startPoint: .top, endPoint: .bottom)
                                    : LinearGradient(colors: [themeTertiaryText, themeTertiaryText],
                                                     startPoint: .top, endPoint: .bottom)
                                )
                                .scaleEffect(selectedRating == rating ? 1.2 : 1.0)
                                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: selectedRating)
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "note.text")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(scheme.secondaryUIElement.color)

                        Text("Reflection")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(themeSecondaryText)
                    }

                    TextField("How did your day go?", text: $dayNotes, axis: .vertical)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(themePrimaryText)
                        .lineLimit(3...6)
                        .padding(16)
                        .background(RoundedRectangle(cornerRadius: 12).fill(scheme.secondaryBackground.color.opacity(0.6)))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(scheme.border.color.opacity(0.8), lineWidth: 1))
                }
            }
        }
        .shadow(color: cardShadowColor, radius: 10, x: 0, y: 5)
        .onAppear {
            if let progress = vm.safeDailyProgress {
                selectedRating = progress.dayRating ?? 0
                dayNotes = progress.dayNotes ?? ""
            }
        }
    }

    // MARK: - Actions
    private func actionSection(_ vm: DailySummaryViewModel) -> some View {
        VStack(spacing: 16) {
            if vm.isDayComplete {
                Text("🎉 Congratulations on completing your day!")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundStyle(scheme.success.color)
                    .multilineTextAlignment(.center)

                ThemedButton(title: "Plan Tomorrow", style: .primary) { planTomorrow() }
            }
        }
    }

    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 32) {
            Spacer()

            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                scheme.success.color.opacity(0.3),
                                scheme.secondaryUIElement.color.opacity(0.12),
                                .clear
                            ],
                            center: .center, startRadius: 50, endRadius: 150
                        )
                    )
                    .frame(width: 200, height: 200)
                    .blur(radius: 30)

                Image(systemName: "chart.pie")
                    .font(.system(size: 80, weight: .thin))
                    .foregroundStyle(
                        LinearGradient(colors: [scheme.success.color, scheme.secondaryUIElement.color],
                                       startPoint: .topLeading, endPoint: .bottomTrailing)
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
                NotificationCenter.default.post(name: .navigateToToday, object: nil)
            }
        }
        .padding(.horizontal, 40)
    }

    // MARK: - Helpers
    @MainActor
    private func setupInitialState() async {
        await viewModel.refreshData()
        withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) { animationPhase = 1 }
        withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.1)) { isVisible = true }
    }

    private func saveDayRatingAndNotes() async {
        if selectedRating > 0 || !dayNotes.isEmpty {
            await viewModel.saveDayRatingAndNotes(rating: selectedRating, notes: dayNotes)
            HapticManager.shared.lightImpact()
        }
    }
}


// MARK: - Supporting Components

struct InsightRow: View {
    let text: String
    let delay: Double

    @Environment(\.themeManager) private var themeManager
    @State private var isVisible = false

    private var theme: Theme { themeManager?.currentTheme ?? Theme.defaultTheme }
    private var scheme: ThemeColorScheme { theme.colorScheme }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(scheme.warning.color.opacity(0.3))
                .frame(width: 6, height: 6)
                .offset(y: 6)

            Text(text)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(theme.secondaryTextColor)
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
