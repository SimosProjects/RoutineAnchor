//
//  DataManager.swift
//  Routine Anchor - Premium Version
//
import Foundation
import SwiftData
import SwiftUI

/// Core data management service for handling all SwiftData operations
@MainActor
class DataManager: ObservableObject {
    // MARK: - Singleton
    static let shared = DataManager()
    
    // MARK: - Published Properties
    @Published var lastError: DataManagerError?
    @Published var isLoading: Bool = false
    
    // MARK: - Private Properties
    private var modelContext: ModelContext?
    
    // MARK: - Initialization
    private init() {}
    
    /// Configure with model context - call this from your app initialization
    func configure(with modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    /// Get the model context with validation
    private func getContext() throws -> ModelContext {
        guard let context = modelContext else {
            throw DataManagerError.notConfigured("DataManager not configured with ModelContext")
        }
        return context
    }
    
    // MARK: - TimeBlock Operations
    
    /// Fetch all time blocks from the database
    func fetchTimeBlocks(from context: ModelContext) async throws -> [TimeBlock] {
        let descriptor = FetchDescriptor<TimeBlock>(
            sortBy: [SortDescriptor(\.startTime, order: .forward)]
        )
        
        do {
            return try context.fetch(descriptor)
        } catch {
            throw DataManagerError.fetchFailed("Failed to fetch time blocks: \(error.localizedDescription)")
        }
    }
    
    /// Load all time blocks
    func loadAllTimeBlocks() async throws -> [TimeBlock] {
        let context = try getContext()
        return try await fetchTimeBlocks(from: context)
    }
    
    /// Load time blocks for a specific date
    func loadTimeBlocks(for date: Date) async throws -> [TimeBlock] {
        let context = try getContext()
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let descriptor = FetchDescriptor<TimeBlock>(
            predicate: #Predicate<TimeBlock> { block in
                block.startTime >= startOfDay && block.startTime < endOfDay
            },
            sortBy: [SortDescriptor(\.startTime, order: .forward)]
        )
        
        do {
            return try context.fetch(descriptor)
        } catch {
            throw DataManagerError.fetchFailed("Failed to load time blocks for date: \(error.localizedDescription)")
        }
    }
    
    /// Load today's time blocks
    func loadTodaysTimeBlocks() async throws -> [TimeBlock] {
        return try await loadTimeBlocks(for: Date())
    }
    
    /// Load time blocks for a date range
    func loadTimeBlocks(from startDate: Date, to endDate: Date) async throws -> [TimeBlock] {
        let context = try getContext()
        
        let descriptor = FetchDescriptor<TimeBlock>(
            predicate: #Predicate<TimeBlock> { block in
                block.startTime >= startDate && block.startTime <= endDate
            },
            sortBy: [SortDescriptor(\.startTime, order: .forward)]
        )
        
        do {
            return try context.fetch(descriptor)
        } catch {
            throw DataManagerError.fetchFailed("Failed to load time blocks for range: \(error.localizedDescription)")
        }
    }
    
    /// Load time blocks by status
    func loadTimeBlocks(withStatus status: BlockStatus) async throws -> [TimeBlock] {
        let context = try getContext()
        let statusValue = status.rawValue
        
        let descriptor = FetchDescriptor<TimeBlock>(
            predicate: #Predicate<TimeBlock> { block in
                block.statusValue == statusValue
            },
            sortBy: [SortDescriptor(\.startTime, order: .forward)]
        )
        
        do {
            return try context.fetch(descriptor)
        } catch {
            throw DataManagerError.fetchFailed("Failed to load time blocks with status: \(error.localizedDescription)")
        }
    }
    
    /// Load time blocks by category
    func loadTimeBlocks(withCategory category: String) async throws -> [TimeBlock] {
        let context = try getContext()
        
        let descriptor = FetchDescriptor<TimeBlock>(
            predicate: #Predicate<TimeBlock> { block in
                block.category == category
            },
            sortBy: [SortDescriptor(\.startTime, order: .forward)]
        )
        
        do {
            return try context.fetch(descriptor)
        } catch {
            throw DataManagerError.fetchFailed("Failed to load time blocks for category: \(error.localizedDescription)")
        }
    }
    
    /// Load time blocks by priority
    func loadHighPriorityTimeBlocks(minPriority: Int = 4) async throws -> [TimeBlock] {
        let context = try getContext()
        
        let descriptor = FetchDescriptor<TimeBlock>(
            predicate: #Predicate<TimeBlock> { block in
                block.priority >= minPriority
            },
            sortBy: [
                SortDescriptor(\.priority, order: .reverse),
                SortDescriptor(\.startTime, order: .forward)
            ]
        )
        
        do {
            return try context.fetch(descriptor)
        } catch {
            throw DataManagerError.fetchFailed("Failed to load high priority time blocks: \(error.localizedDescription)")
        }
    }
    
    /// Search time blocks by text
    func searchTimeBlocks(query: String) async throws -> [TimeBlock] {
        let context = try getContext()
        let searchText = query.lowercased()
        
        let descriptor = FetchDescriptor<TimeBlock>(
            predicate: #Predicate<TimeBlock> { block in
                block.title.localizedStandardContains(searchText) ||
                (block.notes ?? "").localizedStandardContains(searchText) ||
                (block.category ?? "").localizedStandardContains(searchText)
            },
            sortBy: [SortDescriptor(\.startTime, order: .forward)]
        )
        
        do {
            return try context.fetch(descriptor)
        } catch {
            throw DataManagerError.fetchFailed("Failed to search time blocks: \(error.localizedDescription)")
        }
    }
    
    // MARK: - CRUD Operations
    
    /// Add a new time block
    @discardableResult
    func addTimeBlock(_ timeBlock: TimeBlock) async throws -> TimeBlock {
        let context = try getContext()
        
        // Validate the time block
        try validateTimeBlock(timeBlock)
        
        // Check for conflicts
        let conflicts = try await checkConflicts(for: timeBlock)
        if !conflicts.isEmpty {
            throw DataManagerError.conflictDetected("Time block conflicts with \(conflicts.count) existing blocks")
        }
        
        context.insert(timeBlock)
        
        do {
            try context.save()
            return timeBlock
        } catch {
            throw DataManagerError.saveFailed("Failed to add time block: \(error.localizedDescription)")
        }
    }
    
    /// Update an existing time block
    func updateTimeBlock(_ timeBlock: TimeBlock) async throws {
        let context = try getContext()
        
        // Validate the time block
        try validateTimeBlock(timeBlock)
        
        // Check for conflicts (excluding self)
        let conflicts = try await checkConflicts(for: timeBlock, excluding: timeBlock)
        if !conflicts.isEmpty {
            throw DataManagerError.conflictDetected("Time block conflicts with \(conflicts.count) existing blocks")
        }
        
        // Update timestamp
        timeBlock.touch()
        
        do {
            try context.save()
        } catch {
            throw DataManagerError.saveFailed("Failed to update time block: \(error.localizedDescription)")
        }
    }
    
    /// Delete a time block
    func deleteTimeBlock(_ timeBlock: TimeBlock) async throws {
        let context = try getContext()
        
        context.delete(timeBlock)
        
        do {
            try context.save()
        } catch {
            throw DataManagerError.deleteFailed("Failed to delete time block: \(error.localizedDescription)")
        }
    }
    
    /// Delete multiple time blocks
    func deleteTimeBlocks(_ timeBlocks: [TimeBlock]) async throws {
        let context = try getContext()
        
        for block in timeBlocks {
            context.delete(block)
        }
        
        do {
            try context.save()
        } catch {
            throw DataManagerError.deleteFailed("Failed to delete time blocks: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Status Management
    
    /// Update time block status
    func updateTimeBlockStatus(_ timeBlock: TimeBlock, to status: BlockStatus) async throws {
        let context = try getContext()
        
        let previousStatus = timeBlock.status
        timeBlock.status = status
        
        // Handle status-specific actions
        switch status {
        case .inProgress:
            timeBlock.startTracking()
        case .completed:
            if previousStatus == .inProgress {
                timeBlock.completeTracking()
            } else {
                timeBlock.status = .completed
                timeBlock.completionPercentage = 100.0
            }
        case .skipped:
            timeBlock.actualStartTime = nil
            timeBlock.actualEndTime = nil
            timeBlock.completionPercentage = 0.0
        case .notStarted:
            timeBlock.actualStartTime = nil
            timeBlock.actualEndTime = nil
            timeBlock.completionPercentage = 0.0
        }
        
        timeBlock.touch()
        
        do {
            try context.save()
            
            // Update daily progress
            try await updateDailyProgress(for: timeBlock.scheduledDate)
        } catch {
            throw DataManagerError.saveFailed("Failed to update time block status: \(error.localizedDescription)")
        }
    }
    
    /// Mark time block as completed
    func markTimeBlockCompleted(_ timeBlock: TimeBlock) async throws {
        try await updateTimeBlockStatus(timeBlock, to: .completed)
    }
    
    /// Mark time block as skipped
    func markTimeBlockSkipped(_ timeBlock: TimeBlock) async throws {
        try await updateTimeBlockStatus(timeBlock, to: .skipped)
    }
    
    /// Start time block
    func startTimeBlock(_ timeBlock: TimeBlock) async throws {
        try await updateTimeBlockStatus(timeBlock, to: .inProgress)
    }
    
    // MARK: - Daily Progress Operations
    
    /// Load daily progress for a specific date
    func loadDailyProgress(for date: Date) async throws -> DailyProgress? {
        let context = try getContext()
        let startOfDay = Calendar.current.startOfDay(for: date)
        
        let descriptor = FetchDescriptor<DailyProgress>(
            predicate: #Predicate<DailyProgress> { progress in
                progress.date == startOfDay
            }
        )
        
        do {
            let results = try context.fetch(descriptor)
            return results.first
        } catch {
            throw DataManagerError.fetchFailed("Failed to load daily progress: \(error.localizedDescription)")
        }
    }
    
    /// Load or create daily progress
    func loadOrCreateDailyProgress(for date: Date) async throws -> DailyProgress {
        let context = try getContext()
        
        // Try to load existing
        if let existing = try await loadDailyProgress(for: date) {
            return existing
        }
        
        // Create new
        let progress = DailyProgress(date: date)
        context.insert(progress)
        
        do {
            try context.save()
            return progress
        } catch {
            throw DataManagerError.saveFailed("Failed to create daily progress: \(error.localizedDescription)")
        }
    }
    
    /// Update daily progress based on time blocks
    func updateDailyProgress(for date: Date) async throws {
        let context = try getContext()
        let progress = try await loadOrCreateDailyProgress(for: date)
        let timeBlocks = try await loadTimeBlocks(for: date)
        
        // Calculate statistics
        progress.totalBlocks = timeBlocks.count
        progress.completedBlocks = timeBlocks.filter { $0.status == .completed }.count
        progress.skippedBlocks = timeBlocks.filter { $0.status == .skipped }.count
        progress.inProgressBlocks = timeBlocks.filter { $0.status == .inProgress }.count
        
        // Calculate time metrics
        progress.totalPlannedMinutes = timeBlocks.reduce(0) { $0 + $1.durationMinutes }
        progress.completedMinutes = timeBlocks
            .filter { $0.status == .completed }
            .reduce(0) { $0 + $1.durationMinutes }
        
        // Generate insights
        progress.generateInsights()
        
        do {
            try context.save()
        } catch {
            throw DataManagerError.saveFailed("Failed to update daily progress: \(error.localizedDescription)")
        }
    }
    
    /// Load daily progress for a date range
    func loadDailyProgress(from startDate: Date, to endDate: Date) async throws -> [DailyProgress] {
        let context = try getContext()
        let startOfStartDay = Calendar.current.startOfDay(for: startDate)
        let startOfEndDay = Calendar.current.startOfDay(for: endDate)
        
        let descriptor = FetchDescriptor<DailyProgress>(
            predicate: #Predicate<DailyProgress> { progress in
                progress.date >= startOfStartDay && progress.date <= startOfEndDay
            },
            sortBy: [SortDescriptor(\.date, order: .forward)]
        )
        
        do {
            return try context.fetch(descriptor)
        } catch {
            throw DataManagerError.fetchFailed("Failed to load daily progress range: \(error.localizedDescription)")
        }
    }
    
    func deleteAllDailyProgress() async throws {
        let context = try getContext()
        let descriptor = FetchDescriptor<DailyProgress>()
        let allProgress = try context.fetch(descriptor)
        for progress in allProgress {
            context.delete(progress)
        }
        try context.save()
    }

    
    // MARK: - Validation & Conflict Detection
    
    /// Validate time block data
    private func validateTimeBlock(_ timeBlock: TimeBlock) throws {
        // Title validation
        let trimmedTitle = timeBlock.title.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedTitle.isEmpty {
            throw DataManagerError.validationFailed("Title cannot be empty")
        }
        if trimmedTitle.count < 2 {
            throw DataManagerError.validationFailed("Title must be at least 2 characters")
        }
        
        // Time validation
        if timeBlock.startTime >= timeBlock.endTime {
            throw DataManagerError.validationFailed("Start time must be before end time")
        }
        
        // Duration validation
        let duration = timeBlock.durationMinutes
        if duration < 1 {
            throw DataManagerError.validationFailed("Duration must be at least 1 minute")
        }
        if duration > 24 * 60 {
            throw DataManagerError.validationFailed("Duration cannot exceed 24 hours")
        }
        
        // Priority validation
        if timeBlock.priority < 1 || timeBlock.priority > 5 {
            throw DataManagerError.validationFailed("Priority must be between 1 and 5")
        }
        
        // Energy level validation
        if timeBlock.energyLevel < 1 || timeBlock.energyLevel > 5 {
            throw DataManagerError.validationFailed("Energy level must be between 1 and 5")
        }
    }
    
    /// Check for time conflicts
    private func checkConflicts(for timeBlock: TimeBlock, excluding: TimeBlock? = nil) async throws -> [TimeBlock] {
        let dayBlocks = try await loadTimeBlocks(for: timeBlock.scheduledDate)
        
        return dayBlocks.filter { block in
            // Don't check against self
            if let excluding = excluding, block.id == excluding.id {
                return false
            }
            
            // Check for overlap
            return timeBlock.conflictsWith(block)
        }
    }
    
    // MARK: - Utility Operations
    
    /// Get current active time block
    func getCurrentActiveTimeBlock() async throws -> TimeBlock? {
        let todaysBlocks = try await loadTodaysTimeBlocks()
        return todaysBlocks.first { $0.isCurrentlyActive }
    }
    
    /// Get next upcoming time block
    func getNextUpcomingTimeBlock() async throws -> TimeBlock? {
        let todaysBlocks = try await loadTodaysTimeBlocks()
        let now = Date()
        
        return todaysBlocks
            .filter { $0.startTime > now && $0.status == .notStarted }
            .sorted { $0.startTime < $1.startTime }
            .first
    }
    
    /// Update time blocks based on current time
    func updateTimeBlocksBasedOnCurrentTime() async throws {
        let todaysBlocks = try await loadTodaysTimeBlocks()
        let context = try getContext()
        var hasChanges = false
        
        for block in todaysBlocks {
            // Auto-skip blocks that are past their end time and not started
            if block.endTime < Date() && block.status == .notStarted {
                block.status = .skipped
                hasChanges = true
            }
        }
        
        if hasChanges {
            try context.save()
            try await updateDailyProgress(for: Date())
        }
    }
    
    /// Reset all blocks for a date
    func resetTimeBlocks(for date: Date) async throws {
        let blocks = try await loadTimeBlocks(for: date)
        let context = try getContext()
        
        for block in blocks {
            block.status = .notStarted
            block.actualStartTime = nil
            block.actualEndTime = nil
            block.completionPercentage = 0.0
        }
        
        do {
            try context.save()
            try await updateDailyProgress(for: date)
        } catch {
            throw DataManagerError.saveFailed("Failed to reset time blocks: \(error.localizedDescription)")
        }
    }
    
    /// Copy time blocks from one date to another
    func copyTimeBlocks(from sourceDate: Date, to targetDate: Date) async throws {
        let sourceBlocks = try await loadTimeBlocks(for: sourceDate)
        
        for sourceBlock in sourceBlocks {
            let copiedBlock = sourceBlock.copy(to: targetDate)
            try await addTimeBlock(copiedBlock)
        }
    }
    
    // MARK: - Statistics
    
    /// Get completion statistics for a date range
    func getCompletionStatistics(from startDate: Date, to endDate: Date) async throws -> CompletionStatistics {
        let timeBlocks = try await loadTimeBlocks(from: startDate, to: endDate)
        
        let totalBlocks = timeBlocks.count
        let completedBlocks = timeBlocks.filter { $0.status == .completed }.count
        let skippedBlocks = timeBlocks.filter { $0.status == .skipped }.count
        let inProgressBlocks = timeBlocks.filter { $0.status == .inProgress }.count
        
        let completionRate = totalBlocks > 0 ? Double(completedBlocks) / Double(totalBlocks) : 0.0
        
        return CompletionStatistics(
            totalBlocks: totalBlocks,
            completedBlocks: completedBlocks,
            skippedBlocks: skippedBlocks,
            inProgressBlocks: inProgressBlocks,
            completionRate: completionRate,
            startDate: startDate,
            endDate: endDate
        )
    }
    
    /// Get analytics for time blocks
    func getTimeBlockAnalytics(for timeBlock: TimeBlock) -> TimeBlockAnalytics {
        return TimeBlockAnalytics(
            completionRate: timeBlock.completionRate,
            averageCompletionMinutes: timeBlock.averageCompletionMinutes,
            productivityScore: timeBlock.productivityScore,
            suggestions: timeBlock.smartSuggestions,
            motivationalMessage: timeBlock.motivationalMessage
        )
    }
    
    // MARK: - Clear Data
    
    /// Clear all data (use with caution)
    func clearAllData() async throws {
        let context = try getContext()
        
        // Delete all time blocks
        let timeBlocks = try await loadAllTimeBlocks()
        for block in timeBlocks {
            context.delete(block)
        }
        
        // Delete all daily progress
        let progressDescriptor = FetchDescriptor<DailyProgress>()
        let allProgress = try context.fetch(progressDescriptor)
        for progress in allProgress {
            context.delete(progress)
        }
        
        do {
            try context.save()
        } catch {
            throw DataManagerError.deleteFailed("Failed to clear all data: \(error.localizedDescription)")
        }
    }
    
    /// Clear error state
    func clearError() {
        lastError = nil
    }
}

// MARK: - Error Types

enum DataManagerError: LocalizedError {
    case notConfigured(String)
    case fetchFailed(String)
    case saveFailed(String)
    case deleteFailed(String)
    case validationFailed(String)
    case conflictDetected(String)
    case notFound(String)
    
    var errorDescription: String? {
        switch self {
        case .notConfigured(let message),
             .fetchFailed(let message),
             .saveFailed(let message),
             .deleteFailed(let message),
             .validationFailed(let message),
             .conflictDetected(let message),
             .notFound(let message):
            return message
        }
    }
}

// MARK: - Supporting Types

struct CompletionStatistics {
    let totalBlocks: Int
    let completedBlocks: Int
    let skippedBlocks: Int
    let inProgressBlocks: Int
    let completionRate: Double
    let startDate: Date
    let endDate: Date
    
    var formattedCompletionRate: String {
        let percentage = Int(completionRate * 100)
        return "\(percentage)%"
    }
}

struct TimeBlockAnalytics {
    let completionRate: Double
    let averageCompletionMinutes: Double
    let productivityScore: Double
    let suggestions: [String]
    let motivationalMessage: String?
}

