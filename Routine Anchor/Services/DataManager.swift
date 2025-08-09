//
//  DataManager.swift
//  Routine Anchor
//
//  Created by Christopher Simonson on 7/19/25.
//
import Foundation
import SwiftData
import SwiftUI

/// Core data management service for handling all SwiftData operations
@Observable
class DataManager {
    // MARK: - Properties
    
    let modelContext: ModelContext
    
    // MARK: - Published Properties for SwiftUI
    
    /// Current error state for UI display
    var lastError: DataManagerError?
    
    /// Loading state for UI feedback
    var isLoading: Bool = false
    
    // MARK: - Initialization
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - TimeBlock Operations
    
    /// Load all time blocks from the database
    func loadAllTimeBlocks() throws -> [TimeBlock] {
        let descriptor = FetchDescriptor<TimeBlock>(
            sortBy: [SortDescriptor(\.startTime, order: .forward)]
        )
        
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            throw DataManagerError.fetchFailed("Failed to load time blocks: \(error.localizedDescription)")
        }
    }
    
    /// Load time blocks for a specific date
    func loadTimeBlocks(for date: Date) throws -> [TimeBlock] {
        let calendar = Calendar(identifier: .gregorian) // avoids pulling from environment
        let startOfDay = calendar.startOfDay(for: date)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            throw DataManagerError.fetchFailed("Invalid date range")
        }

        // Precompute times to avoid capturing non-Sendable context
        let start = startOfDay
        let end = endOfDay

        let predicate = #Predicate<TimeBlock> { block in
            block.startTime >= start && block.startTime < end
        }

        let descriptor = FetchDescriptor<TimeBlock>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.startTime, order: .forward)]
        )

        do {
            return try modelContext.fetch(descriptor)
        } catch {
            throw DataManagerError.fetchFailed("Failed to load time blocks for date: \(error.localizedDescription)")
        }
    }

    /// Load today's time blocks
    func loadTodaysTimeBlocks() throws -> [TimeBlock] {
        return try loadTimeBlocks(for: Date())
    }
    
    /// Load time blocks for a date range
    func loadTimeBlocks(from startDate: Date, to endDate: Date) throws -> [TimeBlock] {
        let predicate = #Predicate<TimeBlock> { block in
            block.startTime >= startDate && block.startTime <= endDate
        }
        
        let descriptor = FetchDescriptor<TimeBlock>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.startTime, order: .forward)]
        )
        
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            throw DataManagerError.fetchFailed("Failed to load time blocks for range: \(error.localizedDescription)")
        }
    }
    
    /// Load time blocks by status
    func loadTimeBlocks(withStatus status: BlockStatus) throws -> [TimeBlock] {
        let statusValue = status.rawValue
        let predicate = #Predicate<TimeBlock> { block in
            block.statusValue == statusValue
        }
        
        let descriptor = FetchDescriptor<TimeBlock>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.startTime, order: .forward)]
        )
        
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            throw DataManagerError.fetchFailed("Failed to load time blocks with status: \(error.localizedDescription)")
        }
    }
    
    /// Load time blocks by category
    func loadTimeBlocks(withCategory category: String) throws -> [TimeBlock] {
        let categoryValue = category
        let predicate = #Predicate<TimeBlock> { block in
            block.category == categoryValue
        }
        
        let descriptor = FetchDescriptor<TimeBlock>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.startTime, order: .forward)]
        )
        
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            throw DataManagerError.fetchFailed("Failed to load time blocks for category: \(error.localizedDescription)")
        }
    }
    
    /// Add a new time block
    @discardableResult
    func addTimeBlock(_ timeBlock: TimeBlock) throws -> TimeBlock {
        // Validate the time block
        guard timeBlock.isValid else {
            throw DataManagerError.validationFailed("Time block validation failed: \(timeBlock.validationErrors.joined(separator: ", "))")
        }
        
        // Check for conflicts
        let existingBlocks = try loadTimeBlocks(for: timeBlock.scheduledDate)
        let conflicts = timeBlock.conflictsWith(existingBlocks)
        
        if !conflicts.isEmpty {
            throw DataManagerError.conflictDetected("Time block conflicts with existing blocks: \(conflicts.map { $0.title }.joined(separator: ", "))")
        }
        
        do {
            modelContext.insert(timeBlock)
            try save()
            return timeBlock
        } catch {
            throw DataManagerError.saveFailed("Failed to add time block: \(error.localizedDescription)")
        }
    }
    
    /// Update an existing time block
    func updateTimeBlock(_ timeBlock: TimeBlock) throws {
        guard timeBlock.isValid else {
            throw DataManagerError.validationFailed("Time block validation failed: \(timeBlock.validationErrors.joined(separator: ", "))")
        }
        
        // Check for conflicts (excluding self)
        let existingBlocks = try loadTimeBlocks(for: timeBlock.scheduledDate)
        let otherBlocks = existingBlocks.filter { $0.id != timeBlock.id }
        let conflicts = timeBlock.conflictsWith(otherBlocks)
        
        if !conflicts.isEmpty {
            throw DataManagerError.conflictDetected("Time block conflicts with existing blocks: \(conflicts.map { $0.title }.joined(separator: ", "))")
        }
        
        do {
            timeBlock.touch()
            try save()
        } catch {
            throw DataManagerError.saveFailed("Failed to update time block: \(error.localizedDescription)")
        }
    }
    
    /// Delete a time block
    func deleteTimeBlock(_ timeBlock: TimeBlock) throws {
        do {
            modelContext.delete(timeBlock)
            try save()
        } catch {
            throw DataManagerError.deleteFailed("Failed to delete time block: \(error.localizedDescription)")
        }
    }
    
    /// Update time block status
    func updateTimeBlockStatus(_ timeBlock: TimeBlock, to status: BlockStatus) throws {
        timeBlock.updateStatus(to: status)
        try updateTimeBlock(timeBlock)
        
        // Update daily progress after status change
        try updateDailyProgress(for: timeBlock.scheduledDate)
    }
    
    /// Mark time block as completed
    func markTimeBlockCompleted(_ timeBlock: TimeBlock) throws {
        try updateTimeBlockStatus(timeBlock, to: .completed)
    }
    
    /// Mark time block as skipped
    func markTimeBlockSkipped(_ timeBlock: TimeBlock) throws {
        try updateTimeBlockStatus(timeBlock, to: .skipped)
    }
    
    /// Start a time block (mark as in progress)
    func startTimeBlock(_ timeBlock: TimeBlock) throws {
        try updateTimeBlockStatus(timeBlock, to: .inProgress)
    }
    
    // MARK: - DailyProgress Operations
    
    /// Load daily progress for a specific date
    func loadDailyProgress(for date: Date) throws -> DailyProgress? {
        let targetDate = Calendar.current.startOfDay(for: date)

        let predicate = #Predicate<DailyProgress> { [targetDate] progress in
            progress.date == targetDate
        }
        
        let descriptor = FetchDescriptor<DailyProgress>(predicate: predicate)
        
        do {
            let results = try modelContext.fetch(descriptor)
            return results.first
        } catch {
            throw DataManagerError.fetchFailed("Failed to load daily progress: \(error.localizedDescription)")
        }
    }
    
    /// Load or create daily progress for a date
    func loadOrCreateDailyProgress(for date: Date) throws -> DailyProgress {
        if let existing = try loadDailyProgress(for: date) {
            return existing
        } else {
            return try createDailyProgress(for: date)
        }
    }
    
    /// Create daily progress for a specific date
    @discardableResult
    func createDailyProgress(for date: Date) throws -> DailyProgress {
        let timeBlocks = try loadTimeBlocks(for: date)
        let progress = DailyProgress(date: date, timeBlocks: timeBlocks)
        
        do {
            modelContext.insert(progress)
            try save()
            return progress
        } catch {
            throw DataManagerError.saveFailed("Failed to create daily progress: \(error.localizedDescription)")
        }
    }
    
    /// Update daily progress based on current time blocks
    func updateDailyProgress(for date: Date) throws {
        let progress = try loadOrCreateDailyProgress(for: date)
        let timeBlocks = try loadTimeBlocks(for: date)
        
        progress.updateFromTimeBlocks(timeBlocks)
        
        do {
            try save()
        } catch {
            throw DataManagerError.saveFailed("Failed to update daily progress: \(error.localizedDescription)")
        }
    }
    
    /// Load daily progress for a date range
    func loadDailyProgress(from startDate: Date, to endDate: Date) throws -> [DailyProgress] {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: startDate)
        let end = calendar.startOfDay(for: endDate)
        
        let predicate = #Predicate<DailyProgress> { progress in
            progress.date >= start && progress.date <= end
        }
        
        let descriptor = FetchDescriptor<DailyProgress>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.date, order: .forward)]
        )
        
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            throw DataManagerError.fetchFailed("Failed to load daily progress range: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Batch Operations
    
    /// Delete all time blocks for a specific date
    func deleteAllTimeBlocks(for date: Date) throws {
        let timeBlocks = try loadTimeBlocks(for: date)
        
        for block in timeBlocks {
            modelContext.delete(block)
        }
        
        do {
            try save()
        } catch {
            throw DataManagerError.deleteFailed("Failed to delete all time blocks: \(error.localizedDescription)")
        }
    }
    
    /// Reset all time blocks status for a date (back to not started)
    func resetTimeBlocksStatus(for date: Date) throws {
        let timeBlocks = try loadTimeBlocks(for: date)
        
        for block in timeBlocks {
            if block.status.canTransition {
                block.updateStatus(to: .notStarted)
            }
        }
        
        do {
            try save()
            try updateDailyProgress(for: date)
        } catch {
            throw DataManagerError.saveFailed("Failed to reset time blocks: \(error.localizedDescription)")
        }
    }
    
    /// Copy time blocks from one date to another
    func copyTimeBlocks(from sourceDate: Date, to targetDate: Date) throws {
        let sourceBlocks = try loadTimeBlocks(for: sourceDate)
        
        for sourceBlock in sourceBlocks {
            let copiedBlock = sourceBlock.copyToDate(targetDate)
            try addTimeBlock(copiedBlock)
        }
    }
    
    // MARK: - Statistics and Analytics
    
    /// Get completion statistics for a date range
    func getCompletionStatistics(from startDate: Date, to endDate: Date) throws -> CompletionStatistics {
        let timeBlocks = try loadTimeBlocks(from: startDate, to: endDate)
        
        let totalBlocks = timeBlocks.count
        let completedBlocks = timeBlocks.filter { $0.status == .completed }.count
        let skippedBlocks = timeBlocks.filter { $0.status == .skipped }.count
        let inProgressBlocks = timeBlocks.filter { $0.status == .inProgress }.count
        
        return CompletionStatistics(
            totalBlocks: totalBlocks,
            completedBlocks: completedBlocks,
            skippedBlocks: skippedBlocks,
            inProgressBlocks: inProgressBlocks,
            startDate: startDate,
            endDate: endDate
        )
    }
    
    /// Get weekly statistics
    func getWeeklyStatistics(for date: Date) throws -> WeeklyStats {
        let calendar = Calendar.current
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: date)?.start ?? date
        let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart) ?? date
        
        let dailyProgress = try loadDailyProgress(from: weekStart, to: weekEnd)
        return DailyProgress.weeklyStatistics(from: dailyProgress)
    }
    
    // MARK: - Utility Operations
    
    /// Get current active time block
    func getCurrentActiveTimeBlock() throws -> TimeBlock? {
        let todaysBlocks = try loadTodaysTimeBlocks()
        
        return todaysBlocks.first { block in
            block.isCurrentlyActive || block.status == .inProgress
        }
    }
    
    /// Get next upcoming time block
    func getNextUpcomingTimeBlock() throws -> TimeBlock? {
        let todaysBlocks = try loadTodaysTimeBlocks()
        let now = Date()
        
        return todaysBlocks.first { block in
            block.startTime > now && block.status == .notStarted
        }
    }
    
    /// Update time blocks based on current time
    func updateTimeBlocksBasedOnCurrentTime() throws {
        let todaysBlocks = try loadTodaysTimeBlocks()
        var hasChanges = false
        
        for block in todaysBlocks {
            let oldStatus = block.status
            block.updateStatusBasedOnTime()
            
            if block.status != oldStatus {
                hasChanges = true
            }
        }
        
        if hasChanges {
            try save()
            try updateDailyProgress(for: Date())
        }
    }
    
    // MARK: - Core Data Operations
    
    /// Save changes to the persistent store
    private func save() throws {
        do {
            try modelContext.save()
        } catch {
            lastError = DataManagerError.saveFailed("Failed to save changes: \(error.localizedDescription)")
            throw lastError!
        }
    }
    
    /// Clear any error state
    func clearError() {
        lastError = nil
    }
}

// MARK: - Async Wrapper Methods
extension DataManager {
    /// Async wrapper for loading today's time blocks
    @MainActor
    func loadTodaysTimeBlocksAsync() async throws -> [TimeBlock] {
        isLoading = true
        defer { isLoading = false }
        
        return try loadTodaysTimeBlocks()
    }
    
    /// Async wrapper for updating time block status
    @MainActor
    func updateTimeBlockStatusAsync(_ timeBlock: TimeBlock, to status: BlockStatus) async throws {
        isLoading = true
        defer { isLoading = false }
        
        try updateTimeBlockStatus(timeBlock, to: status)
    }
    
    /// Async wrapper for updating daily progress
    @MainActor
    func updateDailyProgressAsync(for date: Date) async throws {
        isLoading = true
        defer { isLoading = false }
        
        try updateDailyProgress(for: date)
    }
}

// MARK: - Error Types
enum DataManagerError: LocalizedError, Sendable {
    case fetchFailed(String)
    case saveFailed(String)
    case deleteFailed(String)
    case validationFailed(String)
    case conflictDetected(String)
    case notFound(String)
    
    var errorDescription: String? {
        switch self {
        case .fetchFailed(let message),
             .saveFailed(let message),
             .deleteFailed(let message),
             .validationFailed(let message),
             .conflictDetected(let message),
             .notFound(let message):
            return message
        }
    }
}

// MARK: - Statistics Helper
struct CompletionStatistics: Sendable {
    let totalBlocks: Int
    let completedBlocks: Int
    let skippedBlocks: Int
    let inProgressBlocks: Int
    let startDate: Date
    let endDate: Date
    
    var completionPercentage: Double {
        guard totalBlocks > 0 else { return 0.0 }
        return Double(completedBlocks) / Double(totalBlocks)
    }
    
    var skipPercentage: Double {
        guard totalBlocks > 0 else { return 0.0 }
        return Double(skippedBlocks) / Double(totalBlocks)
    }
    
    var formattedCompletionPercentage: String {
        return String(format: "%.0f%%", completionPercentage * 100)
    }
}
