//
//  TimeBlockCRUDTests.swift
//  Routine Anchor
//
//  Created by Christopher Simonson on 8/18/25.
//
import XCTest
import SwiftData
@testable import Routine_Anchor

final class TimeBlockCRUDTests: XCTestCase {
    
    var container: ModelContainer!
    
    override func setUp() {
        super.setUp()
        
        let schema = Schema([
            TimeBlock.self,
            DailyProgress.self
        ])
        
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true,
            allowsSave: true
        )
        
        do {
            container = try ModelContainer(
                for: schema,
                configurations: [configuration]
            )
        } catch {
            XCTFail("Failed to create test container: \(error)")
        }
    }
    
    override func tearDown() {
        container = nil
        super.tearDown()
    }
    
    @MainActor
    func testCreateValidTimeBlock() throws {
        let dataManager = DataManager(modelContext: container.mainContext)
        let block = createSampleTimeBlock(title: "Morning Workout")
        try dataManager.addTimeBlock(block)
        
        let allBlocks = try dataManager.loadAllTimeBlocks()
        XCTAssertEqual(allBlocks.count, 1)
        XCTAssertEqual(allBlocks.first?.title, "Morning Workout")
    }
    
    @MainActor
    func testCreateInvalidTimeBlock() throws {
        let dataManager = DataManager(modelContext: container.mainContext)
        
        // Empty title should fail
        let invalidBlock = TimeBlock(
            title: "",
            startTime: Date(),
            endTime: Date().addingTimeInterval(3600)
        )
        
        XCTAssertThrowsError(try dataManager.addTimeBlock(invalidBlock)) { error in
            XCTAssertTrue(error is DataManagerError)
            if case .validationFailed = error as? DataManagerError {
                // Expected error type
            } else {
                XCTFail("Expected validation error, got: \(error)")
            }
        }
    }
    
    @MainActor
    func testUpdateTimeBlock() throws {
        let dataManager = DataManager(modelContext: container.mainContext)
        let block = createSampleTimeBlock(title: "Original Title")
        try dataManager.addTimeBlock(block)
        
        block.title = "Updated Title"
        try dataManager.updateTimeBlock(block)
        
        let allBlocks = try dataManager.loadAllTimeBlocks()
        XCTAssertEqual(allBlocks.first?.title, "Updated Title")
    }
    
    @MainActor
    func testDeleteTimeBlock() throws {
        let dataManager = DataManager(modelContext: container.mainContext)
        let block = createSampleTimeBlock()
        try dataManager.addTimeBlock(block)
        
        try dataManager.deleteTimeBlock(block)
        
        let allBlocks = try dataManager.loadAllTimeBlocks()
        XCTAssertTrue(allBlocks.isEmpty)
    }
    
    @MainActor
    func testLoadTimeBlocksForSpecificDate() throws {
        let dataManager = DataManager(modelContext: container.mainContext)
        let today = Date()
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        
        let todayBlock = createSampleTimeBlock(title: "Today", day: today)
        let tomorrowBlock = createSampleTimeBlock(title: "Tomorrow", day: tomorrow)
        
        try dataManager.addTimeBlock(todayBlock)
        try dataManager.addTimeBlock(tomorrowBlock)
        
        let todayBlocks = try dataManager.loadTimeBlocks(for: today)
        XCTAssertEqual(todayBlocks.count, 1)
        XCTAssertEqual(todayBlocks.first?.title, "Today")
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
        
        let startTime = calendar.date(
            byAdding: .hour,
            value: startHour,
            to: startOfDay
        ) ?? Date()
        
        let endTime = calendar.date(
            byAdding: .hour,
            value: endHour,
            to: startOfDay
        ) ?? Date().addingTimeInterval(3600)
        
        return TimeBlock(
            title: title,
            startTime: startTime,
            endTime: endTime
        )
    }
}
