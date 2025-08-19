//
//  ConflictDetectionTests..swift
//  Routine Anchor
//
//  Created by Christopher Simonson on 8/18/25.
//
import XCTest
import SwiftData
@testable import Routine_Anchor

final class ConflictDetectionTests: XCTestCase {
    
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
    func testDetectOverlappingBlocks() throws {
        let dataManager = DataManager(modelContext: container.mainContext)
        let block1 = createSampleTimeBlock(title: "Block 1", startHour: 10, endHour: 11)
        let block2 = createSampleTimeBlock(title: "Block 2", startHour: 10, endHour: 11)
        
        try dataManager.addTimeBlock(block1)
        
        XCTAssertThrowsError(try dataManager.addTimeBlock(block2)) { error in
            XCTAssertTrue(error is DataManagerError)
            if case .conflictDetected = error as? DataManagerError {
                // Expected
            } else {
                XCTFail("Expected conflict error, got: \(error)")
            }
        }
    }
    
    @MainActor
    func testAllowNonOverlappingBlocks() throws {
        let dataManager = DataManager(modelContext: container.mainContext)
        let block1 = createSampleTimeBlock(title: "Block 1", startHour: 10, endHour: 11)
        let block2 = createSampleTimeBlock(title: "Block 2", startHour: 11, endHour: 12)
        
        try dataManager.addTimeBlock(block1)
        try dataManager.addTimeBlock(block2)
        
        let allBlocks = try dataManager.loadAllTimeBlocks()
        XCTAssertEqual(allBlocks.count, 2)
    }
    
    @MainActor
    func testDetectPartialOverlap() throws {
        let dataManager = DataManager(modelContext: container.mainContext)
        let block1 = createSampleTimeBlock(title: "Block 1", startHour: 10, endHour: 12)
        let block2 = createSampleTimeBlock(title: "Block 2", startHour: 11, endHour: 13)
        
        try dataManager.addTimeBlock(block1)
        
        XCTAssertThrowsError(try dataManager.addTimeBlock(block2)) { error in
            XCTAssertTrue(error is DataManagerError)
        }
    }
    
    @MainActor
    func testAllowSameBlockUpdate() throws {
        let dataManager = DataManager(modelContext: container.mainContext)
        let block = createSampleTimeBlock(title: "Block 1", startHour: 10, endHour: 11)
        try dataManager.addTimeBlock(block)
        
        // Update same block - should not conflict with itself
        block.title = "Updated Block"
        XCTAssertNoThrow(try dataManager.updateTimeBlock(block))
        XCTAssertEqual(block.title, "Updated Block")
    }
    
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
