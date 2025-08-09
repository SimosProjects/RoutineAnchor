//
//  ScheduleBuilderViewModel.swift
//  Routine Anchor
//
//  Created by Christopher Simonson on 7/19/25.
//
import SwiftUI
import SwiftData

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
    
    /// Load time blocks for a specific date
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
    func addTimeBlock(title: String, startTime: Date, endTime: Date, notes: String? = nil, category: String? = nil) {
        isLoading = true
        errorMessage = nil

        do {
            // Validate before constructing the TimeBlock
            guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                throw DataManagerError.validationFailed("Title cannot be empty.")
            }

            let block = TimeBlock(
                title: title,
                startTime: startTime,
                endTime: endTime,
                notes: notes,
                category: category
            )

            try dataManager.addTimeBlock(block)
            loadTimeBlocks() // Refresh the list
            scheduleNotifications()

            // Success feedback
            HapticManager.shared.success()

        } catch DataManagerError.conflictDetected(let message) {
            errorMessage = "Time conflict: \(message)"
            HapticManager.shared.error()
        } catch DataManagerError.validationFailed(let message) {
            errorMessage = "Invalid time block: \(message)"
            HapticManager.shared.error()
        } catch {
            errorMessage = "Failed to add time block: \(error.localizedDescription)"
            HapticManager.shared.error()
        }

        isLoading = false
    }

    
    /// Update an existing time block
    @MainActor
    func updateTimeBlock(_ block: TimeBlock) {
        isLoading = true
        errorMessage = nil
        
        do {
            try dataManager.updateTimeBlock(block)
            loadTimeBlocks() // Refresh the list
            scheduleNotifications()
            
            // Success feedback
            HapticManager.shared.success()
            
        } catch DataManagerError.conflictDetected(let message) {
            errorMessage = "Time conflict: \(message)"
            HapticManager.shared.error()
        } catch DataManagerError.validationFailed(let message) {
            errorMessage = "Invalid time block: \(message)"
            HapticManager.shared.error()
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
            try dataManager.deleteTimeBlock(block)
            loadTimeBlocks() // Refresh the list
            scheduleNotifications()
            
            // Success feedback
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
            errors.append("Title cannot be empty")
        }
        
        if startTime >= endTime {
            errors.append("Start time must be before end time")
        }
        
        let durationMinutes = Int(endTime.timeIntervalSince(startTime) / 60)
        if durationMinutes < 1 {
            errors.append("Duration must be at least 1 minute")
        }
        
        if durationMinutes > 24 * 60 {
            errors.append("Duration cannot exceed 24 hours")
        }
        
        if wouldConflict(startTime: startTime, endTime: endTime) {
            errors.append("Time conflicts with existing blocks")
        }
        
        return errors
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
    /// Quick add methods for common time blocks
    
    // MARK: - Quick Templates
    @MainActor
    func addMorningRoutine() {
        let calendar = Calendar.current
        let now = Date()
        var targetDate = now
        
        // If it's already past 8 AM, schedule for tomorrow
        if let todayMorning = calendar.date(bySettingHour: 8, minute: 0, second: 0, of: now),
           now > todayMorning {
            targetDate = calendar.date(byAdding: .day, value: 1, to: now) ?? now
        }
        
        guard let startTime = calendar.date(bySettingHour: 7, minute: 0, second: 0, of: targetDate),
              let endTime = calendar.date(bySettingHour: 8, minute: 0, second: 0, of: targetDate) else {
            return
        }
        
        addTimeBlock(
            title: "Morning Routine",
            startTime: startTime,
            endTime: endTime,
            notes: "Exercise, shower, breakfast",
            category: "Personal"
        )
    }

    @MainActor
    func addWorkBlock() {
        let calendar = Calendar.current
        let now = Date()
        var targetDate = now
        
        // If it's already past 12 PM, schedule for tomorrow
        if let todayNoon = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: now),
           now > todayNoon {
            targetDate = calendar.date(byAdding: .day, value: 1, to: now) ?? now
        }
        
        guard let startTime = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: targetDate),
              let endTime = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: targetDate) else {
            return
        }
        
        addTimeBlock(
            title: "Deep Work Session",
            startTime: startTime,
            endTime: endTime,
            notes: "Focus time - no distractions",
            category: "Work"
        )
    }

    @MainActor
    func addBreak() {
        let calendar = Calendar.current
        let now = Date()
        var targetDate = now
        
        // If it's already past 1 PM, schedule for tomorrow
        if let todayLunch = calendar.date(bySettingHour: 13, minute: 0, second: 0, of: now),
           now > todayLunch {
            targetDate = calendar.date(byAdding: .day, value: 1, to: now) ?? now
        }
        
        guard let startTime = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: targetDate),
              let endTime = calendar.date(bySettingHour: 13, minute: 0, second: 0, of: targetDate) else {
            return
        }
        
        addTimeBlock(
            title: "Lunch Break",
            startTime: startTime,
            endTime: endTime,
            notes: "Rest and recharge",
            category: "Personal"
        )
    }
}
