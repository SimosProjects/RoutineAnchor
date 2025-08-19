//
//  StatePersistenceTests.swift
//  Routine AnchorTests
//
//  Testing data persistence and state management
//
import XCTest
import SwiftData
@testable import Routine_Anchor

final class StatePersistenceTests: XCTestCase {
    
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
    
    // MARK: - State Consistency
    
    @MainActor
    func testStateConsistencyAfterOperations() throws {
        let dataManager = DataManager(modelContext: container.mainContext)
        
        // Create initial state
        let blocks = [
            createSampleTimeBlock(title: "Block 1", startHour: 9, endHour: 10),
            createSampleTimeBlock(title: "Block 2", startHour: 11, endHour: 12),
            createSampleTimeBlock(title: "Block 3", startHour: 13, endHour: 14)
        ]
        
        for block in blocks {
            try dataManager.addTimeBlock(block)
        }
        
        // Perform various state changes
        try dataManager.markTimeBlockCompleted(blocks[0])
        try dataManager.markTimeBlockSkipped(blocks[1])
        try dataManager.startTimeBlock(blocks[2])
        
        // Update progress
        try dataManager.updateDailyProgress(for: Date())
        
        // Verify state consistency
        let progress = try dataManager.loadDailyProgress(for: Date())
        let loadedBlocks = try dataManager.loadAllTimeBlocks()
        
        XCTAssertEqual(progress?.totalBlocks, 3)
        XCTAssertEqual(progress?.completedBlocks, 1)
        XCTAssertEqual(progress?.skippedBlocks, 1)
        XCTAssertEqual(progress?.inProgressBlocks, 1)
        
        // Verify individual block states
        let completedBlocks = loadedBlocks.filter { $0.status == .completed }
        let skippedBlocks = loadedBlocks.filter { $0.status == .skipped }
        let inProgressBlocks = loadedBlocks.filter { $0.status == .inProgress }
        
        XCTAssertEqual(completedBlocks.count, 1)
        XCTAssertEqual(skippedBlocks.count, 1)
        XCTAssertEqual(inProgressBlocks.count, 1)
        
        XCTAssertEqual(completedBlocks.first?.title, "Block 1")
        XCTAssertEqual(skippedBlocks.first?.title, "Block 2")
        XCTAssertEqual(inProgressBlocks.first?.title, "Block 3")
    }
    
    // MARK: - Data Corruption Testing
    
    @MainActor
    func testDataIntegrityAfterErrors() throws {
        let dataManager = DataManager(modelContext: container.mainContext)
        
        // Create valid data first
        let validBlock = createSampleTimeBlock(title: "Valid Block")
        try dataManager.addTimeBlock(validBlock)
        
        // Attempt operations that might cause corruption
        let invalidBlocks = [
            TimeBlock(title: "", startTime: Date(), endTime: Date().addingTimeInterval(3600)),
            TimeBlock(title: "Invalid Time", startTime: Date(), endTime: Date().addingTimeInterval(-3600))
        ]
        
        for invalidBlock in invalidBlocks {
            XCTAssertThrowsError(try dataManager.addTimeBlock(invalidBlock))
        }
        
        // Verify original data is still intact
        let allBlocks = try dataManager.loadAllTimeBlocks()
        XCTAssertEqual(allBlocks.count, 1)
        XCTAssertEqual(allBlocks.first?.title, "Valid Block")
        XCTAssertTrue(allBlocks.first?.isValid ?? false)
        
        // Verify we can still perform valid operations
        try dataManager.markTimeBlockCompleted(validBlock)
        XCTAssertEqual(validBlock.status, .completed)
    }
    
    // MARK: - Recovery Testing
    
    @MainActor
    func testRecoveryFromInconsistentState() throws {
        let dataManager = DataManager(modelContext: container.mainContext)
        
        // Create blocks
        let blocks = [
            createSampleTimeBlock(title: "Recovery Test 1", startHour: 10, endHour: 11),
            createSampleTimeBlock(title: "Recovery Test 2", startHour: 12, endHour: 13)
        ]
        
        for block in blocks {
            try dataManager.addTimeBlock(block)
        }
        
        // Manually create inconsistent state (simulate corruption)
        let progress = try dataManager.loadOrCreateDailyProgress(for: Date())
        progress.totalBlocks = 5      // Wrong count
        progress.completedBlocks = 3  // Wrong count
        
        // System should recover when recalculating
        try dataManager.updateDailyProgress(for: Date())
        
        let correctedProgress = try dataManager.loadDailyProgress(for: Date())
        XCTAssertEqual(correctedProgress?.totalBlocks, 2)  // Corrected
        XCTAssertEqual(correctedProgress?.completedBlocks, 0)  // Corrected
    }
    
    // MARK: - Cross-Date Persistence
    
    @MainActor
    func testCrossDateDataPersistence() throws {
        let dataManager = DataManager(modelContext: container.mainContext)
        let calendar = Calendar.current
        
        // Create data for multiple days
        let today = Date()
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        
        let dates = [yesterday, today, tomorrow]
        
        for (index, date) in dates.enumerated() {
            let block = createSampleTimeBlock(
                title: "Day \(index) Block",
                startHour: 10,
                endHour: 11,
                day: date
            )
            try dataManager.addTimeBlock(block)
            
            if index < 2 {  // Complete blocks for yesterday and today
                try dataManager.markTimeBlockCompleted(block)
            }
            
            try dataManager.updateDailyProgress(for: date)
        }
        
        // Verify each day's data persists correctly
        for (index, date) in dates.enumerated() {
            let dayBlocks = try dataManager.loadTimeBlocks(for: date)
            let dayProgress = try dataManager.loadDailyProgress(for: date)
            
            XCTAssertEqual(dayBlocks.count, 1)
            XCTAssertEqual(dayProgress?.totalBlocks, 1)
            
            if index < 2 {
                XCTAssertEqual(dayProgress?.completedBlocks, 1)
                XCTAssertEqual(dayBlocks.first?.status, .completed)
            } else {
                XCTAssertEqual(dayProgress?.completedBlocks, 0)
                XCTAssertEqual(dayBlocks.first?.status, .notStarted)
            }
        }
    }
    
    // MARK: - Batch Operation Consistency
    
    @MainActor
    func testBatchOperationConsistency() throws {
        let dataManager = DataManager(modelContext: container.mainContext)
        
        // Create large batch of blocks
        var blocks: [TimeBlock] = []
        for i in 0..<20 {
            let block = createSampleTimeBlock(
                title: "Batch Block \(i)",
                startHour: (i % 12) + 8,  // 8 AM to 7 PM
                day: Date().addingTimeInterval(TimeInterval(i / 12 * 86400)) // Spread across days
            )
            blocks.append(block)
        }
        
        // Add all blocks
        for block in blocks {
            try dataManager.addTimeBlock(block)
        }
        
        // Batch status updates
        for (index, block) in blocks.enumerated() {
            switch index % 3 {
            case 0:
                try dataManager.markTimeBlockCompleted(block)
            case 1:
                try dataManager.markTimeBlockSkipped(block)
            default:
                // Leave as notStarted
                break
            }
        }
        
        // Update all progress
        let uniqueDates = Set(blocks.map { $0.scheduledDate })
        for date in uniqueDates {
            try dataManager.updateDailyProgress(for: date)
        }
        
        // Verify consistency
        let allBlocks = try dataManager.loadAllTimeBlocks()
        XCTAssertEqual(allBlocks.count, 20)
        
        let completedCount = allBlocks.filter { $0.status == .completed }.count
        let skippedCount = allBlocks.filter { $0.status == .skipped }.count
        let notStartedCount = allBlocks.filter { $0.status == .notStarted }.count
        
        XCTAssertEqual(completedCount + skippedCount + notStartedCount, 20)
        
        // Verify progress consistency
        for date in uniqueDates {
            let dayBlocks = try dataManager.loadTimeBlocks(for: date)
            let dayProgress = try dataManager.loadDailyProgress(for: date)
            
            let expectedCompleted = dayBlocks.filter { $0.status == .completed }.count
            let expectedSkipped = dayBlocks.filter { $0.status == .skipped }.count
            
            XCTAssertEqual(dayProgress?.totalBlocks, dayBlocks.count)
            XCTAssertEqual(dayProgress?.completedBlocks, expectedCompleted)
            XCTAssertEqual(dayProgress?.skippedBlocks, expectedSkipped)
        }
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
