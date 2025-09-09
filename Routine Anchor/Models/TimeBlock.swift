//
//  TimeBlock.swift
//  Routine Anchor
//
//  SwiftData model for a scheduled block of time.
//  Model is UI-agnostic; keep display concerns in views.
//

import Foundation
import SwiftData

/// Represents a single time block in the user's daily routine.
@Model
final class TimeBlock {
    // MARK: - Core

    @Attribute(.unique) var id: UUID
    var title: String
    var startTime: Date
    var endTime: Date

    /// Stored raw value for SwiftData compatibility.
    var statusValue: String = BlockStatus.notStarted.rawValue

    // Optional metadata
    var notes: String?
    var icon: String?
    var category: String?
    var colorId: String?

    // MARK: - Metadata

    var createdAt: Date
    var updatedAt: Date

    /// The day this block is scheduled for (derived from startTime).
    var scheduledDate: Date {
        Calendar.current.startOfDay(for: startTime)
    }

    // MARK: - Computed status

    var status: BlockStatus {
        get { BlockStatus(rawValue: statusValue) ?? .notStarted }
        set { statusValue = newValue.rawValue }
    }

    // MARK: - Init

    init(
        title: String,
        startTime: Date,
        endTime: Date,
        notes: String? = nil,
        icon: String? = nil,
        category: String? = nil,
        colorId: String? = nil
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
    }

    /// Builder for a specific calendar day using hour/minute + duration.
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
        let cal = Calendar.current
        let comps = DateComponents(
            year: cal.component(.year, from: date),
            month: cal.component(.month, from: date),
            day: cal.component(.day, from: date),
            hour: startHour,
            minute: startMinute
        )
        guard let start = cal.date(from: comps) else {
            fatalError("Invalid time components")
        }
        let end = cal.date(byAdding: .minute, value: durationMinutes, to: start) ?? start

        self.init(
            title: title,
            startTime: start,
            endTime: end,
            notes: notes,
            icon: icon,
            category: category
        )
    }
}

// MARK: - Computed helpers
extension TimeBlock {
    var durationMinutes: Int { Int(endTime.timeIntervalSince(startTime) / 60) }
    var durationHours: Double { Double(durationMinutes) / 60.0 }

    var formattedDuration: String {
        let h = durationMinutes / 60
        let m = durationMinutes % 60
        if h > 0 && m > 0 { return "\(h)h \(m)m" }
        if h > 0          { return "\(h)h" }
        return "\(m)m"
    }

    var formattedTimeRange: String {
        let f = DateFormatter(); f.timeStyle = .short
        return "\(f.string(from: startTime)) - \(f.string(from: endTime))"
    }

    var shortFormattedTimeRange: String {
        let f = DateFormatter(); f.dateFormat = "H:mm"
        return "\(f.string(from: startTime))-\(f.string(from: endTime))"
    }

    var isToday: Bool { Calendar.current.isDateInToday(startTime) }

    var isCurrentlyActive: Bool {
        let now = Date()
        return now >= startTime && now <= endTime
    }

    var isPast: Bool { Date() > endTime }
    var isFuture: Bool { Date() < startTime }

    /// Progress (0…1) if active now.
    var currentProgress: Double {
        guard isCurrentlyActive else { return 0 }
        let total = endTime.timeIntervalSince(startTime)
        let elapsed = Date().timeIntervalSince(startTime)
        return min(max(elapsed / total, 0), 1)
    }

    /// Remaining minutes if active.
    var remainingMinutes: Int? {
        guard isCurrentlyActive else { return nil }
        return max(0, Int(endTime.timeIntervalSince(Date()) / 60))
    }
}

// MARK: - Status management
extension TimeBlock {
    func updateStatus(to newStatus: BlockStatus) {
        guard status.canTransition else { return }
        guard status.availableTransitions.contains(newStatus) else { return }

        status = newStatus
        updatedAt = Date()

        // Hook for analytics/notifications if needed later.
        switch newStatus {
        case .inProgress: break
        case .completed:  break
        case .skipped:    break
        case .notStarted: break
        }
    }

    func markCompleted() { updateStatus(to: .completed) }
    func markSkipped()   { updateStatus(to: .skipped) }
    func start()         { updateStatus(to: .inProgress) }

    /// Re-evaluate state based on the clock.
    func updateStatusBasedOnTime() {
        let newStatus = BlockStatus.determineStatus(
            startTime: startTime,
            endTime: endTime,
            currentStatus: status
        )
        if newStatus != status { updateStatus(to: newStatus) }
    }
}

// MARK: - Validation
extension TimeBlock {
    var isValid: Bool { validationErrors.isEmpty }

    var validationErrors: [String] {
        var errors: [String] = []

        if title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.append("Title cannot be empty")
        }
        if title.count > 100 { errors.append("Title cannot exceed 100 characters") }

        if startTime >= endTime { errors.append("Start time must be before end time") }

        if durationMinutes < 1 { errors.append("Duration must be at least 1 minute") }
        if durationMinutes > 24 * 60 { errors.append("Duration cannot exceed 24 hours") }

        if let notes, notes.count > 500 { errors.append("Notes cannot exceed 500 characters") }
        if let category, category.count > 50 { errors.append("Category cannot exceed 50 characters") }

        return errors
    }
}

// MARK: - Conflicts
extension TimeBlock {
    /// Whether this block overlaps another block on the same day.
    func conflictsWith(_ other: TimeBlock) -> Bool {
        guard id != other.id else { return false }
        guard Calendar.current.isDate(startTime, inSameDayAs: other.startTime) else { return false }
        return startTime < other.endTime && endTime > other.startTime
    }

    func conflictsWith(_ others: [TimeBlock]) -> [TimeBlock] {
        others.filter { conflictsWith($0) }
    }
}

// MARK: - Utilities
extension TimeBlock {
    /// Duplicate for a different date, keeping hour/minute range.
    func copyToDate(_ date: Date) -> TimeBlock {
        let cal = Calendar.current
        let startHM = cal.dateComponents([.hour, .minute], from: startTime)
        let endHM   = cal.dateComponents([.hour, .minute], from: endTime)

        var startD = cal.dateComponents([.year, .month, .day], from: date)
        startD.hour = startHM.hour; startD.minute = startHM.minute

        var endD = cal.dateComponents([.year, .month, .day], from: date)
        endD.hour = endHM.hour; endD.minute = endHM.minute

        guard let newStart = cal.date(from: startD),
              let newEnd   = cal.date(from: endD) else { return self }

        return TimeBlock(
            title: title,
            startTime: newStart,
            endTime: newEnd,
            notes: notes,
            icon: icon,
            category: category,
            colorId: colorId
        )
    }

    func touch() {
        updatedAt = Date()
    }
}

// MARK: - Identity / Sorting
extension TimeBlock: Hashable {
    static func == (lhs: TimeBlock, rhs: TimeBlock) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

extension TimeBlock: Comparable {
    static func < (lhs: TimeBlock, rhs: TimeBlock) -> Bool {
        if lhs.startTime != rhs.startTime { return lhs.startTime < rhs.startTime }
        if lhs.status.sortPriority != rhs.status.sortPriority {
            // higher priority first
            return lhs.status.sortPriority > rhs.status.sortPriority
        }
        return lhs.title < rhs.title
    }
}
