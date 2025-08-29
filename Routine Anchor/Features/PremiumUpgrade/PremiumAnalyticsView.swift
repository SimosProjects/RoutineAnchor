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
    
    init(premiumManager: PremiumManager) {
        self._premiumManager = State(initialValue: premiumManager)
    }
    
    var body: some View {
        ZStack {
            ThemedAnimatedBackground()
                .ignoresSafeArea()
            
            if premiumManager.canAccessAdvancedAnalytics {
                premiumAnalyticsContent
            } else {
                AnalyticsGate {
                    // Show premium upgrade - would be handled by parent view
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
                        .foregroundStyle(themeManager?.currentTheme.textPrimaryColor ?? Theme.defaultTheme.textPrimaryColor)
                    
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
                
                // Detailed sections based on time range
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
                .tint(themeManager?.currentTheme.textPrimaryColor ?? Theme.defaultTheme.textPrimaryColor)
            
            Text("Loading Analytics...")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle((themeManager?.currentTheme.textPrimaryColor ?? Theme.defaultTheme.textPrimaryColor).opacity(0.7))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func errorView(_ message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 40))
                .foregroundStyle(themeManager?.currentTheme.colorScheme.error.color ?? Theme.defaultTheme.colorScheme.error.color)
            
            Text("Error Loading Analytics")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(themeManager?.currentTheme.textPrimaryColor ?? Theme.defaultTheme.textPrimaryColor)
            
            Text(message)
                .font(.system(size: 14))
                .foregroundStyle((themeManager?.currentTheme.textPrimaryColor ?? Theme.defaultTheme.textPrimaryColor).opacity(0.7))
                .multilineTextAlignment(.center)
            
            Button("Try Again") {
                Task { await loadAnalyticsData() }
            }
            .font(.system(size: 16, weight: .medium))
            .foregroundStyle(themeManager?.currentTheme.textPrimaryColor ?? Theme.defaultTheme.textPrimaryColor)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(themeManager?.currentTheme.colorScheme.blue.color ?? Theme.defaultTheme.colorScheme.blue.color)
            .cornerRadius(8)
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
                        .foregroundStyle(selectedTimeRange == range ? (themeManager?.currentTheme.textPrimaryColor ?? Theme.defaultTheme.textPrimaryColor) : (themeManager?.currentTheme.textSecondaryColor ?? Theme.defaultTheme.textSecondaryColor).opacity(0.85))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(selectedTimeRange == range ? themeManager?.currentTheme.colorScheme.blue.color ?? Theme.defaultTheme.colorScheme.blue.color : Color.clear)
                        )
                }
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(themeManager?.currentTheme.colorScheme.surfacePrimary.color ?? Theme.defaultTheme.colorScheme.surfacePrimary.color)
        )
    }
    
    // MARK: - Weekly Overview Section
    private func weeklyOverviewSection(_ report: WeeklyReport) -> some View {
        VStack(spacing: 16) {
            HStack {
                Text("This Week's Overview")
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundStyle(themeManager?.currentTheme.textPrimaryColor ?? Theme.defaultTheme.textPrimaryColor)
                
                Spacer()
            }
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                AnalyticsCard(
                    title: "Completion Rate",
                    value: "\(Int(report.completionRate * 100))%",
                    subtitle: formatTrendChange(report.trends.percentageChange),
                    color: themeManager?.currentTheme.colorScheme.green.color ?? Theme.defaultTheme.colorScheme.green.color,
                    icon: "checkmark.circle.fill",
                    trend: trendToDirection(report.trends.direction)
                )
                
                AnalyticsCard(
                    title: "Total Blocks",
                    value: "\(report.totalBlocks)",
                    subtitle: "this week",
                    color: themeManager?.currentTheme.colorScheme.blue.color ?? Theme.defaultTheme.colorScheme.blue.color,
                    icon: "calendar",
                    trend: .neutral
                )
                
                AnalyticsCard(
                    title: "Focus Time",
                    value: formatDuration(report.totalCompletedTime),
                    subtitle: "completed",
                    color: themeManager?.currentTheme.colorScheme.purple.color ?? Theme.defaultTheme.colorScheme.purple.color,
                    icon: "brain.head.profile",
                    trend: .neutral
                )
                
                AnalyticsCard(
                    title: "Current Streak",
                    value: "\(report.currentStreak)",
                    subtitle: "days",
                    color: themeManager?.currentTheme.colorScheme.warning.color ?? Theme.defaultTheme.colorScheme.warning.color,
                    icon: "flame.fill",
                    trend: report.currentStreak > report.longestStreak / 2 ? .up : .neutral
                )
            }
        }
        .padding(20)
        .themedGlassMorphism(cornerRadius: 20)
    }
    
    // MARK: - Monthly Overview Section
    private func monthlyOverviewSection(_ report: MonthlyReport) -> some View {
        VStack(spacing: 16) {
            HStack {
                Text("Monthly Overview")
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundStyle(themeManager?.currentTheme.textPrimaryColor ?? Theme.defaultTheme.textPrimaryColor)
                
                Spacer()
            }
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                AnalyticsCard(
                    title: "Total Time",
                    value: formatDuration(report.totalTimeCompleted),
                    subtitle: "completed",
                    color: themeManager?.currentTheme.colorScheme.green.color ?? Theme.defaultTheme.colorScheme.green.color,
                    icon: "clock.fill",
                    trend: .neutral
                )
                
                AnalyticsCard(
                    title: "Productive Days",
                    value: "\(report.mostProductiveDays.count)",
                    subtitle: "high performance",
                    color: themeManager?.currentTheme.colorScheme.blue.color ?? Theme.defaultTheme.colorScheme.blue.color,
                    icon: "star.fill",
                    trend: .up
                )
                
                AnalyticsCard(
                    title: "Weekly Average",
                    value: formatWeeklyAverage(report.weeklyBreakdowns),
                    subtitle: "completion rate",
                    color: themeManager?.currentTheme.colorScheme.purple.color ?? Theme.defaultTheme.colorScheme.purple.color,
                    icon: "chart.line.uptrend.xyaxis",
                    trend: .neutral
                )
                
                AnalyticsCard(
                    title: "Improvements",
                    value: "\(report.improvements.count)",
                    subtitle: "suggestions",
                    color: themeManager?.currentTheme.colorScheme.warning.color ?? Theme.defaultTheme.colorScheme.warning.color,
                    icon: "lightbulb.fill",
                    trend: .neutral
                )
            }
        }
        .padding(20)
        .themedGlassMorphism(cornerRadius: 20)
    }
    
    // MARK: - Weekly Detailed Sections
    private func weeklyDetailedSections(_ report: WeeklyReport) -> some View {
        VStack(spacing: 24) {
            // Category performance
            categoryPerformanceSection(report.categoryPerformance)
            
            // Time of day analysis
            timeOfDaySection(report.timeOfDayStats)
            
            // Trend message
            trendMessageSection(report.trends)
            
            // Daily breakdown
            dailyBreakdownSection(report.dailyStats)
        }
    }
    
    // MARK: - Monthly Detailed Sections
    private func monthlyDetailedSections(_ report: MonthlyReport) -> some View {
        VStack(spacing: 24) {
            // Weekly progression
            weeklyProgressionSection(report.weeklyBreakdowns)
            
            // Most productive days
            productiveDaysSection(report.mostProductiveDays)
            
            // Improvement suggestions
            improvementSuggestionsSection(report.improvements)
        }
    }
    
    // MARK: - Category Performance Section
    private func categoryPerformanceSection(_ categories: [CategoryPerformance]) -> some View {
        VStack(spacing: 16) {
            HStack {
                Text("Category Performance")
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundStyle(themeManager?.currentTheme.textPrimaryColor ?? Theme.defaultTheme.textPrimaryColor)
                
                Spacer()
            }
            
            if categories.isEmpty {
                Text("No category data available")
                    .font(.system(size: 14))
                    .foregroundStyle((themeManager?.currentTheme.textSecondaryColor ?? Theme.defaultTheme.textSecondaryColor).opacity(0.85))
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
        .themedGlassMorphism(cornerRadius: 20)
    }
    
    // MARK: - Time of Day Section
    private func timeOfDaySection(_ timeStats: TimeOfDayStats) -> some View {
        VStack(spacing: 16) {
            HStack {
                Text("Peak Performance Times")
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundStyle(themeManager?.currentTheme.textPrimaryColor ?? Theme.defaultTheme.textPrimaryColor)
                
                Spacer()
            }
            
            if timeStats.mostProductiveHours.isEmpty {
                Text("More data needed for time analysis")
                    .font(.system(size: 14))
                    .foregroundStyle((themeManager?.currentTheme.textSecondaryColor ?? Theme.defaultTheme.textSecondaryColor).opacity(0.85))
                    .padding(.vertical, 20)
            } else {
                VStack(spacing: 12) {
                    ForEach(Array(timeStats.mostProductiveHours.enumerated()), id: \.offset) { index, hour in
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
        .themedGlassMorphism(cornerRadius: 20)
    }
    
    // MARK: - Trend Message Section
    private func trendMessageSection(_ trends: TrendAnalysis) -> some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: trendIcon(trends.direction))
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(trendColor(trends.direction))
                
                Text("Trend Analysis")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(themeManager?.currentTheme.textPrimaryColor ?? Theme.defaultTheme.textPrimaryColor)
                
                Spacer()
            }
            
            Text(trends.message)
                .font(.system(size: 14))
                .foregroundStyle((themeManager?.currentTheme.textPrimaryColor ?? Theme.defaultTheme.textPrimaryColor).opacity(0.8))
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(trendColor(trends.direction).opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(trendColor(trends.direction).opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Daily Breakdown Section
    private func dailyBreakdownSection(_ dailyStats: [DailyStats]) -> some View {
        VStack(spacing: 16) {
            HStack {
                Text("Daily Breakdown")
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundStyle(themeManager?.currentTheme.textPrimaryColor ?? Theme.defaultTheme.textPrimaryColor)
                
                Spacer()
            }
            
            VStack(spacing: 8) {
                ForEach(dailyStats, id: \.date) { stat in
                    DailyStatsRow(dailyStats: stat)
                }
            }
        }
        .padding(20)
        .themedGlassMorphism(cornerRadius: 20)
    }
    
    // MARK: - Weekly Progression Section
    private func weeklyProgressionSection(_ weeklyBreakdowns: [WeeklyBreakdown]) -> some View {
        VStack(spacing: 16) {
            HStack {
                Text("Weekly Progression")
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundStyle(themeManager?.currentTheme.textPrimaryColor ?? Theme.defaultTheme.textPrimaryColor)
                
                Spacer()
            }
            
            VStack(spacing: 12) {
                ForEach(Array(weeklyBreakdowns.enumerated()), id: \.offset) { index, week in
                    WeeklyBreakdownRow(
                        weekNumber: week.weekNumber,
                        completionRate: week.completionRate,
                        totalBlocks: week.totalBlocks
                    )
                }
            }
        }
        .padding(20)
        .themedGlassMorphism(cornerRadius: 20)
    }
    
    // MARK: - Productive Days Section
    private func productiveDaysSection(_ productiveDays: [ProductiveDay]) -> some View {
        VStack(spacing: 16) {
            HStack {
                Text("Most Productive Days")
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundStyle(themeManager?.currentTheme.textPrimaryColor ?? Theme.defaultTheme.textPrimaryColor)
                
                Spacer()
            }
            
            if productiveDays.isEmpty {
                Text("Keep building your routine to see productive day patterns!")
                    .font(.system(size: 14))
                    .foregroundStyle((themeManager?.currentTheme.textSecondaryColor ?? Theme.defaultTheme.textSecondaryColor).opacity(0.85))
                    .multilineTextAlignment(.center)
                    .padding(.vertical, 20)
            } else {
                VStack(spacing: 12) {
                    ForEach(Array(productiveDays.enumerated()), id: \.offset) { index, day in
                        ProductiveDayRow(
                            productiveDay: day,
                            rank: index + 1
                        )
                    }
                }
            }
        }
        .padding(20)
        .themedGlassMorphism(cornerRadius: 20)
    }
    
    // MARK: - Improvement Suggestions Section
    private func improvementSuggestionsSection(_ improvements: [ImprovementSuggestion]) -> some View {
        VStack(spacing: 16) {
            HStack {
                Text("AI Insights & Recommendations")
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundStyle(themeManager?.currentTheme.textPrimaryColor ?? Theme.defaultTheme.textPrimaryColor)
                
                Spacer()
                
                PremiumBadge()
            }
            
            if improvements.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 30))
                        .foregroundStyle(themeManager?.currentTheme.colorScheme.success.color ?? Theme.defaultTheme.colorScheme.success.color)
                    
                    Text("You're doing great!")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(themeManager?.currentTheme.textPrimaryColor ?? Theme.defaultTheme.textPrimaryColor)
                    
                    Text("No specific improvements needed right now. Keep up the excellent work!")
                        .font(.system(size: 14))
                        .foregroundStyle((themeManager?.currentTheme.textPrimaryColor ?? Theme.defaultTheme.textPrimaryColor).opacity(0.7))
                        .multilineTextAlignment(.center)
                }
                .padding(.vertical, 20)
            } else {
                VStack(spacing: 12) {
                    ForEach(Array(improvements.enumerated()), id: \.offset) { index, suggestion in
                        ImprovementSuggestionCard(
                            suggestion: suggestion,
                            color: suggestionColor(for: suggestion.impact)
                        )
                    }
                }
            }
        }
        .padding(20)
        .themedGlassMorphism(cornerRadius: 20)
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
                // For quarter and year, we'll use monthly for now
                monthlyReport = AnalyticsService.shared.generateMonthlyReport(
                    timeBlocks: timeBlocks,
                    dailyProgress: dailyProgress
                )
                weeklyReport = nil
            }
            
            isLoading = false
        }
    }
    
    
    // MARK: - Helper Methods
    private func formatDuration(_ timeInterval: TimeInterval) -> String {
        let hours = Int(timeInterval) / 3600
        let minutes = (Int(timeInterval) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    private func formatTrendChange(_ change: Double) -> String {
        let percentage = Int(abs(change) * 100)
        if change > 0 {
            return "+\(percentage)% this week"
        } else if change < 0 {
            return "-\(percentage)% this week"
        } else {
            return "No change"
        }
    }
    
    private func formatWeeklyAverage(_ breakdowns: [WeeklyBreakdown]) -> String {
        let average = breakdowns.reduce(0) { $0 + $1.completionRate } / Double(breakdowns.count)
        return "\(Int(average * 100))%"
    }
    
    private func formatHourRange(_ hour: Int) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        
        let calendar = Calendar.current
        let startDate = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: Date()) ?? Date()
        let endDate = calendar.date(bySettingHour: hour + 1, minute: 0, second: 0, of: Date()) ?? Date()
        
        return "\(formatter.string(from: startDate)) - \(formatter.string(from: endDate))"
    }
    
    private func trendToDirection(_ trend: TrendDirection) -> TrendDisplayDirection {
        switch trend {
        case .improving: return .up
        case .declining: return .down
        case .stable: return .neutral
        }
    }
    
    private func trendIcon(_ trend: TrendDirection) -> String {
        switch trend {
        case .improving: return "arrow.up.circle.fill"
        case .declining: return "arrow.down.circle.fill"
        case .stable: return "minus.circle.fill"
        }
    }
    
    private func trendColor(_ trend: TrendDirection) -> Color {
        switch trend {
        case .improving:
            return themeManager?.currentTheme.colorScheme.success.color ?? Theme.defaultTheme.colorScheme.success.color
        case .declining:
            return themeManager?.currentTheme.colorScheme.error.color ?? Theme.defaultTheme.colorScheme.error.color
        case .stable:
            return themeManager?.currentTheme.colorScheme.blue.color ?? Theme.defaultTheme.colorScheme.blue.color
        }
    }
    
    private func categoryColor(for index: Int) -> Color {
        guard let theme = themeManager?.currentTheme else {
            // Fallback colors if no theme manager
            let defaultColors: [Color] = [
                Theme.defaultTheme.colorScheme.blue.color,
                Theme.defaultTheme.colorScheme.green.color,
                Theme.defaultTheme.colorScheme.purple.color,
                Theme.defaultTheme.colorScheme.teal.color,
                Theme.defaultTheme.colorScheme.warning.color
            ]
            return defaultColors[index % defaultColors.count]
        }
        
        let colors: [Color] = [
            theme.colorScheme.blue.color,
            theme.colorScheme.green.color,
            theme.colorScheme.purple.color,
            theme.colorScheme.teal.color,
            theme.colorScheme.warning.color
        ]
        return colors[index % colors.count]
    }
    
    private func performanceLabel(_ performance: Double) -> String {
        switch performance {
        case 0.9...: return "Peak Focus"
        case 0.7..<0.9: return "Good Energy"
        case 0.5..<0.7: return "Moderate"
        default: return "Lower Energy"
        }
    }
    
    private func performanceColor(_ performance: Double) -> Color {
        switch performance {
        case 0.9...:
            return themeManager?.currentTheme.colorScheme.success.color ?? Theme.defaultTheme.colorScheme.success.color
        case 0.7..<0.9:
            return themeManager?.currentTheme.colorScheme.blue.color ?? Theme.defaultTheme.colorScheme.blue.color
        case 0.5..<0.7:
            return themeManager?.currentTheme.colorScheme.warning.color ?? Theme.defaultTheme.colorScheme.warning.color
        default:
            return themeManager?.currentTheme.colorScheme.error.color ?? Theme.defaultTheme.colorScheme.error.color
        }
    }
    
    private func suggestionColor(for impact: ImprovementSuggestion.ImpactLevel) -> Color {
        switch impact {
        case .high:
            return themeManager?.currentTheme.colorScheme.error.color ?? Theme.defaultTheme.colorScheme.error.color
        case .medium:
            return themeManager?.currentTheme.colorScheme.warning.color ?? Theme.defaultTheme.colorScheme.warning.color
        case .low:
            return themeManager?.currentTheme.colorScheme.blue.color ?? Theme.defaultTheme.colorScheme.blue.color
        }
    }
}

// MARK: - Supporting View Components

struct DailyStatsRow: View {
    @Environment(\.themeManager) private var themeManager
    let dailyStats: DailyStats
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(dailyStats.date, style: .date)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(themeManager?.currentTheme.textPrimaryColor ?? Theme.defaultTheme.textPrimaryColor)
                
                if let notes = dailyStats.dayNotes, !notes.isEmpty {
                    Text(notes)
                        .font(.system(size: 12))
                        .foregroundStyle((themeManager?.currentTheme.textSecondaryColor ?? Theme.defaultTheme.textSecondaryColor).opacity(0.85))
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(dailyStats.completedBlocks)/\(dailyStats.totalBlocks)")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(themeManager?.currentTheme.textPrimaryColor ?? Theme.defaultTheme.textPrimaryColor)
                
                Text("\(Int(dailyStats.completionRate * 100))%")
                    .font(.system(size: 12))
                    .foregroundStyle(dailyStats.completionRate > 0.8 ?
                        (themeManager?.currentTheme.colorScheme.success.color ?? Theme.defaultTheme.colorScheme.success.color) :
                        (themeManager?.currentTheme.textSecondaryColor ?? Theme.defaultTheme.textSecondaryColor).opacity(0.85))
            }
        }
        .padding(.vertical, 8)
    }
}


struct WeeklyBreakdownRow: View {
    @Environment(\.themeManager) private var themeManager
    let weekNumber: Int
    let completionRate: Double
    let totalBlocks: Int
    
    var body: some View {
        HStack {
            Text("Week \(weekNumber)")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(themeManager?.currentTheme.textPrimaryColor ?? Theme.defaultTheme.textPrimaryColor)
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(Int(completionRate * 100))%")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(themeManager?.currentTheme.textPrimaryColor ?? Theme.defaultTheme.textPrimaryColor)
                
                Text("\(totalBlocks) blocks")
                    .font(.system(size: 12))
                    .foregroundStyle((themeManager?.currentTheme.textSecondaryColor ?? Theme.defaultTheme.textSecondaryColor).opacity(0.85))
            }
        }
        .padding(.vertical, 6)
    }
}

struct ProductiveDayRow: View {
    @Environment(\.themeManager) private var themeManager
    let productiveDay: ProductiveDay
    let rank: Int
    
    var body: some View {
        HStack {
            Text("#\(rank)")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(themeManager?.currentTheme.colorScheme.warning.color ?? Theme.defaultTheme.colorScheme.warning.color)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(productiveDay.date, style: .date)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(themeManager?.currentTheme.textPrimaryColor ?? Theme.defaultTheme.textPrimaryColor)
                
                Text("\(productiveDay.totalBlocks) blocks completed")
                    .font(.system(size: 12))
                    .foregroundStyle((themeManager?.currentTheme.textSecondaryColor ?? Theme.defaultTheme.textSecondaryColor).opacity(0.85))
            }
            
            Spacer()
            
            Text("\(Int(productiveDay.completionRate * 100))%")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.green)
        }
        .padding(.vertical, 8)
    }
}

struct ImprovementSuggestionCard: View {
    @Environment(\.themeManager) private var themeManager
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
                    .foregroundStyle(themeManager?.currentTheme.textPrimaryColor ?? Theme.defaultTheme.textPrimaryColor)
                
                Text(suggestion.description)
                    .font(.system(size: 12))
                    .foregroundStyle((themeManager?.currentTheme.textPrimaryColor ?? Theme.defaultTheme.textPrimaryColor).opacity(0.7))
                    .lineLimit(nil)
            }
            
            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(color.opacity(0.1))
        )
    }
    
    private func impactIcon(_ impact: ImprovementSuggestion.ImpactLevel) -> String {
        switch impact {
        case .high: return "exclamationmark.triangle.fill"
        case .medium: return "lightbulb.fill"
        case .low: return "info.circle.fill"
        }
    }
}

// MARK: - Time Range Enum
enum AnalyticsTimeRange: CaseIterable {
    case week, month, quarter, year
    
    var displayName: String {
        switch self {
        case .week: return "Week"
        case .month: return "Month"
        case .quarter: return "Quarter"
        case .year: return "Year"
        }
    }
}

// Keep existing components from previous version:
// - AnalyticsCard
// - TrendDisplayDirection
// - CategoryPerformanceRow
// - TimeSlotRow

enum TrendDisplayDirection {
    case up, down, neutral
    
    var iconName: String {
        switch self {
        case .up: return "arrow.up.right"
        case .down: return "arrow.down.right"
        case .neutral: return "minus"
        }
    }
    
    func color(theme: Theme? = nil) -> Color {
        switch self {
        case .up: return .green
        case .down: return .red
        case .neutral:
            let themeToUse = theme ?? Theme.defaultTheme
            return themeToUse.textSecondaryColor.opacity(0.85)
        }
    }
}

// MARK: - Preview
#Preview {
    NavigationView {
        PremiumAnalyticsView(premiumManager: PremiumManager())
    }
    .modelContainer(for: [TimeBlock.self, DailyProgress.self], inMemory: true)
}
