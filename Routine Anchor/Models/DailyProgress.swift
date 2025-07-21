//
//  DailyProgress.swift
//  Routine Anchor - Premium Version
//
import Foundation
import SwiftData
import SwiftUI

/// Tracks daily progress and completion statistics for time blocks with premium analytics
@Model
class DailyProgress {
    // MARK: - Core Properties
    
    /// Unique identifier for this daily progress record
    @Attribute(.unique) var id: UUID
    
    /// Date this progress record represents (stored as start of day)
    @Attribute(.unique) var date: Date
    
    /// Total number of time blocks scheduled for this day
    var totalBlocks: Int
    
    /// Number of blocks marked as completed
    var completedBlocks: Int
    
    /// Number of blocks marked as skipped
    var skippedBlocks: Int
    
    /// Number of blocks currently in progress
    var inProgressBlocks: Int
    
    /// Total planned minutes for the day
    var totalPlannedMinutes: Int
    
    /// Total completed minutes for the day
    var completedMinutes: Int
    
    /// User's subjective rating of the day (1-5 scale, optional)
    var dayRating: Int?
    
    /// Optional notes about the day
    var dayNotes: String?
    
    // MARK: - Premium Analytics
    
    /// Performance score (0-100)
    var performanceScore: Double = 0.0
    
    /// Productivity index based on time efficiency
    var productivityIndex: Double = 0.0
    
    /// Focus score based on completion patterns
    var focusScore: Double = 0.0
    
    /// Consistency score compared to previous days
    var consistencyScore: Double = 0.0
    
    /// Energy expenditure estimate (1-5)
    var energyExpenditure: Double = 0.0
    
    /// Momentum indicator (-1 to 1)
    var momentumIndicator: Double = 0.0
    
    /// Categories completed today
    var completedCategories: [String] = []
    
    /// High priority blocks completed
    var highPriorityCompleted: Int = 0
    
    /// Time of day with best productivity
    var peakProductivityTime: String?
    
    /// Longest focus session in minutes
    var longestFocusSession: Int = 0
    
    /// Number of interruptions or context switches
    var contextSwitches: Int = 0
    
    /// Weather conditions (for correlation analysis)
    var weatherCondition: String?
    
    /// Mood tracking (1-5)
    var moodBefore: Int?
    var moodAfter: Int?
    
    // MARK: - Streak & Milestone Tracking
    
    /// Current streak of productive days
    var currentStreak: Int = 0
    
    /// Best streak achieved
    var bestStreak: Int = 0
    
    /// Milestones achieved today
    var milestonesAchieved: [String] = []
    
    /// Badges earned
    var badgesEarned: [String] = []
    
    // MARK: - AI Insights
    
    /// Generated insights about the day
    var insights: [String] = []
    
    /// Suggestions for improvement
    var suggestions: [String] = []
    
    /// Predicted performance for tomorrow
    var tomorrowPrediction: String?
    
    /// Personalized motivational message
    var motivationalMessage: String?
    
    // MARK: - Metadata
    
    /// When this progress record was created
    var createdAt: Date
    
    /// When this progress record was last updated
    var updatedAt: Date
    
    /// Whether the user has viewed the summary for this day
    var summaryViewed: Bool
    
    /// Whether premium analytics have been calculated
    var analyticsCalculated: Bool = false
    
    // MARK: - Initializers
    
    /// Create a new daily progress record
    init(date: Date) {
        self.id = UUID()
        // Ensure we store the start of the day for consistency
        self.date = Calendar.current.startOfDay(for: date)
        self.totalBlocks = 0
        self.completedBlocks = 0
        self.skippedBlocks = 0
        self.inProgressBlocks = 0
        self.totalPlannedMinutes = 0
        self.completedMinutes = 0
        self.dayRating = nil
        self.dayNotes = nil
        self.createdAt = Date()
        self.updatedAt = Date()
        self.summaryViewed = false
    }
    
    /// Create daily progress from a list of time blocks
    convenience init(date: Date, timeBlocks: [TimeBlock]) {
        self.init(date: date)
        updateFromTimeBlocks(timeBlocks)
    }
}

// MARK: - Computed Properties
extension DailyProgress {
    /// Number of blocks that are not started yet
    var notStartedBlocks: Int {
        return totalBlocks - completedBlocks - skippedBlocks - inProgressBlocks
    }
    
    /// Completion percentage (0.0 to 1.0)
    var completionPercentage: Double {
        guard totalBlocks > 0 else { return 0.0 }
        return Double(completedBlocks) / Double(totalBlocks)
    }
    
    /// Success rate including both completed and in-progress blocks (0.0 to 1.0)
    var successRate: Double {
        guard totalBlocks > 0 else { return 0.0 }
        return Double(completedBlocks + inProgressBlocks) / Double(totalBlocks)
    }
    
    /// Skip rate (0.0 to 1.0)
    var skipRate: Double {
        guard totalBlocks > 0 else { return 0.0 }
        return Double(skippedBlocks) / Double(totalBlocks)
    }
    
    /// Completion percentage of planned time (0.0 to 1.0)
    var timeCompletionPercentage: Double {
        guard totalPlannedMinutes > 0 else { return 0.0 }
        return Double(completedMinutes) / Double(totalPlannedMinutes)
    }
    
    /// Formatted completion percentage string
    var formattedCompletionPercentage: String {
        return String(format: "%.0f%%", completionPercentage * 100)
    }
    
    /// Formatted completion summary (e.g., "4 of 6 completed")
    var completionSummary: String {
        return "\(completedBlocks) of \(totalBlocks) completed"
    }
    
    /// Formatted time summary (e.g., "2h 30m of 4h planned")
    var timeSummary: String {
        let plannedHours = totalPlannedMinutes / 60
        let plannedMinutes = totalPlannedMinutes % 60
        let completedHours = completedMinutes / 60
        let completedMins = completedMinutes % 60
        
        let plannedString = plannedHours > 0 ? "\(plannedHours)h \(plannedMinutes)m" : "\(plannedMinutes)m"
        let completedString = completedHours > 0 ? "\(completedHours)h \(completedMins)m" : "\(completedMins)m"
        
        return "\(completedString) of \(plannedString) planned"
    }
    
    /// Whether this is a perfect day (all blocks completed)
    var isPerfectDay: Bool {
        return totalBlocks > 0 && completedBlocks == totalBlocks
    }
    
    /// Whether this day is complete (no pending blocks)
    var isDayComplete: Bool {
        return notStartedBlocks == 0 && inProgressBlocks == 0
    }
    
    /// Performance level based on completion
    var performanceLevel: PerformanceLevel {
        switch completionPercentage {
        case 0.9...1.0: return .excellent
        case 0.7..<0.9: return .good
        case 0.5..<0.7: return .fair
        case 0.0..<0.5: return .poor
        default: return .none
        }
    }
    
    /// Color gradient for performance visualization
    var performanceGradient: [Color] {
        switch performanceLevel {
        case .excellent: return [Color.premiumGreen, Color.premiumTeal]
        case .good: return [Color.premiumBlue, Color.premiumTeal]
        case .fair: return [Color.premiumWarning, Color.premiumTeal]
        case .poor: return [Color.premiumError, Color.premiumWarning]
        case .none: return [Color.premiumTextSecondary, Color.premiumTextTertiary]
        }
    }
    
    /// Emoji representation of the day
    var dayEmoji: String {
        if isPerfectDay { return "🏆" }
        switch performanceLevel {
        case .excellent: return "🌟"
        case .good: return "✨"
        case .fair: return "💫"
        case .poor: return "🌱"
        case .none: return "⏳"
        }
    }
    
    /// Trend indicator compared to previous day
    var trendIndicator: String {
        if momentumIndicator > 0.2 { return "📈" }
        else if momentumIndicator < -0.2 { return "📉" }
        else { return "➡️" }
    }
}

// MARK: - Methods
extension DailyProgress {
    /// Update progress from a list of time blocks
    func updateFromTimeBlocks(_ timeBlocks: [TimeBlock]) {
        // Reset counters
        totalBlocks = timeBlocks.count
        completedBlocks = 0
        skippedBlocks = 0
        inProgressBlocks = 0
        totalPlannedMinutes = 0
        completedMinutes = 0
        highPriorityCompleted = 0
        completedCategories = []
        
        var categorySet = Set<String>()
        var totalEnergyRequired = 0.0
        var focusSessions: [Int] = []
        
        for block in timeBlocks {
            // Status counts
            switch block.status {
            case .completed:
                completedBlocks += 1
                completedMinutes += block.durationMinutes
                if block.priority >= 4 {
                    highPriorityCompleted += 1
                }
                if let category = block.category {
                    categorySet.insert(category)
                }
                focusSessions.append(block.durationMinutes)
            case .skipped:
                skippedBlocks += 1
            case .inProgress:
                inProgressBlocks += 1
            case .notStarted:
                break
            }
            
            // Total planned time
            totalPlannedMinutes += block.durationMinutes
            
            // Energy calculation
            totalEnergyRequired += Double(block.energyLevel)
        }
        
        // Update derived values
        completedCategories = Array(categorySet).sorted()
        energyExpenditure = timeBlocks.isEmpty ? 0 : totalEnergyRequired / Double(timeBlocks.count)
        longestFocusSession = focusSessions.max() ?? 0
        
        // Calculate analytics
        calculatePerformanceScore()
        calculateProductivityIndex()
        calculateFocusScore()
        generateInsights()
        
        // Update timestamp
        touch()
    }
    
    /// Calculate performance score
    private func calculatePerformanceScore() {
        var score = 0.0
        
        // Completion rate (40%)
        score += completionPercentage * 40
        
        // Time efficiency (30%)
        score += timeCompletionPercentage * 30
        
        // Priority focus (20%)
        let priorityRate = totalBlocks > 0 ? Double(highPriorityCompleted) / Double(totalBlocks) : 0
        score += priorityRate * 20
        
        // Consistency bonus (10%)
        if skipRate < 0.1 { score += 10 }
        else if skipRate < 0.2 { score += 5 }
        
        performanceScore = min(score, 100)
    }
    
    /// Calculate productivity index
    private func calculateProductivityIndex() {
        guard totalPlannedMinutes > 0 else {
            productivityIndex = 0
            return
        }
        
        // Base productivity on completion
        var index = timeCompletionPercentage
        
        // Bonus for high-priority completion
        if highPriorityCompleted > 0 {
            index *= 1.0 + (Double(highPriorityCompleted) * 0.1)
        }
        
        // Penalty for excessive skipping
        if skipRate > 0.3 {
            index *= 0.8
        }
        
        productivityIndex = min(index, 1.0)
    }
    
    /// Calculate focus score
    private func calculateFocusScore() {
        guard completedBlocks > 0 else {
            focusScore = 0
            return
        }
        
        // Base on longest session
        let sessionScore = min(Double(longestFocusSession) / 120.0, 1.0) // 2 hours = perfect
        
        // Factor in completion consistency
        let consistencyFactor = 1.0 - (Double(contextSwitches) * 0.1)
        
        focusScore = sessionScore * max(consistencyFactor, 0.5)
    }
    
    /// Generate AI-like insights
    func generateInsights() {
        insights.removeAll()
        suggestions.removeAll()
        
        // Performance insights
        if isPerfectDay {
            insights.append("🏆 Perfect day! You completed every single task.")
            motivationalMessage = "You're unstoppable! Keep this incredible momentum going!"
        } else if performanceLevel == .excellent {
            insights.append("Outstanding performance with \(formattedCompletionPercentage) completion rate!")
        }
        
        // Time insights
        if completedMinutes > totalPlannedMinutes {
            insights.append("You exceeded your planned time - great dedication!")
        } else if timeCompletionPercentage > 0.8 {
            insights.append("Excellent time management today.")
        }
        
        // Category insights
        if completedCategories.count >= 3 {
            insights.append("Well-balanced day across \(completedCategories.count) different categories.")
        }
        
        // Focus insights
        if longestFocusSession >= 90 {
            insights.append("Impressive focus session of \(longestFocusSession) minutes!")
            peakProductivityTime = "Morning" // This would be calculated from actual data
        }
        
        // Generate suggestions
        if skipRate > 0.3 {
            suggestions.append("Consider shorter time blocks to improve completion rate.")
        }
        
        if highPriorityCompleted == 0 && totalBlocks > 0 {
            suggestions.append("Try to tackle high-priority tasks early in the day.")
        }
        
        if energyExpenditure > 4 {
            suggestions.append("Schedule some low-energy tasks or breaks tomorrow.")
        }
        
        // Prediction
        if performanceScore > 80 {
            tomorrowPrediction = "Based on today's momentum, tomorrow looks very promising!"
        } else if performanceScore > 60 {
            tomorrowPrediction = "You're building good habits. Keep it up tomorrow!"
        }
    }
    
    /// Set day rating with validation
    func setDayRating(_ rating: Int) {
        dayRating = max(1, min(5, rating))
        touch()
    }
    
    /// Add a milestone achievement
    func addMilestone(_ milestone: String) {
        if !milestonesAchieved.contains(milestone) {
            milestonesAchieved.append(milestone)
            touch()
        }
    }
    
    /// Add a badge
    func addBadge(_ badge: String) {
        if !badgesEarned.contains(badge) {
            badgesEarned.append(badge)
            touch()
        }
    }
    
    /// Update streak information
    func updateStreak(previousDayStreak: Int, wasSuccessful: Bool) {
        if wasSuccessful && performanceLevel.rawValue >= PerformanceLevel.good.rawValue {
            currentStreak = previousDayStreak + 1
            if currentStreak > bestStreak {
                bestStreak = currentStreak
                addMilestone("New Best Streak: \(bestStreak) days!")
            }
        } else {
            currentStreak = 0
        }
        touch()
    }
    
    /// Mark summary as viewed
    func markSummaryViewed() {
        summaryViewed = true
        touch()
    }
    
    /// Update the metadata timestamp
    func touch() {
        updatedAt = Date()
    }
    
    /// Create a copy for a different date
    func copy(to date: Date) -> DailyProgress {
        let copy = DailyProgress(date: date)
        // Don't copy progress data, only structure
        return copy
    }
}

// MARK: - Performance Level Enum
extension DailyProgress {
    enum PerformanceLevel: String, CaseIterable {
        case excellent = "excellent"
        case good = "good"
        case fair = "fair"
        case poor = "poor"
        case none = "none"
        
        var displayName: String {
            switch self {
            case .excellent: return "Excellent"
            case .good: return "Good"
            case .fair: return "Fair"
            case .poor: return "Poor"
            case .none: return "Not Started"
            }
        }
        
        var gradient: [Color] {
            switch self {
            case .excellent: return [Color.premiumGreen, Color.premiumTeal]
            case .good: return [Color.premiumBlue, Color.premiumTeal]
            case .fair: return [Color.premiumWarning, Color.premiumTeal]
            case .poor: return [Color.premiumError, Color.premiumWarning]
            case .none: return [Color.premiumTextSecondary, Color.premiumTextTertiary]
            }
        }
        
        var emoji: String {
            switch self {
            case .excellent: return "🏆"
            case .good: return "⭐"
            case .fair: return "💪"
            case .poor: return "🌱"
            case .none: return "⏳"
            }
        }
        
        var motivationalQuote: String {
            switch self {
            case .excellent: return "You're crushing it! Excellence is your new normal."
            case .good: return "Great job! You're building powerful momentum."
            case .fair: return "Keep pushing! Every step forward counts."
            case .poor: return "Tomorrow is a fresh start. You've got this!"
            case .none: return "The journey begins with a single step."
            }
        }
    }
}

// MARK: - Date Helpers
extension DailyProgress {
    /// Formatted date string for display
    var formattedDate: String {
        let formatter = DateFormatter()
        
        if Calendar.current.isDateInToday(date) {
            return "Today"
        } else if Calendar.current.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            formatter.dateStyle = .medium
            return formatter.string(from: date)
        }
    }
    
    /// Short formatted date (e.g., "Jan 15")
    var shortFormattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
    
    /// Day of week (e.g., "Monday")
    var dayOfWeek: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: date)
    }
    
    /// Short day of week (e.g., "Mon")
    var shortDayOfWeek: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }
}

// MARK: - Hashable & Equatable
extension DailyProgress: Hashable {
    static func == (lhs: DailyProgress, rhs: DailyProgress) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Comparable (for sorting by date)
extension DailyProgress: Comparable {
    static func < (lhs: DailyProgress, rhs: DailyProgress) -> Bool {
        return lhs.date < rhs.date
    }
}

// MARK: - Identifiable
extension DailyProgress: Identifiable {}

// MARK: - Weekly Statistics Helper
struct WeeklyStats {
    let totalDays: Int
    let totalBlocks: Int
    let completedBlocks: Int
    let totalMinutes: Int
    let completedMinutes: Int
    let averageCompletion: Double
    let averageRating: Double
    let bestDay: DailyProgress?
    let currentStreak: Int
    let perfectDays: Int
    
    var formattedAverageCompletion: String {
        String(format: "%.0f%%", averageCompletion * 100)
    }
    
    var productivityTrend: String {
        if averageCompletion > 0.8 { return "📈 Excellent" }
        else if averageCompletion > 0.6 { return "📊 Good" }
        else if averageCompletion > 0.4 { return "➡️ Steady" }
        else { return "📉 Needs Focus" }
    }
}

// MARK: - Monthly Analytics
struct MonthlyAnalytics {
    let totalDays: Int
    let activeDays: Int
    let totalBlocksCompleted: Int
    let totalMinutesCompleted: Int
    let averagePerformanceScore: Double
    let topCategories: [(category: String, count: Int)]
    let productivityByDayOfWeek: [String: Double]
    let bestStreak: Int
    let perfectDays: Int
    
    var consistency: Double {
        totalDays > 0 ? Double(activeDays) / Double(totalDays) : 0
    }
    
    var formattedConsistency: String {
        String(format: "%.0f%%", consistency * 100)
    }
}
