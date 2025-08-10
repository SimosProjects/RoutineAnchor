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
        
        self.originalTitle = timeBlock.title
        self.originalStartTime = timeBlock.startTime
        self.originalEndTime = timeBlock.endTime
        self.originalNotes = timeBlock.notes ?? ""
        self.originalCategory = timeBlock.category ?? ""
        self.originalIcon = timeBlock.icon ?? ""
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
        
        // Time validation with timezone awareness
        let startComponents = calendar.dateComponents(in: calendar.timeZone, from: startTime)
        let endComponents = calendar.dateComponents(in: calendar.timeZone, from: endTime)
        
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
        
        isFormValid = validationErrors.isEmpty
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
            selectedIcon != originalIcon
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
}
