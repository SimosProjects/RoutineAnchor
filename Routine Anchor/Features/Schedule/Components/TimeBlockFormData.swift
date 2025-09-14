//
//  TimeBlockFormData.swift
//  Routine Anchor
//
//  Created by Christopher Simonson on 7/23/25.
//  Updated for Swift 6 Compatibility
//
import SwiftUI
import Observation

@Observable
@MainActor
final class TimeBlockFormData {
    // MARK: - Observable Properties
    var title = ""
    var startTime = Date()
    var endTime = Date()
    var notes = ""
    var category = ""
    var selectedIcon = ""
    var validationErrors: [String] = []
    var isFormValid = false
    var hasChanges = false
    var excludedTimeBlockId: UUID? = nil
    var existingTimeBlocks: [TimeBlock] = []
    var linkToCalendar: Bool = false
    var selectedCalendarId: String? = nil
    
    // MARK: - Constants
    let categories = ["Work", "Personal", "Health", "Learning", "Social", "Other"]
    let icons = ["💼", "🏠", "💪", "📚", "👥", "🎯", "☕", "🍽️", "🧘", "🎵", "📱", "🚗"]
    
    // MARK: - Private Properties (for comparison in edit mode)
    private var originalTitle = ""
    private var originalStartTime = Date()
    private var originalEndTime = Date()
    private var originalNotes = ""
    private var originalCategory = ""
    private var originalIcon = ""
    private var originalLinkToCalendar: Bool = false
    private var originalSelectedCalendarId: String? = nil
    
    // MARK: - Initialization
    init() {
        setupDefaultTimes()
    }
    
    init(from timeBlock: TimeBlock) {
        self.title = timeBlock.title
        self.startTime = timeBlock.startTime
        self.endTime = timeBlock.endTime
        self.notes = timeBlock.notes ?? ""
        self.category = timeBlock.category ?? ""
        self.selectedIcon = timeBlock.icon ?? ""
        self.linkToCalendar = (timeBlock.calendarEventId != nil)
        self.selectedCalendarId = timeBlock.calendarId
        
        self.originalTitle = timeBlock.title
        self.originalStartTime = timeBlock.startTime
        self.originalEndTime = timeBlock.endTime
        self.originalNotes = timeBlock.notes ?? ""
        self.originalCategory = timeBlock.category ?? ""
        self.originalIcon = timeBlock.icon ?? ""
        self.originalLinkToCalendar = self.linkToCalendar
        self.originalSelectedCalendarId = self.selectedCalendarId
    }
    
    // MARK: - Setup Methods
    private func setupDefaultTimes() {
        let calendar = Calendar.current
        let now = Date()
        let nextHour = calendar.date(byAdding: .hour, value: 1, to: now) ?? now
        
        self.startTime = calendar.dateInterval(of: .hour, for: nextHour)?.start ?? nextHour
        self.endTime = calendar.date(byAdding: .hour, value: 1, to: startTime) ?? startTime
    }
    
    // MARK: - Validation Methods
    func validateForm() {
        validationErrors.removeAll()
        
        // Title validation
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedTitle.isEmpty {
            validationErrors.append("Title is required")
        }
        
        // Get calendar with current timezone
        let calendar = Calendar.current
        
        // Check if spans multiple days
        if !calendar.isDate(startTime, inSameDayAs: endTime) {
            validationErrors.append("Time blocks cannot span multiple days")
        } else if endTime <= startTime {
            validationErrors.append("End time must be after start time")
        }
        
        // Duration validation (minimum 5 minutes)
        let duration = endTime.timeIntervalSince(startTime) / 60
        if duration > 0 && duration < 5 {
            validationErrors.append("Time block must be at least 5 minutes long")
        }
        
        // Duration validation (maximum 24 hours)
        if duration > 1440 {
            validationErrors.append("Time block cannot be longer than 24 hours")
        }
        
        // Conflict validation
        validateConflicts()
        
        isFormValid = validationErrors.isEmpty
    }
    
    /// Check for time conflicts with existing blocks
    private func validateConflicts() {
        let testBlock = TimeBlock(
            title: "Test",
            startTime: startTime,
            endTime: endTime
        )
        
        // Filter out the block being edited (if any)
        let blocksToCheck = existingTimeBlocks.filter { block in
            if let excludedId = excludedTimeBlockId {
                return block.id != excludedId
            }
            return true
        }
        
        // Find conflicts
        let conflicts = testBlock.conflictsWith(blocksToCheck)
        
        if !conflicts.isEmpty {
            if conflicts.count == 1 {
                let conflictingBlock = conflicts.first!
                let formatter = DateFormatter()
                formatter.dateFormat = "h:mm a"
                let conflictTime = "\(formatter.string(from: conflictingBlock.startTime)) - \(formatter.string(from: conflictingBlock.endTime))"
                
                validationErrors.append("This time overlaps with '\(conflictingBlock.title)' (\(conflictTime))")
            } else {
                validationErrors.append("This time overlaps with \(conflicts.count) existing time blocks")
            }
        }
    }
    
    // MARK: - Change Detection Methods
    func checkForChanges() {
        // Normalize dates for comparison (ignore seconds/subseconds)
        let calendar = Calendar.current
        let normalizedStartTime = calendar.dateInterval(of: .minute, for: startTime)?.start ?? startTime
        let normalizedEndTime = calendar.dateInterval(of: .minute, for: endTime)?.start ?? endTime
        let normalizedOriginalStart = calendar.dateInterval(of: .minute, for: originalStartTime)?.start ?? originalStartTime
        let normalizedOriginalEnd = calendar.dateInterval(of: .minute, for: originalEndTime)?.start ?? originalEndTime
        
        hasChanges = (
            sanitizeString(title) != sanitizeString(originalTitle) ||
            normalizedStartTime != normalizedOriginalStart ||
            normalizedEndTime != normalizedOriginalEnd ||
            sanitizeString(notes) != sanitizeString(originalNotes) ||
            sanitizeString(category) != sanitizeString(originalCategory) ||
            selectedIcon != originalIcon ||
            linkToCalendar != originalLinkToCalendar ||
            selectedCalendarId != originalSelectedCalendarId
        )
    }
    
    // MARK: - Duration Methods
    func setDuration(minutes: Int) {
        endTime = Calendar.current.date(byAdding: .minute, value: minutes, to: startTime) ?? startTime
    }
    
    private func sanitizeString(_ input: String) -> String {
        return input
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
    }
    
    // MARK: - Data Preparation Methods
    func prepareForSave() -> (title: String, notes: String?, category: String?) {
        let sanitizedTitle = sanitizeString(title)
        let sanitizedNotes = sanitizeString(notes)
        let sanitizedCategory = sanitizeString(category)
        
        return (
            title: sanitizedTitle,
            notes: sanitizedNotes.isEmpty ? nil : sanitizedNotes,
            category: sanitizedCategory.isEmpty ? nil : sanitizedCategory
        )
    }
    
    func setExistingTimeBlocks(_ blocks: [TimeBlock], excluding excludedId: UUID? = nil) {
        self.existingTimeBlocks = blocks
        self.excludedTimeBlockId = excludedId
        validateForm() // Re-validate when blocks change
    }
    
    func getConflictingBlocks() -> [TimeBlock] {
        let testBlock = TimeBlock(
            title: "Test",
            startTime: startTime,
            endTime: endTime
        )
        
        let blocksToCheck = existingTimeBlocks.filter { block in
            if let excludedId = excludedTimeBlockId {
                return block.id != excludedId
            }
            return true
        }
        
        return testBlock.conflictsWith(blocksToCheck)
    }
}
