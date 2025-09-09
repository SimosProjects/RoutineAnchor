//
//  PremiumAnalyticsView.swift
//  Routine Anchor
//
//  Advanced analytics for premium users
//
import SwiftUI
import SwiftData

struct PremiumAnalyticsView: View {
    @Environment(\.themeManager) private var themeManager
    @Environment(\.modelContext) private var modelContext
    @State private var premiumManager: PremiumManager
    @State private var dataManager: DataManager?
    @State private var selectedTimeRange: AnalyticsTimeRange = .week
    @State private var weeklyReport: WeeklyReport?
    @State private var monthlyReport: MonthlyReport?
    @State private var isLoading = false
    @State private var errorMessage: String?

    private var theme: AppTheme { themeManager?.currentTheme ?? PredefinedThemes.classic }

    init(premiumManager: PremiumManager) {
        self._premiumManager = State(initialValue: premiumManager)
    }

    var body: some View {
        ZStack {
            ThemedAnimatedBackground()
                .ignoresSafeArea()

            if premiumManager.userIsPremium {
                premiumAnalyticsContent
            } else {
                AnalyticsGate {
                    // Parent should present PremiumUpgradeView
                }
            }
        }
        .task {
            await setupDataManager()
            await loadAnalyticsData()
        }
        .refreshable {
            await loadAnalyticsData()
        }
    }

    // MARK: - Premium Analytics Content
    private var premiumAnalyticsContent: some View {
        Group {
            if isLoading {
                loadingView
            } else if let errorMessage = errorMessage {
                errorView(errorMessage)
            } else {
                analyticsScrollView
            }
        }
    }

    private var analyticsScrollView: some View {
        ScrollView {
            VStack(spacing: 24) {
                HStack {
                    Text("Analytics")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(theme.primaryTextColor)
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 20)

                // Time range selector
                timeRangeSelector

                // Overview cards
                if selectedTimeRange == .week, let report = weeklyReport {
                    weeklyOverviewSection(report)
                } else if selectedTimeRange == .month, let report = monthlyReport {
                    monthlyOverviewSection(report)
                }

                // Detailed sections
                if selectedTimeRange == .week, let report = weeklyReport {
                    weeklyDetailedSections(report)
                } else if selectedTimeRange == .month, let report = monthlyReport {
                    monthlyDetailedSections(report)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 100)
        }
    }

    // MARK: - Loading States
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(theme.invertedTextColor)

            Text("Loading Analytics...")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(theme.primaryTextColor.opacity(0.7))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 40))
                .foregroundStyle(theme.statusErrorColor)

            Text("Error Loading Analytics")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(theme.primaryTextColor)

            Text(message)
                .font(.system(size: 14))
                .foregroundStyle(theme.primaryTextColor.opacity(0.7))
                .multilineTextAlignment(.center)

            Button("Try Again") {
                Task { await loadAnalyticsData() }
            }
            .font(.system(size: 16, weight: .medium))
            .foregroundStyle(theme.primaryTextColor)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(theme.accentPrimaryColor)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Time Range Selector
    private var timeRangeSelector: some View {
        HStack(spacing: 0) {
            ForEach(AnalyticsTimeRange.allCases, id: \.self) { range in
                Button(action: {
                    selectedTimeRange = range
                    HapticManager.shared.anchorSelection()
                    Task { await loadAnalyticsData() }
                }) {
                    Text(range.displayName)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(
                            selectedTimeRange == range ? theme.primaryTextColor
                                                       : theme.secondaryTextColor.opacity(0.85)
                        )
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(selectedTimeRange == range ? theme.accentPrimaryColor : .clear)
                        )
                }
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(theme.surfaceCardColor.opacity(0.92))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(theme.glassMaterialOverlay)
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(theme.borderColor.opacity(0.9), lineWidth: 1)
        )
    }

    // MARK: - Weekly Overview
    private func weeklyOverviewSection(_ report: WeeklyReport) -> some View {
        VStack(spacing: 16) {
            HStack {
                Text("This Week's Overview")
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundStyle(theme.primaryTextColor)
                Spacer()
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                AnalyticsCard(
                    title: "Completion Rate",
                    value: "\(Int(report.completionRate * 100))%",
                    subtitle: formatTrendChange(report.trends.percentageChange),
                    color: theme.statusSuccessColor,
                    icon: "checkmark.circle.fill",
                    trend: trendToDirection(report.trends.direction)
                )

                AnalyticsCard(
                    title: "Total Blocks",
                    value: "\(report.totalBlocks)",
                    subtitle: "this week",
                    color: theme.accentPrimaryColor,
                    icon: "calendar",
                    trend: .neutral
                )

                AnalyticsCard(
                    title: "Focus Time",
                    value: formatDuration(report.totalCompletedTime),
                    subtitle: "completed",
                    color: theme.accentSecondaryColor,
                    icon: "brain.head.profile",
                    trend: .neutral
                )

                AnalyticsCard(
                    title: "Current Streak",
                    value: "\(report.currentStreak)",
                    subtitle: "days",
                    color: theme.statusWarningColor,
                    icon: "flame.fill",
                    trend: report.currentStreak > report.longestStreak / 2 ? .up : .neutral
                )
            }
        }
        .padding(20)
    }

    // MARK: - Monthly Overview
    private func monthlyOverviewSection(_ report: MonthlyReport) -> some View {
        VStack(spacing: 16) {
            HStack {
                Text("Monthly Overview")
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundStyle(theme.primaryTextColor)
                Spacer()
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                AnalyticsCard(
                    title: "Total Time",
                    value: formatDuration(report.totalTimeCompleted),
                    subtitle: "completed",
                    color: theme.statusSuccessColor,
                    icon: "clock.fill",
                    trend: .neutral
                )

                AnalyticsCard(
                    title: "Productive Days",
                    value: "\(report.mostProductiveDays.count)",
                    subtitle: "high performance",
                    color: theme.accentPrimaryColor,
                    icon: "star.fill",
                    trend: .up
                )

                AnalyticsCard(
                    title: "Weekly Average",
                    value: formatWeeklyAverage(report.weeklyBreakdowns),
                    subtitle: "completion rate",
                    color: theme.accentSecondaryColor,
                    icon: "chart.line.uptrend.xyaxis",
                    trend: .neutral
                )

                AnalyticsCard(
                    title: "Improvements",
                    value: "\(report.improvements.count)",
                    subtitle: "suggestions",
                    color: theme.statusWarningColor,
                    icon: "lightbulb.fill",
                    trend: .neutral
                )
            }
        }
        .padding(20)
    }

    // MARK: - Weekly/Monthly Details (unchanged structure, themed colors in row components)
    private func weeklyDetailedSections(_ report: WeeklyReport) -> some View {
        VStack(spacing: 24) {
            categoryPerformanceSection(report.categoryPerformance)
            timeOfDaySection(report.timeOfDayStats)
            trendMessageSection(report.trends)
            dailyBreakdownSection(report.dailyStats)
        }
    }

    private func monthlyDetailedSections(_ report: MonthlyReport) -> some View {
        VStack(spacing: 24) {
            weeklyProgressionSection(report.weeklyBreakdowns)
            productiveDaysSection(report.mostProductiveDays)
            improvementSuggestionsSection(report.improvements)
        }
    }

    // MARK: - Category Performance
    private func categoryPerformanceSection(_ categories: [CategoryPerformance]) -> some View {
        VStack(spacing: 16) {
            HStack {
                Text("Category Performance")
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundStyle(theme.primaryTextColor)
                Spacer()
            }

            if categories.isEmpty {
                Text("No category data available")
                    .font(.system(size: 14))
                    .foregroundStyle(theme.secondaryTextColor.opacity(0.85))
                    .padding(.vertical, 20)
            } else {
                VStack(spacing: 12) {
                    ForEach(Array(categories.enumerated()), id: \.offset) { index, category in
                        CategoryPerformanceRow(
                            category: category.category,
                            completionRate: category.completionRate,
                            totalTime: formatDuration(category.totalTime),
                            color: categoryColor(for: index)
                        )
                    }
                }
            }
        }
        .padding(20)
    }

    // MARK: - Time of Day
    private func timeOfDaySection(_ timeStats: TimeOfDayStats) -> some View {
        VStack(spacing: 16) {
            HStack {
                Text("Peak Performance Times")
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundStyle(theme.primaryTextColor)
                Spacer()
            }

            if timeStats.mostProductiveHours.isEmpty {
                Text("More data needed for time analysis")
                    .font(.system(size: 14))
                    .foregroundStyle(theme.secondaryTextColor.opacity(0.85))
                    .padding(.vertical, 20)
            } else {
                VStack(spacing: 12) {
                    ForEach(Array(timeStats.mostProductiveHours.enumerated()), id: \.offset) { _, hour in
                        let stats = timeStats.hourlyBreakdown[hour] ?? (0, 0)
                        let performance = stats.total > 0 ? Double(stats.completed) / Double(stats.total) : 0

                        TimeSlotRow(
                            timeSlot: formatHourRange(hour),
                            performance: performance,
                            label: performanceLabel(performance),
                            color: performanceColor(performance)
                        )
                    }
                }
            }
        }
        .padding(20)
    }

    // MARK: - Trend Message
    private func trendMessageSection(_ trends: TrendAnalysis) -> some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: trendIcon(trends.direction))
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(trendColor(trends.direction))

                Text("Trend Analysis")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(theme.primaryTextColor)

                Spacer()
            }

            Text(trends.message)
                .font(.system(size: 14))
                .foregroundStyle(theme.primaryTextColor.opacity(0.8))
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(trendColor(trends.direction).opacity(0.10))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(trendColor(trends.direction).opacity(0.30), lineWidth: 1)
                )
        )
    }

    // MARK: - Daily Breakdown / Weekly Progression / Productive Days / Improvements
    private func dailyBreakdownSection(_ dailyStats: [DailyStats]) -> some View {
        VStack(spacing: 16) {
            HStack {
                Text("Daily Breakdown")
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundStyle(theme.primaryTextColor)
                Spacer()
            }

            VStack(spacing: 8) {
                ForEach(dailyStats, id: \.date) { stat in
                    DailyStatsRow(dailyStats: stat)
                }
            }
        }
        .padding(20)
    }

    private func weeklyProgressionSection(_ weeklyBreakdowns: [WeeklyBreakdown]) -> some View {
        VStack(spacing: 16) {
            HStack {
                Text("Weekly Progression")
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundStyle(theme.primaryTextColor)
                Spacer()
            }

            VStack(spacing: 12) {
                ForEach(weeklyBreakdowns.indices, id: \.self) { i in
                    WeeklyBreakdownRow(
                        weekNumber: weeklyBreakdowns[i].weekNumber,
                        completionRate: weeklyBreakdowns[i].completionRate,
                        totalBlocks: weeklyBreakdowns[i].totalBlocks
                    )
                }
            }
        }
        .padding(20)
    }

    private func productiveDaysSection(_ productiveDays: [ProductiveDay]) -> some View {
        VStack(spacing: 16) {
            HStack {
                Text("Most Productive Days")
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundStyle(theme.primaryTextColor)
                Spacer()
            }

            if productiveDays.isEmpty {
                Text("Keep building your routine to see productive day patterns!")
                    .font(.system(size: 14))
                    .foregroundStyle(theme.secondaryTextColor.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .padding(.vertical, 20)
            } else {
                VStack(spacing: 12) {
                    ForEach(productiveDays.indices, id: \.self) { i in
                        ProductiveDayRow(
                            productiveDay: productiveDays[i],
                            rank: i + 1
                        )
                    }
                }
            }
        }
        .padding(20)
    }

    private func improvementSuggestionsSection(_ improvements: [ImprovementSuggestion]) -> some View {
        VStack(spacing: 16) {
            HStack {
                Text("AI Insights & Recommendations")
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundStyle(theme.primaryTextColor)
                Spacer()
                PremiumBadge()
            }

            if improvements.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 30))
                        .foregroundStyle(theme.statusSuccessColor)

                    Text("You're doing great!")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(theme.primaryTextColor)

                    Text("No specific improvements needed right now. Keep up the excellent work!")
                        .font(.system(size: 14))
                        .foregroundStyle(theme.primaryTextColor.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
                .padding(.vertical, 20)
            } else {
                VStack(spacing: 12) {
                    ForEach(improvements.indices, id: \.self) { i in
                        ImprovementSuggestionCard(
                            suggestion: improvements[i],
                            color: suggestionColor(for: improvements[i].impact)
                        )
                    }
                }
            }
        }
        .padding(20)
    }

    // MARK: - Data Management
    @MainActor
    private func setupDataManager() async {
        guard dataManager == nil else { return }
        dataManager = DataManager(modelContext: modelContext)
    }

    private func loadAnalyticsData() async {
        guard let dataManager = dataManager else { return }

        isLoading = true
        errorMessage = nil

        // Use safe methods to avoid crashes with invalid models
        let timeBlocks = dataManager.loadAllTimeBlocksSafely()
        let dailyProgress = dataManager.loadDailyProgressRangeSafely(
            from: Calendar.current.date(byAdding: .month, value: -3, to: Date()) ?? Date(),
            to: Date()
        )

        await MainActor.run {
            switch selectedTimeRange {
            case .week:
                weeklyReport = AnalyticsService.shared.generateWeeklyReport(
                    timeBlocks: timeBlocks,
                    dailyProgress: dailyProgress
                )
                monthlyReport = nil

            case .month:
                monthlyReport = AnalyticsService.shared.generateMonthlyReport(
                    timeBlocks: timeBlocks,
                    dailyProgress: dailyProgress
                )
                weeklyReport = nil

            default:
                // For quarter and year, reuse monthly for now
                monthlyReport = AnalyticsService.shared.generateMonthlyReport(
                    timeBlocks: timeBlocks,
                    dailyProgress: dailyProgress
                )
                weeklyReport = nil
            }

            isLoading = false
        }
    }

    // MARK: - Helpers (colors use AppTheme)
    private func trendToDirection(_ trend: TrendDirection) -> TrendDisplayDirection {
        switch trend {
        case .improving: return .up
        case .declining: return .down
        case .stable:    return .neutral
        }
    }

    private func trendIcon(_ trend: TrendDirection) -> String {
        switch trend {
        case .improving: return "arrow.up.circle.fill"
        case .declining: return "arrow.down.circle.fill"
        case .stable:    return "minus.circle.fill"
        }
    }

    private func trendColor(_ trend: TrendDirection) -> Color {
        switch trend {
        case .improving: return theme.statusSuccessColor
        case .declining: return theme.statusErrorColor
        case .stable:    return theme.accentPrimaryColor
        }
    }

    private func categoryColor(for index: Int) -> Color {
        let colors: [Color] = [
            theme.accentPrimaryColor,
            theme.statusSuccessColor,
            theme.accentSecondaryColor,
            theme.statusInfoColor,
            theme.statusWarningColor
        ]
        return colors[index % colors.count]
    }

    private func performanceLabel(_ performance: Double) -> String {
        switch performance {
        case 0.9...:       return "Peak Focus"
        case 0.7..<0.9:    return "Good Energy"
        case 0.5..<0.7:    return "Moderate"
        default:           return "Lower Energy"
        }
    }

    private func performanceColor(_ performance: Double) -> Color {
        switch performance {
        case 0.9...:       return theme.statusSuccessColor
        case 0.7..<0.9:    return theme.accentPrimaryColor
        case 0.5..<0.7:    return theme.statusWarningColor
        default:           return theme.statusErrorColor
        }
    }

    private func suggestionColor(for impact: ImprovementSuggestion.ImpactLevel) -> Color {
        switch impact {
        case .high:   return theme.statusErrorColor
        case .medium: return theme.statusWarningColor
        case .low:    return theme.accentPrimaryColor
        }
    }

    // Formatters
    private func formatDuration(_ t: TimeInterval) -> String {
        let h = Int(t) / 3600
        let m = (Int(t) % 3600) / 60
        return h > 0 ? "\(h)h \(m)m" : "\(m)m"
    }
    private func formatTrendChange(_ change: Double) -> String {
        let pct = Int(abs(change) * 100)
        return change > 0 ? "+\(pct)% this week" : (change < 0 ? "-\(pct)% this week" : "No change")
    }
    private func formatWeeklyAverage(_ breakdowns: [WeeklyBreakdown]) -> String {
        guard !breakdowns.isEmpty else { return "0%" }
        let avg = breakdowns.reduce(0) { $0 + $1.completionRate } / Double(breakdowns.count)
        return "\(Int(avg * 100))%"
    }
    private func formatHourRange(_ hour: Int) -> String {
        let f = DateFormatter(); f.timeStyle = .short
        let cal = Calendar.current
        let start = cal.date(bySettingHour: hour, minute: 0, second: 0, of: Date()) ?? Date()
        let end   = cal.date(bySettingHour: hour + 1, minute: 0, second: 0, of: Date()) ?? Date()
        return "\(f.string(from: start)) - \(f.string(from: end))"
    }
}

// MARK: - Supporting View Components (unchanged layout, themed colors inside)

struct DailyStatsRow: View {
    @Environment(\.themeManager) private var themeManager
    private var theme: AppTheme { themeManager?.currentTheme ?? PredefinedThemes.classic }

    let dailyStats: DailyStats

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(dailyStats.date, style: .date)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(theme.primaryTextColor)

                if let notes = dailyStats.dayNotes, !notes.isEmpty {
                    Text(notes)
                        .font(.system(size: 12))
                        .foregroundStyle(theme.secondaryTextColor.opacity(0.85))
                        .lineLimit(1)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("\(dailyStats.completedBlocks)/\(dailyStats.totalBlocks)")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(theme.primaryTextColor)

                Text("\(Int(dailyStats.completionRate * 100))%")
                    .font(.system(size: 12))
                    .foregroundStyle(dailyStats.completionRate > 0.8 ? theme.statusSuccessColor
                                   : theme.secondaryTextColor.opacity(0.85))
            }
        }
        .padding(.vertical, 8)
    }
}

struct WeeklyBreakdownRow: View {
    @Environment(\.themeManager) private var themeManager
    private var theme: AppTheme { themeManager?.currentTheme ?? PredefinedThemes.classic }

    let weekNumber: Int
    let completionRate: Double
    let totalBlocks: Int

    var body: some View {
        HStack {
            Text("Week \(weekNumber)")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(theme.primaryTextColor)

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("\(Int(completionRate * 100))%")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(theme.primaryTextColor)

                Text("\(totalBlocks) blocks")
                    .font(.system(size: 12))
                    .foregroundStyle(theme.secondaryTextColor.opacity(0.85))
            }
        }
        .padding(.vertical, 6)
    }
}

struct ProductiveDayRow: View {
    @Environment(\.themeManager) private var themeManager
    private var theme: AppTheme { themeManager?.currentTheme ?? PredefinedThemes.classic }

    let productiveDay: ProductiveDay
    let rank: Int

    var body: some View {
        HStack {
            Text("#\(rank)")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(theme.statusWarningColor)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 4) {
                Text(productiveDay.date, style: .date)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(theme.primaryTextColor)

                Text("\(productiveDay.totalBlocks) blocks completed")
                    .font(.system(size: 12))
                    .foregroundStyle(theme.secondaryTextColor.opacity(0.85))
            }

            Spacer()

            Text("\(Int(productiveDay.completionRate * 100))%")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(theme.statusSuccessColor)
        }
        .padding(.vertical, 8)
    }
}

struct ImprovementSuggestionCard: View {
    @Environment(\.themeManager) private var themeManager
    private var theme: AppTheme { themeManager?.currentTheme ?? PredefinedThemes.classic }

    let suggestion: ImprovementSuggestion
    let color: Color

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: impactIcon(suggestion.impact))
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(color)
                .frame(width: 20, height: 20)

            VStack(alignment: .leading, spacing: 4) {
                Text(suggestion.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(theme.primaryTextColor)

                Text(suggestion.description)
                    .font(.system(size: 12))
                    .foregroundStyle(theme.primaryTextColor.opacity(0.7))
                    .lineLimit(nil)
            }

            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8).fill(color.opacity(0.10))
        )
    }

    private func impactIcon(_ impact: ImprovementSuggestion.ImpactLevel) -> String {
        switch impact {
        case .high:   return "exclamationmark.triangle.fill"
        case .medium: return "lightbulb.fill"
        case .low:    return "info.circle.fill"
        }
    }
}

// MARK: - Time Range Enum & Trend Direction helpers

enum AnalyticsTimeRange: CaseIterable {
    case week, month, quarter, year

    var displayName: String {
        switch self {
        case .week:   return "Week"
        case .month:  return "Month"
        case .quarter:return "Quarter"
        case .year:   return "Year"
        }
    }
}

enum TrendDisplayDirection {
    case up, down, neutral

    var iconName: String {
        switch self {
        case .up:     return "arrow.up.right"
        case .down:   return "arrow.down.right"
        case .neutral:return "minus"
        }
    }

    func color(theme: AppTheme? = nil) -> Color {
        let t = theme ?? PredefinedThemes.classic
        switch self {
        case .up:      return t.statusSuccessColor
        case .down:    return t.statusErrorColor
        case .neutral: return t.secondaryTextColor.opacity(0.85)
        }
    }
}

// MARK: - Preview
#Preview {
    NavigationView {
        PremiumAnalyticsView(premiumManager: PremiumManager())
    }
    .modelContainer(for: [TimeBlock.self, DailyProgress.self], inMemory: true)
    .environment(\.themeManager, ThemeManager.preview())
    .preferredColorScheme(.dark)
}
