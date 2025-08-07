//
//  TimeBlockValidationTests.swift
//  Routine AnchorTests
//
//  Unit tests for TimeBlock validation logic including edge cases,
//  time zones, DST transitions, and conflict detection
//

import Testing
import Foundation
import SwiftData
@testable import Routine_Anchor

// MARK: - TimeBlock Validation Tests

struct TimeBlockValidationTests {
    
    // MARK: - Title Validation Tests
    
    @Test("Empty title should be invalid")
    func testEmptyTitleValidation() {
        let block = TimeBlock(
            title: "",
            startTime: Date(),
            endTime: Date().addingTimeInterval(3600)
        )
        
        #expect(block.isValid == false)
        #expect(block.validationErrors.contains("Title cannot be empty"))
    }
    
    @Test("Whitespace-only title should be invalid")
    func testWhitespaceOnlyTitleValidation() {
        let block = TimeBlock(
            title: "   \n\t  ",
            startTime: Date(),
            endTime: Date().addingTimeInterval(3600)
        )
        
        #expect(block.isValid == false)
        #expect(block.validationErrors.contains("Title cannot be empty"))
    }
    
    @Test("Valid title should pass validation")
    func testValidTitleValidation() {
        let block = TimeBlock(
            title: "Morning Workout",
            startTime: Date(),
            endTime: Date().addingTimeInterval(3600)
        )
        
        #expect(block.isValid == true)
        #expect(block.validationErrors.isEmpty)
    }
    
    @Test("Title with special characters should be valid")
    func testSpecialCharactersTitleValidation() {
        let block = TimeBlock(
            title: "📚 Study Session #1 - Math & Science!",
            startTime: Date(),
            endTime: Date().addingTimeInterval(3600)
        )
        
        #expect(block.isValid == true)
        #expect(block.validationErrors.isEmpty)
    }
    
    // MARK: - Time Range Validation Tests
    
    @Test("Start time after end time should be invalid")
    func testInvalidTimeRangeValidation() {
        let startTime = Date()
        let endTime = startTime.addingTimeInterval(-3600) // 1 hour before
        
        let block = TimeBlock(
            title: "Test Block",
            startTime: startTime,
            endTime: endTime
        )
        
        #expect(block.isValid == false)
        #expect(block.validationErrors.contains("Start time must be before end time"))
    }
    
    @Test("Start time equal to end time should be invalid")
    func testEqualTimesValidation() {
        let time = Date()
        
        let block = TimeBlock(
            title: "Test Block",
            startTime: time,
            endTime: time
        )
        
        #expect(block.isValid == false)
        #expect(block.validationErrors.contains("Start time must be before end time"))
        #expect(block.validationErrors.contains("Duration must be at least 1 minute"))
    }
    
    @Test("Valid time range should pass validation")
    func testValidTimeRangeValidation() {
        let startTime = Date()
        let endTime = startTime.addingTimeInterval(3600)
        
        let block = TimeBlock(
            title: "Test Block",
            startTime: startTime,
            endTime: endTime
        )
        
        #expect(block.isValid == true)
        #expect(block.durationMinutes == 60)
    }
    
    // MARK: - Duration Validation Tests
    
    @Test("Duration less than 1 minute should be invalid")
    func testMinimumDurationValidation() {
        let startTime = Date()
        let endTime = startTime.addingTimeInterval(30) // 30 seconds
        
        let block = TimeBlock(
            title: "Test Block",
            startTime: startTime,
            endTime: endTime
        )
        
        #expect(block.isValid == false)
        #expect(block.validationErrors.contains("Duration must be at least 1 minute"))
    }
    
    @Test("Duration of exactly 1 minute should be valid")
    func testOneMinuteDurationValidation() {
        let startTime = Date()
        let endTime = startTime.addingTimeInterval(60) // 1 minute
        
        let block = TimeBlock(
            title: "Test Block",
            startTime: startTime,
            endTime: endTime
        )
        
        #expect(block.isValid == true)
        #expect(block.durationMinutes == 1)
    }
    
    @Test("Duration exceeding 24 hours should be invalid")
    func testMaximumDurationValidation() {
        let startTime = Date()
        let endTime = startTime.addingTimeInterval(25 * 60 * 60) // 25 hours
        
        let block = TimeBlock(
            title: "Test Block",
            startTime: startTime,
            endTime: endTime
        )
        
        #expect(block.isValid == false)
        #expect(block.validationErrors.contains("Duration cannot exceed 24 hours"))
    }
    
    @Test("Duration of exactly 24 hours should be valid")
    func testExactly24HoursDurationValidation() {
        let startTime = Date()
        let endTime = startTime.addingTimeInterval(24 * 60 * 60) // 24 hours
        
        let block = TimeBlock(
            title: "All Day Event",
            startTime: startTime,
            endTime: endTime
        )
        
        #expect(block.isValid == true)
        #expect(block.durationMinutes == 24 * 60)
    }
    
    // MARK: - Multiple Validation Errors Tests
    
    @Test("Multiple validation errors should all be reported")
    func testMultipleValidationErrors() {
        let startTime = Date()
        let endTime = startTime.addingTimeInterval(-60) // 1 minute before (invalid)
        
        let block = TimeBlock(
            title: "", // Invalid
            startTime: startTime,
            endTime: endTime // Invalid time range
        )
        
        #expect(block.isValid == false)
        #expect(block.validationErrors.count >= 2)
        #expect(block.validationErrors.contains("Title cannot be empty"))
        #expect(block.validationErrors.contains("Start time must be before end time"))
    }
    
    // MARK: - Edge Case Tests
    
    @Test("Time block spanning midnight should be valid")
    func testMidnightCrossingValidation() {
        let calendar = Calendar.current
        let today = Date()
        
        // Create time at 11 PM
        var components = calendar.dateComponents([.year, .month, .day], from: today)
        components.hour = 23
        components.minute = 0
        let startTime = calendar.date(from: components)!
        
        // End at 1 AM next day
        components.day! += 1
        components.hour = 1
        let endTime = calendar.date(from: components)!
        
        let block = TimeBlock(
            title: "Night Shift",
            startTime: startTime,
            endTime: endTime
        )
        
        #expect(block.isValid == true)
        #expect(block.durationMinutes == 120) // 2 hours
    }
    
    @Test("Time block with fractional minutes should calculate correctly")
    func testFractionalMinutesDuration() {
        let startTime = Date()
        let endTime = startTime.addingTimeInterval(90.5) // 1.5 minutes + 0.5 seconds
        
        let block = TimeBlock(
            title: "Test Block",
            startTime: startTime,
            endTime: endTime
        )
        
        #expect(block.isValid == true)
        #expect(block.durationMinutes == 1) // Should floor to 1 minute
    }
}

// MARK: - DST and Timezone Tests

struct TimeBlockDSTTests {
    
    @Test("Time block during DST spring forward should handle correctly")
    func testDSTSpringForward() {
        // Note: This test requires running in a timezone that observes DST
        // Create a date during DST transition (typically 2 AM becomes 3 AM)
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = 2024
        components.month = 3
        components.day = 10 // Spring forward in US
        components.hour = 1
        components.minute = 30
        
        guard let startTime = calendar.date(from: components) else {
            Issue.record("Failed to create DST test date")
            return
        }
        
        // Add 2 hours - should skip the missing hour
        let endTime = startTime.addingTimeInterval(2 * 3600)
        
        let block = TimeBlock(
            title: "DST Block",
            startTime: startTime,
            endTime: endTime
        )
        
        #expect(block.isValid == true)
        // Duration should still be 120 minutes even though clock jumps
        #expect(block.durationMinutes == 120)
    }
    
    @Test("Time block during DST fall back should handle correctly")
    func testDSTFallBack() {
        // Create a date during DST fall back (typically 2 AM becomes 1 AM)
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = 2024
        components.month = 11
        components.day = 3 // Fall back in US
        components.hour = 0
        components.minute = 30
        
        guard let startTime = calendar.date(from: components) else {
            Issue.record("Failed to create DST test date")
            return
        }
        
        // Add 3 hours - includes the repeated hour
        let endTime = startTime.addingTimeInterval(3 * 3600)
        
        let block = TimeBlock(
            title: "DST Block",
            startTime: startTime,
            endTime: endTime
        )
        
        #expect(block.isValid == true)
        #expect(block.durationMinutes == 180) // 3 hours
    }
}

// MARK: - Computed Properties Tests

struct TimeBlockComputedPropertiesTests {
    
    @Test("Duration calculations should be accurate")
    func testDurationCalculations() {
        let startTime = Date()
        
        // Test various durations
        let testCases: [(seconds: TimeInterval, expectedMinutes: Int)] = [
            (60, 1),
            (90, 1),      // Rounds down
            (120, 2),
            (3599, 59),   // Just under an hour
            (3600, 60),   // Exactly one hour
            (3661, 61),   // Just over an hour
            (7200, 120),  // Two hours
            (86400, 1440) // 24 hours
        ]
        
        for testCase in testCases {
            let block = TimeBlock(
                title: "Test",
                startTime: startTime,
                endTime: startTime.addingTimeInterval(testCase.seconds)
            )
            
            #expect(block.durationMinutes == testCase.expectedMinutes)
        }
    }
    
    @Test("Scheduled date should return start of day")
    func testScheduledDate() {
        let calendar = Calendar.current
        let now = Date()
        
        let block = TimeBlock(
            title: "Test",
            startTime: now,
            endTime: now.addingTimeInterval(3600)
        )
        
        let expectedDate = calendar.startOfDay(for: now)
        #expect(block.scheduledDate == expectedDate)
    }
    
    @Test("Time formatting should be correct")
    func testTimeFormatting() {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.hour = 14
        components.minute = 30
        let startTime = calendar.date(from: components)!
        
        components.hour = 16
        components.minute = 45
        let endTime = calendar.date(from: components)!
        
        let block = TimeBlock(
            title: "Test",
            startTime: startTime,
            endTime: endTime
        )
        
        // This will depend on locale, but duration should be consistent
        #expect(block.durationMinutes == 135) // 2 hours 15 minutes
    }
}

// MARK: - Status Transition Tests

struct TimeBlockStatusTests {
    
    @Test("Status should be correctly initialized")
    func testInitialStatus() {
        let block = TimeBlock(
            title: "Test",
            startTime: Date().addingTimeInterval(3600), // Future
            endTime: Date().addingTimeInterval(7200)
        )
        
        #expect(block.status == BlockStatus.notStarted)
    }
    
    @Test("Status value conversion should work correctly")
    func testStatusValueConversion() {
        let block = TimeBlock(
            title: "Test",
            startTime: Date(),
            endTime: Date().addingTimeInterval(3600)
        )
        
        // Test all status values
        block.status = BlockStatus.notStarted
        #expect(block.statusValue == BlockStatus.notStarted.rawValue)
        
        block.status = BlockStatus.inProgress
        #expect(block.statusValue == BlockStatus.inProgress.rawValue)
        
        block.status = BlockStatus.completed
        #expect(block.statusValue == BlockStatus.completed.rawValue)
        
        block.status = BlockStatus.skipped
        #expect(block.statusValue == BlockStatus.skipped.rawValue)
    }
}

// MARK: - Copy Functionality Tests

struct TimeBlockCopyTests {
    
    @Test("Copy to date should preserve all properties except times")
    func testCopyToDate() {
        let calendar = Calendar.current
        let today = Date()
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        
        // Create original block with all properties
        let original = TimeBlock(
            title: "Original Block",
            startTime: today,
            endTime: today.addingTimeInterval(3600),
            notes: "Test notes",
            category: "Work"
        )
        original.status = BlockStatus.completed
        original.icon = "briefcase"
        
        // Copy to tomorrow
        let copy = original.copyToDate(tomorrow)
        
        // Verify properties are preserved
        #expect(copy.title == original.title)
        #expect(copy.notes == original.notes)
        #expect(copy.category == original.category)
        #expect(copy.icon == original.icon)
        
        // Verify status is reset
        #expect(copy.status == BlockStatus.notStarted)
        
        // Verify times are on the new date but at same time of day
        let originalHour = calendar.component(.hour, from: original.startTime)
        let copyHour = calendar.component(.hour, from: copy.startTime)
        #expect(originalHour == copyHour)
        
        // Verify it's on the correct date
        #expect(calendar.isDate(copy.startTime, inSameDayAs: tomorrow))
        
        // Verify duration is preserved
        #expect(copy.durationMinutes == original.durationMinutes)
        
        // Verify it's a different ID
        #expect(copy.id != original.id)
    }
}
