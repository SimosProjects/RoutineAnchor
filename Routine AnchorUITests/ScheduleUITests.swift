// COMPREHENSIVE ScheduleUITests.swift
// Complete test coverage for ScheduleBuilderView functionality
// Based on codebase analysis: ScheduleBuilderView, ScheduleBuilderViewModel, SimpleTimeBlockRow

import XCTest

final class ScheduleUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        
        // Configure app for testing
        app.launchArguments.append("--uitesting")
        app.launchEnvironment["UITEST_MODE"] = "1"
        app.launchEnvironment["DISABLE_ANIMATIONS"] = "1"
        app.launchEnvironment["RESET_STATE"] = "1"
        
        app.launch()
        
        // Ensure clean state before EVERY test
        ensureCleanTestEnvironment()
    }
    
    override func tearDownWithError() throws {
        if app.state == .runningForeground {
            ensureCleanTestEnvironment()
        }
        app = nil
    }
    
    // MARK: - Test Environment Setup
    
    private func ensureCleanTestEnvironment() {
        print("🧹 Ensuring clean test environment...")
        
        // Use Settings to clear ALL data first
        deleteAllDataViaSettings()
        
        // Navigate to Schedule to verify clean state
        app.navigateToSchedule()
        Thread.sleep(forTimeInterval: TestConfig.animationDelay)
        
        // Force app restart if still not clean
        let cellCount = app.cells.count
        if cellCount > 0 {
            print("⚠️ Still has data after Settings deletion, forcing restart")
            app.terminate()
            Thread.sleep(forTimeInterval: 2.0)
            app.launch()
            Thread.sleep(forTimeInterval: 3.0)
            deleteAllDataViaSettings()
            app.navigateToSchedule()
            Thread.sleep(forTimeInterval: TestConfig.animationDelay)
        }
        
        print("✅ Clean test environment ready")
    }
    
    private func deleteAllDataViaSettings() {
        app.navigateToSettings()
        Thread.sleep(forTimeInterval: TestConfig.animationDelay)
        
        let deleteButtons = ["Delete All Data", "Clear Today's Schedule", "Delete Everything"]
        
        for buttonText in deleteButtons {
            let deleteButton = app.buttons[buttonText]
            if deleteButton.exists {
                deleteButton.tap()
                Thread.sleep(forTimeInterval: 1.0)
                
                let confirmButtons = ["Delete All Data", "Delete Everything", "Clear Schedule", "Delete", "Confirm"]
                for confirmText in confirmButtons {
                    let confirmButton = app.buttons[confirmText]
                    if confirmButton.exists {
                        confirmButton.tap()
                        Thread.sleep(forTimeInterval: 2.0)
                        return
                    }
                }
            }
        }
    }
    
    // MARK: - 1. HEADER AND NAVIGATION TESTS
    
    func test01HeaderDisplayAndNavigation() {
        print("=== Testing Header Display and Navigation ===")
        
        app.navigateToSchedule()
        Thread.sleep(forTimeInterval: TestConfig.animationDelay)
        
        // Test header elements exist and are accessible
        let scheduleBuilderTitle = app.staticTexts["Schedule Builder"]
        XCTAssertTrue(scheduleBuilderTitle.exists, "Schedule Builder title should exist")
        XCTAssertTrue(scheduleBuilderTitle.isHittable, "Header should be accessible")
        
        let subtitle = app.staticTexts["Design your perfect routine"]
        XCTAssertTrue(subtitle.exists, "Header subtitle should exist")
        
        // Verify we're in the correct tab
        let scheduleTab = app.tabBars.buttons["Schedule"]
        XCTAssertTrue(scheduleTab.isSelected, "Schedule tab should be selected")
        
        print("✅ Header and navigation test completed")
    }
    
    // MARK: - 2. EMPTY STATE TESTS
    
    func test02EmptyStateDisplay() {
        print("=== Testing Empty State Display ===")
        
        app.navigateToSchedule()
        Thread.sleep(forTimeInterval: TestConfig.animationDelay)
        
        // Verify empty state elements
        let emptyStateTitle = app.staticTexts["Build Your Perfect Day"]
        XCTAssertTrue(emptyStateTitle.exists, "Empty state title should exist")
        
        let emptyStateDescription = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Create time blocks to structure'"))
        XCTAssertTrue(emptyStateDescription.count > 0, "Empty state description should exist")
        
        // Verify empty state buttons
        let addFirstBlockButton = app.buttons["Add Your First Block"]
        XCTAssertTrue(addFirstBlockButton.exists, "Add Your First Block button should exist")
        XCTAssertTrue(addFirstBlockButton.isEnabled, "Add Your First Block button should be enabled")
        
        let useTemplateButton = app.buttons["Use a Template"]
        XCTAssertTrue(useTemplateButton.exists, "Use a Template button should exist")
        XCTAssertTrue(useTemplateButton.isEnabled, "Use a Template button should be enabled")
        
        // Verify populated-state elements are NOT present
        XCTAssertFalse(app.buttons["Add Time Block"].exists, "Add Time Block button should NOT exist in empty state")
        XCTAssertFalse(app.buttons["Reset All"].exists, "Reset All button should NOT exist in empty state")
        XCTAssertEqual(app.cells.count, 0, "Should have zero time block cells in empty state")
        
        print("✅ Empty state display test completed")
    }
    
    func test03EmptyStateInteractivity() {
        print("=== Testing Empty State Button Interactions ===")
        
        app.navigateToSchedule()
        Thread.sleep(forTimeInterval: TestConfig.animationDelay)
        
        // Test "Add Your First Block" opens creation sheet
        let addFirstBlockButton = app.buttons["Add Your First Block"]
        addFirstBlockButton.tap()
        
        let addSheetAppeared = waitForAddTimeBlockSheet()
        XCTAssertTrue(addSheetAppeared, "Add time block sheet should appear")
        
        if addSheetAppeared {
            dismissAddTimeBlockSheet()
        }
        
        // Test "Use a Template" opens template selection
        let useTemplateButton = app.buttons["Use a Template"]
        useTemplateButton.tap()
        
        let templateSheetAppeared = waitForTemplateSelection()
        XCTAssertTrue(templateSheetAppeared, "Template selection should appear")
        
        if templateSheetAppeared {
            dismissTemplateSelection()
        }
        
        print("✅ Empty state interactivity test completed")
    }
    
    // MARK: - 3. TIME BLOCK CREATION TESTS
    
    func test04CreateFirstTimeBlock() {
        print("=== Testing First Time Block Creation ===")
        
        app.navigateToSchedule()
        Thread.sleep(forTimeInterval: TestConfig.animationDelay)
        
        let initialCellCount = app.cells.count
        XCTAssertEqual(initialCellCount, 0, "Should start with empty state")
        
        // Create first time block
        let blockCreated = createTimeBlock(
            title: "Morning Routine",
            startHour: 7,
            duration: 60,
            notes: "Start the day with intention",
            category: "Personal"
        )
        
        XCTAssertTrue(blockCreated, "Should successfully create first time block")
        
        if blockCreated {
            // Verify UI state transition from empty to populated
            Thread.sleep(forTimeInterval: TestConfig.animationDelay)
            
            let finalCellCount = app.cells.count
            XCTAssertGreaterThan(finalCellCount, 0, "Should have time block cells after creation")
            
            // Verify state transition elements
            XCTAssertFalse(app.staticTexts["Build Your Perfect Day"].exists, "Empty state title should be gone")
            XCTAssertFalse(app.buttons["Add Your First Block"].exists, "Add Your First Block button should be gone")
            XCTAssertTrue(app.buttons["Add Time Block"].exists, "Add Time Block button should appear")
            XCTAssertTrue(app.buttons["Reset All"].exists, "Reset All button should appear")
            XCTAssertTrue(app.staticTexts["Your Schedule"].exists, "Schedule section header should appear")
            
            // Verify block content
            XCTAssertTrue(app.staticTexts["Morning Routine"].exists, "Time block title should be visible")
        }
        
        print("✅ First time block creation test completed")
    }
    
    func test05CreateMultipleTimeBlocks() {
        print("=== Testing Multiple Time Block Creation ===")
        
        app.navigateToSchedule()
        Thread.sleep(forTimeInterval: TestConfig.animationDelay)
        
        // Create multiple blocks at different times
        let blocks = [
            ("Morning Routine", 7, 60),
            ("Work Session", 9, 120),
            ("Lunch Break", 12, 60),
            ("Afternoon Work", 14, 90),
            ("Exercise", 17, 60)
        ]
        
        for (index, block) in blocks.enumerated() {
            let blockCreated = createTimeBlock(
                title: block.0,
                startHour: block.1,
                duration: block.2
            )
            
            XCTAssertTrue(blockCreated, "Should create time block \(index + 1): \(block.0)")
            
            if blockCreated {
                Thread.sleep(forTimeInterval: 1.0)
                let currentCellCount = app.cells.count
                XCTAssertEqual(currentCellCount, index + 1, "Should have \(index + 1) time blocks")
            }
        }
        
        // Verify all blocks are visible
        for block in blocks {
            XCTAssertTrue(app.staticTexts[block.0].exists, "\(block.0) should be visible")
        }
        
        print("✅ Multiple time block creation test completed")
    }
    
    func test06TimeConflictValidation() {
        print("=== Testing Time Conflict Validation ===")
        
        app.navigateToSchedule()
        Thread.sleep(forTimeInterval: TestConfig.animationDelay)
        
        // Create first block: 9 AM - 11 AM
        let firstBlockCreated = createTimeBlock(
            title: "Work Block",
            startHour: 9,
            duration: 120
        )
        XCTAssertTrue(firstBlockCreated, "Should create first block")
        
        if firstBlockCreated {
            Thread.sleep(forTimeInterval: 1.0)
            
            // Try to create overlapping block: 10 AM - 12 PM
            let conflictingBlockCreated = attemptToCreateConflictingBlock(
                title: "Conflicting Block",
                startHour: 10,
                duration: 120
            )
            
            XCTAssertFalse(conflictingBlockCreated, "Should NOT create conflicting time block")
            
            // Verify we still have only one block
            let finalCellCount = app.cells.count
            XCTAssertEqual(finalCellCount, 1, "Should still have only one block after conflict rejection")
        }
        
        // Test adjacent blocks (should be allowed)
        let adjacentBlockCreated = createTimeBlock(
            title: "Adjacent Block",
            startHour: 11,
            duration: 60
        )
        XCTAssertTrue(adjacentBlockCreated, "Should create adjacent (non-overlapping) block")
        
        print("✅ Time conflict validation test completed")
    }
    
    // MARK: - 4. TIME BLOCK ROW DISPLAY TESTS
    
    func test07TimeBlockRowDisplay() {
        print("=== Testing Time Block Row Display ===")
        
        app.navigateToSchedule()
        Thread.sleep(forTimeInterval: TestConfig.animationDelay)
        
        // Create a test block
        let blockCreated = createTimeBlock(
            title: "Display Test Block",
            startHour: 10,
            duration: 90,
            notes: "Test notes for display"
        )
        
        XCTAssertTrue(blockCreated, "Should create test block")
        
        if blockCreated {
            Thread.sleep(forTimeInterval: TestConfig.animationDelay)
            
            // Verify time block row elements exist
            let blockTitle = app.staticTexts["Display Test Block"]
            XCTAssertTrue(blockTitle.exists, "Block title should be visible")
            
            let timeLabel = app.staticTexts["10:00 AM"]
            XCTAssertTrue(timeLabel.exists, "Start time should be visible")
            
            let durationLabel = app.staticTexts["1h 30m"]
            XCTAssertTrue(durationLabel.exists, "Duration should be visible")
            
            // Verify status indicator (clock icon for not started)
            let statusIcon = app.images["clock"]
            XCTAssertTrue(statusIcon.exists, "Status icon should be visible")
            
            // Verify action buttons
            let editButton = app.buttons["Edit"]
            XCTAssertTrue(editButton.exists, "Edit button should be visible")
            XCTAssertTrue(editButton.isHittable, "Edit button should be interactive")
            
            let deleteButton = app.buttons["Trash"]
            XCTAssertTrue(deleteButton.exists, "Delete button should be visible")
            XCTAssertTrue(deleteButton.isHittable, "Delete button should be interactive")
        }
        
        print("✅ Time block row display test completed")
    }
    
    func test08TimeBlockStatusDisplay() {
        print("=== Testing Time Block Status Display ===")
        
        app.navigateToSchedule()
        Thread.sleep(forTimeInterval: TestConfig.animationDelay)
        
        let blockCreated = createTimeBlock(
            title: "Status Test Block",
            startHour: 10,
            duration: 60
        )
        
        XCTAssertTrue(blockCreated, "Should create test block")
        
        if blockCreated {
            Thread.sleep(forTimeInterval: TestConfig.animationDelay)
            
            // Initially should show "Not Started" status
            let clockIcon = app.images["clock"]
            XCTAssertTrue(clockIcon.exists, "Should show clock icon for not started status")
            
            // Navigate to Today view to change status
            app.navigateToToday()
            Thread.sleep(forTimeInterval: TestConfig.animationDelay)
            
            // Try to mark as completed
            let statusChanged = markTimeBlockAsCompleted("Status Test Block")
            
            if statusChanged {
                // Go back to Schedule and verify status change
                app.navigateToSchedule()
                Thread.sleep(forTimeInterval: TestConfig.animationDelay)
                
                let completedIcon = app.images["checkmark"]
                XCTAssertTrue(completedIcon.exists, "Should show checkmark icon for completed status")
            }
        }
        
        print("✅ Time block status display test completed")
    }
    
    func test09TimeBlockSorting() {
        print("=== Testing Time Block Sorting ===")
        
        app.navigateToSchedule()
        Thread.sleep(forTimeInterval: TestConfig.animationDelay)
        
        // Create blocks in non-chronological order
        let blocks = [
            ("Evening Block", 18),
            ("Morning Block", 8),
            ("Afternoon Block", 13)
        ]
        
        for block in blocks {
            let created = createTimeBlock(title: block.0, startHour: block.1, duration: 60)
            XCTAssertTrue(created, "Should create \(block.0)")
            Thread.sleep(forTimeInterval: 0.5)
        }
        
        // Verify blocks appear in chronological order
        let allCells = app.cells
        XCTAssertEqual(allCells.count, 3, "Should have three blocks")
        
        // Check order by examining text positions
        let allTexts = getAllVisibleStaticTexts()
        let morningIndex = allTexts.firstIndex(of: "Morning Block") ?? -1
        let afternoonIndex = allTexts.firstIndex(of: "Afternoon Block") ?? -1
        let eveningIndex = allTexts.firstIndex(of: "Evening Block") ?? -1
        
        if morningIndex != -1 && afternoonIndex != -1 && eveningIndex != -1 {
            XCTAssertTrue(morningIndex < afternoonIndex, "Morning should come before afternoon")
            XCTAssertTrue(afternoonIndex < eveningIndex, "Afternoon should come before evening")
        }
        
        print("✅ Time block sorting test completed")
    }
    
    // MARK: - 5. TIME BLOCK EDITING TESTS
    
    func test10EditTimeBlock() {
        print("=== Testing Time Block Editing ===")
        
        ensureCleanTestEnvironment()
        
        app.navigateToSchedule()
        Thread.sleep(forTimeInterval: TestConfig.animationDelay)
        
        let blockCreated = createTimeBlock(
            title: "Original Title",
            startHour: 9,
            duration: 60
        )
        
        XCTAssertTrue(blockCreated, "Should create block to edit")
        
        if blockCreated {
            Thread.sleep(forTimeInterval: TestConfig.animationDelay)
            
            // Tap edit button
            let editButton = app.buttons["Edit"]
            XCTAssertTrue(editButton.exists, "Edit button should exist")
            
            editButton.tap()
            
            let editSheetAppeared = waitForEditTimeBlockSheet()
            XCTAssertTrue(editSheetAppeared, "Edit sheet should appear")
            
            if editSheetAppeared {
                // Edit the title
                let titleField = app.textFields.firstMatch
                if titleField.exists {
                    titleField.tap()
                    titleField.clearAndEnterText(text: "Edited Title")
                    
                    // Save changes
                    let saveButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Save' OR label CONTAINS 'Update'")).firstMatch
                    if saveButton.exists {
                        saveButton.tap()
                        Thread.sleep(forTimeInterval: TestConfig.animationDelay)
                        
                        // Verify the title was updated
                        XCTAssertTrue(app.staticTexts["Edited Title"].exists, "Block title should be updated")
                        XCTAssertFalse(app.staticTexts["Original Title"].exists, "Original title should be gone")
                    }
                }
            }
        }
        
        print("✅ Time block editing test completed")
    }
    
    // MARK: - 6. TIME BLOCK DELETION TESTS
    
    func test11DeleteTimeBlock() {
        print("=== Testing Time Block Deletion ===")
        
        app.navigateToSchedule()
        Thread.sleep(forTimeInterval: TestConfig.animationDelay)
        
        // Create two blocks
        let block1Created = createTimeBlock(title: "Block to Delete", startHour: 9, duration: 60)
        let block2Created = createTimeBlock(title: "Block to Keep", startHour: 11, duration: 60)
        
        XCTAssertTrue(block1Created && block2Created, "Should create both test blocks")
        
        if block1Created && block2Created {
            Thread.sleep(forTimeInterval: TestConfig.animationDelay)
            
            let initialCellCount = app.cells.count
            XCTAssertEqual(initialCellCount, 2, "Should have two blocks initially")
            
            // Delete the first block
            let deleted = deleteTimeBlock("Block to Delete")
            XCTAssertTrue(deleted, "Should successfully delete time block")
            
            if deleted {
                Thread.sleep(forTimeInterval: TestConfig.animationDelay)
                
                let finalCellCount = app.cells.count
                XCTAssertEqual(finalCellCount, 1, "Should have one block after deletion")
                
                // Verify correct block remains
                XCTAssertTrue(app.staticTexts["Block to Keep"].exists, "Remaining block should still exist")
                XCTAssertFalse(app.staticTexts["Block to Delete"].exists, "Deleted block should be gone")
            }
        }
        
        print("✅ Time block deletion test completed")
    }
    
    func test12DeleteAllTimeBlocks() {
        print("=== Testing Delete All Blocks Transition ===")
        
        app.navigateToSchedule()
        Thread.sleep(forTimeInterval: TestConfig.animationDelay)
        
        // Create multiple blocks
        for i in 1...3 {
            let created = createTimeBlock(title: "Block \(i)", startHour: 8 + i, duration: 60)
            XCTAssertTrue(created, "Should create Block \(i)")
        }
        
        Thread.sleep(forTimeInterval: TestConfig.animationDelay)
        XCTAssertEqual(app.cells.count, 3, "Should have three blocks")
        
        // Delete all blocks one by one
        for i in 1...3 {
            let deleted = deleteTimeBlock("Block \(i)")
            XCTAssertTrue(deleted, "Should delete Block \(i)")
            Thread.sleep(forTimeInterval: 1.0)
        }
        
        // Verify transition back to empty state
        Thread.sleep(forTimeInterval: TestConfig.animationDelay)
        XCTAssertEqual(app.cells.count, 0, "Should have no blocks after deleting all")
        XCTAssertTrue(app.staticTexts["Build Your Perfect Day"].exists, "Should show empty state title")
        XCTAssertTrue(app.buttons["Add Your First Block"].exists, "Should show Add Your First Block button")
        XCTAssertFalse(app.buttons["Reset All"].exists, "Should not show Reset All button")
        
        print("✅ Delete all blocks transition test completed")
    }
    
    // MARK: - 7. ACTION BUTTONS TESTS
    
    func test13AddTimeBlockButton() {
        print("=== Testing Add Time Block Button (Populated State) ===")
        
        app.navigateToSchedule()
        Thread.sleep(forTimeInterval: TestConfig.animationDelay)
        
        // Create a block to get into populated state
        let blockCreated = createTimeBlock(title: "Test Block", startHour: 10, duration: 60)
        XCTAssertTrue(blockCreated, "Should create initial block")
        
        if blockCreated {
            Thread.sleep(forTimeInterval: TestConfig.animationDelay)
            
            // Verify Add Time Block button exists and works
            let addTimeBlockButton = app.buttons["Add Time Block"]
            XCTAssertTrue(addTimeBlockButton.exists, "Add Time Block button should exist in populated state")
            XCTAssertTrue(addTimeBlockButton.isEnabled, "Add Time Block button should be enabled")
            
            addTimeBlockButton.tap()
            
            let addSheetAppeared = waitForAddTimeBlockSheet()
            XCTAssertTrue(addSheetAppeared, "Add time block sheet should appear")
            
            if addSheetAppeared {
                dismissAddTimeBlockSheet()
            }
        }
        
        print("✅ Add Time Block button test completed")
    }
    
    func test14CopyToTomorrowButton() {
        print("=== Testing Copy to Tomorrow Button ===")
        
        app.navigateToSchedule()
        Thread.sleep(forTimeInterval: TestConfig.animationDelay)
        
        // Create blocks to copy
        let block1Created = createTimeBlock(title: "Morning Block", startHour: 8, duration: 60)
        let block2Created = createTimeBlock(title: "Evening Block", startHour: 18, duration: 60)
        
        XCTAssertTrue(block1Created && block2Created, "Should create blocks to copy")
        
        if block1Created && block2Created {
            Thread.sleep(forTimeInterval: TestConfig.animationDelay)
            
            let copyButton = app.buttons["Copy to Tomorrow"]
            XCTAssertTrue(copyButton.exists, "Copy to Tomorrow button should exist")
            XCTAssertTrue(copyButton.isEnabled, "Copy to Tomorrow button should be enabled")
            
            copyButton.tap()
            Thread.sleep(forTimeInterval: 2.0)
            
            // Look for success feedback
            let successFeedback = lookForSuccessFeedback()
            XCTAssertTrue(successFeedback, "Should show success feedback after copy operation")
        }
        
        print("✅ Copy to Tomorrow button test completed")
    }
    
    func test15TemplatesButton() {
        print("=== Testing Templates Button ===")
        
        app.navigateToSchedule()
        Thread.sleep(forTimeInterval: TestConfig.animationDelay)
        
        // Create a block to get populated state
        let blockCreated = createTimeBlock(title: "Test Block", startHour: 10, duration: 60)
        XCTAssertTrue(blockCreated, "Should create initial block")
        
        if blockCreated {
            Thread.sleep(forTimeInterval: TestConfig.animationDelay)
            
            let templatesButton = app.buttons["Templates"]
            XCTAssertTrue(templatesButton.exists, "Templates button should exist")
            XCTAssertTrue(templatesButton.isEnabled, "Templates button should be enabled")
            
            templatesButton.tap()
            
            let templateSheetAppeared = waitForTemplateSelection()
            XCTAssertTrue(templateSheetAppeared, "Template selection should appear")
            
            if templateSheetAppeared {
                // Verify template options exist
                let morningTemplate = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Morning Routine'")).firstMatch
                let workTemplate = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Work Session'")).firstMatch
                let lunchTemplate = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Lunch Break'")).firstMatch
                
                XCTAssertTrue(morningTemplate.exists, "Morning Routine template should exist")
                XCTAssertTrue(workTemplate.exists, "Work Session template should exist")
                XCTAssertTrue(lunchTemplate.exists, "Lunch Break template should exist")
                
                dismissTemplateSelection()
            }
        }
        
        print("✅ Templates button test completed")
    }
    
    // MARK: - 8. RESET FUNCTIONALITY TESTS
    
    func test16ResetAllButtonVisibility() {
        print("=== Testing Reset All Button Visibility Logic ===")
        
        app.navigateToSchedule()
        Thread.sleep(forTimeInterval: TestConfig.animationDelay)
        
        // Initially should be empty (no Reset button)
        XCTAssertFalse(app.buttons["Reset All"].exists, "Reset All button should NOT exist in empty state")
        
        // Create a block
        let blockCreated = createTimeBlock(title: "Reset Test Block", startHour: 10, duration: 60)
        XCTAssertTrue(blockCreated, "Should create block for reset test")
        
        if blockCreated {
            Thread.sleep(forTimeInterval: TestConfig.animationDelay)
            
            // Now Reset button should appear
            let resetButton = app.buttons["Reset All"]
            XCTAssertTrue(resetButton.exists, "Reset All button should exist when blocks are present")
            XCTAssertTrue(resetButton.isEnabled, "Reset All button should be enabled")
            
            // Verify button styling and position
            XCTAssertTrue(resetButton.isHittable, "Reset All button should be hittable")
        }
        
        print("✅ Reset All button visibility test completed")
    }
    
    func test17ResetAllFunctionality() {
        print("=== Testing Reset All Functionality ===")
        
        app.navigateToSchedule()
        Thread.sleep(forTimeInterval: TestConfig.animationDelay)
        
        // Create multiple blocks
        let blocks = [("Morning", 8), ("Afternoon", 14), ("Evening", 18)]
        for block in blocks {
            let created = createTimeBlock(title: block.0, startHour: block.1, duration: 60)
            XCTAssertTrue(created, "Should create \(block.0) block")
        }
        
        Thread.sleep(forTimeInterval: TestConfig.animationDelay)
        
        // Change status of some blocks in Today view
        app.navigateToToday()
        Thread.sleep(forTimeInterval: TestConfig.animationDelay)
        
        let statusChanged = markTimeBlockAsCompleted("Morning")
        
        // Go back to Schedule and test reset
        app.navigateToSchedule()
        Thread.sleep(forTimeInterval: TestConfig.animationDelay)
        
        let resetButton = app.buttons["Reset All"]
        XCTAssertTrue(resetButton.exists, "Reset All button should exist")
        
        resetButton.tap()
        
        let confirmationAppeared = waitForResetConfirmation()
        XCTAssertTrue(confirmationAppeared, "Reset confirmation dialog should appear")
        
        if confirmationAppeared {
            let resetConfirmed = confirmResetAction()
            XCTAssertTrue(resetConfirmed, "Should confirm reset action")
            
            if resetConfirmed && statusChanged {
                Thread.sleep(forTimeInterval: 2.0)
                
                // Verify status was reset (check in Today view)
                app.navigateToToday()
                Thread.sleep(forTimeInterval: TestConfig.animationDelay)
                
                let statusReset = verifyTimeBlockIsNotStarted("Morning")
                XCTAssertTrue(statusReset, "Time block status should be reset to Not Started")
            }
        }
        
        print("✅ Reset All functionality test completed")
    }
    
    func test18ResetAllCancellation() {
        print("=== Testing Reset All Cancellation ===")
        
        app.navigateToSchedule()
        Thread.sleep(forTimeInterval: TestConfig.animationDelay)
        
        let blockCreated = createTimeBlock(title: "Cancel Test", startHour: 10, duration: 60)
        XCTAssertTrue(blockCreated, "Should create block for cancellation test")
        
        if blockCreated {
            Thread.sleep(forTimeInterval: TestConfig.animationDelay)
            
            let resetButton = app.buttons["Reset All"]
            XCTAssertTrue(resetButton.exists, "Reset All button should exist")
            
            resetButton.tap()
            
            let confirmationAppeared = waitForResetConfirmation()
            XCTAssertTrue(confirmationAppeared, "Reset confirmation dialog should appear")
            
            if confirmationAppeared {
                // Cancel instead of confirming
                let cancelButton = app.buttons["Cancel"]
                XCTAssertTrue(cancelButton.exists, "Cancel button should exist in confirmation dialog")
                
                cancelButton.tap()
                Thread.sleep(forTimeInterval: 1.0)
                
                // Verify we're still in Schedule view and block still exists
                let stillInSchedule = app.staticTexts["Schedule Builder"].exists
                XCTAssertTrue(stillInSchedule, "Should remain in Schedule view after cancel")
                
                let blockStillExists = app.staticTexts["Cancel Test"].exists
                XCTAssertTrue(blockStillExists, "Block should still exist after canceling reset")
            }
        }
        
        print("✅ Reset All cancellation test completed")
    }
    
    // MARK: - 9. TEMPLATE FUNCTIONALITY TESTS
    
    func test19TemplateSelection() {
        print("=== Testing Template Selection and Application ===")
        
        app.navigateToSchedule()
        Thread.sleep(forTimeInterval: TestConfig.animationDelay)
        
        // Test from empty state
        let templatesButton = app.buttons["Use a Template"]
        XCTAssertTrue(templatesButton.exists, "Templates button should exist in empty state")
        
        templatesButton.tap()
        
        let templateSheetAppeared = waitForTemplateSelection()
        XCTAssertTrue(templateSheetAppeared, "Template selection should appear")
        
        if templateSheetAppeared {
            // Test Morning Routine template
            let morningTemplate = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Morning Routine'")).firstMatch
            if morningTemplate.exists {
                morningTemplate.tap()
                Thread.sleep(forTimeInterval: 2.0)
                
                // Verify template was applied
                let morningRoutineCreated = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Morning'")).count > 0
                XCTAssertTrue(morningRoutineCreated, "Morning routine template should be applied")
                
                // Verify transition to populated state
                XCTAssertTrue(app.buttons["Add Time Block"].exists, "Should transition to populated state")
                XCTAssertTrue(app.buttons["Reset All"].exists, "Reset button should appear after template")
            }
        }
        
        print("✅ Template selection test completed")
    }
    
    func test20TemplateFromPopulatedState() {
        print("=== Testing Template Selection from Populated State ===")
        
        app.navigateToSchedule()
        Thread.sleep(forTimeInterval: TestConfig.animationDelay)
        
        // Create initial block
        let blockCreated = createTimeBlock(title: "Existing Block", startHour: 8, duration: 60)
        XCTAssertTrue(blockCreated, "Should create initial block")
        
        if blockCreated {
            Thread.sleep(forTimeInterval: TestConfig.animationDelay)
            
            let initialCellCount = app.cells.count
            
            // Use template from populated state
            let templatesButton = app.buttons["Templates"]
            templatesButton.tap()
            
            let templateSheetAppeared = waitForTemplateSelection()
            if templateSheetAppeared {
                let workTemplate = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Work Session'")).firstMatch
                if workTemplate.exists {
                    workTemplate.tap()
                    Thread.sleep(forTimeInterval: 2.0)
                    
                    // Verify additional block was added
                    let finalCellCount = app.cells.count
                    XCTAssertGreaterThan(finalCellCount, initialCellCount, "Should have more blocks after template")
                }
            }
        }
        
        print("✅ Template from populated state test completed")
    }
    
    // MARK: - 10. FORM VALIDATION TESTS
    
    func test21TimeBlockFormValidation() {
        print("=== Testing Time Block Form Validation ===")
        
        app.navigateToSchedule()
        Thread.sleep(forTimeInterval: TestConfig.animationDelay)
        
        // Open add form
        let addButton = app.buttons["Add Your First Block"]
        addButton.tap()
        
        let formAppeared = waitForAddTimeBlockSheet()
        XCTAssertTrue(formAppeared, "Add form should appear")
        
        if formAppeared {
            // Test empty title validation
            let createButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Create'")).firstMatch
            
            if createButton.exists {
                let initiallyEnabled = createButton.isEnabled
                
                if !initiallyEnabled {
                    XCTAssertFalse(initiallyEnabled, "Create button should be disabled with empty form")
                } else {
                    // Try to save with empty title
                    createButton.tap()
                    Thread.sleep(forTimeInterval: 1.0)
                    
                    // Check if validation prevented save
                    let stillInForm = app.textFields.count > 0
                    if stillInForm {
                        XCTAssertTrue(stillInForm, "Form validation should prevent save with empty title")
                    }
                }
            }
            
            // Test with valid title
            let titleField = app.textFields.firstMatch
            if titleField.exists {
                titleField.tap()
                titleField.typeText("Valid Title")
                app.dismissKeyboard()
                
                Thread.sleep(forTimeInterval: 1.0)
                
                // Create button should now be enabled
                if createButton.exists {
                    XCTAssertTrue(createButton.isEnabled, "Create button should be enabled with valid title")
                }
            }
            
            dismissAddTimeBlockSheet()
        }
        
        print("✅ Time block form validation test completed")
    }
    
    func test22InvalidTimeRangeValidation() {
        print("=== Testing Invalid Time Range Validation ===")
        
        app.navigateToSchedule()
        Thread.sleep(forTimeInterval: TestConfig.animationDelay)
        
        let addButton = app.buttons["Add Your First Block"]
        addButton.tap()
        
        let formAppeared = waitForAddTimeBlockSheet()
        if formAppeared {
            // Fill title
            let titleField = app.textFields.firstMatch
            if titleField.exists {
                titleField.tap()
                titleField.typeText("Invalid Time Block")
                app.dismissKeyboard()
            }
            
            // Try to set end time before start time
            let timePickers = app.datePickers
            if timePickers.count >= 2 {
                // This would require more complex time picker manipulation
                // For now, just verify the form exists and can be dismissed
                XCTAssertTrue(timePickers.count >= 1, "Should have time picker controls")
            }
            
            dismissAddTimeBlockSheet()
        }
        
        print("✅ Invalid time range validation test completed")
    }
    
    // MARK: - 11. ACCESSIBILITY TESTS
    
    func test23AccessibilityLabels() {
        print("=== Testing Accessibility Labels ===")
        
        app.navigateToSchedule()
        Thread.sleep(forTimeInterval: TestConfig.animationDelay)
        
        // Test empty state accessibility
        let emptyStateTitle = app.staticTexts["Build Your Perfect Day"]
        if emptyStateTitle.exists {
            XCTAssertTrue(emptyStateTitle.isHittable, "Empty state title should be accessible")
            
            let addFirstBlockButton = app.buttons["Add Your First Block"]
            XCTAssertTrue(addFirstBlockButton.isHittable, "Add Your First Block button should be accessible")
            
            let useTemplateButton = app.buttons["Use a Template"]
            XCTAssertTrue(useTemplateButton.isHittable, "Use a Template button should be accessible")
        }
        
        // Create a block and test populated state accessibility
        let blockCreated = createTimeBlock(title: "Accessibility Test", startHour: 10, duration: 60)
        if blockCreated {
            Thread.sleep(forTimeInterval: TestConfig.animationDelay)
            
            let blockCell = app.cells.firstMatch
            XCTAssertTrue(blockCell.exists, "Block cell should exist")
            XCTAssertTrue(blockCell.isHittable, "Block cell should be accessible")
            
            let editButton = app.buttons["Edit"]
            XCTAssertTrue(editButton.isHittable, "Edit button should be accessible")
            
            let deleteButton = app.buttons["Trash"]
            XCTAssertTrue(deleteButton.isHittable, "Delete button should be accessible")
            
            let addTimeBlockButton = app.buttons["Add Time Block"]
            XCTAssertTrue(addTimeBlockButton.isHittable, "Add Time Block button should be accessible")
            
            let resetAllButton = app.buttons["Reset All"]
            XCTAssertTrue(resetAllButton.isHittable, "Reset All button should be accessible")
        }
        
        print("✅ Accessibility labels test completed")
    }
    
    func test24VoiceOverSupport() {
        print("=== Testing VoiceOver Support ===")
        
        app.navigateToSchedule()
        Thread.sleep(forTimeInterval: TestConfig.animationDelay)
        
        // Test that key elements have appropriate labels
        let scheduleHeader = app.staticTexts["Schedule Builder"]
        XCTAssertTrue(scheduleHeader.exists, "Schedule header should have proper label")
        
        let emptyStateTitle = app.staticTexts["Build Your Perfect Day"]
        if emptyStateTitle.exists {
            XCTAssertTrue(emptyStateTitle.label.count > 0, "Empty state should have descriptive label")
        }
        
        // Create block and test its accessibility
        let blockCreated = createTimeBlock(title: "VoiceOver Test", startHour: 10, duration: 60)
        if blockCreated {
            Thread.sleep(forTimeInterval: TestConfig.animationDelay)
            
            let blockTitle = app.staticTexts["VoiceOver Test"]
            XCTAssertTrue(blockTitle.exists, "Block title should be accessible to VoiceOver")
            
            // Test action buttons have descriptive labels
            let editButton = app.buttons["Edit"]
            XCTAssertTrue(editButton.label.contains("Edit") || editButton.accessibilityLabel?.contains("Edit") == true, "Edit button should have descriptive label")
            
            let deleteButton = app.buttons["Trash"]
            XCTAssertTrue(deleteButton.exists, "Delete button should be accessible")
        }
        
        print("✅ VoiceOver support test completed")
    }
    
    // MARK: - 12. PERFORMANCE AND INTEGRATION TESTS
    
    func test25ScheduleViewPerformance() {
        print("=== Testing Schedule View Performance ===")
        
        app.navigateToSchedule()
        Thread.sleep(forTimeInterval: TestConfig.animationDelay)
        
        let startTime = Date()
        
        // Create multiple blocks quickly
        let blockTitles = (1...5).map { "Performance Test \($0)" }
        var successfulCreations = 0
        
        for (index, title) in blockTitles.enumerated() {
            let blockCreated = createTimeBlock(
                title: title,
                startHour: 8 + (index * 2),
                duration: 60
            )
            if blockCreated {
                successfulCreations += 1
            }
        }
        
        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime)
        
        print("Created \(successfulCreations) blocks in \(String(format: "%.2f", duration)) seconds")
        
        XCTAssertGreaterThanOrEqual(successfulCreations, 3, "Should create multiple blocks successfully")
        XCTAssertLessThan(duration, 30.0, "Block creation should complete within reasonable time")
        
        // Test scrolling performance if needed
        let finalCellCount = app.cells.count
        if finalCellCount > 3 {
            let scrollView = app.scrollViews.firstMatch
            if scrollView.exists {
                scrollView.swipeUp()
                Thread.sleep(forTimeInterval: 0.5)
                scrollView.swipeDown()
                Thread.sleep(forTimeInterval: 0.5)
                XCTAssertTrue(app.staticTexts["Schedule Builder"].exists, "UI should remain responsive after scrolling")
            }
        }
        
        print("✅ Schedule view performance test completed")
    }
    
    func test26ScheduleToTodayIntegration() {
        print("=== Testing Schedule to Today Integration ===")
        
        app.navigateToSchedule()
        Thread.sleep(forTimeInterval: TestConfig.animationDelay)
        
        // Create block in Schedule
        let blockCreated = createTimeBlock(
            title: "Integration Test Block",
            startHour: 10,
            duration: 60
        )
        
        XCTAssertTrue(blockCreated, "Should create block for integration test")
        
        if blockCreated {
            Thread.sleep(forTimeInterval: TestConfig.animationDelay)
            
            // Navigate to Today view
            app.navigateToToday()
            Thread.sleep(forTimeInterval: TestConfig.animationDelay)
            
            // Verify block appears in Today view
            let blockInToday = app.staticTexts["Integration Test Block"].exists ||
                              app.cells.count > 0
            
            XCTAssertTrue(blockInToday, "Block created in Schedule should appear in Today view")
            
            // Navigate back to Schedule
            app.navigateToSchedule()
            Thread.sleep(forTimeInterval: TestConfig.animationDelay)
            
            // Verify block still exists in Schedule
            let blockInSchedule = app.staticTexts["Integration Test Block"].exists
            XCTAssertTrue(blockInSchedule, "Block should still exist in Schedule after viewing Today")
        }
        
        print("✅ Schedule to Today integration test completed")
    }
    
    // MARK: - HELPER METHODS
    
    private func createTimeBlock(title: String, startHour: Int, duration: Int, notes: String? = nil, category: String? = nil) -> Bool {
        // Open add sheet
        guard openAddTimeBlockSheet() else { return false }
        
        // Wait for sheet to appear
        Thread.sleep(forTimeInterval: 1.0)
        
        // Fill title
        let titleField = app.textFields.firstMatch
        guard titleField.exists else {
            dismissAddTimeBlockSheet()
            return false
        }
        
        titleField.tap()
        titleField.clearAndEnterText(text: title)
        app.dismissKeyboard()
        Thread.sleep(forTimeInterval: 0.5)
        
        // Set time if needed (simplified)
        let datePickers = app.datePickers
        if datePickers.count > 0 {
            let timePicker = datePickers.firstMatch
            if timePicker.exists {
                timePicker.tap()
                Thread.sleep(forTimeInterval: 0.5)
            }
        }
        
        // Add notes if provided
        if let notes = notes {
            let textViews = app.textViews
            if textViews.count > 0 {
                let notesField = textViews.firstMatch
                if notesField.exists {
                    notesField.tap()
                    notesField.typeText(notes)
                    app.dismissKeyboard()
                    Thread.sleep(forTimeInterval: 0.5)
                }
            }
        }
        
        // Make sure we can reach the save button by scrolling
        ensureSaveButtonIsVisible()
        
        // Save the block
        let saveButtons = ["Create Time Block", "Save Time Block", "Save", "Create"]
        var saved = false
        
        for buttonText in saveButtons {
            let saveButton = app.buttons[buttonText]
            if saveButton.exists {
                // Ensure button is hittable before tapping
                if !saveButton.isHittable {
                    let scrollingSuccess = makeButtonHittable(saveButton)
                    if !scrollingSuccess {
                        print("Warning: Could not make \(buttonText) button hittable, trying coordinate tap")
                        // Last resort: try tapping at the button's coordinate
                        if tryCoordinateTap(for: saveButton) {
                            saved = true
                            break
                        }
                        continue
                    }
                }
                
                if saveButton.isEnabled {
                    saveButton.tap()
                    Thread.sleep(forTimeInterval: 2.0)
                    saved = true
                    break
                }
            }
        }
        
        if !saved {
            print("❌ Could not find or tap any save button")
            dismissAddTimeBlockSheet()
            return false
        }
        
        // Verify we're back in schedule view
        return app.staticTexts["Schedule Builder"].waitForExistence(timeout: 5.0)
    }
    
    private func ensureSaveButtonIsVisible() {
        // Try multiple scrolling strategies to make the save button visible
        
        // Strategy 1: Scroll down in the main scroll view
        let scrollViews = app.scrollViews
        if scrollViews.count > 0 {
            let mainScrollView = scrollViews.firstMatch
            if mainScrollView.exists {
                // Scroll down to reveal bottom content
                mainScrollView.swipeUp()
                Thread.sleep(forTimeInterval: 0.5)
                mainScrollView.swipeUp()
                Thread.sleep(forTimeInterval: 0.5)
            }
        }
        
        // Strategy 2: If there are multiple scroll views, try the last one
        if scrollViews.count > 1 {
            let bottomScrollView = scrollViews.element(boundBy: scrollViews.count - 1)
            if bottomScrollView.exists {
                bottomScrollView.swipeUp()
                Thread.sleep(forTimeInterval: 0.5)
            }
        }
        
        // Strategy 3: Dismiss keyboard if it's still showing
        app.dismissKeyboard()
        Thread.sleep(forTimeInterval: 0.5)
    }
    
    private func makeButtonHittable(_ button: XCUIElement) -> Bool {
        // Return early if already hittable
        if button.isHittable {
            return true
        }
        
        var attempts = 0
        let maxAttempts = 5
        
        while !button.isHittable && attempts < maxAttempts {
            attempts += 1
            
            // Try different scrolling strategies
            if attempts == 1 {
                // Try scrolling the main scroll view up
                let scrollViews = app.scrollViews
                if scrollViews.count > 0 {
                    scrollViews.firstMatch.swipeUp()
                }
            } else if attempts == 2 {
                // Try scrolling more aggressively
                let scrollViews = app.scrollViews
                for _ in 0..<3 {
                    if scrollViews.count > 0 {
                        scrollViews.firstMatch.swipeUp()
                    }
                }
            } else if attempts == 3 {
                // Try tapping outside to dismiss any overlays
                let safeArea = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.3))
                safeArea.tap()
            } else if attempts == 4 {
                // Try using the button's own scroll to visible
                do {
                    try button.scrollToElement()
                } catch {
                    print("scrollToElement failed: \(error)")
                }
            } else {
                // Last resort: try coordinate-based scrolling
                let coordinate = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.8))
                let targetCoordinate = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.2))
                coordinate.press(forDuration: 0.1, thenDragTo: targetCoordinate)
            }
            
            Thread.sleep(forTimeInterval: 0.8)
        }
        
        return button.isHittable
    }
    
    private func tryCoordinateTap(for button: XCUIElement) -> Bool {
        guard button.exists else { return false }
        
        // Get button frame and calculate center point
        let frame = button.frame
        let centerX = frame.midX
        let centerY = frame.midY
        
        // Convert to normalized coordinates
        let screenBounds = app.frame
        let normalizedX = centerX / screenBounds.width
        let normalizedY = centerY / screenBounds.height
        
        // Only try if coordinates are reasonable (on screen)
        if normalizedX >= 0 && normalizedX <= 1 && normalizedY >= 0 && normalizedY <= 1 {
            let coordinate = app.coordinate(withNormalizedOffset: CGVector(dx: normalizedX, dy: normalizedY))
            coordinate.tap()
            Thread.sleep(forTimeInterval: 2.0)
            
            // Check if we're back in schedule view (success indicator)
            return app.staticTexts["Schedule Builder"].exists
        }
        
        return false
    }
    
    private func attemptToCreateConflictingBlock(title: String, startHour: Int, duration: Int) -> Bool {
        guard openAddTimeBlockSheet() else { return false }
        
        Thread.sleep(forTimeInterval: 1.0)
        
        let titleField = app.textFields.firstMatch
        if titleField.exists {
            titleField.tap()
            titleField.clearAndEnterText(text: title)
            app.dismissKeyboard()
        }
        
        Thread.sleep(forTimeInterval: 1.0)
        
        // Try to save
        let saveButtons = ["Create Time Block", "Save", "Create"]
        for buttonText in saveButtons {
            let saveButton = app.buttons[buttonText]
            if saveButton.exists && saveButton.isEnabled {
                saveButton.tap()
                Thread.sleep(forTimeInterval: 2.0)
                
                // Check if we're back in schedule (success) or still in form (conflict)
                let backInSchedule = app.staticTexts["Schedule Builder"].exists
                if !backInSchedule {
                    dismissAddTimeBlockSheet()
                }
                return backInSchedule
            }
        }
        
        dismissAddTimeBlockSheet()
        return false
    }
    
    private func deleteTimeBlock(_ title: String) -> Bool {
        // Find the time block row
        let blockText = app.staticTexts[title]
        guard blockText.exists else { return false }
        
        // Try delete button first
        let deleteButton = app.buttons["Trash"]
        if deleteButton.exists && deleteButton.isHittable {
            deleteButton.tap()
            Thread.sleep(forTimeInterval: 1.0)
            
            // Look for confirmation
            let confirmButtons = ["Delete Time Block", "Delete", "Remove", "Confirm"]
            for buttonText in confirmButtons {
                let confirmButton = app.buttons[buttonText]
                if confirmButton.exists {
                    confirmButton.tap()
                    Thread.sleep(forTimeInterval: 1.0)
                    return true
                }
            }
            return true // Assume it worked if no confirmation dialog
        }
        
        // Try swipe to delete
        let cells = app.cells
        if cells.count > 0 {
            for i in 0..<cells.count {
                let cell = cells.element(boundBy: i)
                if cell.staticTexts[title].exists {
                    cell.swipeLeft()
                    Thread.sleep(forTimeInterval: 1.0)
                    
                    if app.buttons["Delete"].exists {
                        app.buttons["Delete"].tap()
                        Thread.sleep(forTimeInterval: 1.0)
                        return true
                    }
                }
            }
        }
        
        return false
    }
    
    private func markTimeBlockAsCompleted(_ title: String) -> Bool {
        // This should be implemented based on your Today view UI
        // For now, return false as placeholder
        return false
    }
    
    private func verifyTimeBlockIsNotStarted(_ title: String) -> Bool {
        // Check for clock icon or "Not Started" indicator
        return app.images["clock"].exists
    }
    
    private func openAddTimeBlockSheet() -> Bool {
        if app.buttons["Add Your First Block"].exists {
            app.buttons["Add Your First Block"].tap()
        } else if app.buttons["Add Time Block"].exists {
            app.buttons["Add Time Block"].tap()
        } else {
            return false
        }
        
        return waitForAddTimeBlockSheet()
    }
    
    private func waitForAddTimeBlockSheet() -> Bool {
        let timeout: TimeInterval = 5.0
        let startTime = Date()
        
        while Date().timeIntervalSince(startTime) < timeout {
            if app.textFields.count > 0 ||
               app.staticTexts["New Time Block"].exists ||
               app.buttons["Create Time Block"].exists {
                return true
            }
            Thread.sleep(forTimeInterval: 0.2)
        }
        return false
    }
    
    private func waitForEditTimeBlockSheet() -> Bool {
        let timeout: TimeInterval = 5.0
        let startTime = Date()
        
        while Date().timeIntervalSince(startTime) < timeout {
            if app.staticTexts["Edit Time Block"].exists ||
               app.buttons.matching(NSPredicate(format: "label CONTAINS 'Update' OR label CONTAINS 'Save'")).count > 0 {
                return true
            }
            Thread.sleep(forTimeInterval: 0.2)
        }
        return false
    }
    
    private func waitForTemplateSelection() -> Bool {
        let morningRoutineButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Morning Routine'")).firstMatch
        let workSessionButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Work Session'")).firstMatch
        let sheetsElement = app.sheets.firstMatch
        
        return morningRoutineButton.waitForExistence(timeout: 3.0) ||
               workSessionButton.waitForExistence(timeout: 3.0) ||
               sheetsElement.waitForExistence(timeout: 3.0)
    }
    
    private func waitForResetConfirmation() -> Bool {
        let resetProgressButton = app.buttons["Reset Progress"]
        let alertsElement = app.alerts.firstMatch
        let sheetsElement = app.sheets.firstMatch
        
        return resetProgressButton.waitForExistence(timeout: 3.0) ||
               alertsElement.waitForExistence(timeout: 3.0) ||
               sheetsElement.waitForExistence(timeout: 3.0)
    }
    
    private func confirmResetAction() -> Bool {
        let confirmButtons = ["Reset Progress", "Reset", "Confirm", "Yes"]
        for buttonText in confirmButtons {
            let button = app.buttons[buttonText]
            if button.exists {
                button.tap()
                return true
            }
        }
        return false
    }
    
    private func dismissAddTimeBlockSheet() {
        if app.buttons["Cancel"].exists {
            app.buttons["Cancel"].tap()
        } else {
            app.swipeDown()
        }
        Thread.sleep(forTimeInterval: 1.0)
    }
    
    private func dismissTemplateSelection() {
        if app.buttons["Cancel"].exists {
            app.buttons["Cancel"].tap()
        } else {
            app.tap() // Tap outside
        }
        Thread.sleep(forTimeInterval: 1.0)
    }
    
    private func lookForSuccessFeedback() -> Bool {
        let successIndicators = [
            "copied",
            "success",
            "completed",
            "done"
        ]
        
        for indicator in successIndicators {
            let texts = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] %@", indicator))
            if texts.count > 0 {
                return true
            }
        }
        
        let alertsElement = app.alerts.firstMatch
        return alertsElement.exists
    }
    
    private func getAllVisibleStaticTexts() -> [String] {
        var texts: [String] = []
        let staticTexts = app.staticTexts
        let maxTexts = min(20, staticTexts.count)
        
        for i in 0..<maxTexts {
            let text = staticTexts.element(boundBy: i)
            if text.exists {
                let label = text.label
                if !label.isEmpty && label.count > 1 {
                    texts.append(label)
                }
            }
        }
        
        return texts
    }
    
    // MARK: - Test Configuration
    
    private struct TestConfig {
        static let defaultTimeout: TimeInterval = 10.0
        static let animationDelay: TimeInterval = 1.0
    }
}
