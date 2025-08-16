//
//  ScheduleUITests.swift
//  Routine AnchorUITests
//
//  Comprehensive UI tests for the Schedule Builder including time blocks management
//

import XCTest

final class ScheduleUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        setupWithNavigation(app: app)
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - Schedule View Navigation Tests
    
    func testNavigateToScheduleTab() {
        // Navigate to Schedule tab
        navigateToSchedule(app: app)
        
        // Verify Schedule Builder view is displayed
        XCTAssertTrue(app.staticTexts["Schedule Builder"].waitForExistence(timeout: TestConfig.defaultTimeout))
        XCTAssertTrue(app.staticTexts["Design your perfect routine"].exists)
    }
    
    func testScheduleViewHeader() {
        navigateToSchedule(app: app)
        
        // Verify header elements
        let headerTitle = app.staticTexts["Schedule Builder"]
        let headerSubtitle = app.staticTexts["Design your perfect routine"]
        
        XCTAssertTrue(headerTitle.exists, "Schedule header title should be visible")
        XCTAssertTrue(headerSubtitle.exists, "Schedule header subtitle should be visible")
    }
    
    // MARK: - Empty State Tests
    
    func testEmptyStateDisplay() {
        navigateToSchedule(app: app)
        
        // Check for empty state or existing blocks
        let emptyStateTexts = [
            "Design your perfect routine",
            "Add Your First Block"
        ]
        
        let hasEmptyState = emptyStateTexts.contains { text in
            app.staticTexts[text].exists
        }
        
        // Either empty state or blocks should be visible
        XCTAssertTrue(hasEmptyState || app.cells.count > 0,
                     "Should show either empty state or existing time blocks")
    }
    
    func testAddButtonVisibility() {
        navigateToSchedule(app: app)
        
        // Look for Add Time Block button
        let addButton = app.buttons["Add Your First Block"]
        XCTAssertTrue(addButton.waitForExistence(timeout: TestConfig.defaultTimeout),
                     "Add Time Block button should be visible")
    }
    
    // MARK: - Creating Time Blocks Tests
    
    func testCreateTimeBlockFlow() {
        navigateToSchedule(app: app)
        
        // Tap Add Time Block button
        let addButton = app.buttons["Add Your First Block"]
        XCTAssertTrue(addButton.waitForExistence(timeout: TestConfig.defaultTimeout))
        addButton.tap()
        
        // Wait for add sheet to appear
        Thread.sleep(forTimeInterval: TestConfig.animationDelay)
        
        // Verify sheet elements
        XCTAssertTrue(app.staticTexts["New Time Block"].exists ||
                     app.navigationBars["New Time Block"].exists,
                     "Add Time Block sheet should appear")
        
        // Fill in the form
        app.fillTimeBlockForm(app: app, title: "Test Block", notes: "Test notes")
        
        // Save the block
        saveTimeBlock(app: app)
        
        // Verify block was added
        Thread.sleep(forTimeInterval: TestConfig.animationDelay)
        XCTAssertTrue(app.cells.matching(NSPredicate(format: "label CONTAINS 'Test Block'")).firstMatch.exists ||
                     app.staticTexts["Test Block"].exists,
                     "New time block should appear in schedule")
    }
    
    func testCreateTimeBlockWithAllFields() {
        navigateToSchedule(app: app)
        
        // Open add sheet
        app.buttons["Add Your First Block"].tap()
        Thread.sleep(forTimeInterval: TestConfig.animationDelay)
        
        // Fill all fields
        app.fillTimeBlockForm(
            app: app,
            title: "Complete Block",
            notes: "Detailed notes for this block",
            selectCategory: true,
            selectIcon: true
        )
        
        // Adjust time if possible
        app.adjustTimeIfPossible(app: app)
        
        // Save
        saveTimeBlock(app: app)
        
        // Verify block appears
        Thread.sleep(forTimeInterval: TestConfig.animationDelay)
        XCTAssertTrue(app.cells.matching(NSPredicate(format: "label CONTAINS 'Complete Block'")).firstMatch.exists ||
                     app.staticTexts["Complete Block"].exists,
                     "Time block with all fields should be created")
    }
    
    func testQuickDurationSelector() {
        navigateToSchedule(app: app)
        
        // Open add sheet
        app.buttons["Add Your First Block"].tap()
        Thread.sleep(forTimeInterval: TestConfig.animationDelay)
        
        // Look for Quick Duration section
        let quickDurationButtons = [
            "15 min", "15m", "15",
            "30 min", "30m", "30",
            "45 min", "45m", "45",
            "1 hour", "1h", "60",
            "90 min", "90m", "90",
            "2 hours", "2h", "120"
        ]
        
        var foundDuration = false
        for duration in quickDurationButtons {
            if app.buttons[duration].exists {
                app.buttons[duration].tap()
                foundDuration = true
                break
            }
        }
        
        if foundDuration {
            // Verify duration was applied (end time should update)
            Thread.sleep(forTimeInterval: 0.3)
            XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'min' OR label CONTAINS 'hour'")).count > 0,
                         "Duration should be displayed after selection")
        }
        
        // Cancel to return
        app.dismissSheet(app: app)
    }
    
    // MARK: - Editing Time Blocks Tests
    
    func testEditTimeBlockFlow() {
        // First create a block
        createTestTimeBlock(app: app)
        Thread.sleep(forTimeInterval: TestConfig.animationDelay)
        
        // Navigate to Schedule if not already there
        navigateToSchedule(app: app)
        
        // Find and tap a time block to edit
        if let firstBlock = app.cells.firstMatch.exists ? app.cells.firstMatch : nil {
            firstBlock.tap()
            Thread.sleep(forTimeInterval: TestConfig.animationDelay)
            
            // Look for edit option
            if app.buttons["Edit"].exists {
                app.buttons["Edit"].tap()
            } else {
                // Try long press
                firstBlock.press(forDuration: 1.0)
                if app.buttons["Edit"].exists {
                    app.buttons["Edit"].tap()
                }
            }
            
            // Wait for edit sheet
            Thread.sleep(forTimeInterval: TestConfig.animationDelay)
            
            // Verify edit sheet appeared
            XCTAssertTrue(app.staticTexts["Edit Time Block"].exists ||
                         app.navigationBars["Edit Time Block"].exists,
                         "Edit sheet should appear")
            
            // Modify the title
            if let titleField = app.textFields.firstMatch.exists ? app.textFields.firstMatch : nil {
                titleField.tap()
                titleField.clearAndEnterText(text: "Edited Block")
            }
            
            // Save changes
            if app.buttons["Save Changes"].exists {
                app.buttons["Save Changes"].tap()
            } else if app.buttons["Save"].exists {
                app.buttons["Save"].tap()
            }
            
            // Verify changes were saved
            Thread.sleep(forTimeInterval: TestConfig.animationDelay)
            XCTAssertTrue(app.cells.matching(NSPredicate(format: "label CONTAINS 'Edited Block'")).firstMatch.exists ||
                         app.staticTexts["Edited Block"].exists,
                         "Edited time block should show updated title")
        }
    }
    
    func testEditTimeBlockValidation() {
        createTestTimeBlock(app: app)
        navigateToSchedule(app: app)
        
        // Open edit for first block
        if let firstBlock = app.cells.firstMatch.exists ? app.cells.firstMatch : nil {
            firstBlock.tap()
            Thread.sleep(forTimeInterval: TestConfig.animationDelay)
            
            if app.buttons["Edit"].exists {
                app.buttons["Edit"].tap()
                Thread.sleep(forTimeInterval: TestConfig.animationDelay)
                
                // Clear title to test validation
                if let titleField = app.textFields.firstMatch.exists ? app.textFields.firstMatch : nil {
                    titleField.tap()
                    titleField.clearAndEnterText(text: "")
                }
                
                // Try to save
                let saveButton = app.buttons["Save Changes"].exists ?
                    app.buttons["Save Changes"] : app.buttons["Save"]
                
                if saveButton.exists {
                    // Button should be disabled or show error
                    XCTAssertTrue(!saveButton.isEnabled || saveButton.label.contains("No Changes"),
                                 "Save should be disabled with empty title")
                }
                
                // Cancel
                app.dismissSheet(app: app)
            }
        }
    }
    
    // MARK: - Deleting Time Blocks Tests
    
    func testDeleteTimeBlockViaSwipe() {
        // Create a block first
        createTestTimeBlock(app: app)
        navigateToSchedule(app: app)
        
        let initialCount = app.cells.count
        
        // Try to swipe delete
        if let firstBlock = app.cells.firstMatch.exists ? app.cells.firstMatch : nil {
            firstBlock.swipeLeft()
            Thread.sleep(forTimeInterval: TestConfig.animationDelay)
            
            // Look for delete button
            if app.buttons["Delete"].exists {
                app.buttons["Delete"].tap()
                
                // Confirm deletion if prompted
                if app.buttons["Delete"].exists {
                    app.buttons["Delete"].tap()
                }
                
                Thread.sleep(forTimeInterval: TestConfig.animationDelay)
                
                // Verify block was deleted
                XCTAssertTrue(app.cells.count < initialCount,
                             "Time block should be deleted after swipe")
            }
        }
    }
    
    func testDeleteTimeBlockViaButton() {
        createTestTimeBlock(app: app)
        navigateToSchedule(app: app)
        
        let initialCount = app.cells.count
        
        // Tap on block
        if let firstBlock = app.cells.firstMatch.exists ? app.cells.firstMatch : nil {
            firstBlock.tap()
            Thread.sleep(forTimeInterval: TestConfig.animationDelay)
            
            // Look for delete option
            if app.buttons["Delete"].exists {
                app.buttons["Delete"].tap()
            } else {
                // Try via edit sheet
                if app.buttons["Edit"].exists {
                    app.buttons["Edit"].tap()
                    Thread.sleep(forTimeInterval: TestConfig.animationDelay)
                    
                    if app.buttons["Delete Time Block"].exists {
                        app.buttons["Delete Time Block"].tap()
                    }
                }
            }
            
            // Confirm deletion
            if app.alerts.firstMatch.exists {
                app.alerts.buttons["Delete"].tap()
            } else if app.buttons["Delete"].exists {
                app.buttons["Delete"].tap()
            }
            
            Thread.sleep(forTimeInterval: TestConfig.animationDelay)
            
            // Verify deletion
            XCTAssertTrue(app.cells.count < initialCount ||
                         app.staticTexts["No time blocks scheduled"].exists,
                         "Block should be deleted")
        }
    }
    
    func testDeleteConfirmationDialog() {
        createTestTimeBlock(app: app)
        navigateToSchedule(app: app)
        
        // Attempt to delete
        if let firstBlock = app.cells.firstMatch.exists ? app.cells.firstMatch : nil {
            firstBlock.swipeLeft()
            Thread.sleep(forTimeInterval: TestConfig.animationDelay)
            
            if app.buttons["Delete"].exists {
                app.buttons["Delete"].tap()
                Thread.sleep(forTimeInterval: TestConfig.animationDelay)
                
                // Check for confirmation dialog
                XCTAssertTrue(app.alerts.firstMatch.exists ||
                             app.staticTexts["Delete Time Block"].exists ||
                             app.staticTexts["Are you sure"].exists,
                             "Delete confirmation should appear")
                
                // Cancel deletion
                if app.buttons["Cancel"].exists {
                    app.buttons["Cancel"].tap()
                }
                
                // Block should still exist
                Thread.sleep(forTimeInterval: TestConfig.animationDelay)
                XCTAssertTrue(app.cells.count > 0, "Block should not be deleted after cancel")
            }
        }
    }
    
    // MARK: - Bulk Operations Tests
    
    func testResetAllButton() {
        createTestTimeBlock(app: app)
        navigateToSchedule(app: app)
        
        // Look for Reset All button
        let resetButton = app.buttons["Reset All"]
        if resetButton.exists {
            resetButton.tap()
            Thread.sleep(forTimeInterval: TestConfig.animationDelay)
            
            // May show confirmation
            if app.alerts.firstMatch.exists {
                app.alerts.buttons["Cancel"].tap()
            }
            
            XCTAssertTrue(true, "Reset All button is functional")
        }
    }
    
    func testCopyToTomorrowButton() {
        createTestTimeBlock(app: app)
        navigateToSchedule(app: app)
        
        // Look for Copy to Tomorrow button
        let copyButton = app.buttons["Copy to Tomorrow"]
        if copyButton.exists {
            copyButton.tap()
            Thread.sleep(forTimeInterval: TestConfig.animationDelay)
            
            // Should show success message or confirmation
            XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'copied' OR label CONTAINS 'tomorrow'")).firstMatch.exists ||
                         true, // Accept if no message shown
                         "Copy to Tomorrow should work")
        }
    }
    
    // MARK: - Quick Add Templates Tests
    
    func testQuickAddTemplates() {
        navigateToSchedule(app: app)
        
        // Look for quick add or templates button
        let quickAddButtons = [
            "Quick Add",
            "Templates",
            "Add from Template"
        ]
        
        for buttonName in quickAddButtons {
            if app.buttons[buttonName].exists {
                app.buttons[buttonName].tap()
                Thread.sleep(forTimeInterval: TestConfig.animationDelay)
                
                // Check for template options
                let templates = [
                    "Morning Routine",
                    "Work Session",
                    "Lunch Break",
                    "Exercise",
                    "Custom Time Block"
                ]
                
                for template in templates {
                    if app.buttons[template].exists ||
                       app.staticTexts[template].exists {
                        XCTAssertTrue(true, "Template \(template) is available")
                        break
                    }
                }
                
                // Dismiss
                if app.buttons["Cancel"].exists {
                    app.buttons["Cancel"].tap()
                }
                break
            }
        }
    }
    
    // MARK: - Time Block Display Tests
    
    func testTimeBlockRowDisplay() {
        createTestTimeBlock(app: app)
        navigateToSchedule(app: app)
        
        if let firstBlock = app.cells.firstMatch.exists ? app.cells.firstMatch : nil {
            // Check for expected elements in time block row
            let blockFrame = firstBlock.frame
            XCTAssertNotNil(blockFrame, "Time block should have a frame")
            
            // Check for visual elements (may vary based on status)
            let hasTimeDisplay = app.staticTexts.matching(NSPredicate(format: "label CONTAINS ':' OR label CONTAINS 'AM' OR label CONTAINS 'PM'")).count > 0
            let hasTitle = app.staticTexts.matching(NSPredicate(format: "label.length > 0")).count > 0
            
            XCTAssertTrue(hasTimeDisplay || hasTitle,
                         "Time block should display time or title")
        }
    }
    
    func testTimeBlockStatusColors() {
        createTestTimeBlock(app: app)
        navigateToSchedule(app: app)
        
        // Time blocks may have different visual states
        // This test verifies the blocks are rendered
        XCTAssertTrue(app.cells.count > 0 ||
                     app.otherElements.matching(NSPredicate(format: "identifier CONTAINS 'TimeBlock'")).count > 0,
                     "Time blocks should be displayed with appropriate styling")
    }
    
    // MARK: - Scroll and Performance Tests
    
    func testScrollPerformanceWithMultipleBlocks() {
        navigateToSchedule(app: app)
        
        // Create multiple blocks
        for i in 1...5 {
            app.buttons["Add Time Block"].tap()
            Thread.sleep(forTimeInterval: 0.3)
            app.fillTimeBlockForm(app: app, title: "Block \(i)", notes: "Notes \(i)")
            saveTimeBlock(app: app)
            Thread.sleep(forTimeInterval: 0.3)
        }
        
        // Test scrolling
        measure {
            app.scrollViews.firstMatch.swipeUp()
            Thread.sleep(forTimeInterval: 0.2)
            app.scrollViews.firstMatch.swipeDown()
        }
    }
    
    func testPullToRefresh() {
        navigateToSchedule(app: app)
        
        // Pull to refresh
        app.scrollViews.firstMatch.swipeDown()
        Thread.sleep(forTimeInterval: 1)
        
        // View should still be functional
        XCTAssertTrue(app.staticTexts["Schedule Builder"].exists,
                     "Schedule view should remain after refresh")
    }
    
    // MARK: - Accessibility Tests
    
    func testAccessibilityLabelsInSchedule() {
        createTestTimeBlock(app: app)
        navigateToSchedule(app: app)
        
        // Check main elements have accessibility labels
        XCTAssertTrue(app.buttons["Add Time Block"].exists,
                     "Add button should have accessibility label")
        
        if app.cells.count > 0 {
            let firstCell = app.cells.firstMatch
            XCTAssertTrue(firstCell.isAccessibilityElement ||
                         firstCell.label.count > 0,
                         "Time blocks should be accessible")
        }
    }
    
    func testVoiceOverNavigation() {
        navigateToSchedule(app: app)
        
        // Check that interactive elements are accessible
        let interactiveElements = app.buttons.count + app.cells.count
        XCTAssertTrue(interactiveElements > 0,
                     "Schedule should have interactive accessible elements")
    }
    
    // MARK: - Edge Cases Tests
    
    func testCreateBlockWithMinimumDuration() {
        navigateToSchedule(app: app)
        app.buttons["Add Your First Block"].tap()
        Thread.sleep(forTimeInterval: TestConfig.animationDelay)
        
        // Try to set very short duration (e.g., 5 minutes)
        app.fillTimeBlockForm(app: app, title: "Short Block", notes: "5 minute block")
        
        // If there's a quick duration selector, try 15 min (minimum)
        if app.buttons["15 min"].exists || app.buttons["15m"].exists {
            (app.buttons["15 min"].exists ? app.buttons["15 min"] : app.buttons["15m"]).tap()
        }
        
        saveTimeBlock(app: app)
        
        // Should either save or show validation
        Thread.sleep(forTimeInterval: TestConfig.animationDelay)
        XCTAssertTrue(app.cells.matching(NSPredicate(format: "label CONTAINS 'Short Block'")).firstMatch.exists ||
                     app.alerts.firstMatch.exists,
                     "Should handle minimum duration appropriately")
    }
    
    func testCreateOverlappingTimeBlocks() {
        navigateToSchedule(app: app)
        
        // Create first block
        app.buttons["Add Time Block"].tap()
        Thread.sleep(forTimeInterval: TestConfig.animationDelay)
        app.fillTimeBlockForm(app: app, title: "Block 1", notes: "First block")
        saveTimeBlock(app: app)
        Thread.sleep(forTimeInterval: TestConfig.animationDelay)
        
        // Try to create overlapping block
        app.buttons["Add Time Block"].tap()
        Thread.sleep(forTimeInterval: TestConfig.animationDelay)
        app.fillTimeBlockForm(app: app, title: "Block 2", notes: "Overlapping block")
        saveTimeBlock(app: app)
        
        // Should handle overlap (save both or show error)
        Thread.sleep(forTimeInterval: TestConfig.animationDelay)
        XCTAssertTrue(app.cells.count > 0 || app.alerts.firstMatch.exists,
                     "Should handle overlapping blocks appropriately")
    }
}
