//
//  TimeBlock.swift
//  Routine Anchor - Premium Version
//
import Foundation
import SwiftData
import SwiftUI

/// Represents a single time block in the user's daily routine with premium features
@Model
class TimeBlock {
    // MARK: - Core Properties
    
    /// Unique identifier for the time block
    @Attribute(.unique) var id: UUID
    
    /// User-defined title for the time block
    var title: String
    
    /// When this time block should start
    var startTime: Date
    
    /// When this time block should end
    var endTime: Date
    
    /// Current status of the time block (stored as String for SwiftData compatibility)
    var statusValue: String = BlockStatus.notStarted.rawValue
    
    /// Optional description or notes about the time block
    var notes: String?
    
    /// Optional emoji or icon identifier
    var icon: String?
    
    /// Optional category for grouping (e.g., "Work", "Personal", "Health")
    var category: String?
    
    /// Optional color identifier for customization
    var colorId: String?
    
    // MARK: - Premium Features
    
    /// Priority level (1-5, with 5 being highest)
    var priority: Int = 3
    
    /// Whether this block is recurring
    var isRecurring: Bool = false
    
    /// Recurrence pattern (daily, weekly, monthly, etc.)
    var recurrencePattern: String?
    
    /// Tags for additional categorization
    var tags: [String] = []
    
    /// Location where this block should be performed
    var location: String?
    
    /// Energy level required (1-5)
    var energyLevel: Int = 3
    
    /// Whether notifications are enabled for this block
    var notificationsEnabled: Bool = true
    
    /// Custom notification minutes before start (-1 means default)
    var notificationMinutesBefore: Int = -1
    
    /// Completion percentage (0-100)
    var completionPercentage: Double = 0.0
    
    /// Actual start time (when user started)
    var actualStartTime: Date?
    
    /// Actual end time (when user finished)
    var actualEndTime: Date?
    
    // MARK: - Analytics
    
    /// Number of times this block has been completed
    var completionCount: Int = 0
    
    /// Number of times this block has been skipped
    var skipCount: Int = 0
    
    /// Average completion time in minutes
    var averageCompletionMinutes: Double = 0.0
    
    /// Last completion date
    var lastCompletedDate: Date?
    
    // MARK: - Metadata
    
    /// When this time block was originally created
    var createdAt: Date
    
    /// When this time block was last modified
    var updatedAt: Date
    
    /// Date this time block is scheduled for (derived from startTime)
    var scheduledDate: Date {
        Calendar.current.startOfDay(for: startTime)
    }
    
    // MARK: - Status Property (Computed)
    
    /// Current status of the time block
    var status: BlockStatus {
        get { BlockStatus(rawValue: statusValue) ?? .notStarted }
        set {
            statusValue = newValue.rawValue
            
            // Update analytics based on status change
            switch newValue {
            case .completed:
                completionCount += 1
                lastCompletedDate = Date()
                if let start = actualStartTime, let end = actualEndTime {
                    let duration = end.timeIntervalSince(start) / 60.0
                    updateAverageCompletionTime(duration)
                }
            case .skipped:
                skipCount += 1
            default:
                break
            }
        }
    }
    
    // MARK: - Initializers
    
    /// Create a new time block with required information
    init(
        title: String,
        startTime: Date,
        endTime: Date,
        notes: String? = nil,
        icon: String? = nil,
        category: String? = nil,
        colorId: String? = nil,
        priority: Int = 3,
        tags: [String] = [],
        location: String? = nil,
        energyLevel: Int = 3
    ) {
        self.id = UUID()
        self.title = title
        self.startTime = startTime
        self.endTime = endTime
        self.statusValue = BlockStatus.notStarted.rawValue
        self.notes = notes
        self.icon = icon
        self.category = category
        self.colorId = colorId
        self.priority = priority
        self.tags = tags
        self.location = location
        self.energyLevel = energyLevel
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    /// Create a time block for a specific date with time components
    convenience init(
        title: String,
        date: Date,
        startHour: Int,
        startMinute: Int = 0,
        durationMinutes: Int,
        notes: String? = nil,
        icon: String? = nil,
        category: String? = nil,
        colorId: String? = nil
    ) {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: date)
        components.hour = startHour
        components.minute = startMinute
        
        guard let startTime = calendar.date(from: components) else {
            fatalError("Failed to create start time")
        }
        
        guard let endTime = calendar.date(byAdding: .minute, value: durationMinutes, to: startTime) else {
            fatalError("Failed to create end time")
        }
        
        self.init(
            title: title,
            startTime: startTime,
            endTime: endTime,
            notes: notes,
            icon: icon,
            category: category,
            colorId: colorId
        )
    }
    
    // MARK: - Computed Properties
    
    /// Duration of the time block in minutes
    var durationMinutes: Int {
        Calendar.current.dateComponents([.minute], from: startTime, to: endTime).minute ?? 0
    }
    
    /// Duration of the time block in hours
    var durationHours: Double {
        Double(durationMinutes) / 60.0
    }
    
    var duration: Int {
        return durationMinutes
    }
    
    /// Formatted duration string (e.g., "2h 30m")
    var formattedDuration: String {
        let hours = durationMinutes / 60
        let minutes = durationMinutes % 60
        
        if hours > 0 && minutes > 0 {
            return "\(hours)h \(minutes)m"
        } else if hours > 0 {
            return "\(hours)h"
        } else {
            return "\(minutes)m"
        }
    }
    
    /// Formatted time range (e.g., "9:00 AM - 10:30 AM")
    var formattedTimeRange: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return "\(formatter.string(from: startTime)) - \(formatter.string(from: endTime))"
    }
    
    /// Short formatted time range (e.g., "9:00-10:30")
    var shortFormattedTimeRange: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm"
        let startStr = formatter.string(from: startTime)
        let endStr = formatter.string(from: endTime)
        
        // Add AM/PM only if they differ
        let startPeriod = DateFormatter.dateFormat(fromTemplate: "a", options: 0, locale: .current)
        formatter.dateFormat = startPeriod
        let startAmPm = formatter.string(from: startTime)
        let endAmPm = formatter.string(from: endTime)
        
        if startAmPm == endAmPm {
            return "\(startStr)-\(endStr)"
        } else {
            formatter.dateFormat = "h:mm a"
            return "\(formatter.string(from: startTime))-\(formatter.string(from: endTime))"
        }
    }
    
    /// Whether this time block is happening today
    var isToday: Bool {
        Calendar.current.isDateInToday(startTime)
    }
    
    /// Whether this time block is happening now
    var isCurrentlyActive: Bool {
        let now = Date()
        return now >= startTime && now <= endTime && status == .inProgress
    }
    
    /// Progress percentage if currently active
    var currentProgress: Double {
        guard isCurrentlyActive else { return 0 }
        
        let total = endTime.timeIntervalSince(startTime)
        let elapsed = Date().timeIntervalSince(startTime)
        return min(max(elapsed / total, 0), 1)
    }
    
    /// Time remaining in minutes
    var minutesRemaining: Int {
        guard Date() < endTime else { return 0 }
        return Calendar.current.dateComponents([.minute], from: Date(), to: endTime).minute ?? 0
    }
    
    /// Premium gradient colors based on category
    var categoryGradient: [Color] {
        switch category?.lowercased() {
        case "work": return [Color.premiumBlue, Color.premiumPurple]
        case "personal": return [Color.premiumGreen, Color.premiumTeal]
        case "health": return [Color.premiumGreen, Color.premiumBlue]
        case "learning": return [Color.premiumPurple, Color.premiumBlue]
        case "social": return [Color.premiumTeal, Color.premiumBlue]
        default: return [Color.premiumTextSecondary, Color.premiumTextTertiary]
        }
    }
    
    /// Priority color
    var priorityColor: Color {
        switch priority {
        case 5: return Color.premiumError
        case 4: return Color.premiumWarning
        case 3: return Color.premiumBlue
        case 2: return Color.premiumTeal
        default: return Color.premiumTextSecondary
        }
    }
    
    /// Energy level icon
    var energyIcon: String {
        switch energyLevel {
        case 5: return "bolt.fill"
        case 4: return "bolt"
        case 3: return "battery.75"
        case 2: return "battery.50"
        default: return "battery.25"
        }
    }
    
    /// Completion rate
    var completionRate: Double {
        let total = completionCount + skipCount
        guard total > 0 else { return 0 }
        return Double(completionCount) / Double(total)
    }
    
    // MARK: - Methods
    
    /// Check if this time block conflicts with another
    func conflictsWith(_ other: TimeBlock) -> Bool {
        // Same day check
        guard Calendar.current.isDate(startTime, inSameDayAs: other.startTime) else {
            return false
        }
        
        // Time overlap check
        return (startTime < other.endTime) && (endTime > other.startTime)
    }
    
    /// Check if this time block conflicts with any in the array
    func conflictsWith(_ others: [TimeBlock]) -> [TimeBlock] {
        others.filter { conflictsWith($0) && $0.id != self.id }
    }
    
    /// Create a copy of this time block for a different date
    func copy(to date: Date) -> TimeBlock {
        let calendar = Calendar.current
        
        // Get time components from original
        let startComponents = calendar.dateComponents([.hour, .minute], from: startTime)
        let endComponents = calendar.dateComponents([.hour, .minute], from: endTime)
        
        // Create new start and end times on the target date
        var newStartComponents = calendar.dateComponents([.year, .month, .day], from: date)
        newStartComponents.hour = startComponents.hour
        newStartComponents.minute = startComponents.minute
        
        var newEndComponents = calendar.dateComponents([.year, .month, .day], from: date)
        newEndComponents.hour = endComponents.hour
        newEndComponents.minute = endComponents.minute
        
        guard let newStartTime = calendar.date(from: newStartComponents),
              let newEndTime = calendar.date(from: newEndComponents) else {
            return self
        }
        
        return TimeBlock(
            title: title,
            startTime: newStartTime,
            endTime: newEndTime,
            notes: notes,
            icon: icon,
            category: category,
            colorId: colorId,
            priority: priority,
            tags: tags,
            location: location,
            energyLevel: energyLevel
        )
    }
    
    /// Update the metadata timestamp
    func touch() {
        updatedAt = Date()
    }
    
    /// Start tracking actual time
    func startTracking() {
        actualStartTime = Date()
        status = .inProgress
        touch()
    }
    
    /// Complete tracking
    func completeTracking() {
        actualEndTime = Date()
        status = .completed
        completionPercentage = 100.0
        touch()
    }
    
    /// Update average completion time
    private func updateAverageCompletionTime(_ newDuration: Double) {
        if averageCompletionMinutes == 0 {
            averageCompletionMinutes = newDuration
        } else {
            // Calculate new average
            let totalDuration = averageCompletionMinutes * Double(completionCount - 1) + newDuration
            averageCompletionMinutes = totalDuration / Double(completionCount)
        }
    }
}

// MARK: - Hashable & Equatable
extension TimeBlock: Hashable {
    static func == (lhs: TimeBlock, rhs: TimeBlock) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Comparable (for sorting)
extension TimeBlock: Comparable {
    static func < (lhs: TimeBlock, rhs: TimeBlock) -> Bool {
        // Primary sort: by start time
        if lhs.startTime != rhs.startTime {
            return lhs.startTime < rhs.startTime
        }
        
        // Secondary sort: by priority
        if lhs.priority != rhs.priority {
            return lhs.priority > rhs.priority
        }
        
        // Tertiary sort: by status priority
        if lhs.status.sortPriority != rhs.status.sortPriority {
            return lhs.status.sortPriority > rhs.status.sortPriority
        }
        
        // Final sort: by title
        return lhs.title < rhs.title
    }
}

// MARK: - Premium Features Extensions

extension TimeBlock {
    /// Generate smart suggestions based on historical data
    var smartSuggestions: [String] {
        var suggestions: [String] = []
        
        // Completion rate suggestion
        if completionRate < 0.5 && skipCount > 2 {
            suggestions.append("Consider shortening this block or scheduling it at a different time")
        }
        
        // Duration suggestion
        if averageCompletionMinutes > 0 && abs(averageCompletionMinutes - Double(durationMinutes)) > 15 {
            let suggestedDuration = Int(averageCompletionMinutes.rounded())
            suggestions.append("Based on history, adjust duration to \(suggestedDuration) minutes")
        }
        
        // Energy level suggestion
        if energyLevel >= 4 && category == "Work" {
            suggestions.append("High-energy block - best scheduled for your peak hours")
        }
        
        return suggestions
    }
    
    /// Calculate productivity score
    var productivityScore: Double {
        var score = 0.0
        
        // Completion rate factor (40%)
        score += completionRate * 40
        
        // Consistency factor (30%)
        if completionCount > 5 {
            score += 30
        } else if completionCount > 2 {
            score += 20
        } else if completionCount > 0 {
            score += 10
        }
        
        // Time accuracy factor (30%)
        if averageCompletionMinutes > 0 {
            let accuracy = 1.0 - abs(averageCompletionMinutes - Double(durationMinutes)) / Double(durationMinutes)
            score += max(accuracy * 30, 0)
        }
        
        return score
    }
    
    /// Get motivational message based on performance
    var motivationalMessage: String? {
        if completionRate >= 0.8 {
            return "🌟 Excellent consistency! Keep it up!"
        } else if completionRate >= 0.6 {
            return "💪 Good progress! A bit more focus will make this perfect."
        } else if skipCount > completionCount {
            return "🎯 This block might need adjusting. Try a different time or shorter duration."
        }
        return nil
    }
}

// MARK: - Identifiable
extension TimeBlock: Identifiable {}
