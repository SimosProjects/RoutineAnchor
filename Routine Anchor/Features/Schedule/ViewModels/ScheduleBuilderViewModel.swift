//
//  ScheduleBuilderViewModel.swift
//  Routine Anchor
//
//  Created by Christopher Simonson on 7/19/25.
//
import SwiftUI
import SwiftData

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
    func addTimeBlock(title: String, startTime: Date, endTime: Date, notes: String? = nil, category: String? = nil) {
        isLoading = true
        errorMessage = nil

        do {
            // Validate before constructing the TimeBlock
            let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedTitle.isEmpty else {
                throw ScheduleBuilderError.emptyTitle
            }
            
            // Validate time range
            guard endTime > startTime else {
                throw ScheduleBuilderError.invalidTimeRange
            }
            
            // Check for conflicts with existing blocks
            let hasConflict = timeBlocks.contains { existing in
                return timeBlocksOverlap(
                    start1: existing.startTime, end1: existing.endTime,
                    start2: startTime, end2: endTime
                )
            }
            
            if hasConflict {
                throw ScheduleBuilderError.conflictingTimeBlock
            }

            let block = TimeBlock(
                title: title,
                startTime: startTime,
                endTime: endTime,
                notes: notes,
                category: category
            )

            try dataManager.addTimeBlock(block)
            loadTimeBlocks()
            scheduleNotifications()
            
            NotificationCenter.default.post(
                name: .timeBlocksDidChange,
                object: nil,
                userInfo: ["action": "added", "date": block.scheduledDate]
            )

            // Success feedback
            HapticManager.shared.success()

        } catch let error as ScheduleBuilderError {
            errorMessage = error.localizedDescription
            print("Validation error: \(error)")
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
    func updateTimeBlock(_ block: TimeBlock) {
        isLoading = true
        errorMessage = nil
        
        do {
            // Validate title
            let trimmedTitle = block.title.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedTitle.isEmpty else {
                throw ScheduleBuilderError.emptyTitle
            }
            
            // Validate time range
            guard block.endTime > block.startTime else {
                throw ScheduleBuilderError.invalidTimeRange
            }
            
            // Check for conflicts (excluding self)
            let hasConflict = timeBlocks.contains { existing in
                return existing.id != block.id && timeBlocksOverlap(
                    start1: existing.startTime, end1: existing.endTime,
                    start2: block.startTime, end2: block.endTime
                )
            }
            
            if hasConflict {
                throw ScheduleBuilderError.conflictingTimeBlock
            }
            
            try dataManager.updateTimeBlock(block)
            loadTimeBlocks()
            scheduleNotifications()
            
            // Success feedback
            HapticManager.shared.success()
            
        } catch let error as ScheduleBuilderError {
            errorMessage = error.localizedDescription
            HapticManager.shared.error()
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
