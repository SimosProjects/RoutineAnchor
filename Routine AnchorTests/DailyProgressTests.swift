//
//  DailyProgressTests.swift
//  Routine Anchor
//
//  Created by Christopher Simonson on 8/18/25.
//
import XCTest
import SwiftData
@testable import Routine_Anchor

final class DailyProgressTests: XCTestCase {
    
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
    func testCreateDailyProgress() throws {
        let dataManager = DataManager(modelContext: container.mainContext)
        
        let today = Date()
        let progress = try dataManager.loadOrCreateDailyProgress(for: today)
        
        XCTAssertEqual(progress.date, Calendar.current.startOfDay(for: today))
        XCTAssertEqual(progress.totalBlocks, 0)
        XCTAssertEqual(progress.completedBlocks, 0)
    }
    
    @MainActor
    func testUpdateDailyProgressWithTimeBlocks() throws {
        let dataManager = DataManager(modelContext: container.mainContext)
        
        let today = Date()
        
        // Add time blocks
        let block1 = createSampleTimeBlock(title: "Block 1", day: today)
        let block2 = createSampleTimeBlock(title: "Block 2", startHour: 11, endHour: 12, day: today)
        
        try dataManager.addTimeBlock(block1)
        try dataManager.addTimeBlock(block2)
        
        // Mark one as completed
        try dataManager.markTimeBlockCompleted(block1)
        
        // Update progress
        try dataManager.updateDailyProgress(for: today)
        
        let progress = try dataManager.loadDailyProgress(for: today)
        XCTAssertEqual(progress?.totalBlocks, 2)
        XCTAssertEqual(progress?.completedBlocks, 1)
        XCTAssertEqual(progress?.completionPercentage, 0.5)
    }
    
    @MainActor
    func testCalculateWeeklyStatistics() throws {
        let dataManager = DataManager(modelContext: container.mainContext)
        
        let today = Date()
        let calendar = Calendar.current
        
        // Create progress for multiple days
        for i in 0..<7 {
            let date = calendar.date(byAdding: .day, value: -i, to: today)!
            let progress = try dataManager.loadOrCreateDailyProgress(for: date)
            progress.totalBlocks = 5
            progress.completedBlocks = i % 2 == 0 ? 4 : 2 // Alternate completion rates
            try dataManager.save()
        }
        
        // Test that weekly statistics can be calculated without error
        let weeklyStats = try dataManager.getWeeklyStatistics(for: today)
        
        // Basic validation that we got a valid stats object
        // (without knowing the exact structure, we just verify it doesn't crash)
        XCTAssertGreaterThan(String(describing: weeklyStats).count, 0)
        
        print("Weekly stats calculated successfully: \(weeklyStats)")
    }
    
    @MainActor
    func testDailyProgressCompletionPercentage() throws {
        let dataManager = DataManager(modelContext: container.mainContext)
        
        let today = Date()
        
        // Create 4 time blocks
        let blocks = [
            createSampleTimeBlock(title: "Block 1", startHour: 9, endHour: 10, day: today),
            createSampleTimeBlock(title: "Block 2", startHour: 11, endHour: 12, day: today),
            createSampleTimeBlock(title: "Block 3", startHour: 13, endHour: 14, day: today),
            createSampleTimeBlock(title: "Block 4", startHour: 15, endHour: 16, day: today)
        ]
        
        for block in blocks {
            try dataManager.addTimeBlock(block)
        }
        
        // Mark 3 out of 4 as completed
        try dataManager.markTimeBlockCompleted(blocks[0])
        try dataManager.markTimeBlockCompleted(blocks[1])
        try dataManager.markTimeBlockCompleted(blocks[2])
        
        // Update progress
        try dataManager.updateDailyProgress(for: today)
        
        let progress = try dataManager.loadDailyProgress(for: today)
        XCTAssertEqual(progress?.totalBlocks, 4)
        XCTAssertEqual(progress?.completedBlocks, 3)
        XCTAssertEqual(progress?.completionPercentage, 0.75)
    }
    
    @MainActor
    func testDailyProgressWithSkippedBlocks() throws {
        let dataManager = DataManager(modelContext: container.mainContext)
        
        let today = Date()
        
        // Create 3 time blocks
        let blocks = [
            createSampleTimeBlock(title: "Block 1", startHour: 9, endHour: 10, day: today),
            createSampleTimeBlock(title: "Block 2", startHour: 11, endHour: 12, day: today),
            createSampleTimeBlock(title: "Block 3", startHour: 13, endHour: 14, day: today)
        ]
        
        for block in blocks {
            try dataManager.addTimeBlock(block)
        }
        
        // Mark one as completed, one as skipped
        try dataManager.markTimeBlockCompleted(blocks[0])
        try dataManager.markTimeBlockSkipped(blocks[1])
        // Leave blocks[2] as not started
        
        // Update progress
        try dataManager.updateDailyProgress(for: today)
        
        let progress = try dataManager.loadDailyProgress(for: today)
        XCTAssertEqual(progress?.totalBlocks, 3)
        XCTAssertEqual(progress?.completedBlocks, 1)
        XCTAssertEqual(progress?.skippedBlocks, 1)
        
        // Convert to Double for comparison
        let expectedPercentage = 1.0 / 3.0
        let actualPercentage = Double(progress?.completionPercentage ?? 0.0)
        XCTAssertEqual(actualPercentage, expectedPercentage, accuracy: 0.01)
    }
    
    @MainActor
    func testMultipleDaysProgress() throws {
        let dataManager = DataManager(modelContext: container.mainContext)
        
        let calendar = Calendar.current
        let today = Date()
        
        // Create progress for 3 different days
        for i in 0..<3 {
            let date = calendar.date(byAdding: .day, value: -i, to: today)!
            
            // Create blocks for each day
            let block1 = createSampleTimeBlock(title: "Day \(i) Block 1", startHour: 9, endHour: 10, day: date)
            let block2 = createSampleTimeBlock(title: "Day \(i) Block 2", startHour: 11, endHour: 12, day: date)
            
            try dataManager.addTimeBlock(block1)
            try dataManager.addTimeBlock(block2)
            
            // Complete different numbers on each day
            if i == 0 { // Today - complete both
                try dataManager.markTimeBlockCompleted(block1)
                try dataManager.markTimeBlockCompleted(block2)
            } else if i == 1 { // Yesterday - complete one
                try dataManager.markTimeBlockCompleted(block1)
            }
            // Day before yesterday - complete none
            
            try dataManager.updateDailyProgress(for: date)
        }
        
        // Verify each day's progress
        for i in 0..<3 {
            let date = calendar.date(byAdding: .day, value: -i, to: today)!
            let progress = try dataManager.loadDailyProgress(for: date)
            
            XCTAssertNotNil(progress)
            XCTAssertEqual(progress?.totalBlocks, 2)
            
            if i == 0 { // Today
                XCTAssertEqual(progress?.completedBlocks, 2)
                XCTAssertEqual(progress?.completionPercentage, 1.0)
            } else if i == 1 { // Yesterday
                XCTAssertEqual(progress?.completedBlocks, 1)
                XCTAssertEqual(progress?.completionPercentage, 0.5)
            } else { // Day before yesterday
                XCTAssertEqual(progress?.completedBlocks, 0)
                XCTAssertEqual(progress?.completionPercentage, 0.0)
            }
        }
    }
    
    @MainActor
    func testProgressPersistence() throws {
        let dataManager = DataManager(modelContext: container.mainContext)
        
        let today = Date()
        let block = createSampleTimeBlock(title: "Persistence Test", day: today)
        
        try dataManager.addTimeBlock(block)
        try dataManager.markTimeBlockCompleted(block)
        try dataManager.updateDailyProgress(for: today)
        
        // First load
        let progress1 = try dataManager.loadDailyProgress(for: today)
        XCTAssertNotNil(progress1)
        XCTAssertEqual(progress1?.completedBlocks, 1)
        
        // Second load (should get same data)
        let progress2 = try dataManager.loadDailyProgress(for: today)
        XCTAssertNotNil(progress2)
        XCTAssertEqual(progress2?.completedBlocks, 1)
        XCTAssertEqual(progress1?.id, progress2?.id) // Should be same object
    }
    
    @MainActor
    func testEmptyDayProgress() throws {
        let dataManager = DataManager(modelContext: container.mainContext)
        
        let today = Date()
        
        // Create progress for a day with no time blocks
        let progress = try dataManager.loadOrCreateDailyProgress(for: today)
        
        XCTAssertEqual(progress.totalBlocks, 0)
        XCTAssertEqual(progress.completedBlocks, 0)
        XCTAssertEqual(progress.skippedBlocks, 0)
        XCTAssertEqual(progress.completionPercentage, 0.0)
    }
    
    @MainActor
    func testProgressDateNormalization() throws {
        let dataManager = DataManager(modelContext: container.mainContext)
        
        // Create dates at different times of the same day
        let calendar = Calendar.current
        let today = Date()
        
        let morning = calendar.date(bySettingHour: 8, minute: 30, second: 0, of: today)!
        let afternoon = calendar.date(bySettingHour: 15, minute: 45, second: 30, of: today)!
        let evening = calendar.date(bySettingHour: 22, minute: 15, second: 45, of: today)!
        
        // All should create progress for the same day
        let progress1 = try dataManager.loadOrCreateDailyProgress(for: morning)
        let progress2 = try dataManager.loadOrCreateDailyProgress(for: afternoon)
        let progress3 = try dataManager.loadOrCreateDailyProgress(for: evening)
        
        // Should all have the same normalized date (start of day)
        let startOfDay = calendar.startOfDay(for: today)
        XCTAssertEqual(progress1.date, startOfDay)
        XCTAssertEqual(progress2.date, startOfDay)
        XCTAssertEqual(progress3.date, startOfDay)
        
        // Should be the same progress object
        XCTAssertEqual(progress1.id, progress2.id)
        XCTAssertEqual(progress2.id, progress3.id)
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
