//
//  DailyProgress.swift
//  Routine Anchor
//
//  Created by Christopher Simonson on 7/19/25.
//
import Foundation
import SwiftData
import SwiftUICore

/// Tracks daily progress and completion statistics for time blocks
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
    
    // MARK: - Metadata
    
    /// When this progress record was created
    var createdAt: Date
    
    /// When this progress record was last updated
    var updatedAt: Date
    
    /// Whether the user has viewed the summary for this day
    var summaryViewed: Bool
    
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
    
    /// Whether this represents today
    var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }
    
    /// Whether this day has any scheduled blocks
    var hasScheduledBlocks: Bool {
        return totalBlocks > 0
    }
    
    /// Whether the day is complete (all blocks are finished)
    var isDayComplete: Bool {
        return totalBlocks > 0 && (completedBlocks + skippedBlocks) == totalBlocks
    }
    
    /// Performance score based on completion and consistency (0.0 to 1.0)
    var performanceScore: Double {
        guard totalBlocks > 0 else { return 0.0 }
        
        // Base score from completion rate
        var score = completionPercentage
        
        // Bonus for consistency (fewer skips)
        let consistencyBonus = (1.0 - skipRate) * 0.2
        score += consistencyBonus
        
        // Small bonus for completing all blocks
        if isDayComplete && skipRate == 0.0 {
            score += 0.1
        }
        
        return min(score, 1.0)
    }
}

// MARK: - Data Updates
extension DailyProgress {
    /// Update all statistics from a list of time blocks for this date
    func updateFromTimeBlocks(_ timeBlocks: [TimeBlock]) {
        // Filter blocks for this specific date
        let dayBlocks = timeBlocks.filter { timeBlock in
            Calendar.current.isDate(timeBlock.startTime, inSameDayAs: date)
        }
        
        // Reset counters
        totalBlocks = dayBlocks.count
        completedBlocks = 0
        skippedBlocks = 0
        inProgressBlocks = 0
        totalPlannedMinutes = 0
        completedMinutes = 0
        
        // Calculate statistics
        for block in dayBlocks {
            totalPlannedMinutes += block.durationMinutes
            
            switch block.status {
            case .completed:
                completedBlocks += 1
                completedMinutes += block.durationMinutes
            case .skipped:
                skippedBlocks += 1
            case .inProgress:
                inProgressBlocks += 1
                // For in-progress blocks, count partial completion based on time elapsed
                if block.isCurrentlyActive {
                    let partialMinutes = Int(block.currentProgress * Double(block.durationMinutes))
                    completedMinutes += partialMinutes
                }
            case .notStarted:
                break
            }
        }
        
        updatedAt = Date()
    }
    
    /// Increment completed blocks count
    func incrementCompleted(duration: Int) {
        completedBlocks += 1
        completedMinutes += duration
        // Adjust in-progress if this was previously in progress
        if inProgressBlocks > 0 {
            inProgressBlocks -= 1
        }
        updatedAt = Date()
    }
    
    /// Increment skipped blocks count
    func incrementSkipped() {
        skippedBlocks += 1
        // Adjust in-progress if this was previously in progress
        if inProgressBlocks > 0 {
            inProgressBlocks -= 1
        }
        updatedAt = Date()
    }
    
    /// Mark block as started (in progress)
    func markBlockStarted() {
        inProgressBlocks += 1
        updatedAt = Date()
    }
    
    /// Set user's subjective rating for the day
    func setDayRating(_ rating: Int) {
        guard rating >= 1 && rating <= 5 else { return }
        dayRating = rating
        updatedAt = Date()
    }
    
    /// Set notes for the day
    func setDayNotes(_ notes: String) {
        dayNotes = notes.isEmpty ? nil : notes
        updatedAt = Date()
    }
    
    /// Mark summary as viewed
    func markSummaryViewed() {
        summaryViewed = true
        updatedAt = Date()
    }
}

// MARK: - Performance Analysis
extension DailyProgress {
    /// Performance level based on completion percentage
    var performanceLevel: PerformanceLevel {
        let percentage = completionPercentage
        
        switch percentage {
        case 0.9...1.0:
            return .excellent
        case 0.7..<0.9:
            return .good
        case 0.5..<0.7:
            return .fair
        case 0.2..<0.5:
            return .poor
        default:
            return .none
        }
    }
    
    /// Motivational message based on performance
    var motivationalMessage: String {
        switch performanceLevel {
        case .excellent:
            return "Outstanding work! You crushed your goals today! 🎉"
        case .good:
            return "Great job! You're building strong habits! 💪"
        case .fair:
            return "Good progress! Tomorrow is another opportunity to improve! 📈"
        case .poor:
            return "Every step counts! Small progress is still progress! 🌱"
        case .none:
            return "Ready to start building your routine? You've got this! ✨"
        }
    }
    
    /// Suggestions for improvement
    var suggestions: [String] {
        var suggestions: [String] = []
        
        if skipRate > 0.3 {
            suggestions.append("Consider shortening time blocks to make them more manageable")
        }
        
        if completionPercentage < 0.5 && totalBlocks > 6 {
            suggestions.append("Try scheduling fewer blocks to build consistency")
        }
        
        if inProgressBlocks > completedBlocks && isDayComplete {
            suggestions.append("Remember to mark completed tasks to track your progress")
        }
        
        if suggestions.isEmpty {
            suggestions.append("Keep up the great work with your routine!")
        }
        
        return suggestions
    }
}

// MARK: - Performance Level Enum
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
    
    var color: Color {
        switch self {
        case .excellent: return .green
        case .good: return .blue
        case .fair: return .orange
        case .poor: return .red
        case .none: return .gray
        }
    }
    
    var emoji: String {
        switch self {
        case .excellent: return "🏆"
        case .good: return "👍"
        case .fair: return "📈"
        case .poor: return "🌱"
        case .none: return "⚪"
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

// MARK: - Validation
extension DailyProgress {
    /// Whether this progress record has valid data
    var isValid: Bool {
        return totalBlocks >= 0 &&
               completedBlocks >= 0 &&
               skippedBlocks >= 0 &&
               inProgressBlocks >= 0 &&
               completedBlocks + skippedBlocks + inProgressBlocks <= totalBlocks &&
               totalPlannedMinutes >= 0 &&
               completedMinutes >= 0 &&
               completedMinutes <= totalPlannedMinutes
    }
    
    /// Validation errors for this progress record
    var validationErrors: [String] {
        var errors: [String] = []
        
        if totalBlocks < 0 {
            errors.append("Total blocks cannot be negative")
        }
        
        if completedBlocks < 0 {
            errors.append("Completed blocks cannot be negative")
        }
        
        if skippedBlocks < 0 {
            errors.append("Skipped blocks cannot be negative")
        }
        
        if inProgressBlocks < 0 {
            errors.append("In-progress blocks cannot be negative")
        }
        
        if completedBlocks + skippedBlocks + inProgressBlocks > totalBlocks {
            errors.append("Sum of block statuses cannot exceed total blocks")
        }
        
        if totalPlannedMinutes < 0 {
            errors.append("Total planned minutes cannot be negative")
        }
        
        if completedMinutes < 0 {
            errors.append("Completed minutes cannot be negative")
        }
        
        if completedMinutes > totalPlannedMinutes {
            errors.append("Completed minutes cannot exceed planned minutes")
        }
        
        if let rating = dayRating, (rating < 1 || rating > 5) {
            errors.append("Day rating must be between 1 and 5")
        }
        
        return errors
    }
}

// MARK: - Statistics
extension DailyProgress {
    /// Statistics summary for analytics or insights
    var statisticsSummary: [String: Any] {
        return [
            "date": date,
            "totalBlocks": totalBlocks,
            "completedBlocks": completedBlocks,
            "skippedBlocks": skippedBlocks,
            "inProgressBlocks": inProgressBlocks,
            "completionPercentage": completionPercentage,
            "skipRate": skipRate,
            "totalPlannedMinutes": totalPlannedMinutes,
            "completedMinutes": completedMinutes,
            "timeCompletionPercentage": timeCompletionPercentage,
            "performanceScore": performanceScore,
            "performanceLevel": performanceLevel.rawValue,
            "isDayComplete": isDayComplete,
            "dayRating": dayRating as Any
        ]
    }
    
    /// Export data for backup or analysis
    var exportData: [String: Any] {
        return [
            "id": id.uuidString,
            "date": ISO8601DateFormatter().string(from: date),
            "totalBlocks": totalBlocks,
            "completedBlocks": completedBlocks,
            "skippedBlocks": skippedBlocks,
            "inProgressBlocks": inProgressBlocks,
            "totalPlannedMinutes": totalPlannedMinutes,
            "completedMinutes": completedMinutes,
            "dayRating": dayRating as Any,
            "dayNotes": dayNotes as Any,
            "summaryViewed": summaryViewed,
            "createdAt": ISO8601DateFormatter().string(from: createdAt),
            "updatedAt": ISO8601DateFormatter().string(from: updatedAt)
        ]
    }
}

// MARK: - Convenience Methods
extension DailyProgress {
    /// Reset all progress for a fresh start (useful for testing or correction)
    func reset() {
        totalBlocks = 0
        completedBlocks = 0
        skippedBlocks = 0
        inProgressBlocks = 0
        totalPlannedMinutes = 0
        completedMinutes = 0
        dayRating = nil
        dayNotes = nil
        summaryViewed = false
        updatedAt = Date()
    }
    
    /// Create a copy for a different date (useful for templates)
    func copyToDate(_ newDate: Date) -> DailyProgress {
        let copy = DailyProgress(date: newDate)
        copy.totalBlocks = self.totalBlocks
        copy.totalPlannedMinutes = self.totalPlannedMinutes
        // Don't copy progress data, only structure
        return copy
    }
    
    /// Update the metadata timestamp
    func touch() {
        updatedAt = Date()
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

// MARK: - Static Helpers
extension DailyProgress {
    /// Create daily progress from time blocks for a specific date
    static func from(timeBlocks: [TimeBlock], date: Date) -> DailyProgress {
        return DailyProgress(date: date, timeBlocks: timeBlocks)
    }
    
    /// Calculate weekly statistics from multiple daily progress records
    static func weeklyStatistics(from dailyProgress: [DailyProgress]) -> WeeklyStats {
        let totalDays = dailyProgress.count
        let completedDays = dailyProgress.filter { $0.isDayComplete }.count
        let averageCompletion = dailyProgress.map { $0.completionPercentage }.reduce(0, +) / Double(max(totalDays, 1))
        let totalBlocks = dailyProgress.map { $0.totalBlocks }.reduce(0, +)
        let totalCompleted = dailyProgress.map { $0.completedBlocks }.reduce(0, +)
        
        return WeeklyStats(
            totalDays: totalDays,
            completedDays: completedDays,
            averageCompletion: averageCompletion,
            totalBlocks: totalBlocks,
            totalCompleted: totalCompleted
        )
    }
}

// MARK: - Weekly Statistics Helper
struct WeeklyStats {
    let totalDays: Int
    let completedDays: Int
    let averageCompletion: Double
    let totalBlocks: Int
    let totalCompleted: Int
    
    var formattedAverageCompletion: String {
        return String(format: "%.0f%%", averageCompletion * 100)
    }
    
    var completionSummary: String {
        return "\(totalCompleted) of \(totalBlocks) blocks completed"
    }
}
