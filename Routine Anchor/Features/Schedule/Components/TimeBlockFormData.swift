//
//  TimeBlockFormData.swift
//  Routine Anchor
//
//  Created by Christopher Simonson on 7/23/25.
//
import SwiftUI

class TimeBlockFormData: ObservableObject {
    @Published var title = ""
    @Published var startTime = Date()
    @Published var endTime = Date()
    @Published var notes = ""
    @Published var category = ""
    @Published var selectedIcon = ""
    @Published var validationErrors: [String] = []
    @Published var isFormValid = false
    @Published var hasChanges = false

    // Constants
    let categories = ["Work", "Personal", "Health", "Learning", "Social", "Other"]
    let icons = ["💼", "🏠", "💪", "📚", "👥", "🎯", "☕", "🍽️", "🧘", "🎵", "📱", "🚗"]

    // Original data for comparison (used in edit mode)
    private var originalTitle = ""
    private var originalStartTime = Date()
    private var originalEndTime = Date()
    private var originalNotes = ""
    private var originalCategory = ""
    private var originalIcon = ""

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

    private func setupDefaultTimes() {
        let calendar = Calendar.current
        let now = Date()
        let nextHour = calendar.date(byAdding: .hour, value: 1, to: now) ?? now

        self.startTime = calendar.dateInterval(of: .hour, for: nextHour)?.start ?? nextHour
        self.endTime = calendar.date(byAdding: .hour, value: 1, to: nextHour) ?? nextHour
    }

    func validateForm() {
        validationErrors.removeAll()

        if title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            validationErrors.append("Title is required")
        } else if title.count < 3 {
            validationErrors.append("Title must be at least 3 characters")
        }

        if startTime >= endTime {
            validationErrors.append("End time must be after start time")
        }

        let duration = durationMinutes
        if duration < 1 {
            validationErrors.append("Duration must be at least 1 minute")
        }

        if duration > 24 * 60 {
            validationErrors.append("Duration cannot exceed 24 hours")
        }

        isFormValid = validationErrors.isEmpty
    }

    func checkForChanges() {
        hasChanges = title != originalTitle ||
                     startTime != originalStartTime ||
                     endTime != originalEndTime ||
                     notes != originalNotes ||
                     category != originalCategory ||
                     selectedIcon != originalIcon
    }

    func setDuration(minutes: Int) {
        endTime = Calendar.current.date(byAdding: .minute, value: minutes, to: startTime) ?? endTime
        validateForm()
    }

    var durationMinutes: Int {
        max(0, Int(endTime.timeIntervalSince(startTime) / 60))
    }

    var durationColor: Color {
        switch durationMinutes {
        case 0:
            return Color.premiumError
        case 1...30:
            return Color.premiumWarning
        case 31...120:
            return Color.premiumGreen
        case 121...240:
            return Color.premiumBlue
        default:
            return Color.premiumWarning
        }
    }

    func prepareForSave() -> (title: String, notes: String?, category: String?) {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalNotes = trimmedNotes.isEmpty ? nil : trimmedNotes
        let finalCategory = category.isEmpty ? nil : category

        return (trimmedTitle, finalNotes, finalCategory)
    }
}

