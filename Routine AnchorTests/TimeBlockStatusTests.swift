//
//  TimeBlockStatusTests.swift
//  Routine Anchor
//
//  Created by Christopher Simonson on 8/18/25.
//
import XCTest
import SwiftData
@testable import Routine_Anchor

final class TimeBlockStatusTests: XCTestCase {
    
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
    func testMarkAsCompleted() throws {
        let dataManager = DataManager(modelContext: container.mainContext)
        let block = createSampleTimeBlock()
        try dataManager.addTimeBlock(block)
        
        try dataManager.markTimeBlockCompleted(block)
        
        XCTAssertEqual(block.status, .completed)
    }
    
    @MainActor
    func testMarkAsSkipped() throws {
        let dataManager = DataManager(modelContext: container.mainContext)
        let block = createSampleTimeBlock()
        try dataManager.addTimeBlock(block)
        
        try dataManager.markTimeBlockSkipped(block)
        
        XCTAssertEqual(block.status, .skipped)
    }
    
    @MainActor
    func testStartTimeBlock() throws {
        let dataManager = DataManager(modelContext: container.mainContext)
        let block = createSampleTimeBlock()
        try dataManager.addTimeBlock(block)
        
        try dataManager.startTimeBlock(block)
        
        XCTAssertEqual(block.status, .inProgress)
    }
    
    func testStatusTransitionValidation() {
        let block = createSampleTimeBlock()
        block.status = .completed
        
        // Can't transition from completed to notStarted directly
        XCTAssertFalse(block.status.availableTransitions.contains(.notStarted))
    }
    
    @MainActor
    func testAutoUpdateStatusBasedOnTime() throws {
        let dataManager = DataManager(modelContext: container.mainContext)
        
        // Test with a completely past block that was never started
        let pastStartTime = Date().addingTimeInterval(-7200) // 2 hours ago
        let pastEndTime = pastStartTime.addingTimeInterval(1800) // Ended 1.5 hours ago
        
        let pastBlock = TimeBlock(
            title: "Past Block",
            startTime: pastStartTime,
            endTime: pastEndTime
        )
        
        try dataManager.addTimeBlock(pastBlock)
        try dataManager.updateTimeBlocksBasedOnCurrentTime()
        
        // Past blocks that were never started typically remain .notStarted
        XCTAssertEqual(pastBlock.status, .notStarted)
    }
    
    private func createSampleTimeBlock() -> TimeBlock {
        return TimeBlock(
            title: "Test Block",
            startTime: Date(),
            endTime: Date().addingTimeInterval(3600)
        )
    }
}
