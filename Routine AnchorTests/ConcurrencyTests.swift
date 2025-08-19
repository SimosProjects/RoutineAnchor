//
//  ConcurrencyTests.swift
//  Routine AnchorTests
//
//  Testing concurrent operations and thread safety
//
import XCTest
import SwiftData
@testable import Routine_Anchor

final class ConcurrencyTests: XCTestCase {
    
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
    
    // MARK: - Concurrent Data Access
    
    @MainActor
    func testConcurrentTimeBlockCreation() async throws {
        let dataManager = DataManager(modelContext: container.mainContext)
        
        // Create multiple time blocks concurrently
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<10 {
                group.addTask { @MainActor in
                    let block = self.createSampleTimeBlock(
                        title: "Concurrent Block \(i)",
                        startHour: (i % 22) + 1,
                        day: Date().addingTimeInterval(TimeInterval(i * 86400))
                    )
                    
                    do {
                        try dataManager.addTimeBlock(block)
                    } catch {
                        // Some may fail due to conflicts - that's expected
                        print("Block \(i) failed: \(error)")
                    }
                }
            }
        }
        
        // Verify some blocks were created
        let blocks = try dataManager.loadAllTimeBlocks()
        XCTAssertGreaterThan(blocks.count, 5, "Should create most blocks without corruption")
        
        // Verify data integrity
        for block in blocks {
            XCTAssertTrue(block.isValid)
            XCTAssertFalse(block.title.isEmpty)
        }
    }
    
    @MainActor
    func testConcurrentStatusUpdates() async throws {
        let dataManager = DataManager(modelContext: container.mainContext)
        
        // Create test blocks
        var blocks: [TimeBlock] = []
        for i in 0..<5 {
            let block = createSampleTimeBlock(
                title: "Status Test \(i)",
                startHour: (i * 2) + 9,
                endHour: (i * 2) + 10
            )
            try dataManager.addTimeBlock(block)
            blocks.append(block)
        }
        
        // Update statuses concurrently
        await withTaskGroup(of: Void.self) { group in
            for (index, block) in blocks.enumerated() {
                group.addTask { @MainActor in
                    do {
                        switch index % 3 {
                        case 0:
                            try dataManager.markTimeBlockCompleted(block)
                        case 1:
                            try dataManager.markTimeBlockSkipped(block)
                        default:
                            try dataManager.startTimeBlock(block)
                        }
                    } catch {
                        print("Status update failed for block \(index): \(error)")
                    }
                }
            }
        }
        
        // Verify status updates completed
        let updatedBlocks = try dataManager.loadAllTimeBlocks()
        let statusChangedCount = updatedBlocks.filter { $0.status != .notStarted }.count
        XCTAssertGreaterThan(statusChangedCount, 3, "Most status updates should succeed")
    }
    
    // MARK: - Progress Calculation Concurrency
    
    @MainActor
    func testConcurrentProgressUpdates() async throws {
        let dataManager = DataManager(modelContext: container.mainContext)
        let testDate = Date()
        
        // Create blocks for the same day
        var blocks: [TimeBlock] = []
        for i in 0..<8 {
            let block = createSampleTimeBlock(
                title: "Progress Test \(i)",
                startHour: (i + 8),
                endHour: (i + 9),
                day: testDate
            )
            try dataManager.addTimeBlock(block)
            blocks.append(block)
        }
        
        // Update progress concurrently from multiple tasks
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<4 {
                group.addTask { @MainActor in
                    do {
                        // Each task updates different blocks and triggers progress update
                        let startIndex = i * 2
                        let endIndex = min(startIndex + 2, blocks.count)
                        
                        for j in startIndex..<endIndex {
                            try dataManager.markTimeBlockCompleted(blocks[j])
                        }
                        
                        try dataManager.updateDailyProgress(for: testDate)
                    } catch {
                        print("Progress update failed in task \(i): \(error)")
                    }
                }
            }
        }
        
        // Verify final progress state
        let progress = try dataManager.loadDailyProgress(for: testDate)
        XCTAssertNotNil(progress)
        XCTAssertEqual(progress?.totalBlocks, 8)
        XCTAssertGreaterThan(progress?.completedBlocks ?? 0, 6, "Most blocks should be completed")
    }
    
    // MARK: - Memory Safety
    
    @MainActor
    func testConcurrentMemoryAccess() async throws {
        let dataManager = DataManager(modelContext: container.mainContext)
        
        // Test concurrent read/write operations
        let block = createSampleTimeBlock(title: "Memory Test")
        try dataManager.addTimeBlock(block)
        
        await withTaskGroup(of: Void.self) { group in
            // Reading tasks
            for i in 0..<5 {
                group.addTask { @MainActor in
                    do {
                        let _ = try dataManager.loadAllTimeBlocks()
                        let _ = try dataManager.loadTimeBlocks(for: Date())
                    } catch {
                        print("Read task \(i) failed: \(error)")
                    }
                }
            }
            
            // Writing tasks
            for i in 0..<3 {
                group.addTask { @MainActor in
                    do {
                        block.notes = "Updated by task \(i) at \(Date())"
                        try dataManager.updateTimeBlock(block)
                    } catch {
                        print("Write task \(i) failed: \(error)")
                    }
                }
            }
        }
        
        // Verify data integrity after concurrent access
        let updatedBlock = try dataManager.loadAllTimeBlocks().first!
        XCTAssertEqual(updatedBlock.id, block.id)
        XCTAssertTrue(updatedBlock.isValid)
        XCTAssertNotNil(updatedBlock.notes)
    }
    
    // MARK: - Actor Isolation Testing
    
    @MainActor
    func testMainActorIsolation() async throws {
        let dataManager = DataManager(modelContext: container.mainContext)
        
        // Verify all operations respect @MainActor
        let block = createSampleTimeBlock()
        
        // These should all execute on MainActor
        try dataManager.addTimeBlock(block)
        try dataManager.markTimeBlockCompleted(block)
        try dataManager.updateDailyProgress(for: Date())
        
        // Verify operations completed successfully
        let loadedBlocks = try dataManager.loadAllTimeBlocks()
        XCTAssertEqual(loadedBlocks.count, 1)
        XCTAssertEqual(loadedBlocks.first?.status, .completed)
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
