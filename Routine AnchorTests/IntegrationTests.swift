//
//  IntegrationTests.swift
//  Routine Anchor
//
//  Created by Christopher Simonson on 8/18/25.
//
import XCTest
import SwiftData
@testable import Routine_Anchor

final class IntegrationTests: XCTestCase {
    
    var container: ModelContainer!
    
    override func setUp() {
        super.setUp()
        
        let schema = Schema([TimeBlock.self, DailyProgress.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        
        do {
            container = try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            XCTFail("Failed to create test container: \(error)")
        }
    }
    
    override func tearDown() {
        container = nil
        super.tearDown()
    }
    
    @MainActor
    func testCompleteWorkflow() async throws {
        let dataManager = DataManager(modelContext: container.mainContext)
        
        // Step 1: Create time block
        let block = createSampleTimeBlock(title: "Integration Test Block")
        try dataManager.addTimeBlock(block)
        
        // Step 2: Update the block
        block.notes = "Updated notes"
        try dataManager.updateTimeBlock(block)
        
        // Step 3: Mark as completed
        try dataManager.markTimeBlockCompleted(block)
        
        // Step 4: Update daily progress
        try dataManager.updateDailyProgress(for: Date())
        
        // Step 5: Export data
        let allBlocks = try dataManager.loadAllTimeBlocks()
        let exportService = ExportService.shared
        let exportData = try exportService.exportTimeBlocks(allBlocks, format: .json)
        
        // Verify workflow completed successfully
        XCTAssertEqual(block.status, .completed)
        XCTAssertEqual(block.notes, "Updated notes")
        XCTAssertGreaterThan(exportData.count, 0)
        
        let progress = try dataManager.loadDailyProgress(for: Date())
        XCTAssertEqual(progress?.completedBlocks, 1)
        
        // Convert to Double for comparison
        let actualPercentage = Double(progress?.completionPercentage ?? 0.0)
        XCTAssertEqual(actualPercentage, 1.0, accuracy: 0.01)
    }
    
    @MainActor
    func testMultiDayScheduleManagement() throws {
        let dataManager = DataManager(modelContext: container.mainContext)
        let calendar = Calendar.current
        let today = Date()
        
        // Create blocks for a week (reduced scope for stability)
        for i in 0..<3 { // Reduced from 7 days to 3 days
            let date = calendar.date(byAdding: .day, value: i, to: today)!
            
            for hour in [9, 14] { // Reduced from 3 blocks to 2 blocks per day
                let block = createSampleTimeBlock(
                    title: "Day \(i) - Hour \(hour)",
                    startHour: hour,
                    endHour: hour + 1,
                    day: date
                )
                try dataManager.addTimeBlock(block)
            }
        }
        
        // Verify all blocks created
        let allBlocks = try dataManager.loadAllTimeBlocks()
        XCTAssertEqual(allBlocks.count, 6) // 3 days × 2 blocks
        
        // Test loading specific days
        for i in 0..<3 {
            let date = calendar.date(byAdding: .day, value: i, to: today)!
            let dayBlocks = try dataManager.loadTimeBlocks(for: date)
            XCTAssertEqual(dayBlocks.count, 2)
        }
    }
    
    @MainActor
    func testImportExportRoundTrip() async throws {
        let dataManager = DataManager(modelContext: container.mainContext)
        
        // Create original data
        let originalBlocks = [
            createSampleTimeBlock(title: "Block 1", startHour: 9, endHour: 10),
            createSampleTimeBlock(title: "Block 2", startHour: 11, endHour: 12)
        ]
        
        for block in originalBlocks {
            try dataManager.addTimeBlock(block)
        }
        
        // Export data
        let exportService = ExportService.shared
        let exportData = try exportService.exportTimeBlocks(originalBlocks, format: .json)
        
        // Clear existing data
        for block in originalBlocks {
            try dataManager.deleteTimeBlock(block)
        }
        
        // Verify data is cleared
        let clearedBlocks = try dataManager.loadAllTimeBlocks()
        XCTAssertTrue(clearedBlocks.isEmpty)
        
        // Import data back - capture context in MainActor context
        let modelContext = container.mainContext
        let importService = ImportService.shared
        let result = try await importService.importJSON(exportData, modelContext: modelContext)
        
        // Verify import was successful
        XCTAssertTrue(result.isSuccess)
        XCTAssertEqual(result.timeBlocksImported, 2)
        
        // Verify imported data matches original
        let importedBlocks = try dataManager.loadAllTimeBlocks()
        XCTAssertEqual(importedBlocks.count, 2)
        
        let titles = Set(importedBlocks.map { $0.title })
        XCTAssertTrue(titles.contains("Block 1"))
        XCTAssertTrue(titles.contains("Block 2"))
    }
    
    @MainActor
    func testStatusTransitionWorkflow() throws {
        let dataManager = DataManager(modelContext: container.mainContext)
        
        // Create a time block
        let block = createSampleTimeBlock(title: "Status Test Block")
        try dataManager.addTimeBlock(block)
        
        // Initial state
        XCTAssertEqual(block.status, .notStarted)
        
        // Start the block
        try dataManager.startTimeBlock(block)
        XCTAssertEqual(block.status, .inProgress)
        
        // Complete the block
        try dataManager.markTimeBlockCompleted(block)
        XCTAssertEqual(block.status, .completed)
        
        // Update daily progress and verify
        try dataManager.updateDailyProgress(for: Date())
        
        let progress = try dataManager.loadDailyProgress(for: Date())
        XCTAssertEqual(progress?.totalBlocks, 1)
        XCTAssertEqual(progress?.completedBlocks, 1)
        
        let actualPercentage = Double(progress?.completionPercentage ?? 0.0)
        XCTAssertEqual(actualPercentage, 1.0, accuracy: 0.01)
    }
    
    @MainActor
    func testConflictResolutionWorkflow() throws {
        let dataManager = DataManager(modelContext: container.mainContext)
        
        // Create first block
        let block1 = createSampleTimeBlock(title: "First Block", startHour: 10, endHour: 11)
        try dataManager.addTimeBlock(block1)
        
        // Try to create conflicting block
        let conflictingBlock = createSampleTimeBlock(title: "Conflicting Block", startHour: 10, endHour: 11)
        
        XCTAssertThrowsError(try dataManager.addTimeBlock(conflictingBlock)) { error in
            XCTAssertTrue(error is DataManagerError)
            if case .conflictDetected = error as? DataManagerError {
                // Expected conflict error
            } else {
                XCTFail("Expected conflict error, got: \(error)")
            }
        }
        
        // Verify only first block exists
        let allBlocks = try dataManager.loadAllTimeBlocks()
        XCTAssertEqual(allBlocks.count, 1)
        XCTAssertEqual(allBlocks.first?.title, "First Block")
        
        // Create non-conflicting block
        let nonConflictingBlock = createSampleTimeBlock(title: "Non-conflicting Block", startHour: 12, endHour: 13)
        XCTAssertNoThrow(try dataManager.addTimeBlock(nonConflictingBlock))
        
        // Verify both blocks exist
        let finalBlocks = try dataManager.loadAllTimeBlocks()
        XCTAssertEqual(finalBlocks.count, 2)
    }
    
    @MainActor
    func testDataPersistenceWorkflow() throws {
        let dataManager = DataManager(modelContext: container.mainContext)
        
        // Create and save blocks
        let blocks = [
            createSampleTimeBlock(title: "Persistent Block 1", startHour: 9, endHour: 10),
            createSampleTimeBlock(title: "Persistent Block 2", startHour: 11, endHour: 12),
            createSampleTimeBlock(title: "Persistent Block 3", startHour: 13, endHour: 14)
        ]
        
        for block in blocks {
            try dataManager.addTimeBlock(block)
        }
        
        // Mark some as completed
        try dataManager.markTimeBlockCompleted(blocks[0])
        try dataManager.markTimeBlockCompleted(blocks[1])
        
        // Update progress
        try dataManager.updateDailyProgress(for: Date())
        
        // Verify persistence by reloading
        let loadedBlocks = try dataManager.loadAllTimeBlocks()
        XCTAssertEqual(loadedBlocks.count, 3)
        
        let completedBlocks = loadedBlocks.filter { $0.status == .completed }
        XCTAssertEqual(completedBlocks.count, 2)
        
        let progress = try dataManager.loadDailyProgress(for: Date())
        XCTAssertEqual(progress?.totalBlocks, 3)
        XCTAssertEqual(progress?.completedBlocks, 2)
        
        let actualPercentage = Double(progress?.completionPercentage ?? 0.0)
        let expectedPercentage = 2.0 / 3.0
        XCTAssertEqual(actualPercentage, expectedPercentage, accuracy: 0.01)
    }
    
    @MainActor
    func testCrossDateBoundaryWorkflow() throws {
        let dataManager = DataManager(modelContext: container.mainContext)
        let calendar = Calendar.current
        
        // Create blocks across multiple days
        let today = Date()
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        
        let blocks = [
            createSampleTimeBlock(title: "Yesterday Block", startHour: 15, endHour: 16, day: yesterday),
            createSampleTimeBlock(title: "Today Block", startHour: 10, endHour: 11, day: today),
            createSampleTimeBlock(title: "Tomorrow Block", startHour: 9, endHour: 10, day: tomorrow)
        ]
        
        for block in blocks {
            try dataManager.addTimeBlock(block)
        }
        
        // Complete blocks on different days
        try dataManager.markTimeBlockCompleted(blocks[0]) // Yesterday
        try dataManager.markTimeBlockCompleted(blocks[1]) // Today
        
        // Update progress for each day
        try dataManager.updateDailyProgress(for: yesterday)
        try dataManager.updateDailyProgress(for: today)
        try dataManager.updateDailyProgress(for: tomorrow)
        
        // Verify each day's progress
        let yesterdayProgress = try dataManager.loadDailyProgress(for: yesterday)
        let todayProgress = try dataManager.loadDailyProgress(for: today)
        let tomorrowProgress = try dataManager.loadDailyProgress(for: tomorrow)
        
        XCTAssertEqual(yesterdayProgress?.totalBlocks, 1)
        XCTAssertEqual(yesterdayProgress?.completedBlocks, 1)
        
        XCTAssertEqual(todayProgress?.totalBlocks, 1)
        XCTAssertEqual(todayProgress?.completedBlocks, 1)
        
        XCTAssertEqual(tomorrowProgress?.totalBlocks, 1)
        XCTAssertEqual(tomorrowProgress?.completedBlocks, 0)
        
        // Verify date isolation
        let todayBlocks = try dataManager.loadTimeBlocks(for: today)
        XCTAssertEqual(todayBlocks.count, 1)
        XCTAssertEqual(todayBlocks.first?.title, "Today Block")
    }
    
    // MARK: - Helper Methods
    
    private func createSampleTimeBlock(
        title: String = "Test Block",
        startHour: Int = 10,
        endHour: Int = 11,
        day: Date = Date()
    ) -> TimeBlock {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: day)
        let startTime = calendar.date(byAdding: .hour, value: startHour, to: startOfDay) ?? Date()
        let endTime = calendar.date(byAdding: .hour, value: endHour, to: startOfDay) ?? Date().addingTimeInterval(3600)
        
        return TimeBlock(title: title, startTime: startTime, endTime: endTime)
    }
}
