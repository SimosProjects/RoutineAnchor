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
        if title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            validationErrors.append("Title is required")
        }
        
        // Time validation
        if endTime <= startTime {
            validationErrors.append("End time must be after start time")
        }
        
        // Duration validation (minimum 5 minutes)
        let duration = endTime.timeIntervalSince(startTime) / 60
        if duration < 5 {
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
        hasChanges = (title != originalTitle ||
                     startTime != originalStartTime ||
                     endTime != originalEndTime ||
                     notes != originalNotes ||
                     category != originalCategory ||
                     selectedIcon != originalIcon)
    }
    
    // MARK: - Duration Methods
    func setDuration(minutes: Int) {
        endTime = Calendar.current.date(byAdding: .minute, value: minutes, to: startTime) ?? startTime
    }
    
    // MARK: - Data Preparation Methods
    func prepareForSave() -> (title: String, notes: String?, category: String?) {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedCategory = category.trimmingCharacters(in: .whitespacesAndNewlines)
        
        return (
            title: trimmedTitle,
            notes: trimmedNotes.isEmpty ? nil : trimmedNotes,
            category: trimmedCategory.isEmpty ? nil : trimmedCategory
        )
    }
}
