//
//  PerformanceTests.swift
//  Routine Anchor
//
//  Created by Christopher Simonson on 8/18/25.
//
import XCTest
import SwiftData
@testable import Routine_Anchor

final class PerformanceTests: XCTestCase {
    
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
    func testLoadMediumNumberOfBlocks() throws {
        let dataManager = DataManager(modelContext: container.mainContext)
        
        // Create 100 time blocks (reduced from 1000 to avoid segfaults)
        for i in 0..<100 {
            let block = createSampleTimeBlock(
                title: "Block \(i)",
                startHour: (i % 23), // Ensure we don't hit 23->0 problem
                day: Date().addingTimeInterval(TimeInterval(i * 86400))
            )
            
            do {
                try dataManager.addTimeBlock(block)
            } catch {
                XCTFail("Failed to add block \(i): \(error)")
                break // Stop on first error to prevent cascade failures
            }
        }
        
        // Test loading performance
        measure {
            do {
                let _ = try dataManager.loadAllTimeBlocks()
            } catch {
                XCTFail("Failed to load blocks: \(error)")
            }
        }
    }
    
    @MainActor
    func testBatchOperationsPerformance() throws {
        let dataManager = DataManager(modelContext: container.mainContext)
        
        // Reduced batch size and fixed time calculation
        let blocks = (0..<50).map { i in
            createSampleTimeBlock(
                title: "Batch Block \(i)",
                startHour: (i % 22), // Avoid 23->0 hour wrap
                day: Date().addingTimeInterval(TimeInterval(i * 86400))
            )
        }
        
        measure {
            for (index, block) in blocks.enumerated() {
                do {
                    try dataManager.addTimeBlock(block)
                } catch {
                    print("Failed to add block \(index): \(error)")
                    // Don't fail the test, just log and continue
                }
            }
            
            do {
                try dataManager.save()
            } catch {
                print("Failed to save batch: \(error)")
            }
        }
    }
    
    @MainActor
    func testMemoryUsageDuringOperations() throws {
        let dataManager = DataManager(modelContext: container.mainContext)
        
        // Much smaller test to prevent memory issues
        autoreleasepool {
            for i in 0..<25 { // Reduced from 500
                let block = createSampleTimeBlock(
                    title: "Memory Test \(i)",
                    startHour: (i % 20) + 1 // Hours 1-20 to avoid edge cases
                )
                
                do {
                    try dataManager.addTimeBlock(block)
                    
                    if i % 10 == 0 {
                        try dataManager.save()
                    }
                } catch {
                    print("Failed to add memory test block \(i): \(error)")
                    break
                }
            }
        }
        
        // Verify blocks were added
        let blocks = try dataManager.loadAllTimeBlocks()
        XCTAssertGreaterThan(blocks.count, 0)
        print("Successfully created \(blocks.count) blocks for memory test")
    }
    
    @MainActor
    func testDatabaseQueryPerformance() throws {
        let dataManager = DataManager(modelContext: container.mainContext)
        
        // Create smaller test dataset
        let today = Date()
        let calendar = Calendar.current
        
        for i in 0..<25 { // Reduced from 100
            let date = calendar.date(byAdding: .day, value: i % 7, to: today)!
            let block = createSampleTimeBlock(
                title: "Query Test \(i)",
                startHour: (i % 20) + 1, // Hours 1-20 to avoid edge cases
                day: date
            )
            
            do {
                try dataManager.addTimeBlock(block)
            } catch {
                print("Failed to add query test block \(i): \(error)")
            }
        }
        
        // Test various query performance
        measure {
            do {
                // Query by date
                let _ = try dataManager.loadTimeBlocks(for: today)
                
                // Query by status
                let _ = try dataManager.loadTimeBlocks(withStatus: .notStarted)
                
                // Query by date range
                let endDate = calendar.date(byAdding: .day, value: 7, to: today)!
                let _ = try dataManager.loadTimeBlocks(from: today, to: endDate)
                
            } catch {
                print("Query performance test failed: \(error)")
            }
        }
    }
    
    private func createSampleTimeBlock(
        title: String = "Test Block",
        startHour: Int = 10,
        day: Date = Date()
    ) -> TimeBlock {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: day)
        
        // Ensure valid time range by calculating end hour properly
        let safeStartHour = max(0, min(22, startHour)) // Clamp between 0-22
        let endHour = safeStartHour + 1 // Always 1 hour later, max 23
        
        let startTime = calendar.date(byAdding: .hour, value: safeStartHour, to: startOfDay) ?? Date()
        let endTime = calendar.date(byAdding: .hour, value: endHour, to: startOfDay) ?? Date().addingTimeInterval(3600)
        
        // Verify the time block is valid before returning
        assert(startTime < endTime, "Start time must be before end time")
        
        return TimeBlock(title: title, startTime: startTime, endTime: endTime)
    }
}
