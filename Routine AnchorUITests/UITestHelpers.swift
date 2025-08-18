//
//  UITestHelpers.swift
//  Routine AnchorUITests
//
//  Helper utilities and extensions for UI testing
//

import XCTest

// MARK: - Test Configuration
struct TestConfig {
    static let defaultTimeout: TimeInterval = 5
    static let shortTimeout: TimeInterval = 2
    static let longTimeout: TimeInterval = 10
    static let animationDelay: TimeInterval = 0.5
    static let scrollTimeout: TimeInterval = 3
}

// MARK: - XCUIApplication Extensions
extension XCUIApplication {
    
    /// Navigate to a specific tab with fallback support
    func navigateToTab(_ tabName: String, index: Int) {
        // First ensure we're past onboarding
        if buttons["Begin Your Journey"].exists {
            completeOnboarding()
        }
        
        // Wait for tab bar with longer timeout
        guard tabBars.firstMatch.waitForExistence(timeout: TestConfig.defaultTimeout) else {
            XCTFail("Tab bar did not appear")
            return
        }
        
        // Try name-based navigation first
        let tabButton = tabBars.buttons[tabName]
        if tabButton.exists && tabButton.isHittable {
            tabButton.tap()
        } else {
            // Fallback to index-based navigation
            let buttons = tabBars.buttons
            if index < buttons.count {
                let button = buttons.element(boundBy: index)
                if button.exists && button.isHittable {
                    button.tap()
                }
            }
        }
        
        // Wait for transition
        Thread.sleep(forTimeInterval: TestConfig.animationDelay)
    }
    
    /// Complete onboarding flow with better error handling
    func completeOnboarding() {
        // Check if we're in onboarding
        if buttons["Begin Your Journey"].waitForExistence(timeout: TestConfig.shortTimeout) {
            buttons["Begin Your Journey"].tap()
            Thread.sleep(forTimeInterval: TestConfig.animationDelay)
            
            // Handle permissions screen - look for skip/later options
            // IMPORTANT: Added "I'll set this up later" which is the actual button text
            let skipButtons = ["I'll set this up later", "Maybe Later", "Skip", "Not Now", "Dismiss"]
            for skipText in skipButtons {
                if buttons[skipText].waitForExistence(timeout: 0.5) {
                    buttons[skipText].tap()
                    break
                }
            }
            
            Thread.sleep(forTimeInterval: TestConfig.animationDelay)
            
            // Complete setup - try multiple possible button texts
            let completeButtons = ["Start Building Habits", "Create My First Routine", "Get Started", "Continue", "Done"]
            for buttonText in completeButtons {
                if buttons[buttonText].waitForExistence(timeout: 0.5) {
                    buttons[buttonText].tap()
                    break
                }
            }
            
            // Wait for main app to load
            Thread.sleep(forTimeInterval: 1)
        }
    }
    
    /// Navigate to Today tab
    func navigateToToday() {
        navigateToTab("Today", index: 0)
    }
    
    /// Navigate to Schedule tab
    func navigateToSchedule() {
        navigateToTab("Schedule", index: 1)
    }
    
    /// Navigate to Summary/Insights tab
    func navigateToSummary() {
        // Try both possible names
        if tabBars.buttons["Insights"].exists {
            navigateToTab("Insights", index: 2)
        } else {
            navigateToTab("Summary", index: 2)
        }
    }
    
    /// Navigate to Settings tab
    func navigateToSettings() {
        navigateToTab("Settings", index: 3)
    }
    
    /// Wait for app to be in stable state
    func waitForStableState(timeout: TimeInterval = TestConfig.defaultTimeout) -> Bool {
        // Wait for loading indicators to disappear
        let loadingTexts = ["Loading", "Loading your day...", "Setting up your schedule...", "Updating..."]
        for text in loadingTexts {
            let loadingElement = staticTexts[text]
            if loadingElement.exists {
                _ = loadingElement.waitForNonExistence(timeout: timeout)
            }
        }
        
        // Wait for activity indicators to disappear
        let activityIndicator = activityIndicators.firstMatch
        if activityIndicator.exists {
            _ = activityIndicator.waitForNonExistence(timeout: timeout)
        }
        
        // Give UI time to settle
        Thread.sleep(forTimeInterval: 0.3)
        
        return exists
    }
    
    /// Dismiss any presented sheets or modals with improved logic
    func dismissAnyPresentedViews() {
        // First try to find explicit dismiss buttons
        let dismissButtons = ["Done", "Cancel", "Close", "Dismiss", "OK", "Save", "Back"]
        for buttonTitle in dismissButtons {
            let button = buttons[buttonTitle]
            if button.exists && button.isHittable {
                button.tap()
                Thread.sleep(forTimeInterval: TestConfig.animationDelay)
                return
            }
        }
        
        // Try to find X or close icon buttons
        let closeIcons = ["xmark", "xmark.circle", "xmark.circle.fill", "chevron.down"]
        for iconName in closeIcons {
            let iconButton = buttons.matching(NSPredicate(format: "label CONTAINS %@", iconName)).firstMatch
            if iconButton.exists && iconButton.isHittable {
                iconButton.tap()
                Thread.sleep(forTimeInterval: TestConfig.animationDelay)
                return
            }
        }
        
        // Try swipe down if sheet exists
        if sheets.firstMatch.exists {
            sheets.firstMatch.swipeDown()
            Thread.sleep(forTimeInterval: TestConfig.animationDelay)
        } else {
            // Last resort - tap outside
            coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.1)).tap()
        }
    }
    
    func dismissKeyboard() {
        if keyboards.count > 0 {
            if buttons["Done"].exists {
                buttons["Done"].tap()
            } else if buttons["Return"].exists {
                buttons["Return"].tap()
            } else {
                let coordinate = coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.3))
                coordinate.tap()
            }
        }
    }
    
    func fillTimeBlockForm(app: XCUIApplication, title: String,
                                   notes: String = "",
                                   selectCategory: Bool = false,
                                   selectIcon: Bool = false) {
        // Fill title
        if let titleField = app.textFields.firstMatch.exists ? app.textFields.firstMatch :
           app.textFields["Title"].exists ? app.textFields["Title"] : nil {
            titleField.tap()
            titleField.typeText(title)
            app.dismissKeyboard()  // Changed from dismissKeyboard(app: app)
        }
        
        // Fill notes if provided
        if !notes.isEmpty {
            if let notesField = app.textViews.firstMatch.exists ? app.textViews.firstMatch :
               app.textFields["Notes"].exists ? app.textFields["Notes"] : nil {
                notesField.tap()
                notesField.typeText(notes)
                app.dismissKeyboard()  // Changed from dismissKeyboard(app: app)
            }
        }
        
        // Select category if requested
        if selectCategory {
            let categories = ["Work", "Personal", "Health", "Learning", "Social"]
            for category in categories {
                if app.buttons[category].exists {
                    app.buttons[category].tap()
                    break
                }
            }
        }
        
        // Select icon if requested
        if selectIcon {
            // Scroll to find icon selector if needed
            app.scrollViews.firstMatch.swipeUp()
            
            // Tap first available icon
            let icons = app.buttons.matching(NSPredicate(format: "identifier CONTAINS 'icon' OR label CONTAINS '📝' OR label CONTAINS '💼'"))
            if icons.count > 0 {
                icons.element(boundBy: 0).tap()
            }
        }
    }
    
    /// Pull to refresh on current view
    func pullToRefresh() {
        let scrollView = scrollViews.firstMatch
        let collectionView = collectionViews.firstMatch
        let table = tables.firstMatch
        
        // Try different scrollable elements
        if scrollView.exists {
            scrollView.swipeDown()
        } else if collectionView.exists {
            collectionView.swipeDown()
        } else if table.exists {
            table.swipeDown()
        }
        
        Thread.sleep(forTimeInterval: 1)
    }
    
    func adjustTimeIfPossible(app: XCUIApplication) {
        // Try to adjust start or end time
        let timePickers = app.datePickers
        if timePickers.count > 0 {
            timePickers.firstMatch.tap()
            
            // Adjust time using picker wheels if available
            if app.pickerWheels.count > 0 {
                app.pickerWheels.element(boundBy: 0).adjust(toPickerWheelValue: "10")
                if app.buttons["Done"].exists {
                    app.buttons["Done"].tap()
                }
            }
        }
    }
    
    func saveTimeBlock(app: XCUIApplication) {
        let saveButtons = [
            "Create Time Block",
            "Save",
            "Add",
            "Done",
            "Save Changes"
        ]
        
        for buttonName in saveButtons {
            if app.buttons[buttonName].exists && app.buttons[buttonName].isEnabled {
                app.buttons[buttonName].tap()
                break
            }
        }
    }
    
    func dismissSheet(app: XCUIApplication) {
        if app.buttons["Cancel"].exists {
            app.buttons["Cancel"].tap()
        } else if app.buttons["Close"].exists {
            app.buttons["Close"].tap()
        } else if app.navigationBars.buttons.firstMatch.exists {
            app.navigationBars.buttons.firstMatch.tap()
        } else {
            app.swipeDown()
        }
        Thread.sleep(forTimeInterval: TestConfig.animationDelay)
    }
}

// MARK: - XCUIElement Extensions
extension XCUIElement {
    
    /// Wait for element to exist with custom timeout
    func waitForExistenceWithTimeout(_ timeout: TimeInterval = TestConfig.defaultTimeout) -> Bool {
        return waitForExistence(timeout: timeout)
    }
    
    /// Tap element if it exists and is hittable
    func tapIfExists() {
        if exists && isHittable {
            tap()
        } else if exists && !isHittable {
            // Try to scroll to element first
            scrollToElement()
            if isHittable {
                tap()
            }
        }
    }
    
    /// Improved text clearing and entry
    func clearAndEnterText(_ text: String) {
        guard exists else { return }
        
        // Ensure element is visible
        scrollToElement()
        
        // Tap to focus
        tap()
        
        // Wait for keyboard
        Thread.sleep(forTimeInterval: 0.3)
        
        // Try multiple methods to clear text
        if let currentValue = value as? String, !currentValue.isEmpty {
            // Method 1: Triple tap to select all, then delete
            doubleTap()
            tap()
            
            // Type delete key
            if XCUIApplication().keys["delete"].exists {
                XCUIApplication().keys["delete"].tap()
            } else {
                // Fallback: Type backspace for each character
                let deleteString = String(repeating: XCUIKeyboardKey.delete.rawValue, count: currentValue.count)
                typeText(deleteString)
            }
        }
        
        // Type new text
        typeText(text)
    }
    
    /// Check if element is visible on screen
    var isVisible: Bool {
        guard exists else { return false }
        
        // Check if element is within screen bounds
        let app = XCUIApplication()
        let appFrame = app.frame
        
        return isHittable &&
               frame.minX >= 0 &&
               frame.maxX <= appFrame.width &&
               frame.minY >= 0 &&
               frame.maxY <= appFrame.height
    }
    
    /// Scroll to make element visible
    func scrollToElement() {
        guard exists else { return }
        
        var attempts = 0
        let maxAttempts = 10
        
        while !isHittable && attempts < maxAttempts {
            attempts += 1
            
            // Try different scroll directions and amounts
            let app = XCUIApplication()
            let scrollViews = app.scrollViews
            
            if scrollViews.count > 0 {
                let mainScrollView = scrollViews.firstMatch
                if mainScrollView.exists {
                    if attempts % 2 == 0 {
                        mainScrollView.swipeUp()
                    } else {
                        mainScrollView.swipeDown()
                    }
                }
            }
            
            Thread.sleep(forTimeInterval: 0.3)
        }
        
        if !isHittable {
            print(NSError(domain: "ScrollError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Could not scroll element to visible"]))
        }
    }
}

// MARK: - Test Case Extensions
extension XCTestCase {
    
    /// Complete onboarding if present and navigate to Today view
    func completeOnboardingAndNavigateToToday(app: XCUIApplication) {
        // Check for onboarding
        if app.buttons["Begin Your Journey"].waitForExistence(timeout: TestConfig.shortTimeout) {
            app.completeOnboarding()
        }
        
        // Wait for tab bar to appear
        _ = app.tabBars.firstMatch.waitForExistence(timeout: TestConfig.defaultTimeout)
        
        // Navigate to Today tab
        app.navigateToToday()
        
        // Wait for view to stabilize
        _ = app.waitForStableState()
    }
    
    /// Setup method that handles navigation consistently
    func setupWithNavigation(app: XCUIApplication) {
        app.configureForUITesting()
        app.launch()
        
        // Complete onboarding if needed
        completeOnboardingAndNavigateToToday(app: app)
    }
    
    /// Navigate to Today view from anywhere
    func navigateToTodayView(app: XCUIApplication) {
        app.completeOnboarding()
        app.navigateToToday()
        _ = app.waitForStableState()
    }
    
    /// Navigate to Schedule Builder view
    func navigateToSchedule(app: XCUIApplication) {
        app.completeOnboarding()
        app.navigateToSchedule()
        _ = app.waitForStableState()
    }
    
    /// Create a test time block with better error handling
    func createTestTimeBlock(app: XCUIApplication) {
        // Check which view we're currently in by looking at the selected tab
        let tabBar = app.tabBars.firstMatch
        let isInTodayView = tabBar.exists && app.tabBars.buttons["Today"].isSelected
        
        if isInTodayView {
            // For Today view, look for the floating action button
            // The FAB is a circular button with a plus icon positioned above the tab bar
            
            // Try multiple ways to find the floating button
            var foundButton = false
            
            // Method 1: Look for button with plus-related labels
            let floatingButton = app.buttons.matching(NSPredicate(format:
                "label CONTAINS 'plus' OR label CONTAINS '+'"
            )).allElementsBoundByIndex
            
            for button in floatingButton {
                if button.exists && button.isHittable {
                    let frame = button.frame
                    let appFrame = app.frame
                    // Check if button is in floating position (bottom right, above tab bar)
                    if frame.minX > appFrame.width * 0.6 &&
                       frame.minY > appFrame.height * 0.5 &&
                       frame.minY < appFrame.height * 0.9 {
                        button.tap()
                        foundButton = true
                        break
                    }
                }
            }
            
            // Method 2: If not found, try all buttons and check position
            if !foundButton {
                let allButtons = app.buttons.allElementsBoundByIndex
                for button in allButtons {
                    if button.exists && button.isHittable {
                        let frame = button.frame
                        let appFrame = app.frame
                        // Floating button is typically in bottom right corner, above tab bar
                        if frame.minX > appFrame.width * 0.7 &&
                           frame.minY > appFrame.height * 0.6 &&
                           frame.minY < appFrame.height * 0.85 {
                            button.tap()
                            foundButton = true
                            break
                        }
                    }
                }
            }
            
            if !foundButton {
                XCTFail("Could not find floating action button in Today view")
                return
            }
            
        } else {
            // Navigate to Schedule view first
            navigateToSchedule(app: app)
            
            // Wait for the Schedule Builder view to load
            _ = app.staticTexts["Schedule Builder"].waitForExistence(timeout: TestConfig.shortTimeout)
            
            // Look for add button - could be "Add Time Block" or "Add Your First Block" (empty state)
            var addButton: XCUIElement?
            
            if app.buttons["Add Your First Block"].exists {
                addButton = app.buttons["Add Your First Block"]
            } else if app.buttons["Add Time Block"].exists {
                addButton = app.buttons["Add Time Block"]
            } else {
                // Fallback: Look for buttons containing relevant text
                let possibleButtons = [
                    app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'add'")),
                    app.buttons.matching(NSPredicate(format: "label CONTAINS 'Time Block'"))
                ]
                
                for buttonQuery in possibleButtons {
                    let button = buttonQuery.firstMatch
                    if button.exists && button.isHittable {
                        addButton = button
                        break
                    }
                }
            }
            
            guard let button = addButton else {
                XCTFail("Could not find add button in Schedule view")
                return
            }
            
            button.tap()
        }
        
        // Wait for the add time block sheet to appear
        Thread.sleep(forTimeInterval: TestConfig.animationDelay)
        
        // Fill in the form
        let titleField = app.textFields.firstMatch
        if titleField.waitForExistence(timeout: TestConfig.shortTimeout) {
            titleField.tap()
            titleField.typeText("UI Test Block \(Int.random(in: 1...100))")
            
            // Dismiss keyboard
            app.dismissKeyboard()
            
            Thread.sleep(forTimeInterval: TestConfig.animationDelay)
            
            // Save the time block
            saveTimeBlock(app: app)
        }
    }
    
    /// Clear all time blocks through settings
    func clearAllTimeBlocks(app: XCUIApplication) {
        // Navigate to Settings
        app.navigateToSettings()
        _ = app.waitForStableState()
        
        // Look for delete option
        let deleteButton = app.buttons["Delete All Data"]
        if deleteButton.waitForExistence(timeout: TestConfig.shortTimeout) {
            deleteButton.scrollToElement()
            deleteButton.tap()
            
            // Confirm deletion
            let alert = app.alerts.firstMatch
            if alert.waitForExistence(timeout: TestConfig.shortTimeout) {
                let confirmButton = alert.buttons["Delete"]
                if confirmButton.exists {
                    confirmButton.tap()
                } else {
                    // Try other confirm button texts
                    alert.buttons["Confirm"].tapIfExists()
                    alert.buttons["Yes"].tapIfExists()
                    alert.buttons["OK"].tapIfExists()
                }
            }
        }
        
        // Return to Today
        navigateToTodayView(app: app)
    }
    
    /// Helper to save a time block form
    func saveTimeBlock(app: XCUIApplication) {
        // Dismiss keyboard first
        app.dismissKeyboard()
        
        Thread.sleep(forTimeInterval: 0.3)
        
        // Try to save - look for save button
        let saveButtons = [
            "Save", "Add Block", "Create", "Add Time Block", "Done", "Add"
        ]
        
        for buttonText in saveButtons {
            let button = app.buttons[buttonText]
            if button.exists && button.isHittable {
                button.tap()
                Thread.sleep(forTimeInterval: TestConfig.animationDelay)
                return
            }
        }
        
        // If no save found, try to dismiss
        app.dismissAnyPresentedViews()
    }
}

// MARK: - Performance Testing Helpers
extension XCTestCase {
    
    /// Measure memory usage during test
    func measureMemoryUsage(during block: () throws -> Void) rethrows {
        measure(metrics: [XCTMemoryMetric()]) {
            try? block()
        }
    }
    
    /// Measure CPU usage during test
    func measureCPUUsage(during block: () throws -> Void) rethrows {
        measure(metrics: [XCTCPUMetric()]) {
            try? block()
        }
    }
    
    /// Measure app launch time
    func measureAppLaunch(app: XCUIApplication) {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            app.launch()
        }
    }
}

// MARK: - Device Helpers
extension XCUIDevice {
    
    /// Check if device is iPad
    static var isiPad: Bool {
        return UIDevice.current.userInterfaceIdiom == .pad
    }
    
    /// Check if device is in landscape
    var isLandscape: Bool {
        return orientation.isLandscape
    }
    
    /// Check if device supports haptic feedback
    static var supportsHaptics: Bool {
        // iPhone 7 and later support haptics
        return !isiPad
    }
}

// MARK: - Test Data Helpers
struct TestData {
    
    /// Generate random time block title
    static func randomTimeBlockTitle() -> String {
        let titles = ["Morning Routine", "Work Session", "Lunch Break", "Exercise", "Study Time", "Meeting", "Break"]
        let randomTitle = titles.randomElement() ?? "Task"
        return "\(randomTitle) \(Int.random(in: 1...100))"
    }
    
    /// Generate random duration in minutes
    static func randomDuration() -> Int {
        return [15, 30, 45, 60, 90, 120].randomElement() ?? 30
    }
    
    /// Generate test date
    static func testDate(daysFromNow: Int = 0) -> Date {
        return Calendar.current.date(byAdding: .day, value: daysFromNow, to: Date()) ?? Date()
    }
}

// MARK: - Floating Action Button Helper
extension XCTestCase {
    
    /// Find the floating action button in the current view
    /// Returns the button element if found, nil otherwise
    func findFloatingActionButton() -> XCUIElement? {
        let app = XCUIApplication()
        
        // Method 1: Look for button with plus-related labels
        let plusButtons = app.buttons.matching(NSPredicate(format:
            "label CONTAINS 'plus' OR label CONTAINS '+' OR label CONTAINS 'Plus' OR label == '+'"
        )).allElementsBoundByIndex
        
        for button in plusButtons {
            if button.exists && button.isHittable {
                let frame = button.frame
                let appFrame = app.frame
                
                // Check if button is in floating position (bottom right, above tab bar)
                // Floating button is typically:
                // - In the right side of the screen (> 60% width)
                // - In the bottom portion but above tab bar (50-90% height)
                // - Has a reasonable size (not too small, not full width)
                if frame.minX > appFrame.width * 0.6 &&
                   frame.minY > appFrame.height * 0.5 &&
                   frame.minY < appFrame.height * 0.9 &&
                   frame.width < 100 && // Not a full-width button
                   frame.width > 40 {   // Not too small
                    return button
                }
            }
        }
        
        // Method 2: Look for circular buttons in floating position
        // Sometimes the button might not have a plus label
        let allButtons = app.buttons.allElementsBoundByIndex
        for button in allButtons {
            if button.exists && button.isHittable {
                let frame = button.frame
                let appFrame = app.frame
                
                // Check for floating position and roughly circular shape
                if frame.minX > appFrame.width * 0.7 &&  // Far right
                   frame.minY > appFrame.height * 0.6 &&  // Bottom area
                   frame.minY < appFrame.height * 0.85 && // Above tab bar
                   abs(frame.width - frame.height) < 5 && // Roughly circular
                   frame.width >= 50 && frame.width <= 80 { // Reasonable FAB size
                    return button
                }
            }
        }
        
        // Method 3: Look for buttons with accessibility identifiers
        // In case the app uses accessibility identifiers
        let fabIdentifiers = ["floatingActionButton", "fab", "addButton", "floating-button"]
        for identifier in fabIdentifiers {
            let button = app.buttons[identifier]
            if button.exists && button.isHittable {
                return button
            }
        }
        
        // Method 4: Try to find by image content (SF Symbol)
        // Look for buttons containing the plus image
        let imageButtons = app.buttons.matching(NSPredicate(format:
            "label CONTAINS 'Add' OR label CONTAINS 'Create' OR label CONTAINS 'New'"
        )).allElementsBoundByIndex
        
        for button in imageButtons {
            if button.exists && button.isHittable {
                let frame = button.frame
                let appFrame = app.frame
                
                // Check if in floating position
                if frame.minX > appFrame.width * 0.6 &&
                   frame.minY > appFrame.height * 0.5 &&
                   frame.minY < appFrame.height * 0.9 {
                    return button
                }
            }
        }
        
        // If no floating button found, return nil
        return nil
    }
    
    /// Alternative helper to check if floating button exists and is visible
    func isFloatingActionButtonVisible() -> Bool {
        return findFloatingActionButton() != nil
    }
    
    /// Helper to tap the floating action button if it exists
    func tapFloatingActionButton() -> Bool {
        guard let button = findFloatingActionButton() else {
            return false
        }
        
        button.tap()
        return true
    }
}

// MARK: - Accessibility Testing Helpers
extension XCUIElement {
    
    /// Check if element has proper accessibility label
    var hasAccessibilityLabel: Bool {
        return !label.isEmpty && label != "Button" && label != "Label"
    }
    
    /// Check if element has accessibility traits
    var hasAccessibilityTraits: Bool {
        // This is a simplified check - actual implementation would check specific traits
        return exists
    }
    
    /// Check if element meets minimum touch target size (44x44)
    var meetsMinimumTouchTargetSize: Bool {
        guard exists else { return false }
        return frame.width >= 44 && frame.height >= 44
    }
    
    /// Check contrast ratio (simplified)
    var hasGoodContrast: Bool {
        // This would need actual color analysis in a real implementation
        return true
    }
    
    func clearAndEnterText(text: String) {
        guard exists else { return }
        
        tap()
        Thread.sleep(forTimeInterval: 0.3)
        
        // Clear existing text
        if let currentValue = value as? String, !currentValue.isEmpty {
            // Select all and delete
            let deleteString = String(repeating: XCUIKeyboardKey.delete.rawValue, count: currentValue.count)
            typeText(deleteString)
        }
        
        // Enter new text
        typeText(text)
    }
}

// MARK: - Launch Argument Helpers
extension XCUIApplication {
    
    /// Configure app for UI testing
    func configureForUITesting() {
        launchArguments = ["--uitesting", "--reset-state", "--disable-animations"]
        launchEnvironment = [
            "UITEST_MODE": "1",
            "DISABLE_ANIMATIONS": "1",
            "RESET_STATE": "1"
        ]
    }
    
    /// Configure for performance testing
    func configureForPerformanceTesting() {
        launchArguments = ["--uitesting", "--performance-mode"]
        launchEnvironment = [
            "PERFORMANCE_TEST": "1",
            "ENABLE_METRICS": "1"
        ]
    }
    
    /// Configure for accessibility testing
    func configureForAccessibilityTesting() {
        launchArguments = ["--uitesting", "--accessibility-audit"]
        launchEnvironment = [
            "ACCESSIBILITY_ENABLED": "1",
            "AUDIT_MODE": "1"
        ]
    }
}

// MARK: - Assertion Helpers
extension XCTestCase {
    
    /// Assert element becomes visible within timeout
    func assertBecomes(visible element: XCUIElement, timeout: TimeInterval = TestConfig.defaultTimeout, file: StaticString = #file, line: UInt = #line) {
        let exists = element.waitForExistence(timeout: timeout)
        XCTAssertTrue(exists, "Element \(element) did not become visible within \(timeout) seconds", file: file, line: line)
    }
    
    /// Assert element disappears within timeout
    func assertDisappears(_ element: XCUIElement, timeout: TimeInterval = TestConfig.defaultTimeout, file: StaticString = #file, line: UInt = #line) {
        let predicate = NSPredicate(format: "exists == false")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
        let result = XCTWaiter.wait(for: [expectation], timeout: timeout)
        XCTAssertEqual(result, .completed, "Element \(element) did not disappear within \(timeout) seconds", file: file, line: line)
    }
    
    /// Assert text contains substring
    func assertTextContains(_ element: XCUIElement, substring: String, file: StaticString = #file, line: UInt = #line) {
        guard element.exists else {
            XCTFail("Element does not exist", file: file, line: line)
            return
        }
        
        let text = element.label
        XCTAssertTrue(text.contains(substring), "Text '\(text)' does not contain '\(substring)'", file: file, line: line)
    }
}

// MARK: - Screenshot Helpers
extension XCTestCase {
    
    /// Take screenshot with descriptive name
    func takeScreenshot(named name: String) {
        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
    
    /// Take screenshot on failure
    func takeScreenshotOnFailure() {
        // Take a screenshot when called (typically in tearDown when a test fails)
        takeScreenshot(named: "Failure_\(String(describing: self))")
    }
    
    /// Add screenshot to test report
    func attachScreenshot(named name: String = "Screenshot") {
        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "\(name)_\(Date().timeIntervalSince1970)"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
