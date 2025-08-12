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
}

// MARK: - XCUIApplication Extensions
extension XCUIApplication {
    
    /// Navigate to a specific tab with fallback support
    func navigateToTab(_ tabName: String, index: Int) {
        let tabButton = tabBars.buttons[tabName]
        if tabButton.exists {
            tabButton.tap()
        } else {
            // Fallback to index-based navigation
            let buttons = tabBars.buttons
            if index < buttons.count {
                buttons.element(boundBy: index).tap()
            }
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
    
    /// Navigate to Summary tab
    func navigateToSummary() {
        navigateToTab("Summary", index: 2)
    }
    
    /// Navigate to Settings tab
    func navigateToSettings() {
        navigateToTab("Settings", index: 3)
    }
    
    /// Wait for app to be in stable state
    func waitForStableState(timeout: TimeInterval = TestConfig.defaultTimeout) -> Bool {
        // Wait for loading indicators to disappear
        let loadingTexts = ["Loading", "Loading your day...", "Setting up your schedule..."]
        for text in loadingTexts {
            if staticTexts[text].exists {
                _ = staticTexts[text].waitForNonExistence(timeout: timeout)
            }
        }
        
        // Wait for activity indicators
        if activityIndicators.firstMatch.exists {
            _ = activityIndicators.firstMatch.waitForNonExistence(timeout: timeout)
        }
        
        return exists && isHittable
    }
    
    /// Dismiss any presented sheets or modals
    func dismissAnyPresentedViews() {
        // Try common dismiss buttons
        let dismissButtons = ["Done", "Cancel", "Close", "Dismiss"]
        for buttonTitle in dismissButtons {
            if buttons[buttonTitle].exists {
                buttons[buttonTitle].tap()
                return
            }
        }
        
        // Try X button
        if buttons["xmark.circle.fill"].exists {
            buttons["xmark.circle.fill"].tap()
            return
        }
        
        // Try swipe down
        if sheets.firstMatch.exists {
            swipeDown()
        }
    }
    
    /// Pull to refresh on current view
    func pullToRefresh() {
        let scrollView = scrollViews.firstMatch
        if scrollView.exists {
            scrollView.swipeDown()
        }
    }
}

// MARK: - XCUIElement Extensions
extension XCUIElement {
    
    /// Wait for element to exist with custom timeout
    func waitForExistenceWithTimeout(_ timeout: TimeInterval = TestConfig.defaultTimeout) -> Bool {
        return waitForExistence(timeout: timeout)
    }
    
    /// Tap element if it exists
    func tapIfExists() {
        if exists {
            tap()
        }
    }
    
    /// Clear text field and enter new text
    func clearAndEnterText(_ text: String) {
        tap()
        
        // Select all text
        press(forDuration: 1.0)
        
        // Delete selected text
        if menuItems["Select All"].waitForExistence(timeout: 1) {
            menuItems["Select All"].tap()
        }
        
        typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: 1))
        typeText(text)
    }
    
    /// Check if element is visible on screen
    var isVisible: Bool {
        return exists && isHittable && frame.isEmpty == false
    }
    
    /// Swipe to element if needed
    func scrollToElement(in scrollView: XCUIElement, maxSwipes: Int = 5) {
        var swipeCount = 0
        while !isVisible && swipeCount < maxSwipes {
            scrollView.swipeUp()
            swipeCount += 1
        }
    }
}

// MARK: - Test Assertions
extension XCTestCase {
    
    /// Assert element becomes visible within timeout
    func assertElementBecomesVisible(
        _ element: XCUIElement,
        timeout: TimeInterval = TestConfig.defaultTimeout,
        message: String = ""
    ) {
        let predicate = NSPredicate(format: "exists == true AND isHittable == true")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
        
        let result = XCTWaiter.wait(for: [expectation], timeout: timeout)
        XCTAssertEqual(
            result, .completed,
            message.isEmpty ? "Element \(element) did not become visible" : message
        )
    }
    
    /// Assert element disappears within timeout
    func assertElementDisappears(
        _ element: XCUIElement,
        timeout: TimeInterval = TestConfig.defaultTimeout,
        message: String = ""
    ) {
        let predicate = NSPredicate(format: "exists == false")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
        
        let result = XCTWaiter.wait(for: [expectation], timeout: timeout)
        XCTAssertEqual(
            result, .completed,
            message.isEmpty ? "Element \(element) did not disappear" : message
        )
    }
    
    /// Wait for a condition with custom timeout
    func waitFor(
        _ condition: @escaping () -> Bool,
        timeout: TimeInterval = TestConfig.defaultTimeout,
        pollingInterval: TimeInterval = 0.1
    ) -> Bool {
        let startTime = Date()
        
        while Date().timeIntervalSince(startTime) < timeout {
            if condition() {
                return true
            }
            Thread.sleep(forTimeInterval: pollingInterval)
        }
        
        return false
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
    
    /// Measure complete performance metrics
    func measureFullPerformance(during block: () throws -> Void) rethrows {
        measure(metrics: [
            XCTClockMetric(),
            XCTMemoryMetric(),
            XCTCPUMetric(),
            XCTStorageMetric()
        ]) {
            try? block()
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
    
    /// Rotate device and wait for animation
    func rotateToOrientation(_ orientation: UIDeviceOrientation, waitTime: TimeInterval = 1) {
        self.orientation = orientation
        Thread.sleep(forTimeInterval: waitTime)
    }
}

// MARK: - Test Data Helpers
struct TestData {
    
    /// Generate random time block title
    static func randomTimeBlockTitle() -> String {
        let titles = ["Morning Routine", "Work Session", "Lunch Break", "Exercise", "Study Time"]
        return "\(titles.randomElement()!) \(Int.random(in: 1...100))"
    }
    
    /// Generate test time block data
    static func createTestTimeBlock(in app: XCUIApplication, title: String? = nil) {
        app.navigateToSchedule()
        
        // Find and tap add button
        let addButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Add'")).firstMatch
        if addButton.waitForExistence(timeout: TestConfig.shortTimeout) {
            addButton.tap()
            
            // Fill in form
            let titleField = app.textFields["Title"]
            if titleField.waitForExistence(timeout: TestConfig.shortTimeout) {
                titleField.clearAndEnterText(title ?? randomTimeBlockTitle())
                
                // Save
                app.buttons["Save"].tapIfExists()
            }
        }
    }
    
    /// Clear all data via Settings
    static func clearAllData(in app: XCUIApplication) {
        app.navigateToSettings()
        
        let deleteButton = app.buttons["Delete All Data"]
        if deleteButton.waitForExistence(timeout: TestConfig.shortTimeout) {
            deleteButton.tap()
            
            // Confirm deletion
            if app.alerts.firstMatch.waitForExistence(timeout: TestConfig.shortTimeout) {
                app.alerts.buttons["Delete"].tap()
            }
        }
    }
}

// MARK: - Accessibility Testing Helpers
extension XCUIElement {
    
    /// Check if element has proper accessibility label
    var hasAccessibilityLabel: Bool {
        return label.isEmpty == false
    }
    
    /// Check if element has proper accessibility hint
    var hasAccessibilityHint: Bool {
        guard let hint = value(forKey: "accessibilityHint") as? String else { return false }
        return hint.isEmpty == false
    }
    
    /// Check if element meets minimum touch target size (44x44)
    var meetsMinimumTouchTargetSize: Bool {
        return frame.width >= 44 && frame.height >= 44
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
    
    /// Configure app for performance testing
    func configureForPerformanceTesting() {
        launchArguments = ["--uitesting", "--performance-mode"]
        launchEnvironment = [
            "PERFORMANCE_TEST": "1",
            "ENABLE_METRICS": "1"
        ]
    }
    
    /// Configure app for Swift 6 compliance testing
    func configureForSwift6Testing() {
        launchArguments = [
            "--uitesting",
            "--enable-actor-data-race-checks",
            "--strict-concurrency=complete"
        ]
        launchEnvironment = [
            "SWIFT_DETERMINISTIC_HASHING": "1",
            "SWIFT_ENABLE_ACTOR_DATA_RACE_CHECKS": "1",
            "SWIFT_STRICT_CONCURRENCY": "complete",
            "LIBDISPATCH_COOPERATIVE_POOL_STRICT": "1"
        ]
    }
    
    /// Configure app for iOS 17+ feature testing
    func configureForIOS17Testing() {
        launchArguments = ["--uitesting", "--reset-state"]
        launchEnvironment = [
            "ENABLE_IOS17_FEATURES": "1",
            "TEST_OBSERVABLE_MACRO": "1",
            "ANIMATIONS_ENABLED": "1"
        ]
    }
}

// MARK: - Test Fixtures
struct TestFixtures {
    
    /// Create standard test scenario with sample data
    static func setupStandardTestData(in app: XCUIApplication) {
        // Navigate to Schedule
        app.navigateToSchedule()
        
        // Add morning routine
        addTimeBlock(in: app, title: "Morning Routine", category: "Personal")
        
        // Add work block
        addTimeBlock(in: app, title: "Work Session", category: "Work")
        
        // Add lunch break
        addTimeBlock(in: app, title: "Lunch Break", category: "Personal")
    }
    
    private static func addTimeBlock(in app: XCUIApplication, title: String, category: String) {
        let addButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'plus' OR label CONTAINS 'Add' OR label CONTAINS '+'")).firstMatch
        if addButton.waitForExistence(timeout: 2) {
            addButton.tap()
            
            // Fill form
            let titleField = app.textFields.firstMatch
            if titleField.waitForExistence(timeout: 2) {
                titleField.tap()
                titleField.typeText(title)
                
                // Select category if available
                let categoryButton = app.buttons[category]
                categoryButton.tapIfExists()
                
                // Save
                let saveButton = app.buttons["Save"]
                if saveButton.exists {
                    saveButton.tap()
                } else {
                    app.buttons.matching(NSPredicate(format: "label CONTAINS 'Done' OR label CONTAINS 'Add'")).firstMatch.tapIfExists()
                }
                
                Thread.sleep(forTimeInterval: 0.5)
            }
        }
    }
}
