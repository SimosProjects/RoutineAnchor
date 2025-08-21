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
@MainActor
class DataManager {
    // MARK: - Properties
    
    let modelContext: ModelContext
    private var lastSaveTime: Date = .distantPast
    private let saveThrottleInterval: TimeInterval = 0.1
    
    // MARK: - Published Properties for SwiftUI
    
    /// Current error state for UI display
    var lastError: DataManagerError?
    
    /// Loading state for UI feedback
    var isLoading: Bool = false
    
    // MARK: - Initialization
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Model Safety Guards
    
    /// Safely access model properties with error handling
    func safeModelAccess<T>(_ operation: () throws -> T, fallback: T) -> T {
        do {
            return try operation()
        } catch {
            print("⚠️ Model access failed (likely destroyed), using fallback: \(error)")
            return fallback
        }
    }
    
    /// Check if a model object is still valid
    func isModelValid<T: PersistentModel>(_ model: T) -> Bool {
        do {
            // Try to access the persistent identifier to check validity
            _ = model.persistentModelID
            return true
        } catch {
            return false
        }
    }
    
    func loadDailyProgressSafely(for date: Date) -> DailyProgress? {
        return safeModelAccess({
            try loadDailyProgress(for: date)
        }, fallback: nil)
    }
    
    /// Safe version of loadAllTimeBlocks
    func loadAllTimeBlocksSafely() -> [TimeBlock] {
        return safeModelAccess({
            try loadAllTimeBlocks()
        }, fallback: [])
    }
    
    /// Safe version of loadTimeBlocks(for:) - for specific dates
    func loadTimeBlocksSafely(for date: Date) -> [TimeBlock] {
        return safeModelAccess({
            try loadTimeBlocks(for: date)
        }, fallback: [])
    }
    
    /// Safe version of resetTimeBlocksStatus
    func resetTimeBlocksStatusSafely(for date: Date) {
        safeModelAccess({
            try resetTimeBlocksStatus(for: date)
        }, fallback: ())
    }
    
    /// Safe version of deleteAllTimeBlocks
    func deleteAllTimeBlocksSafely(for date: Date) {
        safeModelAccess({
            try deleteAllTimeBlocks(for: date)
        }, fallback: ())
    }
    
    /// Safe version of clearDailyProgress
    func clearDailyProgressSafely(for date: Date) {
        safeModelAccess({
            try clearDailyProgress(for: date)
        }, fallback: ())
    }
    
    /// Safe version of loadDailyProgress range
    func loadDailyProgressRangeSafely(from startDate: Date, to endDate: Date) -> [DailyProgress] {
        return safeModelAccess({
            try loadDailyProgress(from: startDate, to: endDate)
        }, fallback: [])
    }
    
    /// Safe version of deleteTimeBlock
    func deleteTimeBlockSafely(_ timeBlock: TimeBlock) {
        safeModelAccess({
            try deleteTimeBlock(timeBlock)
        }, fallback: ())
    }
    
    /// Safe generic model deletion
    func deleteModelSafely<T: PersistentModel>(_ model: T) {
        safeModelAccess({
            modelContext.delete(model)
            try save()
        }, fallback: ())
    }
    
    /// Safe version of addTimeBlock
    func addTimeBlockSafely(_ timeBlock: TimeBlock) {
        safeModelAccess({
            try addTimeBlock(timeBlock)
        }, fallback: ())
    }
    
    /// Safely update daily progress with error recovery
    func updateDailyProgressSafely(for date: Date) {
        safeModelAccess({
            try updateDailyProgress(for: date)
        }, fallback: ())
    }
    
    func updateTimeBlockStatusSafely(_ timeBlock: TimeBlock, to status: BlockStatus) {
        safeModelAccess({
            try updateTimeBlockStatus(timeBlock, to: status)
        }, fallback: ())
    }
    
    /// Refresh context if models become invalid
    func refreshContextIfNeeded() {
        // Check if context is still valid by performing a simple operation
        do {
            var descriptor = FetchDescriptor<TimeBlock>(
                sortBy: [SortDescriptor(\.startTime, order: .forward)]
            )
            descriptor.fetchLimit = 1
            _ = try modelContext.fetch(descriptor)
        } catch {
            print("🔄 Context appears invalid, attempting refresh...")
            // The context will be recreated by the SwiftData system automatically
        }
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

    /// Load today's time blocks with safety
    func loadTodaysTimeBlocks() throws -> [TimeBlock] {
        return try loadTimeBlocks(for: Date())
    }
    
    /// Safely load today's time blocks
    func loadTodaysTimeBlocksSafely() -> [TimeBlock] {
        return safeModelAccess({
            try loadTodaysTimeBlocks()
        }, fallback: [])
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
    
    func createTimeBlock(_ timeBlock: TimeBlock) throws {
        // Use the existing addTimeBlock method which has validation
        try addTimeBlock(timeBlock)
        
        // Post notification for observers
        NotificationCenter.default.post(
            name: .timeBlocksDidChange,
            object: nil,
            userInfo: ["date": timeBlock.startTime]
        )
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
        
        timeBlock.touch()
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
    
    /// Update time block status with safety
    func updateTimeBlockStatus(_ timeBlock: TimeBlock, to status: BlockStatus) throws {
        // Check if the model is still valid first
        guard isModelValid(timeBlock) else {
            print("⚠️ TimeBlock model is invalid, skipping status update")
            return
        }
        
        timeBlock.updateStatus(to: status)
        try updateTimeBlock(timeBlock)
        
        // Update daily progress after status change with safety
        updateDailyProgressSafely(for: timeBlock.scheduledDate)
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
        try performBatchOperation {
            let progress = try loadOrCreateDailyProgress(for: date)
            let timeBlocks = try loadTimeBlocks(for: date)
            
            // Check if progress model is still valid before updating
            guard isModelValid(progress) else {
                print("⚠️ DailyProgress model is invalid, recreating...")
                let newProgress = try createDailyProgress(for: date)
                newProgress.updateFromTimeBlocks(timeBlocks)
                return
            }
            
            progress.updateFromTimeBlocks(timeBlocks)
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
        try performBatchOperation {
            let timeBlocks = try loadTimeBlocks(for: date)
            
            for block in timeBlocks {
                // Check if model is still valid before updating
                guard isModelValid(block) else {
                    print("⚠️ TimeBlock model invalid during reset, skipping...")
                    continue
                }
                
                print("🔄 Resetting block '\(block.title)' from \(block.status.rawValue) to notStarted")
                block.status = .notStarted
                block.updatedAt = Date()
            }
            
            // Update daily progress safely
            updateDailyProgressSafely(for: date)
            print("🔄 ✅ Status reset completed (single save)")
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
    
    /// Clear daily progress for a specific date
    func clearDailyProgress(for date: Date) throws {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        
        let predicate = #Predicate<DailyProgress> { progress in
            progress.date == startOfDay
        }
        
        let descriptor = FetchDescriptor<DailyProgress>(predicate: predicate)
        
        do {
            let progressRecords = try modelContext.fetch(descriptor)
            
            for record in progressRecords {
                modelContext.delete(record)
            }
            
            try save()
            print("✅ Daily progress cleared for \(startOfDay)")
            
        } catch {
            throw DataManagerError.deleteFailed("Failed to clear daily progress: \(error.localizedDescription)")
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
            // Check if model is still valid
            guard isModelValid(block) else {
                print("⚠️ TimeBlock model invalid during time update, skipping...")
                continue
            }
            
            let oldStatus = block.status
            block.updateStatusBasedOnTime()
            
            if block.status != oldStatus {
                hasChanges = true
            }
        }
        
        if hasChanges {
            try save()
            updateDailyProgressSafely(for: Date())
        }
    }
    
    // MARK: - Core Data Operations
    
    /// Save changes to the persistent store
    func save() throws {
        let now = Date()
        
        // Throttle saves to prevent excessive calls
        guard now.timeIntervalSince(lastSaveTime) >= saveThrottleInterval else {
            return // Skip this save if too recent
        }
        
        do {
            try modelContext.save()
            lastSaveTime = now
        } catch {
            lastError = DataManagerError.saveFailed("Failed to save changes: \(error.localizedDescription)")
            throw lastError!
        }
    }
    
    /// Save only if there are actual changes
    func saveIfNeeded() throws {
        if modelContext.hasChanges {
            try modelContext.save()
        }
    }
    
    func performBatchOperation<T>(_ operation: () throws -> T) throws -> T {
        let result = try operation()
        try saveIfNeeded()
        return result
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
