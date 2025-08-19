//
//  TimeBlockValidationTests.swift
//  Routine AnchorTests
//
//  Comprehensive validation testing for TimeBlock model
//
import XCTest
import SwiftData
@testable import Routine_Anchor

final class TimeBlockValidationTests: XCTestCase {
    
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
    
    // MARK: - Title Validation
    
    func testTitleValidation() {
        // Empty title
        let emptyBlock = TimeBlock(title: "", startTime: Date(), endTime: Date().addingTimeInterval(3600))
        XCTAssertFalse(emptyBlock.isValid)
        XCTAssertTrue(emptyBlock.validationErrors.contains { $0.contains("title") || $0.contains("empty") })
        
        // Whitespace only title
        let whitespaceBlock = TimeBlock(title: "   ", startTime: Date(), endTime: Date().addingTimeInterval(3600))
        XCTAssertFalse(whitespaceBlock.isValid)
        
        // Title too long
        let longTitle = String(repeating: "a", count: 150)
        let longTitleBlock = TimeBlock(title: longTitle, startTime: Date(), endTime: Date().addingTimeInterval(3600))
        XCTAssertFalse(longTitleBlock.isValid)
        XCTAssertTrue(longTitleBlock.validationErrors.contains { $0.contains("long") })
        
        // Valid title
        let validBlock = TimeBlock(title: "Valid Title", startTime: Date(), endTime: Date().addingTimeInterval(3600))
        XCTAssertTrue(validBlock.isValid)
        XCTAssertTrue(validBlock.validationErrors.isEmpty)
    }
    
    // MARK: - Time Validation
    
    func testTimeRangeValidation() {
        let now = Date()
        
        // End time before start time
        let invalidTimeBlock = TimeBlock(title: "Invalid", startTime: now, endTime: now.addingTimeInterval(-3600))
        XCTAssertFalse(invalidTimeBlock.isValid)
        
        // Same start and end time
        let sameTimeBlock = TimeBlock(title: "Same Time", startTime: now, endTime: now)
        XCTAssertFalse(sameTimeBlock.isValid)
        
        // Too short duration (< 1 minute)
        let tooShortBlock = TimeBlock(title: "Too Short", startTime: now, endTime: now.addingTimeInterval(30))
        XCTAssertFalse(tooShortBlock.isValid)
        
        // Too long duration (> 24 hours)
        let tooLongBlock = TimeBlock(title: "Too Long", startTime: now, endTime: now.addingTimeInterval(86401))
        XCTAssertFalse(tooLongBlock.isValid)
        
        // Valid duration
        let validBlock = TimeBlock(title: "Valid", startTime: now, endTime: now.addingTimeInterval(3600))
        XCTAssertTrue(validBlock.isValid)
    }
    
    // MARK: - Notes and Category Validation
    
    func testNotesValidation() {
        let now = Date()
        
        // Notes too long
        let longNotes = String(repeating: "n", count: 600)
        let longNotesBlock = TimeBlock(title: "Test", startTime: now, endTime: now.addingTimeInterval(3600), notes: longNotes)
        XCTAssertFalse(longNotesBlock.isValid)
        
        // Valid notes
        let validNotesBlock = TimeBlock(title: "Test", startTime: now, endTime: now.addingTimeInterval(3600), notes: "Valid notes")
        XCTAssertTrue(validNotesBlock.isValid)
    }
    
    func testCategoryValidation() {
        let now = Date()
        
        // Category too long
        let longCategory = String(repeating: "c", count: 60)
        let longCategoryBlock = TimeBlock(title: "Test", startTime: now, endTime: now.addingTimeInterval(3600), category: longCategory)
        XCTAssertFalse(longCategoryBlock.isValid)
        
        // Valid category
        let validCategoryBlock = TimeBlock(title: "Test", startTime: now, endTime: now.addingTimeInterval(3600), category: "Work")
        XCTAssertTrue(validCategoryBlock.isValid)
    }
    
    // MARK: - Edge Cases
    
    func testMidnightBoundaryValidation() {
        let calendar = Calendar.current
        let today = Date()
        let midnight = calendar.startOfDay(for: today)
        
        // Block ending at midnight (valid)
        let endMidnightBlock = TimeBlock(
            title: "End at Midnight",
            startTime: midnight.addingTimeInterval(-3600),
            endTime: midnight
        )
        XCTAssertTrue(endMidnightBlock.isValid)
        
        // Block starting at midnight (valid)
        let startMidnightBlock = TimeBlock(
            title: "Start at Midnight",
            startTime: midnight,
            endTime: midnight.addingTimeInterval(3600)
        )
        XCTAssertTrue(startMidnightBlock.isValid)
    }
    
    func testSpanMultipleDaysValidation() {
        let calendar = Calendar.current
        let today = Date()
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        
        // Block spanning multiple days (should be invalid)
        let spanningBlock = TimeBlock(
            title: "Spanning Days",
            startTime: today,
            endTime: tomorrow
        )
        XCTAssertFalse(spanningBlock.isValid)
        XCTAssertTrue(spanningBlock.validationErrors.contains { $0.contains("day") || $0.contains("span") })
    }
}
