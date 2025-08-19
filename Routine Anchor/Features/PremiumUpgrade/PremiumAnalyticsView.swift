//
//  PremiumAnalyticsView.swift
//  Routine Anchor
//
//  Advanced analytics for premium users
//
import SwiftUI
import Charts

struct PremiumAnalyticsView: View {
    @State private var premiumManager: PremiumManager
    @State private var analyticsService = AnalyticsService.shared
    @State private var selectedTimeRange: AnalyticsTimeRange = .week
    @State private var showingInsights = false
    
    // Sample data - replace with real data from your AnalyticsService
    @State private var weeklyReport: WeeklyReport?
    @State private var monthlyReport: MonthlyReport?
    
    init(premiumManager: PremiumManager) {
        self._premiumManager = State(initialValue: premiumManager)
    }
    
    var body: some View {
        ZStack {
            AnimatedGradientBackground()
                .ignoresSafeArea()
            
            if premiumManager.canAccessAdvancedAnalytics {
                premiumAnalyticsContent
            } else {
                AnalyticsGate {
                    // Show premium upgrade
                }
            }
        }
        .navigationTitle("Analytics")
        .navigationBarTitleDisplayMode(.large)
        .task {
            await loadAnalyticsData()
        }
    }
    
    // MARK: - Premium Analytics Content
    private var premiumAnalyticsContent: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Time range selector
                timeRangeSelector
                
                // Overview cards
                overviewSection
                
                // Productivity trends chart
                productivityChart
                
                // Category performance
                categoryPerformanceSection
                
                // Time of day analysis
                timeOfDaySection
                
                // Insights and recommendations
                insightsSection
                
                // Streak tracking
                streakSection
            }
            .padding(.horizontal)
            .padding(.bottom, 100)
        }
    }
    
    // MARK: - Time Range Selector
    private var timeRangeSelector: some View {
        HStack(spacing: 0) {
            ForEach(AnalyticsTimeRange.allCases, id: \.self) { range in
                Button(action: {
                    selectedTimeRange = range
                    HapticManager.shared.premiumSelection()
                    Task { await loadAnalyticsData() }
                }) {
                    Text(range.displayName)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(selectedTimeRange == range ? .white : .white.opacity(0.6))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(selectedTimeRange == range ? Color.premiumBlue : Color.clear)
                        )
                }
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.1))
        )
    }
    
    // MARK: - Overview Section
    private var overviewSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Overview")
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                
                Spacer()
                
                Button("View Insights") {
                    showingInsights = true
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.premiumBlue)
            }
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                AnalyticsCard(
                    title: "Completion Rate",
                    value: "87%",
                    subtitle: "+5% this week",
                    color: Color.premiumGreen,
                    icon: "checkmark.circle.fill",
                    trend: .up
                )
                
                AnalyticsCard(
                    title: "Focus Time",
                    value: "4.2h",
                    subtitle: "avg per day",
                    color: Color.premiumBlue,
                    icon: "brain.head.profile",
                    trend: .up
                )
                
                AnalyticsCard(
                    title: "Best Day",
                    value: "Tuesday",
                    subtitle: "95% completion",
                    color: Color.premiumPurple,
                    icon: "star.fill",
                    trend: .neutral
                )
                
                AnalyticsCard(
                    title: "Streak",
                    value: "12 days",
                    subtitle: "current",
                    color: Color.premiumWarning,
                    icon: "flame.fill",
                    trend: .up
                )
            }
        }
        .padding(20)
        .glassMorphism(cornerRadius: 20)
    }
    
    // MARK: - Productivity Chart
    private var productivityChart: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Productivity Trends")
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                
                Spacer()
            }
            
            // Chart placeholder - replace with actual Chart view
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Completion Rate Over Time")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.white.opacity(0.8))
                        
                        Text("Last 7 days")
                            .font(.system(size: 12))
                            .foregroundStyle(.white.opacity(0.6))
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 16) {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color.premiumBlue)
                                .frame(width: 8, height: 8)
                            Text("Completed")
                                .font(.system(size: 12))
                                .foregroundStyle(.white.opacity(0.7))
                        }
                        
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color.premiumWarning)
                                .frame(width: 8, height: 8)
                            Text("Skipped")
                                .font(.system(size: 12))
                                .foregroundStyle(.white.opacity(0.7))
                        }
                    }
                }
                
                // Placeholder chart area
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.05))
                    .frame(height: 200)
                    .overlay(
                        Text("📊 Interactive chart would go here")
                            .font(.system(size: 16))
                            .foregroundStyle(.white.opacity(0.5))
                    )
            }
        }
        .padding(20)
        .glassMorphism(cornerRadius: 20)
    }
    
    // MARK: - Category Performance
    private var categoryPerformanceSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Category Performance")
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                
                Spacer()
            }
            
            VStack(spacing: 12) {
                CategoryPerformanceRow(
                    category: "Work",
                    completionRate: 0.92,
                    totalTime: "8.5h",
                    color: Color.premiumBlue
                )
                
                CategoryPerformanceRow(
                    category: "Health",
                    completionRate: 0.78,
                    totalTime: "2.3h",
                    color: Color.premiumGreen
                )
                
                CategoryPerformanceRow(
                    category: "Learning",
                    completionRate: 0.65,
                    totalTime: "1.8h",
                    color: Color.premiumPurple
                )
                
                CategoryPerformanceRow(
                    category: "Personal",
                    completionRate: 0.85,
                    totalTime: "3.2h",
                    color: Color.premiumTeal
                )
            }
        }
        .padding(20)
        .glassMorphism(cornerRadius: 20)
    }
    
    // MARK: - Time of Day Analysis
    private var timeOfDaySection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Peak Performance Times")
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                
                Spacer()
            }
            
            VStack(spacing: 12) {
                TimeSlotRow(
                    timeSlot: "9:00 AM - 11:00 AM",
                    performance: 0.95,
                    label: "Peak Focus",
                    color: Color.premiumGreen
                )
                
                TimeSlotRow(
                    timeSlot: "2:00 PM - 4:00 PM",
                    performance: 0.82,
                    label: "Good Energy",
                    color: Color.premiumBlue
                )
                
                TimeSlotRow(
                    timeSlot: "11:00 AM - 1:00 PM",
                    performance: 0.78,
                    label: "Moderate",
                    color: Color.premiumWarning
                )
                
                TimeSlotRow(
                    timeSlot: "7:00 PM - 9:00 PM",
                    performance: 0.65,
                    label: "Lower Energy",
                    color: Color.premiumError
                )
            }
        }
        .padding(20)
        .glassMorphism(cornerRadius: 20)
    }
    
    // MARK: - Insights Section
    private var insightsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("AI Insights & Recommendations")
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                
                Spacer()
                
                PremiumBadge()
            }
            
            VStack(spacing: 12) {
                InsightCard(
                    icon: "lightbulb.fill",
                    title: "Optimize Your Schedule",
                    description: "Your completion rate is highest on Tuesday mornings. Consider scheduling your most important tasks during this time.",
                    color: Color.premiumWarning
                )
                
                InsightCard(
                    icon: "target",
                    title: "Focus Improvement",
                    description: "You tend to skip 'Learning' blocks more often. Try breaking them into smaller, 15-minute sessions.",
                    color: Color.premiumPurple
                )
                
                InsightCard(
                    icon: "clock.arrow.circlepath",
                    title: "Time Pattern",
                    description: "Your productivity peaks between 9-11 AM. Avoid scheduling meetings during this golden hour.",
                    color: Color.premiumGreen
                )
            }
        }
        .padding(20)
        .glassMorphism(cornerRadius: 20)
    }
    
    // MARK: - Streak Section
    private var streakSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Consistency Tracking")
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                
                Spacer()
            }
            
            HStack(spacing: 20) {
                StreakCard(
                    title: "Current Streak",
                    value: "12",
                    subtitle: "days",
                    icon: "flame.fill",
                    color: Color.premiumWarning
                )
                
                StreakCard(
                    title: "Longest Streak",
                    value: "23",
                    subtitle: "days",
                    icon: "trophy.fill",
                    color: Color.premiumGreen
                )
                
                StreakCard(
                    title: "This Month",
                    value: "89%",
                    subtitle: "completion",
                    icon: "calendar",
                    color: Color.premiumBlue
                )
            }
        }
        .padding(20)
        .glassMorphism(cornerRadius: 20)
    }
    
    // MARK: - Helper Methods
    private func loadAnalyticsData() async {
        // Load real analytics data based on selectedTimeRange
        // This would integrate with your existing AnalyticsService
    }
}

// MARK: - Supporting Views

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

struct AnalyticsCard: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    let icon: String
    let trend: TrendDirection
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(color)
                
                Spacer()
                
                Image(systemName: trend.iconName)
                    .font(.system(size: 12))
                    .foregroundStyle(trend.color)
            }
            
            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.8))
                
                Text(subtitle)
                    .font(.system(size: 10))
                    .foregroundStyle(.white.opacity(0.6))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

enum TrendDirection {
    case up, down, neutral
    
    var iconName: String {
        switch self {
        case .up: return "arrow.up.right"
        case .down: return "arrow.down.right"
        case .neutral: return "minus"
        }
    }
    
    var color: Color {
        switch self {
        case .up: return .green
        case .down: return .red
        case .neutral: return .white.opacity(0.6)
        }
    }
}

struct CategoryPerformanceRow: View {
    let category: String
    let completionRate: Double
    let totalTime: String
    let color: Color
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(category)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.white)
                
                Text(totalTime)
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.6))
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(Int(completionRate * 100))%")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                
                ProgressView(value: completionRate)
                    .progressViewStyle(LinearProgressViewStyle(tint: color))
                    .frame(width: 80)
                    .scaleEffect(y: 1.5)
            }
        }
        .padding(.vertical, 8)
    }
}

struct TimeSlotRow: View {
    let timeSlot: String
    let performance: Double
    let label: String
    let color: Color
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(timeSlot)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white)
                
                Text(label)
                    .font(.system(size: 12))
                    .foregroundStyle(color)
            }
            
            Spacer()
            
            HStack(spacing: 8) {
                Text("\(Int(performance * 100))%")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                
                Circle()
                    .fill(color)
                    .frame(width: 8, height: 8)
            }
        }
        .padding(.vertical, 6)
    }
}

struct InsightCard: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(color)
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                
                Text(description)
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.7))
                    .lineLimit(3)
            }
            
            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(color.opacity(0.1))
        )
    }
}

struct StreakCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(color)
            
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            
            VStack(spacing: 2) {
                Text(subtitle)
                    .font(.system(size: 10))
                    .foregroundStyle(.white.opacity(0.6))
                
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.8))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - Preview
#Preview {
    NavigationView {
        PremiumAnalyticsView(premiumManager: PremiumManager())
    }
}
