//
//  TimeBlockConflictDetectionTests.swift
//  Routine AnchorTests
//
//  Unit tests for TimeBlock conflict detection including overlap scenarios,
//  edge cases, same-day validation, and TimeBlockService conflict checking
//

import Testing
import Foundation
import SwiftData
@testable import Routine_Anchor

// MARK: - TimeBlock Model Conflict Detection Tests

struct TimeBlockConflictDetectionTests {
    
    // MARK: - Helper Methods
    
    /// Helper to create a date with specific time components
    private func createDate(
        year: Int = 2024,
        month: Int = 7,
        day: Int = 19,
        hour: Int,
        minute: Int = 0
    ) -> Date {
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = minute
        components.second = 0
        
        return calendar.date(from: components) ?? Date()
    }
    
    /// Helper to create a time block with specific hours
    private func createTimeBlock(
        title: String = "Test Block",
        day: Int = 19,
        startHour: Int,
        startMinute: Int = 0,
        endHour: Int,
        endMinute: Int = 0
    ) -> TimeBlock {
        return TimeBlock(
            title: title,
            startTime: createDate(day: day, hour: startHour, minute: startMinute),
            endTime: createDate(day: day, hour: endHour, minute: endMinute)
        )
    }
    
    // MARK: - Basic Conflict Tests
    
    @Test("Non-overlapping blocks should not conflict")
    func testNonOverlappingBlocks() {
        let block1 = createTimeBlock(
            title: "Morning Block",
            startHour: 9,
            endHour: 10
        )
        
        let block2 = createTimeBlock(
            title: "Afternoon Block",
            startHour: 14,
            endHour: 15
        )
        
        #expect(block1.conflictsWith(block2) == false)
        #expect(block2.conflictsWith(block1) == false)
    }
    
    @Test("Completely overlapping blocks should conflict")
    func testCompleteOverlap() {
        let block1 = createTimeBlock(
            title: "Block 1",
            startHour: 10,
            endHour: 12
        )
        
        let block2 = createTimeBlock(
            title: "Block 2",
            startHour: 10,
            endHour: 12
        )
        
        #expect(block1.conflictsWith(block2) == true)
        #expect(block2.conflictsWith(block1) == true)
    }
    
    @Test("Partially overlapping blocks should conflict")
    func testPartialOverlap() {
        let block1 = createTimeBlock(
            title: "Block 1",
            startHour: 9,
            endHour: 11
        )
        
        let block2 = createTimeBlock(
            title: "Block 2",
            startHour: 10,
            endHour: 12
        )
        
        #expect(block1.conflictsWith(block2) == true)
        #expect(block2.conflictsWith(block1) == true)
    }
    
    // MARK: - Adjacent Block Tests
    
    @Test("Adjacent blocks (end meets start) should not conflict")
    func testAdjacentBlocksEndMeetsStart() {
        let block1 = createTimeBlock(
            title: "Block 1",
            startHour: 9,
            endHour: 10
        )
        
        let block2 = createTimeBlock(
            title: "Block 2",
            startHour: 10,
            endHour: 11
        )
        
        // The implementation uses < and > for overlap check, so adjacent blocks don't conflict
        #expect(block1.conflictsWith(block2) == false)
        #expect(block2.conflictsWith(block1) == false)
    }
    
    @Test("Adjacent blocks with minute precision should not conflict")
    func testAdjacentBlocksWithMinutes() {
        let block1 = createTimeBlock(
            title: "Block 1",
            startHour: 9,
            startMinute: 0,
            endHour: 9,
            endMinute: 45
        )
        
        let block2 = createTimeBlock(
            title: "Block 2",
            startHour: 9,
            startMinute: 45,
            endHour: 10,
            endMinute: 30
        )
        
        #expect(block1.conflictsWith(block2) == false)
        #expect(block2.conflictsWith(block1) == false)
    }
    
    // MARK: - Overlap Scenario Tests
    
    @Test("Block starting during another should conflict")
    func testBlockStartingDuringAnother() {
        let block1 = createTimeBlock(
            title: "Block 1",
            startHour: 9,
            endHour: 11
        )
        
        let block2 = createTimeBlock(
            title: "Block 2",
            startHour: 10,
            endHour: 13
        )
        
        #expect(block1.conflictsWith(block2) == true)
        #expect(block2.conflictsWith(block1) == true)
    }
    
    @Test("Block ending during another should conflict")
    func testBlockEndingDuringAnother() {
        let block1 = createTimeBlock(
            title: "Block 1",
            startHour: 10,
            endHour: 12
        )
        
        let block2 = createTimeBlock(
            title: "Block 2",
            startHour: 8,
            endHour: 11
        )
        
        #expect(block1.conflictsWith(block2) == true)
        #expect(block2.conflictsWith(block1) == true)
    }
    
    @Test("Block completely containing another should conflict")
    func testBlockContainingAnother() {
        let largeBlock = createTimeBlock(
            title: "Large Block",
            startHour: 8,
            endHour: 17
        )
        
        let smallBlock = createTimeBlock(
            title: "Small Block",
            startHour: 10,
            endHour: 11
        )
        
        #expect(largeBlock.conflictsWith(smallBlock) == true)
        #expect(smallBlock.conflictsWith(largeBlock) == true)
    }
    
    @Test("Block completely contained within another should conflict")
    func testBlockContainedWithinAnother() {
        let outerBlock = createTimeBlock(
            title: "Outer Block",
            startHour: 9,
            endHour: 17
        )
        
        let innerBlock = createTimeBlock(
            title: "Inner Block",
            startHour: 12,
            endHour: 13
        )
        
        #expect(outerBlock.conflictsWith(innerBlock) == true)
        #expect(innerBlock.conflictsWith(outerBlock) == true)
    }
    
    // MARK: - Same Day Validation Tests
    
    @Test("Blocks on different days should not conflict")
    func testDifferentDayBlocks() {
        let block1 = createTimeBlock(
            title: "Today Block",
            day: 19,
            startHour: 10,
            endHour: 12
        )
        
        let block2 = createTimeBlock(
            title: "Tomorrow Block",
            day: 20,
            startHour: 10,
            endHour: 12
        )
        
        #expect(block1.conflictsWith(block2) == false)
        #expect(block2.conflictsWith(block1) == false)
    }
    
    @Test("Same time on different days should not conflict")
    func testSameTimeOnDifferentDays() {
        let mondayBlock = createTimeBlock(
            title: "Monday Meeting",
            day: 15,
            startHour: 14,
            endHour: 15
        )
        
        let tuesdayBlock = createTimeBlock(
            title: "Tuesday Meeting",
            day: 16,
            startHour: 14,
            endHour: 15
        )
        
        #expect(mondayBlock.conflictsWith(tuesdayBlock) == false)
    }
    
    // MARK: - Self Conflict Tests
    
    @Test("Block should not conflict with itself")
    func testSelfConflict() {
        let block = createTimeBlock(
            title: "Test Block",
            startHour: 10,
            endHour: 11
        )
        
        // The implementation checks self.id != other.id
        #expect(block.conflictsWith(block) == false)
    }
    
    @Test("Block with same ID should not conflict")
    func testSameIdNoConflict() {
        let block1 = createTimeBlock(
            title: "Original",
            startHour: 10,
            endHour: 11
        )
        
        // In a real scenario, this would be the same block being edited
        let block2 = block1 // Same reference, same ID
        
        #expect(block1.conflictsWith(block2) == false)
    }
    
    // MARK: - Multiple Block Conflict Tests
    
    @Test("Detect conflicts with multiple blocks")
    func testConflictWithMultipleBlocks() {
        let targetBlock = createTimeBlock(
            title: "Target",
            startHour: 10,
            endHour: 12
        )
        
        let blocks = [
            createTimeBlock(title: "Early Morning", startHour: 6, endHour: 8),
            createTimeBlock(title: "Morning", startHour: 8, endHour: 9),
            createTimeBlock(title: "Conflict 1", startHour: 11, endHour: 13),
            createTimeBlock(title: "Lunch", startHour: 13, endHour: 14),
            createTimeBlock(title: "Conflict 2", startHour: 9, startMinute: 30, endHour: 10, endMinute: 30),
            createTimeBlock(title: "Evening", startHour: 17, endHour: 19)
        ]
        
        let conflicts = targetBlock.conflictsWith(blocks)
        
        #expect(conflicts.count == 2)
        #expect(conflicts.contains { $0.title == "Conflict 1" })
        #expect(conflicts.contains { $0.title == "Conflict 2" })
    }
    
    @Test("Empty array should have no conflicts")
    func testEmptyArrayNoConflicts() {
        let block = createTimeBlock(
            title: "Test Block",
            startHour: 10,
            endHour: 11
        )
        
        let conflicts = block.conflictsWith([])
        
        #expect(conflicts.isEmpty)
    }
    
    // MARK: - Edge Case Tests
    
    @Test("Midnight crossing blocks on same day")
    func testMidnightCrossingBlocks() {
        // Block from 11 PM to 1 AM (crosses midnight)
        let nightBlock = TimeBlock(
            title: "Night Shift",
            startTime: createDate(day: 19, hour: 23, minute: 0),
            endTime: createDate(day: 20, hour: 1, minute: 0)
        )
        
        // Block at 11:30 PM same day
        let lateBlock = TimeBlock(
            title: "Late Task",
            startTime: createDate(day: 19, hour: 23, minute: 30),
            endTime: createDate(day: 19, hour: 23, minute: 45)
        )
        
        // These should conflict as they overlap on day 19
        #expect(nightBlock.conflictsWith(lateBlock) == true)
    }
    
    @Test("One-minute blocks should detect conflicts correctly")
    func testOneMinuteBlocks() {
        let block1 = createTimeBlock(
            title: "Quick Task 1",
            startHour: 10,
            startMinute: 30,
            endHour: 10,
            endMinute: 31
        )
        
        let block2 = createTimeBlock(
            title: "Quick Task 2",
            startHour: 10,
            startMinute: 30,
            endHour: 10,
            endMinute: 31
        )
        
        #expect(block1.conflictsWith(block2) == true)
    }
    
    @Test("Very long blocks spanning most of day")
    func testVeryLongBlocks() {
        let allDayBlock = createTimeBlock(
            title: "All Day Event",
            startHour: 0,
            endHour: 23,
            endMinute: 59
        )
        
        let morningBlock = createTimeBlock(
            title: "Morning Task",
            startHour: 9,
            endHour: 10
        )
        
        #expect(allDayBlock.conflictsWith(morningBlock) == true)
        #expect(morningBlock.conflictsWith(allDayBlock) == true)
    }
}

// MARK: - TimeBlockService Conflict Detection Tests

struct TimeBlockServiceConflictTests {
    
    // MARK: - Helper Methods
    
    private func createDate(day: Int = 19, hour: Int, minute: Int = 0) -> Date {
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = 2024
        components.month = 7
        components.day = day
        components.hour = hour
        components.minute = minute
        return calendar.date(from: components) ?? Date()
    }
    
    private func createBlock(
        title: String = "Test",
        day: Int = 19,
        startHour: Int,
        startMinute: Int = 0,
        endHour: Int,
        endMinute: Int = 0
    ) -> TimeBlock {
        let block = TimeBlock(
            title: title,
            startTime: createDate(day: day, hour: startHour, minute: startMinute),
            endTime: createDate(day: day, hour: endHour, minute: endMinute)
        )
        return block
    }
    
    // MARK: - Service Conflict Tests
    
    @Test("Service should detect basic conflicts")
    func testServiceBasicConflictDetection() {
        let service = TimeBlockService.shared
        
        let newBlock = createBlock(title: "New Block", startHour: 10, endHour: 12)
        
        let existingBlocks = [
            createBlock(title: "Morning", startHour: 8, endHour: 9),
            createBlock(title: "Conflict", startHour: 11, endHour: 13),
            createBlock(title: "Afternoon", startHour: 14, endHour: 15)
        ]
        
        let conflicts = service.checkConflicts(
            for: newBlock,
            existingBlocks: existingBlocks
        )
        
        #expect(conflicts.count == 1)
        #expect(conflicts.first?.title == "Conflict")
    }
    
    @Test("Debug: Service overlap detection edge case")
    func testServiceOverlapDebug() {
        let service = TimeBlockService.shared
        
        // Test if 10:30-12:30 overlaps with 12:00-13:00
        let block1 = createBlock(
            title: "Block1",
            startHour: 10,
            startMinute: 30,
            endHour: 12,
            endMinute: 30
        )
        
        let block2 = createBlock(
            title: "Block2",
            startHour: 12,
            endHour: 13
        )
        
        // According to the implementation, this checks if times overlap
        let conflicts = service.checkConflicts(
            for: block1,
            existingBlocks: [block2]
        )
        
        // These should overlap because block1 ends at 12:30 and block2 starts at 12:00
        #expect(conflicts.count == 1)
        
        // Now test adjacent blocks (should NOT overlap)
        let block3 = createBlock(
            title: "Block3",
            startHour: 10,
            endHour: 12
        )
        
        let block4 = createBlock(
            title: "Block4",
            startHour: 12,
            endHour: 13
        )
        
        let conflicts2 = service.checkConflicts(
            for: block3,
            existingBlocks: [block4]
        )
        
        // These should NOT overlap (adjacent)
        #expect(conflicts2.count == 0)
    }
    
    @Test("Service should exclude block by ID when specified - Fixed")
    func testServiceExcludeByIdFixed() {
        let service = TimeBlockService.shared
        
        // Create an existing block
        let existingBlock = createBlock(
            title: "Meeting",
            startHour: 10,
            endHour: 11
        )
        
        // Create an updated version that overlaps with the original
        let updatedVersion = createBlock(
            title: "Meeting (Updated)",
            startHour: 10,
            startMinute: 30,
            endHour: 11,
            endMinute: 30
        )
        
        // Create a non-conflicting block
        let nonConflictingBlock = createBlock(
            title: "Afternoon Task",
            startHour: 14,
            endHour: 15
        )
        
        let existingBlocks = [existingBlock, nonConflictingBlock]
        
        // Without excluding: should find conflict with original
        let conflictsWithoutExclude = service.checkConflicts(
            for: updatedVersion,
            existingBlocks: existingBlocks,
            excludingId: nil
        )
        
        #expect(conflictsWithoutExclude.count == 1)
        #expect(conflictsWithoutExclude.first?.title == "Meeting")
        
        // With excluding: should find no conflicts
        let conflictsWithExclude = service.checkConflicts(
            for: updatedVersion,
            existingBlocks: existingBlocks,
            excludingId: existingBlock.id
        )
        
        #expect(conflictsWithExclude.count == 0)
    }
    
    @Test("Service should only exclude specified ID, not all conflicts")
    func testServiceExcludeOnlySpecifiedId() {
        let service = TimeBlockService.shared
        
        // Create a block we're editing
        let blockBeingEdited = createBlock(
            title: "Work Block",
            startHour: 9,
            endHour: 10
        )
        
        // New time for the edited block (9:30-11:30)
        let editedVersion = createBlock(
            title: "Work Block (Edited)",
            startHour: 9,
            startMinute: 30,
            endHour: 11,
            endMinute: 30
        )
        
        // Other blocks that might conflict
        let otherBlocks = [
            blockBeingEdited,  // Original version - should be excluded
            createBlock(title: "Team Meeting", startHour: 11, endHour: 12),  // Overlaps at 11:00-11:30
            createBlock(title: "Break", startHour: 10, startMinute: 30, endHour: 10, endMinute: 45)  // Overlaps
        ]
        
        let conflicts = service.checkConflicts(
            for: editedVersion,
            existingBlocks: otherBlocks,
            excludingId: blockBeingEdited.id
        )
        
        // Should find conflicts with Team Meeting and Break, but not with the original
        #expect(conflicts.count == 2)
        #expect(conflicts.contains { $0.title == "Team Meeting" })
        #expect(conflicts.contains { $0.title == "Break" })
        #expect(!conflicts.contains { $0.title == "Work Block" })
    }
    
    @Test("Service should handle different days correctly")
    func testServiceDifferentDays() {
        let service = TimeBlockService.shared
        
        let todayBlock = createBlock(
            title: "Today",
            day: 19,
            startHour: 10,
            endHour: 12
        )
        
        let existingBlocks = [
            createBlock(title: "Yesterday", day: 18, startHour: 10, endHour: 12),
            createBlock(title: "Today Conflict", day: 19, startHour: 11, endHour: 13),
            createBlock(title: "Tomorrow", day: 20, startHour: 10, endHour: 12)
        ]
        
        let conflicts = service.checkConflicts(
            for: todayBlock,
            existingBlocks: existingBlocks
        )
        
        // Should only conflict with same day
        #expect(conflicts.count == 1)
        #expect(conflicts.first?.title == "Today Conflict")
    }
    
    @Test("Service isOverlapping method edge cases")
    func testServiceOverlappingLogic() {
        let service = TimeBlockService.shared
        
        // Test the private isOverlapping method indirectly through checkConflicts
        
        // Case 1: Block starts exactly when another ends
        let block1 = createBlock(title: "First", startHour: 9, endHour: 10)
        let block2 = createBlock(title: "Second", startHour: 10, endHour: 11)
        
        let conflicts1 = service.checkConflicts(for: block1, existingBlocks: [block2])
        #expect(conflicts1.isEmpty) // Adjacent blocks don't overlap
        
        // Case 2: Block starts one minute before another ends
        let block3 = createBlock(title: "Third", startHour: 9, endHour: 10)
        let block4 = TimeBlock(
            title: "Fourth",
            startTime: createDate(hour: 9, minute: 59),
            endTime: createDate(hour: 11, minute: 0)
        )
        
        let conflicts2 = service.checkConflicts(for: block3, existingBlocks: [block4])
        #expect(conflicts2.count == 1) // These should overlap by 1 minute
    }
    
    @Test("Service should handle empty existing blocks")
    func testServiceEmptyExistingBlocks() {
        let service = TimeBlockService.shared
        
        let newBlock = createBlock(title: "New", startHour: 10, endHour: 12)
        
        let conflicts = service.checkConflicts(
            for: newBlock,
            existingBlocks: []
        )
        
        #expect(conflicts.isEmpty)
    }
    
    @Test("Service should detect multiple conflicts")
    func testServiceMultipleConflicts() {
        let service = TimeBlockService.shared
        
        let newBlock = createBlock(
            title: "Long Meeting",
            startHour: 9,
            endHour: 15
        )
        
        let existingBlocks = [
            createBlock(title: "Morning Standup", startHour: 9, endHour: 10),
            createBlock(title: "Team Meeting", startHour: 11, endHour: 12),
            createBlock(title: "Lunch", startHour: 12, endHour: 13),
            createBlock(title: "Afternoon Workshop", startHour: 14, endHour: 16),
            createBlock(title: "Evening", startHour: 17, endHour: 18)
        ]
        
        let conflicts = service.checkConflicts(
            for: newBlock,
            existingBlocks: existingBlocks
        )
        
        #expect(conflicts.count == 4) // All except Evening
        #expect(!conflicts.contains { $0.title == "Evening" })
    }
}

// MARK: - Integration Tests for Conflict Detection

struct ConflictDetectionIntegrationTests {
    
    @Test("TimeBlock and TimeBlockService should agree on conflicts")
    func testModelAndServiceAgreement() {
        let service = TimeBlockService.shared
        
        // Create test scenario
        let block1 = TimeBlock(
            title: "Block 1",
            startTime: Date(),
            endTime: Date().addingTimeInterval(3600)
        )
        
        let block2 = TimeBlock(
            title: "Block 2",
            startTime: Date().addingTimeInterval(1800), // 30 min later
            endTime: Date().addingTimeInterval(5400) // 90 min total
        )
        
        // Test using model method
        let modelConflict = block1.conflictsWith(block2)
        
        // Test using service method
        let serviceConflicts = service.checkConflicts(
            for: block1,
            existingBlocks: [block2]
        )
        
        // Both should agree
        #expect(modelConflict == !serviceConflicts.isEmpty)
    }
    
    @Test("Validation in ScheduleBuilderViewModel pattern")
    func testViewModelValidationPattern() {
        // This tests the pattern used in ScheduleBuilderViewModel
        let existingBlocks = [
            TimeBlock(
                title: "Existing",
                startTime: Date().addingTimeInterval(3600),
                endTime: Date().addingTimeInterval(7200)
            )
        ]
        
        let testBlock = TimeBlock(
            title: "Test",
            startTime: Date().addingTimeInterval(5400), // Overlaps with existing
            endTime: Date().addingTimeInterval(9000)
        )
        
        // Pattern from ScheduleBuilderViewModel.wouldConflict
        let conflicts = testBlock.conflictsWith(existingBlocks)
        let wouldConflict = !conflicts.isEmpty
        
        #expect(wouldConflict == true)
    }
}
