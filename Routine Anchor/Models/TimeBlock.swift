//
//  TimeBlock.swift
//  Routine Anchor
//
//  Created by Christopher Simonson on 7/19/25.
//
import Foundation
import SwiftData

/// Represents a single time block in the user's daily routine
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
    
    var calendarEventId: String?
    var calendarId: String?
    var calendarLastModified: Date?
    
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
        set { statusValue = newValue.rawValue }
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
        calendarEventId: String? = nil,
        calendarId: String? = nil,
        calendarLastModified: Date? = nil
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
        self.createdAt = Date()
        self.updatedAt = Date()
        self.calendarEventId = calendarEventId
        self.calendarId = calendarId
        self.calendarLastModified = calendarLastModified
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
        category: String? = nil
    ) {
        let calendar = Calendar.current
        let startComponents = DateComponents(
            year: calendar.component(.year, from: date),
            month: calendar.component(.month, from: date),
            day: calendar.component(.day, from: date),
            hour: startHour,
            minute: startMinute
        )
        
        guard let startTime = calendar.date(from: startComponents) else {
            fatalError("Invalid time components")
        }
        
        let endTime = calendar.date(byAdding: .minute, value: durationMinutes, to: startTime) ?? startTime
        
        self.init(
            title: title,
            startTime: startTime,
            endTime: endTime,
            notes: notes,
            icon: icon,
            category: category
        )
    }
}

// MARK: - Computed Properties
extension TimeBlock {
    /// Duration of the time block in minutes
    var durationMinutes: Int {
        Int(endTime.timeIntervalSince(startTime) / 60)
    }
    
    /// Duration of the time block in hours (rounded to 1 decimal place)
    var durationHours: Double {
        Double(durationMinutes) / 60.0
    }
    
    /// Formatted duration string (e.g., "1h 30m", "45m")
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
    
    /// Formatted time range string (e.g., "9:00 AM - 10:30 AM")
    var formattedTimeRange: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return "\(formatter.string(from: startTime)) - \(formatter.string(from: endTime))"
    }
    
    /// Short formatted time range (e.g., "9:00-10:30")
    var shortFormattedTimeRange: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "H:mm"
        return "\(formatter.string(from: startTime))-\(formatter.string(from: endTime))"
    }
    
    /// Whether this time block is scheduled for today
    var isToday: Bool {
        Calendar.current.isDateInToday(startTime)
    }
    
    /// Whether this time block is currently active (within its time range)
    var isCurrentlyActive: Bool {
        let now = Date()
        return now >= startTime && now <= endTime
    }
    
    /// Whether this time block is in the past
    var isPast: Bool {
        Date() > endTime
    }
    
    /// Whether this time block is in the future
    var isFuture: Bool {
        Date() < startTime
    }
    
    /// Progress percentage if currently active (0.0 to 1.0)
    var currentProgress: Double {
        guard isCurrentlyActive else { return 0.0 }
        
        let totalDuration = endTime.timeIntervalSince(startTime)
        let elapsed = Date().timeIntervalSince(startTime)
        
        return min(max(elapsed / totalDuration, 0.0), 1.0)
    }
    
    /// Remaining time in minutes if currently active
    var remainingMinutes: Int? {
        guard isCurrentlyActive else { return nil }
        return max(0, Int(endTime.timeIntervalSince(Date()) / 60))
    }
}

// MARK: - Status Management
extension TimeBlock {
    /// Update the status and handle side effects
    func updateStatus(to newStatus: BlockStatus) {
        guard status.canTransition else { return }
        guard status.availableTransitions.contains(newStatus) else { return }
        
        status = newStatus
        updatedAt = Date()
        
        // Handle status-specific logic
        switch newStatus {
        case .inProgress:
            // Could trigger analytics or notifications
            break
        case .completed:
            // Could trigger celebration or next task suggestion
            break
        case .skipped:
            // Could track skip reasons for insights
            break
        case .notStarted:
            break
        }
    }
    
    /// Mark this time block as completed
    func markCompleted() {
        updateStatus(to: .completed)
    }
    
    /// Mark this time block as skipped
    func markSkipped() {
        updateStatus(to: .skipped)
    }
    
    /// Start this time block (mark as in progress)
    func start() {
        updateStatus(to: .inProgress)
    }
    
    /// Update status based on current time
    func updateStatusBasedOnTime() {
        let newStatus = BlockStatus.determineStatus(
            startTime: startTime,
            endTime: endTime,
            currentStatus: status
        )
        
        if newStatus != status {
            updateStatus(to: newStatus)
        }
    }
}

extension TimeBlock {
    var isLinkedToCalendar: Bool { calendarEventId != nil }

    func attachCalendar(eventId: String, calendarId: String, lastModified: Date?) {
        self.calendarEventId = eventId
        self.calendarId = calendarId
        self.calendarLastModified = lastModified
        self.updatedAt = Date()
    }

    func detachCalendar() {
        self.calendarEventId = nil
        self.calendarId = nil
        self.calendarLastModified = nil
        self.updatedAt = Date()
    }
}

// MARK: - Validation
extension TimeBlock {
    /// Whether this time block passes all validation checks
    var isValid: Bool {
        return validationErrors.isEmpty
    }
    
    /// All validation errors for this time block
    var validationErrors: [String] {
        var errors: [String] = []
        
        // Title validation
        if title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.append("Title cannot be empty")
        }
        
        if title.count > 100 {
            errors.append("Title cannot exceed 100 characters")
        }
        
        // Time validation
        if startTime >= endTime {
            errors.append("Start time must be before end time")
        }
        
        if durationMinutes < 1 {
            errors.append("Duration must be at least 1 minute")
        }
        
        if durationMinutes > 24 * 60 {
            errors.append("Duration cannot exceed 24 hours")
        }
        
        // Notes validation
        if let notes = notes, notes.count > 500 {
            errors.append("Notes cannot exceed 500 characters")
        }
        
        // Category validation
        if let category = category, category.count > 50 {
            errors.append("Category cannot exceed 50 characters")
        }
        
        return errors
    }
}

// MARK: - Conflict Detection
extension TimeBlock {
    /// Check if this time block conflicts with another time block
    func conflictsWith(_ other: TimeBlock) -> Bool {
        guard self.id != other.id else { return false }
        guard Calendar.current.isDate(self.startTime, inSameDayAs: other.startTime) else { return false }
        
        // Check for time overlap
        return self.startTime < other.endTime && self.endTime > other.startTime
    }
    
    /// Check if this time block conflicts with a list of other time blocks
    func conflictsWith(_ others: [TimeBlock]) -> [TimeBlock] {
        return others.filter { conflictsWith($0) }
    }
}

// MARK: - Convenience Methods
extension TimeBlock {
    /// Create a copy of this time block for a different date
    func copyToDate(_ date: Date) -> TimeBlock {
        let calendar = Calendar.current
        
        // Calculate the time components from original start time
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
            calendarEventId: nil,
            calendarId: nil,
            calendarLastModified: nil
        )
    }
    
    /// Update the metadata timestamp
    func touch() {
        updatedAt = Date()
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
        
        // Secondary sort: by status priority
        if lhs.status.sortPriority != rhs.status.sortPriority {
            return lhs.status.sortPriority > rhs.status.sortPriority
        }
        
        // Tertiary sort: by title
        return lhs.title < rhs.title
    }
}
