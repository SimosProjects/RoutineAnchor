//
//  TimeBlockFormData.swift
//  Routine Anchor
//
//  Observable form model for Add/Edit time block sheets.
//  - Holds editable fields
//  - Validates inputs (title, time ordering, duration limits, conflicts)
//  - Detects changes in edit mode
//  - Provides helpers for quick durations & next available slot
//

import SwiftUI
import Observation

@Observable
@MainActor
final class TimeBlockFormData {
    // MARK: - Form Fields (observable)
    var title = ""
    var startTime = Date()
    var endTime = Date()
    var notes = ""
    var category = ""
    var selectedIcon = ""

    // MARK: - Derived Form State
    var validationErrors: [String] = []
    var isFormValid = false
    var hasChanges = false

    // MARK: - Context for conflict detection
    var excludedTimeBlockId: UUID? = nil
    var existingTimeBlocks: [TimeBlock] = []

    // MARK: - Display options
    let categories = ["Work", "Personal", "Health", "Learning", "Social", "Other"]
    let icons = ["💼", "🏠", "💪", "📚", "👥", "🎯", "☕", "🍽️", "🧘", "🎵", "📱", "🚗"]

    // MARK: - Snapshot of original values (used in edit flow)
    private var originalTitle = ""
    private var originalStartTime = Date()
    private var originalEndTime = Date()
    private var originalNotes = ""
    private var originalCategory = ""
    private var originalIcon = ""

    // MARK: - Init

    init() {
        setupDefaultTimes()
    }

    init(from timeBlock: TimeBlock) {
        title = timeBlock.title
        startTime = timeBlock.startTime
        endTime = timeBlock.endTime
        notes = timeBlock.notes ?? ""
        category = timeBlock.category ?? ""
        selectedIcon = timeBlock.icon ?? ""

        originalTitle = timeBlock.title
        originalStartTime = timeBlock.startTime
        originalEndTime = timeBlock.endTime
        originalNotes = timeBlock.notes ?? ""
        originalCategory = timeBlock.category ?? ""
        originalIcon = timeBlock.icon ?? ""
    }

    // MARK: - Defaults

    /// Aligns to the start of the next hour with a 1-hour duration.
    private func setupDefaultTimes() {
        let calendar = Calendar.current
        let now = Date()
        let nextHour = calendar.date(byAdding: .hour, value: 1, to: now) ?? now
        startTime = calendar.dateInterval(of: .hour, for: nextHour)?.start ?? nextHour
        endTime = calendar.date(byAdding: .hour, value: 1, to: startTime) ?? startTime
    }

    // MARK: - Validation

    func validateForm() {
        validationErrors.removeAll()

        // Title
        if sanitizeString(title).isEmpty {
            validationErrors.append("Title is required")
        }

        let calendar = Calendar.current

        // Same-day check and ordering
        if !calendar.isDate(startTime, inSameDayAs: endTime) {
            validationErrors.append("Time blocks cannot span multiple days")
        } else if endTime <= startTime {
            validationErrors.append("End time must be after start time")
        }

        // Duration limits
        let minutes = endTime.timeIntervalSince(startTime) / 60
        if minutes > 0 && minutes < 5 {
            validationErrors.append("Time block must be at least 5 minutes long")
        }
        if minutes > 1440 {
            validationErrors.append("Time block cannot be longer than 24 hours")
        }

        // Conflict detection
        validateConflicts()

        isFormValid = validationErrors.isEmpty
    }

    /// Appends a conflict message if overlaps with existing blocks (excluding edited block).
    private func validateConflicts() {
        let conflicts = getConflictingBlocks()
        guard !conflicts.isEmpty else { return }

        if conflicts.count == 1, let conflictingBlock = conflicts.first {
            let f = DateFormatter()
            f.dateFormat = "h:mm a"
            let conflictTime = "\(f.string(from: conflictingBlock.startTime)) - \(f.string(from: conflictingBlock.endTime))"
            validationErrors.append("This time overlaps with '\(conflictingBlock.title)' (\(conflictTime))")
        } else {
            validationErrors.append("This time overlaps with \(conflicts.count) existing time blocks")
        }
    }

    // MARK: - Change Tracking (edit mode)

    func checkForChanges() {
        // Normalize to minute precision for sensible comparisons
        let cal = Calendar.current
        let normStart = cal.dateInterval(of: .minute, for: startTime)?.start ?? startTime
        let normEnd = cal.dateInterval(of: .minute, for: endTime)?.start ?? endTime
        let normOriginalStart = cal.dateInterval(of: .minute, for: originalStartTime)?.start ?? originalStartTime
        let normOriginalEnd = cal.dateInterval(of: .minute, for: originalEndTime)?.start ?? originalEndTime

        hasChanges = (
            sanitizeString(title) != sanitizeString(originalTitle) ||
            normStart != normOriginalStart ||
            normEnd != normOriginalEnd ||
            sanitizeString(notes) != sanitizeString(originalNotes) ||
            sanitizeString(category) != sanitizeString(originalCategory) ||
            selectedIcon != originalIcon
        )
    }

    // MARK: - Duration helpers

    /// Adjusts the end time to be exactly `minutes` after `startTime`.
    func setDuration(minutes: Int) {
        endTime = Calendar.current.date(byAdding: .minute, value: minutes, to: startTime) ?? startTime
    }

    // MARK: - Data prep

    /// Returns sanitized values ready for persistence.
    func prepareForSave() -> (title: String, notes: String?, category: String?) {
        let t = sanitizeString(title)
        let n = sanitizeString(notes)
        let c = sanitizeString(category)
        return (title: t, notes: n.isEmpty ? nil : n, category: c.isEmpty ? nil : c)
    }

    // MARK: - Conflict APIs

    /// Provide the full set of blocks to check (optionally excluding the block being edited).
    func setExistingTimeBlocks(_ blocks: [TimeBlock], excluding excludedId: UUID? = nil) {
        existingTimeBlocks = blocks
        excludedTimeBlockId = excludedId
        validateForm()
    }

    /// Returns the blocks that overlap with the current [startTime, endTime].
    func getConflictingBlocks() -> [TimeBlock] {
        let candidate = TimeBlock(title: "Candidate", startTime: startTime, endTime: endTime)
        let blocksToCheck = existingTimeBlocks.filter { block in
            if let excludedId = excludedTimeBlockId { return block.id != excludedId }
            return true
        }
        return candidate.conflictsWith(blocksToCheck)
    }

    // MARK: - Next Available Slot (quality-of-life)

    /// Finds the next non-conflicting slot of `duration` (default: 1h) starting from the next hour.
    func findNextAvailableTimeSlot(duration: TimeInterval = 3600) -> (start: Date, end: Date)? {
        let cal = Calendar.current
        let now = Date()
        let startOfNextHour = cal.dateInterval(of: .hour, for: now)?.end ?? now
        var candidateStart = startOfNextHour

        for _ in 0..<24 {
            let candidateEnd = candidateStart.addingTimeInterval(duration)
            let probe = TimeBlock(title: "Probe", startTime: candidateStart, endTime: candidateEnd)
            if probe.conflictsWith(existingTimeBlocks.filter { block in
                if let excludedId = excludedTimeBlockId { return block.id != excludedId }
                return true
            }).isEmpty {
                return (candidateStart, candidateEnd)
            }
            candidateStart = cal.date(byAdding: .hour, value: 1, to: candidateStart) ?? candidateStart
        }
        return nil
    }

    /// Sets the form times to the next available 1h slot and revalidates.
    func setToNextAvailableSlot() {
        if let next = findNextAvailableTimeSlot() {
            startTime = next.start
            endTime = next.end
            validateForm()
        }
    }

    // MARK: - Utils

    private func sanitizeString(_ input: String) -> String {
        input
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
    }
}
