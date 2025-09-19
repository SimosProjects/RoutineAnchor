//
//  ScheduleBuilderViewModel.swift
//  Routine Anchor
//
//  Created by Christopher Simonson on 7/19/25.
//
import SwiftUI
import SwiftData
import EventKit

enum ScheduleBuilderError: LocalizedError {
    case conflictingTimeBlock
    case invalidTimeRange
    case emptyTitle
    
    var errorDescription: String? {
        switch self {
        case .conflictingTimeBlock:
            return "This time slot conflicts with an existing block"
        case .invalidTimeRange:
            return "End time must be after start time"
        case .emptyTitle:
            return "Title cannot be empty"
        }
    }
}

@Observable
@MainActor
class ScheduleBuilderViewModel {
    // MARK: - Published Properties
    var timeBlocks: [TimeBlock] = []
    var isEditing = false
    var isLoading = false
    var errorMessage: String?
    
    // MARK: - Private Properties
    private let dataManager: DataManager
    private let notificationService = NotificationService.shared
    
    // MARK: - Initialization
    init(dataManager: DataManager) {
        self.dataManager = dataManager
        loadTimeBlocks()
    }
    
    // MARK: - Data Loading
    
    /// Load time blocks for today (or current editing date)
    func loadTimeBlocks() {
        isLoading = true
        errorMessage = nil
        
        do {
            // Load today's time blocks by default
            timeBlocks = try dataManager.loadTodaysTimeBlocks()
        } catch {
            errorMessage = "Failed to load time blocks: \(error.localizedDescription)"
            print("Error loading time blocks: \(error)")
        }
        
        isLoading = false
    }
    
    /// Reset today's progress back to not started
    @MainActor
    func resetTodaysProgress() {
        print("🔄 ===== RESET PROCESS STARTING =====")
        
        // Debug: Show current state before reset
        print("🔄 Current timeBlocks count: \(timeBlocks.count)")
        for block in timeBlocks {
            print("🔄 Block '\(block.title)' status: \(block.status.rawValue)")
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            print("🔄 Calling dataManager.resetTimeBlocksStatus(for: Date())")
            try dataManager.resetTimeBlocksStatus(for: Date())
            print("🔄 ✅ resetTimeBlocksStatus completed successfully")
            
            // Force a save to ensure persistence
            print("🔄 Forcing data save...")
            try dataManager.save()
            print("🔄 ✅ Data save completed")
            
            print("🔄 Reloading time blocks...")
            loadTimeBlocks()
            print("🔄 ✅ loadTimeBlocks completed")
            
            // Debug: Show state after reset
            print("🔄 After reset - timeBlocks count: \(timeBlocks.count)")
            for block in timeBlocks {
                print("🔄 Block '\(block.title)' status: \(block.status.rawValue)")
            }
            
            print("🔄 Scheduling notifications...")
            scheduleNotifications()
            print("🔄 ✅ Notifications scheduled")
            
            // Force refresh of TodayView by posting notification
            print("🔄 Posting refreshTodayView notification...")
            NotificationCenter.default.post(name: .refreshTodayView, object: nil)
            print("🔄 ✅ Notification posted")
            
            // Also post a general data change notification
            print("🔄 Posting timeBlocksDidChange notification...")
            NotificationCenter.default.post(
                name: .timeBlocksDidChange,
                object: nil,
                userInfo: ["action": "reset", "date": Date()]
            )
            print("🔄 ✅ timeBlocksDidChange notification posted")
            
            HapticManager.shared.success()
            print("🔄 ✅ SUCCESS: Reset completed successfully")
            
        } catch {
            print("🔄 ❌ ERROR: Reset failed with error: \(error)")
            print("🔄 ❌ Error details: \(error.localizedDescription)")
            errorMessage = "Failed to reset today's progress: \(error.localizedDescription)"
            HapticManager.shared.error()
        }
        
        isLoading = false
        print("🔄 ===== RESET PROCESS COMPLETED =====")
    }
    
    /// Load time blocks for a specific date
    @MainActor
    func loadTimeBlocks(for date: Date) {
        isLoading = true
        errorMessage = nil
        
        do {
            timeBlocks = try dataManager.loadTimeBlocks(for: date)
        } catch {
            errorMessage = "Failed to load time blocks: \(error.localizedDescription)"
            print("Error loading time blocks for date: \(error)")
        }
        
        isLoading = false
    }
    
    // MARK: - Time Block Management
    
    /// Add a new time block
    @MainActor
    func addTimeBlock(
        title: String,
        startTime: Date,
        endTime: Date,
        notes: String? = nil,
        category: String? = nil,
        icon: String? = nil,
        linkToCalendar: Bool = false,
        selectedCalendarId: String? = nil
    ) {

        isLoading = true
        errorMessage = nil

        do {
            // Validate
            let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedTitle.isEmpty else { throw ScheduleBuilderError.emptyTitle }
            guard endTime > startTime else { throw ScheduleBuilderError.invalidTimeRange }

            let hasConflict = timeBlocks.contains {
                timeBlocksOverlap(start1: $0.startTime, end1: $0.endTime, start2: startTime, end2: endTime)
            }
            if hasConflict { throw ScheduleBuilderError.conflictingTimeBlock }

            // 1) Optionally create EKEvent first (so we can persist linkage)
            var eventId: String? = nil
            var calId: String? = nil
            var lastMod: Date? = nil

            if linkToCalendar, let targetCalId = selectedCalendarId, hasEventAccess() {
                do {
                    let result = try createEKEvent(in: targetCalId, title: trimmedTitle, notes: notes, start: startTime, end: endTime)
                    eventId = result.eventId
                    calId   = targetCalId
                    lastMod = result.lastModified
                } catch {
                    print("EventKit create failed: \(error)")
                    // continue; we still save the local block
                }
            }

            // 2) Create & persist TimeBlock (with linkage if any)
            let block = TimeBlock(
                title: trimmedTitle,
                startTime: startTime,
                endTime: endTime,
                notes: notes,
                category: category
            )

            // ✅ Persist the icon (treat empty string as nil)
            if let icon, !icon.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                block.icon = icon
            } else {
                block.icon = nil
            }

            block.calendarEventId = eventId
            block.calendarId = calId
            block.calendarLastModified = lastMod

            try dataManager.addTimeBlock(block)

            // 3) Refresh UI/notifications
            loadTimeBlocks()
            scheduleNotifications()
            NotificationCenter.default.post(
                name: .timeBlocksDidChange,
                object: nil,
                userInfo: ["action": "added", "date": block.scheduledDate]
            )
            HapticManager.shared.success()

        } catch let e as ScheduleBuilderError {
            errorMessage = e.localizedDescription
            print("Validation error: \(e)")
        } catch {
            errorMessage = "Failed to save time block: \(error.localizedDescription)"
            print("Error adding time block: \(error)")
        }

        isLoading = false
    }

    
    private func timeBlocksOverlap(start1: Date, end1: Date, start2: Date, end2: Date) -> Bool {
        // Check if blocks are on the same day first
        let calendar = Calendar.current
        guard calendar.isDate(start1, inSameDayAs: start2) else { return false }
        
        // Check for overlap
        return start1 < end2 && start2 < end1
    }
    
    /// Update an existing time block
    @MainActor
    func updateTimeBlock(_ block: TimeBlock, linkToCalendar: Bool, selectedCalendarId: String?) {
        isLoading = true
        errorMessage = nil

        do {
            // Validate
            let trimmedTitle = block.title.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedTitle.isEmpty else { throw ScheduleBuilderError.emptyTitle }
            guard block.endTime > block.startTime else { throw ScheduleBuilderError.invalidTimeRange }

            let hasConflict = timeBlocks.contains {
                $0.id != block.id && timeBlocksOverlap(start1: $0.startTime, end1: $0.endTime,
                                                       start2: block.startTime, end2: block.endTime)
            }
            if hasConflict { throw ScheduleBuilderError.conflictingTimeBlock }

            // 1) Persist normal edits
            try dataManager.updateTimeBlock(block)

            // 2) Calendar sync based on intent
            if let eventId = block.calendarEventId {
                if linkToCalendar {
                    // Update existing event
                    if hasEventAccess() {
                        do {
                            let last = try updateEKEvent(eventId: eventId, title: trimmedTitle, notes: block.notes, start: block.startTime, end: block.endTime)
                            let updated = block
                            updated.calendarLastModified = last
                            try dataManager.updateTimeBlock(updated)
                        } catch {
                            print("EventKit update failed: \(error)")
                            errorMessage = "Updated, but couldn’t update Calendar."
                        }
                    }
                } else {
                    // Unlink → delete event then clear ids
                    do { try deleteEKEvent(eventId: eventId) } catch { print("EventKit delete failed: \(error)") }
                    let cleared = block
                    cleared.calendarEventId = nil
                    cleared.calendarId = nil
                    cleared.calendarLastModified = nil
                    try dataManager.updateTimeBlock(cleared)
                }
            } else if linkToCalendar, let calId = selectedCalendarId, hasEventAccess() {
                // Create new event for an unlinked block
                do {
                    let result = try createEKEvent(in: calId, title: trimmedTitle, notes: block.notes, start: block.startTime, end: block.endTime)
                    let linked = block
                    linked.calendarEventId = result.eventId
                    linked.calendarId = calId
                    linked.calendarLastModified = result.lastModified
                    try dataManager.updateTimeBlock(linked)
                } catch {
                    print("EventKit create (on edit) failed: \(error)")
                    errorMessage = "Saved, but couldn’t add to Calendar."
                }
            }

            // 3) Refresh UI/notifications
            loadTimeBlocks()
            scheduleNotifications()
            HapticManager.shared.success()

        } catch let e as ScheduleBuilderError {
            errorMessage = e.localizedDescription
            HapticManager.shared.error()
        } catch DataManagerError.conflictDetected(let message) {
            errorMessage = "Time conflict: \(message)"; HapticManager.shared.error()
        } catch DataManagerError.validationFailed(let message) {
            errorMessage = "Invalid time block: \(message)"; HapticManager.shared.error()
        } catch {
            errorMessage = "Failed to update time block: \(error.localizedDescription)"
            HapticManager.shared.error()
        }

        isLoading = false
    }

    
    /// Delete a time block
    @MainActor
    func deleteTimeBlock(_ block: TimeBlock) {
        isLoading = true
        errorMessage = nil
        do {
            if let eventId = block.calendarEventId {
                try? deleteEKEvent(eventId: eventId)
            }
            try dataManager.deleteTimeBlock(block)
            loadTimeBlocks()
            scheduleNotifications()
            HapticManager.shared.success()
        } catch {
            errorMessage = "Failed to delete time block: \(error.localizedDescription)"
            HapticManager.shared.error()
        }
        isLoading = false
    }
    
    /// Delete all time blocks for the current day
    @MainActor
    func deleteAllTimeBlocks() {
        isLoading = true
        errorMessage = nil
        
        do {
            try dataManager.deleteAllTimeBlocks(for: Date())
            loadTimeBlocks() // Refresh the list
            scheduleNotifications()
            
            // Success feedback
            HapticManager.shared.success()
            
        } catch {
            errorMessage = "Failed to delete all time blocks: \(error.localizedDescription)"
            HapticManager.shared.error()
        }
        
        isLoading = false
    }
    
    // MARK: - Routine Management
    
    /// Save the current routine and schedule notifications
    @MainActor
    func saveRoutine() {
        scheduleNotifications()
        
        // Mark editing as complete
        isEditing = false
        
        // Success feedback
        HapticManager.shared.success()
    }
    
    /// Copy today's routine to another date
    @MainActor
    func copyRoutineToDate(_ targetDate: Date) {
        isLoading = true
        errorMessage = nil
        
        do {
            try dataManager.copyTimeBlocks(from: Date(), to: targetDate)
            
            // Success feedback
            HapticManager.shared.success()
            
        } catch {
            errorMessage = "Failed to copy routine: \(error.localizedDescription)"
            HapticManager.shared.error()
        }
        
        isLoading = false
    }
    
    /// Reset all time blocks status (back to not started)
    @MainActor
    func resetRoutineStatus() {
        isLoading = true
        errorMessage = nil
        
        do {
            try dataManager.resetTimeBlocksStatus(for: Date())
            loadTimeBlocks() // Refresh the list
            
            // Success feedback
            HapticManager.shared.success()
            
        } catch {
            errorMessage = "Failed to reset routine: \(error.localizedDescription)"
            HapticManager.shared.error()
        }
        
        isLoading = false
    }
    
    // MARK: - Validation
    
    /// Check if a new time block would conflict with existing ones
    func wouldConflict(startTime: Date, endTime: Date, excluding excludedBlock: TimeBlock? = nil) -> Bool {
        let testBlock = TimeBlock(title: "Test", startTime: startTime, endTime: endTime)
        
        let blocksToCheck = excludedBlock != nil
            ? timeBlocks.filter { $0.id != excludedBlock!.id }
            : timeBlocks
        
        return !testBlock.conflictsWith(blocksToCheck).isEmpty
    }
    
    /// Get conflicting time blocks for a given time range
    func getConflictingBlocks(startTime: Date, endTime: Date, excluding excludedBlock: TimeBlock? = nil) -> [TimeBlock] {
        let testBlock = TimeBlock(title: "Test", startTime: startTime, endTime: endTime)
        
        let blocksToCheck = excludedBlock != nil
            ? timeBlocks.filter { $0.id != excludedBlock!.id }
            : timeBlocks
        
        return testBlock.conflictsWith(blocksToCheck)
    }
    
    /// Validate time block data before saving
    func validateTimeBlock(title: String, startTime: Date, endTime: Date) -> [String] {
        var errors: [String] = []
        
        if title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.append(ScheduleBuilderError.emptyTitle.localizedDescription)
        }
        
        if startTime >= endTime {
            errors.append(ScheduleBuilderError.invalidTimeRange.localizedDescription)
        }
        
        let durationMinutes = Int(endTime.timeIntervalSince(startTime) / 60)
        if durationMinutes < 1 {
            errors.append("Duration must be at least 1 minute")
        }
        
        if durationMinutes > 24 * 60 {
            errors.append("Duration cannot exceed 24 hours")
        }
        
        if wouldConflict(startTime: startTime, endTime: endTime) {
            errors.append(ScheduleBuilderError.conflictingTimeBlock.localizedDescription)
        }
        
        return errors
    }
    
    // MARK: - EventKit Helpers
    private let ekStore = EKEventStore()

    private func hasEventAccess() -> Bool {
        switch EKEventStore.authorizationStatus(for: .event) {
        case .fullAccess, .writeOnly: return true
        case .authorized: return true
        default: return false
        }
    }

    private func createEKEvent(in calendarId: String, title: String, notes: String?, start: Date, end: Date) throws -> (eventId: String, lastModified: Date?) {
        guard let cal = ekStore.calendar(withIdentifier: calendarId) else {
            throw NSError(domain: "Calendar", code: 404, userInfo: [NSLocalizedDescriptionKey: "Calendar not found"])
        }
        let ev = EKEvent(eventStore: ekStore)
        ev.calendar = cal
        ev.title    = title
        ev.notes    = notes
        ev.startDate = start
        ev.endDate   = end
        try ekStore.save(ev, span: .thisEvent, commit: true)
        return (ev.eventIdentifier, ev.lastModifiedDate)
    }

    private func updateEKEvent(eventId: String, title: String, notes: String?, start: Date, end: Date) throws -> Date? {
        guard let ev = ekStore.event(withIdentifier: eventId) else {
            throw NSError(domain: "Calendar", code: 404, userInfo: [NSLocalizedDescriptionKey: "Event not found"])
        }
        ev.title     = title
        ev.notes     = notes
        ev.startDate = start
        ev.endDate   = end
        try ekStore.save(ev, span: .thisEvent, commit: true)
        return ev.lastModifiedDate
    }

    private func deleteEKEvent(eventId: String) throws {
        guard let ev = ekStore.event(withIdentifier: eventId) else { return }
        try ekStore.remove(ev, span: .thisEvent, commit: true)
    }
    
    // MARK: - Computed Properties
    
    /// Total duration of all time blocks in minutes
    var totalDurationMinutes: Int {
        return timeBlocks.reduce(0) { $0 + $1.durationMinutes }
    }
    
    /// Formatted total duration
    var formattedTotalDuration: String {
        let hours = totalDurationMinutes / 60
        let minutes = totalDurationMinutes % 60
        
        if hours > 0 && minutes > 0 {
            return "\(hours)h \(minutes)m"
        } else if hours > 0 {
            return "\(hours)h"
        } else {
            return "\(minutes)m"
        }
    }
    
    /// Whether the routine has any time blocks
    var hasTimeBlocks: Bool {
        return !timeBlocks.isEmpty
    }
    
    /// Sorted time blocks by start time
    var sortedTimeBlocks: [TimeBlock] {
        return timeBlocks.sorted { $0.startTime < $1.startTime }
    }
    
    // MARK: - Notifications
    
    /// Schedule notifications for all time blocks
    private func scheduleNotifications() {
        Task {
            await notificationService.scheduleTimeBlockNotifications(for: timeBlocks)
        }
    }
    
    // MARK: - Error Handling
    
    /// Clear any error messages
    func clearError() {
        errorMessage = nil
        dataManager.clearError()
    }
    
    /// Retry the last failed operation
    func retryLastOperation() {
        clearError()
        loadTimeBlocks()
    }
}

// MARK: - Convenience Methods
extension ScheduleBuilderViewModel {

    private func createTimeBlockForTemplate(
        title: String,
        hour: Int,
        minute: Int = 0,
        duration: Int,
        notes: String? = nil,
        category: String? = nil
    ) {
        let calendar = Calendar.current
        let now = Date()
        var targetDate = now
        
        // If it's already past the specified time, schedule for tomorrow
        if let todayTime = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: now),
           now > todayTime {
            targetDate = calendar.date(byAdding: .day, value: 1, to: now) ?? now
        }
        
        guard let startTime = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: targetDate),
              let endTime = calendar.date(byAdding: .minute, value: duration, to: startTime) else {
            return
        }
        
        addTimeBlock(
            title: title,
            startTime: startTime,
            endTime: endTime,
            notes: notes,
            category: category
        )
    }
    
    // MARK: - Quick Templates
    @MainActor
    func addMorningRoutine() {
        createTimeBlockForTemplate(
            title: "Morning Routine",
            hour: 7,
            duration: 60,
            notes: "Exercise, shower, breakfast",
            category: "Personal"
        )
    }

    @MainActor
    func addWorkBlock() {
        createTimeBlockForTemplate(
            title: "Deep Work Session",
            hour: 9,
            duration: 180,
            notes: "Focus time - no distractions",
            category: "Work"
        )
    }

    @MainActor
    func addBreak() {
        createTimeBlockForTemplate(
            title: "Lunch Break",
            hour: 12,
            duration: 60,
            notes: "Rest and recharge",
            category: "Personal"
        )
    }
}
