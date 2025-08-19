//
//  DataManagerTests.swift
//  Routine AnchorTests
//
//  DataManager testing for edge cases and complex scenarios
//
import XCTest
import SwiftData
@testable import Routine_Anchor

final class DataManagerTests: XCTestCase {
    
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
    
    // MARK: - Complex Query Tests
    
    @MainActor
    func testComplexQueries() throws {
        let dataManager = DataManager(modelContext: container.mainContext)
        let calendar = Calendar.current
        let today = Date()
        
        // Create diverse test data
        let testData = [
            (title: "Morning Work", hour: 9, status: BlockStatus.completed, day: today),
            (title: "Lunch", hour: 12, status: BlockStatus.completed, day: today),
            (title: "Afternoon Work", hour: 14, status: BlockStatus.inProgress, day: today),
            (title: "Evening Exercise", hour: 18, status: BlockStatus.notStarted, day: today),
            (title: "Yesterday Work", hour: 10, status: BlockStatus.completed, day: calendar.date(byAdding: .day, value: -1, to: today)!),
            (title: "Tomorrow Meeting", hour: 11, status: BlockStatus.notStarted, day: calendar.date(byAdding: .day, value: 1, to: today)!)
        ]
        
        for data in testData {
            let block = createSampleTimeBlock(title: data.title, startHour: data.hour, day: data.day)
            block.status = data.status
            try dataManager.addTimeBlock(block)
        }
        
        // Test various query combinations
        let todayBlocks = try dataManager.loadTimeBlocks(for: today)
        XCTAssertEqual(todayBlocks.count, 4)
        
        let completedBlocks = try dataManager.loadTimeBlocks(withStatus: .completed)
        XCTAssertEqual(completedBlocks.count, 3)
        
        let todayCompleted = todayBlocks.filter { $0.status == .completed }
        XCTAssertEqual(todayCompleted.count, 2)
        
        // Test date range queries
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        let rangeProgress = try dataManager.loadDailyProgress(from: yesterday, to: tomorrow)
        XCTAssertEqual(rangeProgress.count, 3) // Yesterday, today, tomorrow
    }
    
    @MainActor
    func testAdvancedConflictDetection() throws {
        let dataManager = DataManager(modelContext: container.mainContext)
        
        // Create base block
        let baseBlock = createSampleTimeBlock(title: "Base Block", startHour: 10, endHour: 12)
        try dataManager.addTimeBlock(baseBlock)
        
        // Test various conflict scenarios
        let conflictScenarios = [
            (title: "Exact Overlap", startHour: 10, endHour: 12),
            (title: "Start Overlap", startHour: 9, endHour: 11),
            (title: "End Overlap", startHour: 11, endHour: 13),
            (title: "Contains Base", startHour: 9, endHour: 13),
            (title: "Inside Base", startHour: 10, endHour: 11),
            (title: "Touch Start", startHour: 8, endHour: 10),  // Should NOT conflict
            (title: "Touch End", startHour: 12, endHour: 14)    // Should NOT conflict
        ]
        
        for (index, scenario) in conflictScenarios.enumerated() {
            let testBlock = createSampleTimeBlock(
                title: scenario.title,
                startHour: scenario.startHour,
                endHour: scenario.endHour
            )
            
            if index < 5 { // First 5 should conflict
                XCTAssertThrowsError(try dataManager.addTimeBlock(testBlock)) { error in
                    XCTAssertTrue(error is DataManagerError, "Scenario '\(scenario.title)' should conflict")
                }
            } else { // Last 2 should NOT conflict (touching boundaries)
                XCTAssertNoThrow(try dataManager.addTimeBlock(testBlock), "Scenario '\(scenario.title)' should not conflict")
            }
        }
        
        // Verify final state
        let allBlocks = try dataManager.loadAllTimeBlocks()
        XCTAssertEqual(allBlocks.count, 3) // Base + 2 non-conflicting
    }
    
    @MainActor
    func testDataIntegrityWithRapidOperations() throws {
        let dataManager = DataManager(modelContext: container.mainContext)
        
        // Rapidly create, modify, and delete blocks
        var createdBlocks: [TimeBlock] = []
        
        for i in 0..<50 {
            autoreleasepool {
                let block = createSampleTimeBlock(
                    title: "Rapid Block \(i)",
                    startHour: (i % 20) + 1,
                    day: Date().addingTimeInterval(TimeInterval(i * 86400 / 10))
                )
                
                do {
                    try dataManager.addTimeBlock(block)
                    createdBlocks.append(block)
                    
                    // Rapidly modify some blocks
                    if i % 3 == 0 {
                        block.title = "Modified \(i)"
                        try dataManager.updateTimeBlock(block)
                    }
                    
                    // Rapidly delete some blocks
                    if i % 5 == 0 && !createdBlocks.isEmpty {
                        let blockToDelete = createdBlocks.removeFirst()
                        try dataManager.deleteTimeBlock(blockToDelete)
                    }
                    
                    // Update status rapidly
                    if i % 4 == 0 {
                        try dataManager.markTimeBlockCompleted(block)
                    }
                    
                } catch {
                    // Some operations may fail due to conflicts - that's expected
                    print("Operation failed, but this is expected due to conflicts: \(error)")
                }
            }
        }
        
        // Verify data integrity after rapid operations
        let finalBlocks = try dataManager.loadAllTimeBlocks()
        
        // All remaining blocks should be valid
        for block in finalBlocks {
            XCTAssertTrue(block.isValid)
            XCTAssertFalse(block.title.isEmpty)
            XCTAssertTrue(block.startTime < block.endTime)
        }
        
        // Progress should be consistent
        let uniqueDates = Set(finalBlocks.map { $0.scheduledDate })
        for date in uniqueDates {
            try dataManager.updateDailyProgress(for: date)
            let progress = try dataManager.loadDailyProgress(for: date)
            let dayBlocks = try dataManager.loadTimeBlocks(for: date)
            
            XCTAssertEqual(progress?.totalBlocks, dayBlocks.count)
        }
    }
    
    // MARK: - Memory Management Tests
    
    @MainActor
    func testMemoryManagementWithLargeDataset() throws {
        let dataManager = DataManager(modelContext: container.mainContext)
        
        // Create large dataset in batches to test memory management
        for batch in 0..<10 {
            autoreleasepool {
                for i in 0..<50 {
                    let blockNumber = batch * 50 + i
                    let block = createSampleTimeBlock(
                        title: "Memory Test \(blockNumber)",
                        startHour: (blockNumber % 22) + 1,
                        day: Date().addingTimeInterval(TimeInterval(blockNumber * 3600))
                    )
                    
                    do {
                        try dataManager.addTimeBlock(block)
                        
                        // Periodically save to manage memory
                        if blockNumber % 25 == 0 {
                            try dataManager.save()
                        }
                    } catch {
                        // Some may fail due to conflicts
                        continue
                    }
                }
            }
        }
        
        // Verify we created a substantial dataset
        let allBlocks = try dataManager.loadAllTimeBlocks()
        XCTAssertGreaterThan(allBlocks.count, 400)
        
        // Test memory efficiency of large queries
        measure {
            do {
                let _ = try dataManager.loadAllTimeBlocks()
                let _ = try dataManager.loadTimeBlocks(withStatus: .notStarted)
            } catch {
                XCTFail("Large dataset query failed: \(error)")
            }
        }
    }
    
    // MARK: - Transaction and Atomicity Tests
    
    @MainActor
    func testTransactionAtomicity() throws {
        let dataManager = DataManager(modelContext: container.mainContext)
        
        // Test that operations are atomic - either all succeed or all fail
        let validBlocks = [
            createSampleTimeBlock(title: "Valid 1", startHour: 9, endHour: 10),
            createSampleTimeBlock(title: "Valid 2", startHour: 11, endHour: 12)
        ]
        
        let invalidBlock = TimeBlock(title: "", startTime: Date(), endTime: Date().addingTimeInterval(3600))
        
        // Add valid blocks first
        for block in validBlocks {
            try dataManager.addTimeBlock(block)
        }
        
        let initialCount = try dataManager.loadAllTimeBlocks().count
        XCTAssertEqual(initialCount, 2)
        
        // Try to add invalid block (should fail without affecting existing data)
        XCTAssertThrowsError(try dataManager.addTimeBlock(invalidBlock))
        
        // Verify existing data is still intact
        let afterFailureCount = try dataManager.loadAllTimeBlocks().count
        XCTAssertEqual(afterFailureCount, 2)
        
        let loadedBlocks = try dataManager.loadAllTimeBlocks()
        for block in loadedBlocks {
            XCTAssertTrue(block.isValid)
            XCTAssertFalse(block.title.isEmpty)
        }
    }
    
    // MARK: - Edge Case Testing
    
    @MainActor
    func testEdgeCaseTimeHandling() throws {
        let dataManager = DataManager(modelContext: container.mainContext)
        let calendar = Calendar.current
        
        // Test leap year edge case
        let leapYear = calendar.date(from: DateComponents(year: 2024, month: 2, day: 29))!
        let leapYearBlock = createSampleTimeBlock(title: "Leap Year", startHour: 10, endHour: 11, day: leapYear)
        XCTAssertNoThrow(try dataManager.addTimeBlock(leapYearBlock))
        
        // Test year boundary
        let newYearsEve = calendar.date(from: DateComponents(year: 2023, month: 12, day: 31))!
        let newYearBlock = createSampleTimeBlock(title: "New Year", startHour: 23, endHour: 24, day: newYearsEve)
        XCTAssertNoThrow(try dataManager.addTimeBlock(newYearBlock))
        
        // Test very distant future/past dates
        let distantFuture = Date().addingTimeInterval(365 * 24 * 3600 * 10) // 10 years
        let futureBlock = createSampleTimeBlock(title: "Future", startHour: 12, endHour: 13, day: distantFuture)
        XCTAssertNoThrow(try dataManager.addTimeBlock(futureBlock))
        
        let distantPast = Date().addingTimeInterval(-365 * 24 * 3600 * 10) // 10 years ago
        let pastBlock = createSampleTimeBlock(title: "Past", startHour: 14, endHour: 15, day: distantPast)
        XCTAssertNoThrow(try dataManager.addTimeBlock(pastBlock))
        
        // Verify all edge case blocks were handled correctly
        let allBlocks = try dataManager.loadAllTimeBlocks()
        XCTAssertEqual(allBlocks.count, 4)
        
        for block in allBlocks {
            XCTAssertTrue(block.isValid)
        }
    }
    
    // MARK: - Data Migration Simulation
    
    @MainActor
    func testDataMigrationSimulation() throws {
        let dataManager = DataManager(modelContext: container.mainContext)
        
        // Simulate old data format (pre-migration)
        let oldFormatBlocks = [
            createSampleTimeBlock(title: "Old Block 1", startHour: 9, endHour: 10),
            createSampleTimeBlock(title: "Old Block 2", startHour: 11, endHour: 12)
        ]
        
        for block in oldFormatBlocks {
            // Simulate old format by removing some properties
            block.notes = nil
            block.category = nil
            block.colorId = nil
            try dataManager.addTimeBlock(block)
        }
        
        // Simulate migration by updating blocks with new properties
        let migratedBlocks = try dataManager.loadAllTimeBlocks()
        for block in migratedBlocks {
            block.category = "Migrated"
            block.notes = "Updated during migration"
            try dataManager.updateTimeBlock(block)
        }
        
        // Verify migration was successful
        let postMigrationBlocks = try dataManager.loadAllTimeBlocks()
        XCTAssertEqual(postMigrationBlocks.count, 2)
        
        for block in postMigrationBlocks {
            XCTAssertEqual(block.category, "Migrated")
            XCTAssertEqual(block.notes, "Updated during migration")
            XCTAssertTrue(block.isValid)
        }
    }
    
    // MARK: - Stress Testing
    
    @MainActor
    func testStressWithConcurrentModifications() throws {
        let dataManager = DataManager(modelContext: container.mainContext)
        
        // Create initial dataset
        var stressBlocks: [TimeBlock] = []
        for i in 0..<20 {
            let block = createSampleTimeBlock(
                title: "Stress Block \(i)",
                startHour: (i % 20) + 1,
                day: Date().addingTimeInterval(TimeInterval(i * 86400))
            )
            try dataManager.addTimeBlock(block)
            stressBlocks.append(block)
        }
        
        // Perform many concurrent-like operations
        for iteration in 0..<100 {
            autoreleasepool {
                let randomBlock = stressBlocks.randomElement()!
                
                switch iteration % 4 {
                case 0:
                    // Update title
                    randomBlock.title = "Stressed \(iteration)"
                    try? dataManager.updateTimeBlock(randomBlock)
                    
                case 1:
                    // Update status
                    let statuses: [BlockStatus] = [.notStarted, .inProgress, .completed, .skipped]
                    let randomStatus = statuses.randomElement()!
                    try? dataManager.updateTimeBlockStatus(randomBlock, to: randomStatus)
                    
                case 2:
                    // Update notes
                    randomBlock.notes = "Stress test iteration \(iteration)"
                    try? dataManager.updateTimeBlock(randomBlock)
                    
                case 3:
                    // Query operations
                    let _ = try? dataManager.loadTimeBlocks(for: randomBlock.scheduledDate)
                    let _ = try? dataManager.loadTimeBlocks(withStatus: randomBlock.status)
                    
                default:
                    break
                }
                
                // Periodically update progress
                if iteration % 10 == 0 {
                    try? dataManager.updateDailyProgress(for: randomBlock.scheduledDate)
                }
            }
        }
        
        // Verify data integrity after stress test
        let finalBlocks = try dataManager.loadAllTimeBlocks()
        XCTAssertEqual(finalBlocks.count, 20)
        
        for block in finalBlocks {
            XCTAssertTrue(block.isValid)
            XCTAssertFalse(block.title.isEmpty)
        }
        
        // Verify progress consistency
        let uniqueDates = Set(finalBlocks.map { $0.scheduledDate })
        for date in uniqueDates {
            let dayBlocks = try dataManager.loadTimeBlocks(for: date)
            let progress = try dataManager.loadDailyProgress(for: date)
            
            if let progress = progress {
                XCTAssertEqual(progress.totalBlocks, dayBlocks.count)
                
                let actualCompleted = dayBlocks.filter { $0.status == .completed }.count
                let actualSkipped = dayBlocks.filter { $0.status == .skipped }.count
                let actualInProgress = dayBlocks.filter { $0.status == .inProgress }.count
                
                XCTAssertEqual(progress.completedBlocks, actualCompleted)
                XCTAssertEqual(progress.skippedBlocks, actualSkipped)
                XCTAssertEqual(progress.inProgressBlocks, actualInProgress)
            }
        }
    }
    
    // MARK: - Performance Regression Tests
    
    @MainActor
    func testPerformanceRegression() throws {
        let dataManager = DataManager(modelContext: container.mainContext)
        
        // Create baseline dataset
        for i in 0..<200 {
            let block = createSampleTimeBlock(
                title: "Perf Baseline \(i)",
                startHour: (i % 22) + 1,
                day: Date().addingTimeInterval(TimeInterval(i * 3600))
            )
            try dataManager.addTimeBlock(block)
        }
        
        // Test critical operations for performance regression
        let options = XCTMeasureOptions()
        options.iterationCount = 5
        
        // Test load all performance
        measure(metrics: [XCTClockMetric()], options: options) {
            let _ = try? dataManager.loadAllTimeBlocks()
        }
        
        // Test filtered load performance
        measure(metrics: [XCTClockMetric()], options: options) {
            let _ = try? dataManager.loadTimeBlocks(for: Date())
        }
        
        // Test status update performance
        if let randomBlock = try dataManager.loadAllTimeBlocks().randomElement() {
            measure(metrics: [XCTClockMetric()], options: options) {
                try? dataManager.updateTimeBlockStatus(randomBlock, to: .completed)
                try? dataManager.updateTimeBlockStatus(randomBlock, to: .notStarted)
            }
        }
        
        // Test progress calculation performance
        measure(metrics: [XCTClockMetric()], options: options) {
            try? dataManager.updateDailyProgress(for: Date())
        }
    }
    
    // MARK: - Bulk Operations Testing
    
    @MainActor
    func testBulkOperationsEfficiency() throws {
        let dataManager = DataManager(modelContext: container.mainContext)
        
        // Test bulk creation
        var bulkBlocks: [TimeBlock] = []
        for i in 0..<100 {
            let block = createSampleTimeBlock(
                title: "Bulk Block \(i)",
                startHour: (i % 22) + 1,
                day: Date().addingTimeInterval(TimeInterval(i * 86400 / 5))
            )
            bulkBlocks.append(block)
        }
        
        // Measure bulk creation performance
        measure(metrics: [XCTClockMetric(), XCTMemoryMetric()]) {
            for block in bulkBlocks {
                try? dataManager.addTimeBlock(block)
            }
        }
        
        // Test bulk status updates
        let createdBlocks = try dataManager.loadAllTimeBlocks()
        measure(metrics: [XCTClockMetric()]) {
            for (index, block) in createdBlocks.enumerated() {
                if index % 3 == 0 {
                    try? dataManager.markTimeBlockCompleted(block)
                }
            }
        }
        
        // Test bulk deletion
        let blocksToDelete = Array(createdBlocks.prefix(50))
        measure(metrics: [XCTClockMetric()]) {
            for block in blocksToDelete {
                try? dataManager.deleteTimeBlock(block)
            }
        }
        
        // Verify final state
        let remainingBlocks = try dataManager.loadAllTimeBlocks()
        XCTAssertEqual(remainingBlocks.count, createdBlocks.count - blocksToDelete.count)
    }
    
    // MARK: - Data Consistency Under Load
    
    @MainActor
    func testDataConsistencyUnderLoad() throws {
        let dataManager = DataManager(modelContext: container.mainContext)
        
        // Create initial balanced dataset
        let today = Date()
        let calendar = Calendar.current
        
        for i in 0..<30 {
            let date = calendar.date(byAdding: .day, value: i % 7, to: today) ?? today
            let block = createSampleTimeBlock(
                title: "Load Test \(i)",
                startHour: (i % 12) + 8,
                day: date
            )
            try dataManager.addTimeBlock(block)
        }
        
        // Perform intensive operations
        let allBlocks = try dataManager.loadAllTimeBlocks()
        
        for iteration in 0..<50 {
            autoreleasepool {
                // Random operations
                let randomBlock = allBlocks.randomElement()!
                
                switch iteration % 5 {
                case 0:
                    try? dataManager.markTimeBlockCompleted(randomBlock)
                case 1:
                    try? dataManager.markTimeBlockSkipped(randomBlock)
                case 2:
                    randomBlock.notes = "Load test \(iteration)"
                    try? dataManager.updateTimeBlock(randomBlock)
                case 3:
                    let _ = try? dataManager.loadTimeBlocks(for: randomBlock.scheduledDate)
                case 4:
                    try? dataManager.updateDailyProgress(for: randomBlock.scheduledDate)
                default:
                    break
                }
            }
        }
        
        // Verify data consistency after load test
        let finalBlocks = try dataManager.loadAllTimeBlocks()
        XCTAssertEqual(finalBlocks.count, 30)
        
        // Check that all progress records are consistent
        let uniqueDates = Set(finalBlocks.map { $0.scheduledDate })
        for date in uniqueDates {
            let dayBlocks = try dataManager.loadTimeBlocks(for: date)
            let progress = try dataManager.loadDailyProgress(for: date)
            
            let manualTotal = dayBlocks.count
            let manualCompleted = dayBlocks.filter { $0.status == .completed }.count
            let manualSkipped = dayBlocks.filter { $0.status == .skipped }.count
            let manualInProgress = dayBlocks.filter { $0.status == .inProgress }.count
            
            if let progress = progress {
                XCTAssertEqual(progress.totalBlocks, manualTotal, "Progress total mismatch for \(date)")
                XCTAssertEqual(progress.completedBlocks, manualCompleted, "Progress completed mismatch for \(date)")
                XCTAssertEqual(progress.skippedBlocks, manualSkipped, "Progress skipped mismatch for \(date)")
                XCTAssertEqual(progress.inProgressBlocks, manualInProgress, "Progress in-progress mismatch for \(date)")
            }
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
