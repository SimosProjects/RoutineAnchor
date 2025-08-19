//
//  EdgeCaseTests.swift
//  Routine Anchor
//
//  Created by Christopher Simonson on 8/18/25.
//
import XCTest
import SwiftData
@testable import Routine_Anchor

final class EdgeCaseTests: XCTestCase {
    
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
    func testDaylightSavingTimeTransitions() throws {
        let dataManager = DataManager(modelContext: container.mainContext)
        let timeZone = TimeZone(identifier: "America/New_York")!
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        
        // Spring forward date (2024-03-10)
        let springForward = DateComponents(
            calendar: calendar,
            timeZone: timeZone,
            year: 2024,
            month: 3,
            day: 10,
            hour: 1,
            minute: 30
        ).date!
        
        let block = TimeBlock(
            title: "DST Test",
            startTime: springForward,
            endTime: springForward.addingTimeInterval(7200) // 2 hours
        )
        
        XCTAssertTrue(block.isValid)
        XCTAssertGreaterThan(block.durationMinutes, 0)
        
        // Should be able to add DST blocks without issues
        XCTAssertNoThrow(try dataManager.addTimeBlock(block))
    }
    
    @MainActor
    func testLeapYearHandling() throws {
        let dataManager = DataManager(modelContext: container.mainContext)
        let calendar = Calendar.current
        
        // February 29, 2024 (leap year)
        let leapDay = DateComponents(
            calendar: calendar,
            year: 2024,
            month: 2,
            day: 29,
            hour: 10
        ).date!
        
        let block = createSampleTimeBlock(title: "Leap Day Block", day: leapDay)
        
        XCTAssertTrue(block.isValid)
        XCTAssertEqual(calendar.component(.day, from: block.startTime), 29)
        
        XCTAssertNoThrow(try dataManager.addTimeBlock(block))
    }
    
    @MainActor
    func testYearBoundaryTransitions() throws {
        let dataManager = DataManager(modelContext: container.mainContext)
        let calendar = Calendar.current
        
        // December 31, 11:30 PM
        let yearEnd = DateComponents(
            calendar: calendar,
            year: 2024,
            month: 12,
            day: 31,
            hour: 23,
            minute: 30
        ).date!
        
        let block = TimeBlock(
            title: "Year Boundary",
            startTime: yearEnd,
            endTime: yearEnd.addingTimeInterval(3600) // Crosses into new year
        )
        
        XCTAssertTrue(block.isValid)
        XCTAssertEqual(calendar.component(.year, from: block.endTime), 2025)
        
        XCTAssertNoThrow(try dataManager.addTimeBlock(block))
    }
    
    func testUnicodeAndEmojiInTitles() {
        let unicodeTitle = "🏃‍♂️ Morning Run 中文 العربية 🌅"
        
        let block = TimeBlock(
            title: unicodeTitle,
            startTime: Date(),
            endTime: Date().addingTimeInterval(3600)
        )
        
        XCTAssertTrue(block.isValid)
        XCTAssertEqual(block.title, unicodeTitle)
    }
    
    @MainActor
    func testTimeZoneBoundaryConditions() throws {
        let dataManager = DataManager(modelContext: container.mainContext)
        
        // Test with UTC
        var calendar = Calendar.current
        calendar.timeZone = TimeZone(identifier: "UTC")!
        
        let utcTime = Date()
        let block = TimeBlock(
            title: "UTC Test",
            startTime: utcTime,
            endTime: utcTime.addingTimeInterval(3600)
        )
        
        XCTAssertNoThrow(try dataManager.addTimeBlock(block))
        
        // Verify we can query by date even with different time zones
        let blocks = try dataManager.loadTimeBlocks(for: utcTime)
        XCTAssertGreaterThanOrEqual(blocks.count, 1)
    }
    
    func testExtremelyLongTitles() {
        let longTitle = String(repeating: "Very Long Title ", count: 100) // ~1600 characters
        
        let block = TimeBlock(
            title: longTitle,
            startTime: Date(),
            endTime: Date().addingTimeInterval(3600)
        )
        
        // Should fail validation for being too long
        XCTAssertFalse(block.isValid)
    }
    
    func testMinimumDurationBlocks() {
        // Test with exactly 1 minute duration (minimum allowed)
        let startTime = Date()
        let endTime = startTime.addingTimeInterval(60) // Exactly 1 minute
        
        let block = TimeBlock(
            title: "Minimum Duration",
            startTime: startTime,
            endTime: endTime
        )
        
        XCTAssertTrue(block.isValid)
        XCTAssertEqual(block.durationMinutes, 1)
    }
    
    func testMaximumDurationBlocks() {
        // Test with 24 hour duration (maximum reasonable)
        let startTime = Date()
        let endTime = startTime.addingTimeInterval(86400) // 24 hours
        
        let block = TimeBlock(
            title: "Maximum Duration",
            startTime: startTime,
            endTime: endTime
        )
        
        // This might be invalid depending on your business rules
        // Adjust based on your actual maximum duration limits
        XCTAssertEqual(block.durationMinutes, 1440) // 24 hours = 1440 minutes
    }
    
    @MainActor
    func testMidnightTransitions() throws {
        let dataManager = DataManager(modelContext: container.mainContext)
        let calendar = Calendar.current
        
        // Block that starts before midnight and ends after
        let today = Date()
        let nearMidnight = calendar.date(bySettingHour: 23, minute: 45, second: 0, of: today)!
        
        let block = TimeBlock(
            title: "Midnight Transition",
            startTime: nearMidnight,
            endTime: nearMidnight.addingTimeInterval(1800) // 30 minutes, crosses midnight
        )
        
        XCTAssertTrue(block.isValid)
        XCTAssertEqual(block.durationMinutes, 30)
        
        // Should handle midnight transitions properly
        XCTAssertNotEqual(
            calendar.component(.day, from: block.startTime),
            calendar.component(.day, from: block.endTime)
        )
        
        XCTAssertNoThrow(try dataManager.addTimeBlock(block))
    }
    
    func testSpecialCharactersInTitles() {
        let specialCharacters = "!@#$%^&*()_+-=[]{}|;':\",./<>?"
        
        let block = TimeBlock(
            title: "Special Characters: \(specialCharacters)",
            startTime: Date(),
            endTime: Date().addingTimeInterval(3600)
        )
        
        XCTAssertTrue(block.isValid)
        XCTAssertTrue(block.title.contains(specialCharacters))
    }
    
    func testEmptyAndWhitespaceHandling() {
        // Test empty title
        let emptyBlock = TimeBlock(
            title: "",
            startTime: Date(),
            endTime: Date().addingTimeInterval(3600)
        )
        XCTAssertFalse(emptyBlock.isValid)
        
        // Test whitespace-only title
        let whitespaceBlock = TimeBlock(
            title: "   \n\t  ",
            startTime: Date(),
            endTime: Date().addingTimeInterval(3600)
        )
        XCTAssertFalse(whitespaceBlock.isValid)
        
        // Test title with leading/trailing whitespace
        let trimBlock = TimeBlock(
            title: "  Valid Title  ",
            startTime: Date(),
            endTime: Date().addingTimeInterval(3600)
        )
        XCTAssertTrue(trimBlock.isValid)
    }
    
    private func createSampleTimeBlock(title: String, day: Date) -> TimeBlock {
        let calendar = Calendar.current
        let startTime = calendar.date(byAdding: .hour, value: 10, to: calendar.startOfDay(for: day)) ?? Date()
        let endTime = startTime.addingTimeInterval(3600)
        
        return TimeBlock(title: title, startTime: startTime, endTime: endTime)
    }
}
