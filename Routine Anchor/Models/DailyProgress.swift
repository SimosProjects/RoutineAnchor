//
//  DailyProgress.swift
//  Routine Anchor
//
//  SwiftData model tracking a single day's schedule stats.
//  Core model is UI-agnostic. A SwiftUI-only extension at the bottom
//  maps performance levels to theme-aware colors.
//

import Foundation
import SwiftData

/// Tracks daily progress and completion statistics for time blocks.
@Model
final class DailyProgress {
    // MARK: - Core Properties

    /// Stable unique identifier.
    @Attribute(.unique) var id: UUID

    /// The day this record represents (stored as start-of-day for consistency).
    var date: Date

    // Counts
    var totalBlocks: Int
    var completedBlocks: Int
    var skippedBlocks: Int
    var inProgressBlocks: Int

    // Time totals (minutes)
    var totalPlannedMinutes: Int
    var completedMinutes: Int

    // Optional user inputs
    var dayRating: Int?          // 1–5
    var dayNotes: String?

    // Metadata
    var createdAt: Date
    var updatedAt: Date
    var summaryViewed: Bool

    // MARK: - Init

    init(date: Date) {
        self.id = UUID()
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

    /// Create daily progress from a list of time blocks.
    convenience init(date: Date, timeBlocks: [TimeBlock]) {
        self.init(date: date)
        updateFromTimeBlocks(timeBlocks)
    }
}

// MARK: - Computed
extension DailyProgress {
    var notStartedBlocks: Int {
        totalBlocks - completedBlocks - skippedBlocks - inProgressBlocks
    }

    /// Completion (0…1).
    var completionPercentage: Double {
        guard totalBlocks > 0 else { return 0 }
        return Double(completedBlocks) / Double(totalBlocks)
    }

    /// Success incl. in-progress (0…1).
    var successRate: Double {
        guard totalBlocks > 0 else { return 0 }
        return Double(completedBlocks + inProgressBlocks) / Double(totalBlocks)
    }

    /// Skip rate (0…1).
    var skipRate: Double {
        guard totalBlocks > 0 else { return 0 }
        return Double(skippedBlocks) / Double(totalBlocks)
    }

    /// Completed time vs planned (0…1).
    var timeCompletionPercentage: Double {
        guard totalPlannedMinutes > 0 else { return 0 }
        return Double(completedMinutes) / Double(totalPlannedMinutes)
    }

    var formattedCompletionPercentage: String {
        String(format: "%.0f%%", completionPercentage * 100)
    }

    var completionSummary: String {
        "\(completedBlocks) of \(totalBlocks) completed"
    }

    var timeSummary: String {
        let plannedH = totalPlannedMinutes / 60
        let plannedM = totalPlannedMinutes % 60
        let doneH = completedMinutes / 60
        let doneM = completedMinutes % 60

        let planned = plannedH > 0 ? "\(plannedH)h \(plannedM)m" : "\(plannedM)m"
        let done    = doneH > 0 ? "\(doneH)h \(doneM)m" : "\(doneM)m"
        return "\(done) of \(planned) planned"
    }

    var isToday: Bool { Calendar.current.isDateInToday(date) }
    var hasScheduledBlocks: Bool { totalBlocks > 0 }
    var isDayComplete: Bool { totalBlocks > 0 && (completedBlocks + skippedBlocks) == totalBlocks }

    /// Completion + small bonuses (0…1).
    var performanceScore: Double {
        guard totalBlocks > 0 else { return 0 }
        var score = completionPercentage
        let consistencyBonus = (1.0 - skipRate) * 0.2
        score += consistencyBonus
        if isDayComplete && skipRate == 0 { score += 0.1 }
        return min(score, 1.0)
    }
}

// MARK: - Updates
extension DailyProgress {
    /// Recompute stats from blocks belonging to this date.
    func updateFromTimeBlocks(_ timeBlocks: [TimeBlock]) {
        let dayBlocks = timeBlocks.filter { Calendar.current.isDate($0.startTime, inSameDayAs: date) }

        totalBlocks = dayBlocks.count
        completedBlocks = 0
        skippedBlocks = 0
        inProgressBlocks = 0
        totalPlannedMinutes = 0
        completedMinutes = 0

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
                if block.isCurrentlyActive {
                    let partial = Int(block.currentProgress * Double(block.durationMinutes))
                    completedMinutes += partial
                }
            case .notStarted:
                break
            }
        }

        updatedAt = Date()
    }

    func incrementCompleted(duration: Int) {
        completedBlocks += 1
        completedMinutes += duration
        if inProgressBlocks > 0 { inProgressBlocks -= 1 }
        updatedAt = Date()
    }

    func incrementSkipped() {
        skippedBlocks += 1
        if inProgressBlocks > 0 { inProgressBlocks -= 1 }
        updatedAt = Date()
    }

    func markBlockStarted() {
        inProgressBlocks += 1
        updatedAt = Date()
    }

    func setDayRating(_ rating: Int) {
        guard (1...5).contains(rating) else { return }
        dayRating = rating
        updatedAt = Date()
    }

    func setDayNotes(_ notes: String) {
        dayNotes = notes.isEmpty ? nil : notes
        updatedAt = Date()
    }

    func markSummaryViewed() {
        summaryViewed = true
        updatedAt = Date()
    }
}

// MARK: - Performance / Copy
extension DailyProgress {
    enum PerformanceLevel: String, CaseIterable, Sendable {
        case excellent, good, fair, poor, none

        var displayName: String {
            switch self {
            case .excellent: return "Excellent"
            case .good:      return "Good"
            case .fair:      return "Fair"
            case .poor:      return "Poor"
            case .none:      return "Not Started"
            }
        }

        var emoji: String {
            switch self {
            case .excellent: return "🏆"
            case .good:      return "👍"
            case .fair:      return "📈"
            case .poor:      return "🌱"
            case .none:      return "⚪"
            }
        }
    }

    var performanceLevel: PerformanceLevel {
        switch completionPercentage {
        case 0.9...1.0:  return .excellent
        case 0.7..<0.9:  return .good
        case 0.5..<0.7:  return .fair
        case 0.2..<0.5:  return .poor
        default:         return .none
        }
    }

    var motivationalMessage: String {
        switch performanceLevel {
        case .excellent: return "Outstanding work! You crushed your goals today! 🎉"
        case .good:      return "Great job! You're building strong habits! 💪"
        case .fair:      return "Good progress! Tomorrow is another opportunity to improve! 📈"
        case .poor:      return "Every step counts! Small progress is still progress! 🌱"
        case .none:      return "Ready to start building your routine? You've got this! ✨"
        }
    }

    var suggestions: [String] {
        var result: [String] = []
        if skipRate > 0.3 { result.append("Consider shortening time blocks to make them more manageable") }
        if completionPercentage < 0.5 && totalBlocks > 6 { result.append("Try scheduling fewer blocks to build consistency") }
        if inProgressBlocks > completedBlocks && isDayComplete { result.append("Remember to mark completed tasks to track your progress") }
        if result.isEmpty { result.append("Keep up the great work with your routine!") }
        return result
    }
}

// MARK: - Formatting / Dates
extension DailyProgress {
    var formattedDate: String {
        let f = DateFormatter()
        if Calendar.current.isDateInToday(date) { return "Today" }
        if Calendar.current.isDateInYesterday(date) { return "Yesterday" }
        f.dateStyle = .medium
        return f.string(from: date)
    }

    var shortFormattedDate: String {
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return f.string(from: date)
    }

    var dayOfWeek: String {
        let f = DateFormatter()
        f.dateFormat = "EEEE"
        return f.string(from: date)
    }

    var shortDayOfWeek: String {
        let f = DateFormatter()
        f.dateFormat = "EEE"
        return f.string(from: date)
    }
}

// MARK: - Validation
extension DailyProgress {
    var isValid: Bool {
        totalBlocks >= 0 &&
        completedBlocks >= 0 &&
        skippedBlocks >= 0 &&
        inProgressBlocks >= 0 &&
        completedBlocks + skippedBlocks + inProgressBlocks <= totalBlocks &&
        totalPlannedMinutes >= 0 &&
        completedMinutes >= 0 &&
        completedMinutes <= totalPlannedMinutes &&
        (dayRating == nil || (1...5).contains(dayRating!))
    }

    var validationErrors: [String] {
        var errors: [String] = []
        if totalBlocks < 0 { errors.append("Total blocks cannot be negative") }
        if completedBlocks < 0 { errors.append("Completed blocks cannot be negative") }
        if skippedBlocks < 0 { errors.append("Skipped blocks cannot be negative") }
        if inProgressBlocks < 0 { errors.append("In-progress blocks cannot be negative") }
        if completedBlocks + skippedBlocks + inProgressBlocks > totalBlocks {
            errors.append("Sum of block statuses cannot exceed total blocks")
        }
        if totalPlannedMinutes < 0 { errors.append("Total planned minutes cannot be negative") }
        if completedMinutes < 0 { errors.append("Completed minutes cannot be negative") }
        if completedMinutes > totalPlannedMinutes { errors.append("Completed minutes cannot exceed planned minutes") }
        if let r = dayRating, !(1...5).contains(r) { errors.append("Day rating must be between 1 and 5") }
        return errors
    }
}

// MARK: - Stats / Export
extension DailyProgress {
    var statisticsSummary: [String: Any] {
        [
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

    var exportData: [String: Any] {
        [
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

// MARK: - Utilities
extension DailyProgress {
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

    func copyToDate(_ newDate: Date) -> DailyProgress {
        let copy = DailyProgress(date: newDate)
        copy.totalBlocks = self.totalBlocks
        copy.totalPlannedMinutes = self.totalPlannedMinutes
        return copy
    }

    func touch() {
        updatedAt = Date()
    }
}

// MARK: - Sorting / Identity
extension DailyProgress: Hashable {
    static func == (lhs: DailyProgress, rhs: DailyProgress) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}
extension DailyProgress: Comparable {
    static func < (lhs: DailyProgress, rhs: DailyProgress) -> Bool { lhs.date < rhs.date }
}

// MARK: - Aggregation
extension DailyProgress {
    static func from(timeBlocks: [TimeBlock], date: Date) -> DailyProgress {
        DailyProgress(date: date, timeBlocks: timeBlocks)
    }

    static func weeklyStatistics(from daily: [DailyProgress]) -> WeeklyStats {
        let totalDays = daily.count
        let completedDays = daily.filter { $0.isDayComplete }.count
        let avgCompletion = daily.map { $0.completionPercentage }.reduce(0, +) / Double(max(totalDays, 1))
        let totalBlocks = daily.map { $0.totalBlocks }.reduce(0, +)
        let totalCompleted = daily.map { $0.completedBlocks }.reduce(0, +)

        return WeeklyStats(
            totalDays: totalDays,
            completedDays: completedDays,
            averageCompletion: avgCompletion,
            totalBlocks: totalBlocks,
            totalCompleted: totalCompleted
        )
    }
}

struct WeeklyStats: Sendable {
    let totalDays: Int
    let completedDays: Int
    let averageCompletion: Double
    let totalBlocks: Int
    let totalCompleted: Int

    var formattedAverageCompletion: String {
        String(format: "%.0f%%", averageCompletion * 100)
    }

    var completionSummary: String {
        "\(totalCompleted) of \(totalBlocks) blocks completed"
    }
}

#if canImport(SwiftUI)
import SwiftUI

// MARK: - Theme-aware color mapping (SwiftUI-only)

extension DailyProgress.PerformanceLevel {
    /// Map level to a semantic color in the current theme.
    func color(theme: AppTheme) -> Color {
        switch self {
        case .excellent: return theme.statusSuccessColor
        case .good:      return theme.accentPrimaryColor
        case .fair:      return theme.statusWarningColor
        case .poor:      return theme.statusErrorColor
        case .none:      return theme.subtleTextColor
        }
    }
}
#endif
