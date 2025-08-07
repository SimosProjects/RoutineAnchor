//
//  DataManagerCRUDTests.swift
//  Routine AnchorTests
//
//  Unit tests for DataManager CRUD operations with SwiftData including
//  error handling, validation, conflict detection, and batch operations
//

import Testing
import Foundation
import SwiftData
@testable import Routine_Anchor

// MARK: - Test Helpers

/// Helper class to create in-memory SwiftData containers for testing
class TestModelContainer {
    static func create() throws -> ModelContainer {
        let schema = Schema([
            TimeBlock.self,
            DailyProgress.self
        ])
        
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true,
            allowsSave: true
        )
        
        return try ModelContainer(
            for: schema,
            configurations: [configuration]
        )
    }
}

// MARK: - DataManager CRUD Tests

struct DataManagerCRUDTests {
    
    // MARK: - Helper Methods
    
    /// Create a test DataManager with in-memory storage
    private func createTestDataManager() throws -> (DataManager, ModelContainer) {
        let container = try TestModelContainer.create()
        let context = container.mainContext
        let dataManager = DataManager(modelContext: context)
        return (dataManager, container)
    }
    
    /// Create a sample TimeBlock for testing
    private func createSampleTimeBlock(
        title: String = "Test Block",
        startHour: Int = 10,
        endHour: Int = 11,
        day: Date = Date()
    ) -> TimeBlock {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: day)
        
        let startTime = calendar.date(
            byAdding: .hour,
            value: startHour,
            to: startOfDay
        ) ?? Date()
        
        let endTime = calendar.date(
            byAdding: .hour,
            value: endHour,
            to: startOfDay
        ) ?? Date()
        
        return TimeBlock(
            title: title,
            startTime: startTime,
            endTime: endTime
        )
    }
    
    // MARK: - Create (Add) Tests
    
    @Test("Add valid time block should succeed")
    func testAddValidTimeBlock() throws {
        let (dataManager, _) = try createTestDataManager()
        
        let block = createSampleTimeBlock(title: "Morning Meeting")
        
        let addedBlock = try dataManager.addTimeBlock(block)
        
        #expect(addedBlock.id == block.id)
        #expect(addedBlock.title == "Morning Meeting")
        
        // Verify it was saved
        let allBlocks = try dataManager.loadAllTimeBlocks()
        #expect(allBlocks.count == 1)
        #expect(allBlocks.first?.id == block.id)
    }
    
    @Test("Add invalid time block should throw validation error")
    func testAddInvalidTimeBlock() throws {
        let (dataManager, _) = try createTestDataManager()
        
        // Create invalid block (empty title)
        let block = createSampleTimeBlock(title: "")
        
        #expect(throws: DataManagerError.self) {
            try dataManager.addTimeBlock(block)
        }
        
        // Verify nothing was saved
        let allBlocks = try dataManager.loadAllTimeBlocks()
        #expect(allBlocks.isEmpty)
    }
    
    @Test("Add conflicting time block should throw conflict error")
    func testAddConflictingTimeBlock() throws {
        let (dataManager, _) = try createTestDataManager()
        
        // Add first block
        let block1 = createSampleTimeBlock(
            title: "First Meeting",
            startHour: 10,
            endHour: 12
        )
        try dataManager.addTimeBlock(block1)
        
        // Try to add overlapping block
        let block2 = createSampleTimeBlock(
            title: "Second Meeting",
            startHour: 11,
            endHour: 13
        )
        
        #expect(throws: DataManagerError.self) {
            try dataManager.addTimeBlock(block2)
        }
        
        // Verify only first block was saved
        let allBlocks = try dataManager.loadAllTimeBlocks()
        #expect(allBlocks.count == 1)
        #expect(allBlocks.first?.title == "First Meeting")
    }
    
    @Test("Add multiple non-conflicting blocks should succeed")
    func testAddMultipleNonConflictingBlocks() throws {
        let (dataManager, _) = try createTestDataManager()
        
        let blocks = [
            createSampleTimeBlock(title: "Morning", startHour: 9, endHour: 10),
            createSampleTimeBlock(title: "Midday", startHour: 12, endHour: 13),
            createSampleTimeBlock(title: "Evening", startHour: 17, endHour: 18)
        ]
        
        for block in blocks {
            try dataManager.addTimeBlock(block)
        }
        
        let allBlocks = try dataManager.loadAllTimeBlocks()
        #expect(allBlocks.count == 3)
        #expect(allBlocks.map { $0.title }.sorted() == ["Evening", "Midday", "Morning"])
    }
    
    // MARK: - Read (Load) Tests
    
    @Test("Load all time blocks should return all blocks")
    func testLoadAllTimeBlocks() throws {
        let (dataManager, _) = try createTestDataManager()
        
        // Add multiple blocks
        for i in 1...5 {
            let block = createSampleTimeBlock(
                title: "Block \(i)",
                startHour: 8 + i,
                endHour: 9 + i
            )
            try dataManager.addTimeBlock(block)
        }
        
        let allBlocks = try dataManager.loadAllTimeBlocks()
        
        #expect(allBlocks.count == 5)
        // Should be sorted by start time
        #expect(allBlocks[0].title == "Block 1")
        #expect(allBlocks[4].title == "Block 5")
    }
    
    @Test("Load today's time blocks should filter correctly")
    func testLoadTodaysTimeBlocks() throws {
        let (dataManager, _) = try createTestDataManager()
        
        let calendar = Calendar.current
        let today = Date()
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        
        // Add blocks for different days
        try dataManager.addTimeBlock(
            createSampleTimeBlock(title: "Yesterday", day: yesterday)
        )
        try dataManager.addTimeBlock(
            createSampleTimeBlock(title: "Today 1", startHour: 9, endHour: 10, day: today)
        )
        try dataManager.addTimeBlock(
            createSampleTimeBlock(title: "Today 2", startHour: 14, endHour: 15, day: today)
        )
        try dataManager.addTimeBlock(
            createSampleTimeBlock(title: "Tomorrow", day: tomorrow)
        )
        
        let todaysBlocks = try dataManager.loadTodaysTimeBlocks()
        
        #expect(todaysBlocks.count == 2)
        #expect(todaysBlocks.map { $0.title }.contains("Today 1"))
        #expect(todaysBlocks.map { $0.title }.contains("Today 2"))
    }
    
    @Test("Load time blocks by status should filter correctly")
    func testLoadTimeBlocksByStatus() throws {
        let (dataManager, _) = try createTestDataManager()
        
        // Add blocks with different statuses
        let block1 = createSampleTimeBlock(title: "Completed", startHour: 9, endHour: 10)
        block1.status = BlockStatus.completed
        try dataManager.addTimeBlock(block1)
        
        let block2 = createSampleTimeBlock(title: "In Progress", startHour: 11, endHour: 12)
        block2.status = BlockStatus.inProgress
        try dataManager.addTimeBlock(block2)
        
        let block3 = createSampleTimeBlock(title: "Not Started", startHour: 14, endHour: 15)
        block3.status = BlockStatus.notStarted
        try dataManager.addTimeBlock(block3)
        
        // Load completed blocks
        let completedBlocks = try dataManager.loadTimeBlocks(withStatus: BlockStatus.completed)
        #expect(completedBlocks.count == 1)
        #expect(completedBlocks.first?.title == "Completed")
        
        // Load in progress blocks
        let inProgressBlocks = try dataManager.loadTimeBlocks(withStatus: BlockStatus.inProgress)
        #expect(inProgressBlocks.count == 1)
        #expect(inProgressBlocks.first?.title == "In Progress")
    }
    
    @Test("Load time blocks for date range should filter correctly")
    func testLoadTimeBlocksForDateRange() throws {
        let (dataManager, _) = try createTestDataManager()
        
        let calendar = Calendar.current
        let today = Date()
        
        // Add blocks across a week
        for dayOffset in -3...3 {
            let date = calendar.date(byAdding: .day, value: dayOffset, to: today)!
            let block = createSampleTimeBlock(
                title: "Day \(dayOffset)",
                day: date
            )
            try dataManager.addTimeBlock(block)
        }
        
        // Load blocks for past 2 days
        let twoDaysAgo = calendar.date(byAdding: .day, value: -2, to: today)!
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        
        let rangeBlocks = try dataManager.loadTimeBlocks(
            from: twoDaysAgo,
            to: yesterday
        )
        
        #expect(rangeBlocks.count == 2)
        #expect(rangeBlocks.map { $0.title }.contains("Day -2"))
        #expect(rangeBlocks.map { $0.title }.contains("Day -1"))
    }
    
    // MARK: - Update Tests
    
    @Test("Update valid time block should succeed")
    func testUpdateValidTimeBlock() throws {
        let (dataManager, _) = try createTestDataManager()
        
        // Add initial block
        let block = createSampleTimeBlock(title: "Original Title")
        try dataManager.addTimeBlock(block)
        
        // Update the block
        block.title = "Updated Title"
        block.notes = "Added some notes"
        try dataManager.updateTimeBlock(block)
        
        // Verify update
        let allBlocks = try dataManager.loadAllTimeBlocks()
        #expect(allBlocks.count == 1)
        #expect(allBlocks.first?.title == "Updated Title")
        #expect(allBlocks.first?.notes == "Added some notes")
        #expect(allBlocks.first!.updatedAt > allBlocks.first?.createdAt ?? Date())
    }
    
    @Test("Update with invalid data should throw validation error")
    func testUpdateWithInvalidData() throws {
        let (dataManager, _) = try createTestDataManager()
        
        // Add initial block
        let block = createSampleTimeBlock(title: "Valid Title")
        try dataManager.addTimeBlock(block)
        
        // Try to update with invalid data
        block.title = "" // Invalid
        
        #expect(throws: DataManagerError.self) {
            try dataManager.updateTimeBlock(block)
        }
        
        // Verify block wasn't updated
        let allBlocks = try dataManager.loadAllTimeBlocks()
        #expect(allBlocks.first?.title == "Valid Title")
    }
    
    @Test("Update causing conflict should throw error")
    func testUpdateCausingConflict() throws {
        let (dataManager, _) = try createTestDataManager()
        
        // Add two non-conflicting blocks
        let block1 = createSampleTimeBlock(title: "Block 1", startHour: 9, endHour: 10)
        let block2 = createSampleTimeBlock(title: "Block 2", startHour: 11, endHour: 12)
        try dataManager.addTimeBlock(block1)
        try dataManager.addTimeBlock(block2)
        
        // Try to update block1 to conflict with block2
        block1.startTime = block2.startTime
        block1.endTime = block2.endTime
        
        #expect(throws: DataManagerError.self) {
            try dataManager.updateTimeBlock(block1)
        }
    }
    
    // MARK: - Delete Tests
    
    @Test("Delete time block should remove it")
    func testDeleteTimeBlock() throws {
        let (dataManager, _) = try createTestDataManager()
        
        // Add blocks
        let block1 = createSampleTimeBlock(title: "Keep Me", startHour: 9, endHour: 10)
        let block2 = createSampleTimeBlock(title: "Delete Me", startHour: 11, endHour: 12)
        try dataManager.addTimeBlock(block1)
        try dataManager.addTimeBlock(block2)
        
        // Delete block2
        try dataManager.deleteTimeBlock(block2)
        
        // Verify deletion
        let allBlocks = try dataManager.loadAllTimeBlocks()
        #expect(allBlocks.count == 1)
        #expect(allBlocks.first?.title == "Keep Me")
    }
    
    @Test("Delete all time blocks for date should clear that day")
    func testDeleteAllTimeBlocksForDate() throws {
        let (dataManager, _) = try createTestDataManager()
        
        let calendar = Calendar.current
        let today = Date()
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        
        // Add blocks for today and tomorrow
        try dataManager.addTimeBlock(
            createSampleTimeBlock(title: "Today 1", startHour: 9, endHour: 10, day: today)
        )
        try dataManager.addTimeBlock(
            createSampleTimeBlock(title: "Today 2", startHour: 14, endHour: 15, day: today)
        )
        try dataManager.addTimeBlock(
            createSampleTimeBlock(title: "Tomorrow", day: tomorrow)
        )
        
        // Delete all blocks for today
        try dataManager.deleteAllTimeBlocks(for: today)
        
        // Verify only tomorrow's block remains
        let allBlocks = try dataManager.loadAllTimeBlocks()
        #expect(allBlocks.count == 1)
        #expect(allBlocks.first?.title == "Tomorrow")
    }
    
    // MARK: - Status Update Tests
    
    @Test("Update time block status should succeed")
    func testUpdateTimeBlockStatus() throws {
        let (dataManager, _) = try createTestDataManager()
        
        let block = createSampleTimeBlock(title: "Task")
        try dataManager.addTimeBlock(block)
        
        #expect(block.status == BlockStatus.notStarted)
        
        // Start the block
        try dataManager.startTimeBlock(block)
        #expect(block.status == BlockStatus.inProgress)
        
        // Complete the block
        try dataManager.markTimeBlockCompleted(block)
        #expect(block.status == BlockStatus.completed)
        
        // Verify persistence
        let allBlocks = try dataManager.loadAllTimeBlocks()
        #expect(allBlocks.first?.status == BlockStatus.completed)
    }
    
    @Test("Mark block as skipped should update status")
    func testMarkTimeBlockSkipped() throws {
        let (dataManager, _) = try createTestDataManager()
        
        let block = createSampleTimeBlock(title: "Optional Task")
        try dataManager.addTimeBlock(block)
        
        try dataManager.markTimeBlockSkipped(block)
        
        #expect(block.status == BlockStatus.skipped)
        
        // Verify persistence
        let allBlocks = try dataManager.loadAllTimeBlocks()
        #expect(allBlocks.first?.status == BlockStatus.skipped)
    }
    
    // MARK: - Batch Operation Tests
    
    @Test("Reset all time blocks status for date")
    func testResetTimeBlocksStatus() throws {
        let (dataManager, _) = try createTestDataManager()
        
        // Add blocks with various statuses
        let blocks = [
            createSampleTimeBlock(title: "Completed", startHour: 9, endHour: 10),
            createSampleTimeBlock(title: "Skipped", startHour: 11, endHour: 12),
            createSampleTimeBlock(title: "In Progress", startHour: 14, endHour: 15)
        ]
        
        for block in blocks {
            try dataManager.addTimeBlock(block)
        }
        
        // Set different statuses
        blocks[0].status = BlockStatus.completed
        blocks[1].status = BlockStatus.skipped
        blocks[2].status = BlockStatus.inProgress
        
        // Reset all statuses
        try dataManager.resetTimeBlocksStatus(for: Date())
        
        // Verify all are reset to notStarted
        let allBlocks = try dataManager.loadTodaysTimeBlocks()
        for block in allBlocks {
            #expect(block.status == BlockStatus.notStarted)
        }
    }
    
    @Test("Copy time blocks to another date")
    func testCopyTimeBlocksToDate() throws {
        let (dataManager, _) = try createTestDataManager()
        
        let calendar = Calendar.current
        let today = Date()
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        
        // Add blocks for today
        let blocks = [
            createSampleTimeBlock(title: "Morning Routine", startHour: 7, endHour: 8, day: today),
            createSampleTimeBlock(title: "Work", startHour: 9, endHour: 17, day: today),
            createSampleTimeBlock(title: "Exercise", startHour: 18, endHour: 19, day: today)
        ]
        
        for block in blocks {
            try dataManager.addTimeBlock(block)
        }
        
        // Copy to tomorrow
        try dataManager.copyTimeBlocks(from: today, to: tomorrow)
        
        // Verify blocks exist for both days
        let todayBlocks = try dataManager.loadTimeBlocks(for: today)
        let tomorrowBlocks = try dataManager.loadTimeBlocks(for: tomorrow)
        
        #expect(todayBlocks.count == 3)
        #expect(tomorrowBlocks.count == 3)
        
        // Verify copied blocks have same titles but different IDs
        let todayTitles = todayBlocks.map { $0.title }.sorted()
        let tomorrowTitles = tomorrowBlocks.map { $0.title }.sorted()
        #expect(todayTitles == tomorrowTitles)
        
        // Verify different IDs
        let todayIds = Set(todayBlocks.map { $0.id })
        let tomorrowIds = Set(tomorrowBlocks.map { $0.id })
        #expect(todayIds.isDisjoint(with: tomorrowIds))
        
        // Verify times are on correct days
        for block in tomorrowBlocks {
            #expect(calendar.isDate(block.startTime, inSameDayAs: tomorrow))
        }
    }
    
    // MARK: - Error Handling Tests
    
    @Test("DataManager should set lastError on failure")
    func testErrorStateManagement() throws {
        let (dataManager, _) = try createTestDataManager()
        
        // Create invalid block
        let block = createSampleTimeBlock(title: "")
        
        // Try to add invalid block
        do {
            try dataManager.addTimeBlock(block)
            Issue.record("Should have thrown error")
        } catch {
            // Error should be set
            #expect(dataManager.lastError != nil)
        }
        
        // Clear error
        dataManager.clearError()
        #expect(dataManager.lastError == nil)
    }
    
    // MARK: - Daily Progress Tests
    
    @Test("Load or create daily progress")
    func testLoadOrCreateDailyProgress() throws {
        let (dataManager, _) = try createTestDataManager()
        
        let today = Date()
        
        // First call should create
        let progress1 = try dataManager.loadOrCreateDailyProgress(for: today)
        #expect(progress1.date == Calendar.current.startOfDay(for: today))
        
        // Second call should load existing
        let progress2 = try dataManager.loadOrCreateDailyProgress(for: today)
        #expect(progress1.id == progress2.id)
    }
    
    @Test("Update daily progress from time blocks")
    func testUpdateDailyProgress() throws {
        let (dataManager, _) = try createTestDataManager()
        
        // Add time blocks with different statuses
        let blocks = [
            createSampleTimeBlock(title: "Completed", startHour: 9, endHour: 10),
            createSampleTimeBlock(title: "Skipped", startHour: 11, endHour: 12),
            createSampleTimeBlock(title: "Not Started", startHour: 14, endHour: 15)
        ]
        
        for block in blocks {
            try dataManager.addTimeBlock(block)
        }
        
        blocks[0].status = BlockStatus.completed
        blocks[1].status = BlockStatus.skipped
        
        // Update progress
        try dataManager.updateDailyProgress(for: Date())
        
        // Load and verify progress
        let progress = try dataManager.loadDailyProgress(for: Date())
        #expect(progress?.totalBlocks == 3)
        #expect(progress?.completedBlocks == 1)
        #expect(progress?.skippedBlocks == 1)
    }
    
    // MARK: - Edge Case Tests
    
    @Test("Handle empty database gracefully")
    func testEmptyDatabase() throws {
        let (dataManager, _) = try createTestDataManager()
        
        // Should return empty arrays, not throw
        let allBlocks = try dataManager.loadAllTimeBlocks()
        let todaysBlocks = try dataManager.loadTodaysTimeBlocks()
        
        #expect(allBlocks.isEmpty)
        #expect(todaysBlocks.isEmpty)
    }
    
    @Test("Handle very long time blocks")
    func testVeryLongTimeBlocks() throws {
        let (dataManager, _) = try createTestDataManager()
        
        // Create 23-hour block (should be valid)
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        
        let longBlock = TimeBlock(
            title: "All Day Event",
            startTime: startOfDay,
            endTime: calendar.date(byAdding: .hour, value: 23, to: startOfDay)!
        )
        
        let addedBlock = try dataManager.addTimeBlock(longBlock)
        #expect(addedBlock.durationMinutes == 23 * 60)
    }
    
    @Test("Handle rapid successive operations")
    func testRapidOperations() throws {
        let (dataManager, _) = try createTestDataManager()
        
        // Rapidly add, update, and delete
        let block = createSampleTimeBlock(title: "Rapid Test")
        try dataManager.addTimeBlock(block)
        
        block.title = "Updated Rapidly"
        try dataManager.updateTimeBlock(block)
        
        block.notes = "More updates"
        try dataManager.updateTimeBlock(block)
        
        try dataManager.deleteTimeBlock(block)
        
        // Should be empty
        let allBlocks = try dataManager.loadAllTimeBlocks()
        #expect(allBlocks.isEmpty)
    }
}
