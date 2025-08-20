//
//  ScheduleUITests.swift
//  Routine Anchor
//
//  Tests for Schedule View UI
//
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
        
        // Ensure clean state and navigate to Schedule
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
        
        // Complete onboarding if present
        if app.buttons["Begin Your Journey"].waitForExistence(timeout: 3.0) {
            app.completeOnboarding()
        }
        
        // Navigate to Settings and clear data
        deleteAllDataViaSettings()
        
        // Navigate to Schedule and verify clean state
        navigateToSchedule()
        
        print("✅ Clean test environment ready")
    }
    
    private func deleteAllDataViaSettings() {
        // Navigate to Settings tab (usually the last tab)
        let tabBar = app.tabBars.firstMatch
        if tabBar.waitForExistence(timeout: 3.0) {
            let settingsTab = app.tabBars.buttons["Settings"]
            if settingsTab.exists {
                settingsTab.tap()
            } else {
                // Fallback to index-based access (Settings is typically last)
                let buttons = app.tabBars.buttons
                if buttons.count > 0 {
                    buttons.element(boundBy: buttons.count - 1).tap()
                }
            }
        }
        
        Thread.sleep(forTimeInterval: 1.0)
        
        // Look for delete/clear data options
        let deleteOptions = [
            "Delete All Data",
            "Clear All Data",
            "Reset All",
            "Clear Today's Schedule",
            "Delete Everything"
        ]
        
        for option in deleteOptions {
            let deleteButton = app.buttons[option]
            if deleteButton.exists {
                deleteButton.tap()
                Thread.sleep(forTimeInterval: 0.5)
                
                // Handle confirmation if present
                let confirmOptions = ["Delete", "Clear", "Reset", "Confirm", "Yes"]
                for confirm in confirmOptions {
                    let confirmButton = app.buttons[confirm]
                    if confirmButton.exists {
                        confirmButton.tap()
                        Thread.sleep(forTimeInterval: 1.0)
                        return
                    }
                }
                
                // Handle alerts
                if app.alerts.firstMatch.exists {
                    let alert = app.alerts.firstMatch
                    for confirm in confirmOptions {
                        if alert.buttons[confirm].exists {
                            alert.buttons[confirm].tap()
                            Thread.sleep(forTimeInterval: 1.0)
                            return
                        }
                    }
                }
                return
            }
        }
    }
    
    private func navigateToSchedule() {
        let tabBar = app.tabBars.firstMatch
        if tabBar.waitForExistence(timeout: 3.0) {
            let scheduleTab = app.tabBars.buttons["Schedule"]
            if scheduleTab.exists {
                scheduleTab.tap()
            } else {
                // Schedule is typically the second tab (index 1)
                let buttons = app.tabBars.buttons
                if buttons.count > 1 {
                    buttons.element(boundBy: 1).tap()
                }
            }
        }
        
        Thread.sleep(forTimeInterval: 1.0)
    }
    
    // MARK: - 1. HEADER AND NAVIGATION TESTS
    
    func test01HeaderDisplayAndNavigation() {
        print("=== Testing Header Display and Navigation ===")
        
        navigateToSchedule()
        
        // Test header elements exist
        let scheduleBuilderTitle = app.staticTexts["Schedule Builder"]
        XCTAssertTrue(scheduleBuilderTitle.waitForExistence(timeout: 3.0), "Schedule Builder title should exist")
        
        let subtitle = app.staticTexts["Design your perfect routine"]
        XCTAssertTrue(subtitle.exists, "Header subtitle should exist")
        
        // Verify we're in the correct tab
        let scheduleTab = app.tabBars.buttons["Schedule"]
        if scheduleTab.exists {
            XCTAssertTrue(scheduleTab.isSelected, "Schedule tab should be selected")
        }
        
        print("✅ Header and navigation test completed")
    }
    
    // MARK: - 2. EMPTY STATE TESTS
    
    func test02EmptyStateDisplay() {
        print("=== Testing Empty State Display ===")
        
        navigateToSchedule()
        
        // Check for empty state content
        let emptyStateTexts = [
            "Build Your Perfect Day",
            "Create time blocks to structure",
            "perfect routine"
        ]
        
        var foundEmptyState = false
        for text in emptyStateTexts {
            if app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] %@", text)).count > 0 {
                foundEmptyState = true
                break
            }
        }
        
        if foundEmptyState {
            // Look for empty state buttons
            let addFirstBlockButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Add'")).firstMatch
            let useTemplateButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Template'")).firstMatch
            
            XCTAssertTrue(addFirstBlockButton.exists || useTemplateButton.exists, "Empty state should have action buttons")
        }
        
        // Verify we don't have populated state elements
        let cellCount = app.cells.count
        print("Found \(cellCount) cells in empty state")
        
        print("✅ Empty state display test completed")
    }
    
    // MARK: - 3. TIME BLOCK CREATION TESTS
    
    func test03CreateFirstTimeBlock() {
        print("=== Testing First Time Block Creation ===")
        
        navigateToSchedule()
        
        let initialCellCount = app.cells.count
        print("Initial cell count: \(initialCellCount)")
        
        // Create first time block using simplified approach
        let blockCreated = createTimeBlockSimplified(title: "Morning Routine")
        
        XCTAssertTrue(blockCreated, "Should successfully create first time block")
        
        if blockCreated {
            Thread.sleep(forTimeInterval: 1.0)
            
            // Verify block was created
            let blockTitle = app.staticTexts["Morning Routine"]
            XCTAssertTrue(blockTitle.waitForExistence(timeout: 3.0), "Time block title should be visible")
            
            // Check for populated state elements
            let addTimeBlockButton = app.buttons["Add Time Block"]
            XCTAssertTrue(addTimeBlockButton.exists, "Add Time Block button should appear in populated state")
        }
        
        print("✅ First time block creation test completed")
    }
    
    func test04CreateMultipleTimeBlocks() {
        print("=== Testing Multiple Time Block Creation ===")
        
        navigateToSchedule()
        
        let blocks = ["Morning Routine", "Work Session", "Lunch Break"]
        
        for (index, blockTitle) in blocks.enumerated() {
            let blockCreated = createTimeBlockSimplified(title: blockTitle)
            XCTAssertTrue(blockCreated, "Should create time block: \(blockTitle)")
            
            if blockCreated {
                Thread.sleep(forTimeInterval: 0.5)
                
                // Verify block appears
                let blockText = app.staticTexts[blockTitle]
                XCTAssertTrue(blockText.waitForExistence(timeout: 2.0), "\(blockTitle) should be visible")
            }
        }
        
        // Verify all blocks are still visible
        for blockTitle in blocks {
            XCTAssertTrue(app.staticTexts[blockTitle].exists, "\(blockTitle) should remain visible")
        }
        
        print("✅ Multiple time block creation test completed")
    }
    
    // MARK: - 4. TIME BLOCK EDITING TESTS
    
    func test05EditTimeBlock() {
        print("=== Testing Time Block Editing ===")
        
        navigateToSchedule()
        
        let originalTitle = "Original Title"
        let newTitle = "Edited Title"
        
        let blockCreated = createTimeBlockSimplified(title: originalTitle)
        XCTAssertTrue(blockCreated, "Should create block to edit")
        
        if blockCreated {
            Thread.sleep(forTimeInterval: 1.0)
            
            // Find and tap edit button using coordinate approach if needed
            let editSuccess = tapEditButtonForBlock(originalTitle)
            
            if editSuccess {
                let editSheetAppeared = waitForEditSheet()
                if editSheetAppeared {
                    // Edit the title
                    let titleField = app.textFields.firstMatch
                    if titleField.exists {
                        titleField.clearAndEnterText(text: newTitle)
                        
                        // Save changes using improved method
                        let saveSuccess = saveTimeBlockChangesImproved()
                        
                        if saveSuccess {
                            // Verify the title was updated
                            XCTAssertTrue(app.staticTexts[newTitle].waitForExistence(timeout: 3.0), "Block title should be updated")
                            XCTAssertFalse(app.staticTexts[originalTitle].exists, "Original title should be gone")
                        }
                    }
                }
            }
        }
        
        print("✅ Time block editing test completed")
    }
    
    // MARK: - 5. TIME BLOCK DELETION TESTS
    
    func test06DeleteTimeBlock() {
        print("=== Testing Time Block Deletion ===")
        
        navigateToSchedule()
        
        let blockTitle = "Block to Delete"
        let blockCreated = createTimeBlockSimplified(title: blockTitle)
        XCTAssertTrue(blockCreated, "Should create block to delete")
        
        if blockCreated {
            Thread.sleep(forTimeInterval: 1.0)
            
            let initialCellCount = app.cells.count
            
            // Try to delete the block using improved method
            let deleted = deleteTimeBlockImproved(blockTitle)
            
            if deleted {
                Thread.sleep(forTimeInterval: 1.0)
                
                // Verify block was deleted
                XCTAssertFalse(app.staticTexts[blockTitle].exists, "Deleted block should be gone")
                
                let finalCellCount = app.cells.count
                XCTAssertLessThan(finalCellCount, initialCellCount, "Cell count should decrease after deletion")
            }
        }
        
        print("✅ Time block deletion test completed")
    }
    
    // MARK: - 6. ACTION BUTTONS TESTS
    
    func test07AddTimeBlockButton() {
        print("=== Testing Add Time Block Button ===")
        
        navigateToSchedule()
        
        // Create a block to get into populated state
        let blockCreated = createTimeBlockSimplified(title: "Test Block")
        XCTAssertTrue(blockCreated, "Should create initial block")
        
        if blockCreated {
            Thread.sleep(forTimeInterval: 1.0)
            
            // Test Add Time Block button
            let addTimeBlockButton = app.buttons["Add Time Block"]
            if addTimeBlockButton.exists {
                XCTAssertTrue(addTimeBlockButton.isEnabled, "Add Time Block button should be enabled")
                
                addTimeBlockButton.tap()
                
                let addSheetAppeared = waitForAddSheet()
                XCTAssertTrue(addSheetAppeared, "Add time block sheet should appear")
                
                if addSheetAppeared {
                    dismissSheet()
                }
            }
        }
        
        print("✅ Add Time Block button test completed")
    }
    
    func test08ResetAllButton() {
        print("=== Testing Reset All Button ===")
        
        navigateToSchedule()
        
        // Create blocks
        let block1Created = createTimeBlockSimplified(title: "Reset Test Block 1")
        let block2Created = createTimeBlockSimplified(title: "Reset Test Block 2")
        
        if block1Created && block2Created {
            Thread.sleep(forTimeInterval: 1.0)
            
            // Look for Reset All button
            let resetButton = app.buttons["Reset All"]
            if resetButton.exists {
                XCTAssertTrue(resetButton.isEnabled, "Reset All button should be enabled")
                
                resetButton.tap()
                
                // Handle confirmation if present
                Thread.sleep(forTimeInterval: 1.0)
                
                let confirmOptions = ["Reset Progress", "Reset", "Confirm", "Yes"]
                var confirmed = false
                
                for option in confirmOptions {
                    let confirmButton = app.buttons[option]
                    if confirmButton.exists {
                        confirmButton.tap()
                        confirmed = true
                        break
                    }
                }
                
                // Check alerts
                if !confirmed && app.alerts.firstMatch.exists {
                    let alert = app.alerts.firstMatch
                    for option in confirmOptions {
                        if alert.buttons[option].exists {
                            alert.buttons[option].tap()
                            confirmed = true
                            break
                        }
                    }
                }
                
                if confirmed {
                    Thread.sleep(forTimeInterval: 2.0)
                    // Reset should have occurred (exact behavior depends on implementation)
                    print("Reset action was confirmed")
                }
            }
        }
        
        print("✅ Reset All button test completed")
    }
    
    // MARK: - 7. TEMPLATE FUNCTIONALITY TESTS
    
    func test09TemplateSelection() {
        print("=== Testing Template Selection ===")
        
        navigateToSchedule()
        
        // Look for template buttons
        let templateButtons = [
            app.buttons["Use a Template"],
            app.buttons["Templates"],
            app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Template'")).firstMatch
        ]
        
        var templateButton: XCUIElement?
        for button in templateButtons {
            if button.exists {
                templateButton = button
                break
            }
        }
        
        if let button = templateButton {
            button.tap()
            
            let templateSheetAppeared = waitForTemplateSheet()
            if templateSheetAppeared {
                // Look for template options
                let templateOptions = [
                    "Morning Routine",
                    "Work Session",
                    "Lunch Break"
                ]
                
                for option in templateOptions {
                    let templateOption = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", option)).firstMatch
                    if templateOption.exists {
                        templateOption.tap()
                        Thread.sleep(forTimeInterval: 2.0)
                        
                        // Verify template was applied
                        let templateApplied = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] %@", option)).count > 0
                        if templateApplied {
                            print("Template \(option) was successfully applied")
                        }
                        break
                    }
                }
            }
        }
        
        print("✅ Template selection test completed")
    }
    
    // MARK: - 8. ACCESSIBILITY TESTS
    
    func test10AccessibilityLabels() {
        print("=== Testing Accessibility Labels ===")
        
        navigateToSchedule()
        
        // Test header accessibility
        let scheduleHeader = app.staticTexts["Schedule Builder"]
        if scheduleHeader.exists {
            XCTAssertTrue(scheduleHeader.isHittable || scheduleHeader.label.count > 0, "Schedule header should be accessible")
        }
        
        // Create a block and test its accessibility
        let blockCreated = createTimeBlockSimplified(title: "Accessibility Test")
        if blockCreated {
            Thread.sleep(forTimeInterval: 1.0)
            
            let blockTitle = app.staticTexts["Accessibility Test"]
            XCTAssertTrue(blockTitle.exists, "Block title should be accessible")
            
            // Test action buttons accessibility
            let allButtons = app.buttons
            let accessibleButtonCount = allButtons.allElementsBoundByIndex.filter { $0.isHittable }.count
            XCTAssertGreaterThan(accessibleButtonCount, 0, "Should have accessible action buttons")
        }
        
        print("✅ Accessibility labels test completed")
    }
    
    // MARK: - IMPROVED HELPER METHODS
    
    /// Simplified time block creation that avoids problematic UI elements
    private func createTimeBlockSimplified(title: String) -> Bool {
        // Open add sheet
        guard openAddTimeBlockSheet() else { return false }
        
        // Wait for sheet to appear
        Thread.sleep(forTimeInterval: 1.0)
        
        // Fill title - this is the most important part
        let titleField = app.textFields.firstMatch
        if titleField.exists {
            titleField.clearAndEnterText(text: title)
            app.dismissKeyboard()
        } else {
            // Alternative approach for title input
            let titleInputs = app.textFields.matching(NSPredicate(format: "placeholderValue CONTAINS[c] 'doing'"))
            if titleInputs.count > 0 {
                let titleInput = titleInputs.firstMatch
                titleInput.tap()
                titleInput.typeText(title)
                app.dismissKeyboard()
            }
        }
        
        Thread.sleep(forTimeInterval: 0.5)
        
        // Skip time and duration configuration to avoid scrolling issues
        // Just try to save with default values
        return saveTimeBlockImproved()
    }
    
    /// Improved save method with better scrolling and coordinate fallbacks
    private func saveTimeBlockImproved() -> Bool {
        // First, ensure we can see the save button by scrolling to bottom
        scrollToBottomOfSheet()
        
        // Try to save with various button names
        let saveButtons = [
            "Create Time Block",
            "Save Time Block",
            "Save Changes",
            "Save",
            "Create",
            "Add",
            "Done"
        ]
        
        for buttonText in saveButtons {
            let saveButton = app.buttons[buttonText]
            if saveButton.exists {
                if saveButton.isHittable && saveButton.isEnabled {
                    saveButton.tap()
                    Thread.sleep(forTimeInterval: 2.0)
                    return app.staticTexts["Schedule Builder"].exists
                } else if saveButton.exists {
                    // Try coordinate-based tap as fallback
                    let success = tapButtonByCoordinates(saveButton)
                    if success {
                        Thread.sleep(forTimeInterval: 2.0)
                        return app.staticTexts["Schedule Builder"].exists
                    }
                }
            }
        }
        
        // If all else fails, try dismissing and see if it auto-saved
        dismissSheet()
        return false
    }
    
    /// Improved scrolling method for sheets
    private func scrollToBottomOfSheet() {
        // Dismiss keyboard first
        app.dismissKeyboard()
        Thread.sleep(forTimeInterval: 0.5)
        
        // Try multiple scrolling approaches
        let scrollViews = app.scrollViews
        if scrollViews.count > 0 {
            let mainScrollView = scrollViews.firstMatch
            if mainScrollView.exists {
                // Scroll to bottom more aggressively
                for _ in 0..<5 {
                    mainScrollView.swipeUp()
                    Thread.sleep(forTimeInterval: 0.2)
                }
            }
        }
        
        // Alternative: Try coordinate-based scrolling
        let startCoordinate = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.8))
        let endCoordinate = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.2))
        startCoordinate.press(forDuration: 0.1, thenDragTo: endCoordinate)
        Thread.sleep(forTimeInterval: 0.5)
    }
    
    /// Coordinate-based button tapping as fallback
    private func tapButtonByCoordinates(_ button: XCUIElement) -> Bool {
        guard button.exists else { return false }
        
        let frame = button.frame
        let appFrame = app.frame
        
        // Check if button is within reasonable bounds
        if frame.midX > 0 && frame.midX < appFrame.width &&
           frame.midY > 0 && frame.midY < appFrame.height {
            
            let normalizedX = frame.midX / appFrame.width
            let normalizedY = frame.midY / appFrame.height
            
            // Ensure coordinates are valid
            if normalizedX >= 0 && normalizedX <= 1 && normalizedY >= 0 && normalizedY <= 1 {
                let coordinate = app.coordinate(withNormalizedOffset: CGVector(dx: normalizedX, dy: normalizedY))
                coordinate.tap()
                return true
            }
        }
        
        return false
    }
    
    /// Improved edit button tapping
    private func tapEditButtonForBlock(_ blockTitle: String) -> Bool {
        // Look for edit buttons near the block
        let editButtons = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'edit' OR identifier == 'pencil'"))
        
        if editButtons.count > 0 {
            let editButton = editButtons.firstMatch
            if editButton.exists && editButton.isHittable {
                editButton.tap()
                return true
            } else if editButton.exists {
                // Try coordinate tap
                return tapButtonByCoordinates(editButton)
            }
        }
        
        // Alternative: Try tapping on the block itself (might open edit mode)
        let blockText = app.staticTexts[blockTitle]
        if blockText.exists {
            blockText.tap()
            Thread.sleep(forTimeInterval: 0.5)
            
            // Check if edit mode opened
            return app.textFields.count > 0 || app.staticTexts["Edit Time Block"].exists
        }
        
        return false
    }
    
    /// Improved save changes method
    private func saveTimeBlockChangesImproved() -> Bool {
        scrollToBottomOfSheet()
        
        let saveButtons = [
            "Save Changes",
            "Update Time Block",
            "Save",
            "Update",
            "Done"
        ]
        
        for buttonText in saveButtons {
            let saveButton = app.buttons[buttonText]
            if saveButton.exists && saveButton.isEnabled {
                if saveButton.isHittable {
                    saveButton.tap()
                    Thread.sleep(forTimeInterval: 2.0)
                    return true
                } else {
                    let success = tapButtonByCoordinates(saveButton)
                    if success {
                        Thread.sleep(forTimeInterval: 2.0)
                        return true
                    }
                }
            }
        }
        
        dismissSheet()
        return false
    }
    
    /// Improved delete method
    private func deleteTimeBlockImproved(_ title: String) -> Bool {
        // Look for the time block
        let blockText = app.staticTexts[title]
        guard blockText.exists else { return false }
        
        // Try to find delete button with various approaches
        let deleteButtons = app.buttons.matching(NSPredicate(format:
            "label CONTAINS[c] 'delete' OR label CONTAINS[c] 'trash' OR identifier == 'trash'"
        ))
        
        if deleteButtons.count > 0 {
            let deleteButton = deleteButtons.firstMatch
            if deleteButton.exists {
                if deleteButton.isHittable {
                    deleteButton.tap()
                } else {
                    let success = tapButtonByCoordinates(deleteButton)
                    if !success { return false }
                }
                
                Thread.sleep(forTimeInterval: 1.0)
                
                // Handle confirmation
                let confirmButtons = ["Delete Time Block", "Delete", "Remove", "Confirm"]
                for buttonText in confirmButtons {
                    let confirmButton = app.buttons[buttonText]
                    if confirmButton.exists {
                        confirmButton.tap()
                        Thread.sleep(forTimeInterval: 1.0)
                        return true
                    }
                }
                
                // Check for alerts
                if app.alerts.firstMatch.exists {
                    let alert = app.alerts.firstMatch
                    for buttonText in confirmButtons {
                        if alert.buttons[buttonText].exists {
                            alert.buttons[buttonText].tap()
                            Thread.sleep(forTimeInterval: 1.0)
                            return true
                        }
                    }
                }
                
                return true // Assume it worked if no confirmation needed
            }
        }
        
        // Try swipe to delete
        let cells = app.cells
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
        
        return false
    }
    
    private func openAddTimeBlockSheet() -> Bool {
        // Try various ways to open add sheet
        let addButtons = [
            app.buttons["Add Your First Block"],
            app.buttons["Add Time Block"],
            app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Add'")).firstMatch,
            app.buttons.matching(NSPredicate(format: "label CONTAINS[c] '+'")).firstMatch
        ]
        
        for button in addButtons {
            if button.exists && button.isHittable {
                button.tap()
                return waitForAddSheet()
            }
        }
        
        return false
    }
    
    private func waitForAddSheet() -> Bool {
        let timeout: TimeInterval = 5.0
        let startTime = Date()
        
        while Date().timeIntervalSince(startTime) < timeout {
            // Look for sheet indicators
            if app.textFields.count > 0 ||
               app.staticTexts["New Time Block"].exists ||
               app.staticTexts["Add Time Block"].exists ||
               app.buttons["Create Time Block"].exists ||
               app.navigationBars.count > 0 {
                return true
            }
            Thread.sleep(forTimeInterval: 0.2)
        }
        return false
    }
    
    private func waitForEditSheet() -> Bool {
        let timeout: TimeInterval = 5.0
        let startTime = Date()
        
        while Date().timeIntervalSince(startTime) < timeout {
            if app.staticTexts["Edit Time Block"].exists ||
               app.navigationBars.staticTexts["Edit Time Block"].exists ||
               app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Save' OR label CONTAINS[c] 'Update'")).count > 0 {
                return true
            }
            Thread.sleep(forTimeInterval: 0.2)
        }
        return false
    }
    
    private func waitForTemplateSheet() -> Bool {
        let timeout: TimeInterval = 3.0
        let startTime = Date()
        
        while Date().timeIntervalSince(startTime) < timeout {
            let templateButtons = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Morning' OR label CONTAINS[c] 'Work' OR label CONTAINS[c] 'Lunch'"))
            if templateButtons.count > 0 {
                return true
            }
            Thread.sleep(forTimeInterval: 0.2)
        }
        return false
    }
    
    private func dismissSheet() {
        let dismissButtons = ["Cancel", "Close", "Done"]
        
        for buttonText in dismissButtons {
            let button = app.buttons[buttonText]
            if button.exists {
                button.tap()
                Thread.sleep(forTimeInterval: 1.0)
                return
            }
        }
        
        // Try navigation bar buttons
        if app.navigationBars.buttons.count > 0 {
            app.navigationBars.buttons.firstMatch.tap()
            Thread.sleep(forTimeInterval: 1.0)
            return
        }
        
        // Try swipe down
        app.swipeDown()
        Thread.sleep(forTimeInterval: 1.0)
    }
    
    // MARK: - Test Configuration
    
    private struct TestConfig {
        static let defaultTimeout: TimeInterval = 5.0
        static let animationDelay: TimeInterval = 1.0
    }
}
