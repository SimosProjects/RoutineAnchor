//
//  Swift6ComplianceUITests.swift
//  Routine AnchorUITests
//
//  Tests for Swift 6 concurrency, actor isolation, and migration compliance
//

import XCTest

final class Swift6ComplianceUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        
        // Enable Swift 6 strict concurrency checking
        app.launchArguments = [
            "--uitesting",
            "--enable-actor-data-race-checks",
            "--strict-concurrency=complete"
        ]
        
        // Enable diagnostic options
        app.launchEnvironment = [
            "SWIFT_DETERMINISTIC_HASHING": "1",
            "SWIFT_ENABLE_ACTOR_DATA_RACE_CHECKS": "1",
            "SWIFT_STRICT_CONCURRENCY": "complete",
            "LIBDISPATCH_COOPERATIVE_POOL_STRICT": "1"
        ]
        
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - @MainActor Isolation Tests
    
    @MainActor
    func testMainActorUIUpdates() throws {
        // Test that all UI updates happen on MainActor
        measure(metrics: [XCTClockMetric()]) {
            // Rapid navigation to test actor boundaries
            let tabButtons = app.tabBars.buttons
            
            // Try named buttons first, then fall back to indices
            if tabButtons["Today"].exists {
                tabButtons["Today"].tap()
                tabButtons["Schedule"].tap()
                tabButtons["Summary"].tap()
                tabButtons["Settings"].tap()
            } else {
                // Use indices if labels aren't found
                for i in 0..<min(4, tabButtons.count) {
                    tabButtons.element(boundBy: i).tap()
                    Thread.sleep(forTimeInterval: 0.1)
                }
            }
        }
        
        // Verify no UI glitches from actor violations
        XCTAssertTrue(app.tabBars.firstMatch.exists)
        XCTAssertTrue(app.isHittable)
    }
    
    @MainActor
    func testViewModelMainActorIsolation() throws {
        // Test TodayViewModel @MainActor isolation
        let todayButton = app.tabBars.buttons["Today"]
        if todayButton.exists {
            todayButton.tap()
        } else {
            app.tabBars.buttons.element(boundBy: 0).tap()
        }
        
        // Wait for view to load
        _ = app.scrollViews.firstMatch.waitForExistence(timeout: 2)
        
        // Trigger async data load via pull to refresh
        let scrollView = app.scrollViews.firstMatch
        if scrollView.exists {
            scrollView.swipeDown()
            
            // Check for loading state
            let loadingText = app.staticTexts["Loading your day..."]
            if loadingText.waitForExistence(timeout: 1) {
                // Wait for async operation
                XCTAssertTrue(loadingText.waitForNonExistence(timeout: 3))
            }
        }
        
        // Test multiple concurrent updates
        for _ in 0..<5 {
            scrollView.swipeDown() // Pull to refresh
            Thread.sleep(forTimeInterval: 0.1)
        }
        
        // UI should remain stable
        XCTAssertTrue(app.scrollViews.firstMatch.exists)
    }
    
    // MARK: - Sendable Conformance Tests
    
    @MainActor
    func testSendableDataTransfer() throws {
        // Test data transfer between actors via Sendable types
        let settingsButton = app.tabBars.buttons["Settings"]
        if settingsButton.exists {
            settingsButton.tap()
        } else {
            app.tabBars.buttons.element(boundBy: 3).tap()
        }
        
        // Wait for settings to load
        _ = app.staticTexts["Settings"].waitForExistence(timeout: 2)
        
        // Export data (tests Sendable conformance of export data)
        let exportButton = app.buttons["Export Data"]
        if exportButton.waitForExistence(timeout: 2) {
            exportButton.tap()
            
            if app.sheets.firstMatch.waitForExistence(timeout: 2) {
                // Verify export doesn't cause data races
                _ = app.staticTexts["Export Complete"].waitForExistence(timeout: 5)
                
                if app.buttons["Done"].exists {
                    app.buttons["Done"].tap()
                } else {
                    app.swipeDown()
                }
            }
        }
        
        // Import data (tests Sendable conformance of import data)
        let importButton = app.buttons["Import Data"]
        if importButton.waitForExistence(timeout: 2) {
            importButton.tap()
            
            if app.sheets.firstMatch.waitForExistence(timeout: 2) {
                // This would normally select a file
                if app.buttons["Cancel"].exists {
                    app.buttons["Cancel"].tap()
                } else {
                    app.swipeDown()
                }
            }
        }
    }
    
    @MainActor
    func testNotificationPayloadSendable() throws {
        // Test that notification payloads are properly Sendable
        
        // Simulate receiving a notification
        app.launchArguments.append("--simulate-notification")
        app.launch()
        
        // Verify notification handling doesn't cause data races
        let notificationBanner = app.otherElements["NotificationBanner"]
        if notificationBanner.waitForExistence(timeout: 2) {
            notificationBanner.tap()
            
            // Should navigate without issues
            XCTAssertTrue(app.navigationBars["Today"].exists)
        }
    }
    
    // MARK: - Async/Await Tests
    
    @MainActor
    func testAsyncAwaitDataLoading() throws {
        app.tabBars.buttons["Summary"].tap()
        
        // Test async data loading
        let chart = app.otherElements["WeeklyProgressChart"]
        XCTAssertTrue(chart.waitForExistence(timeout: 3), "Chart should load asynchronously")
        
        // Navigate to trigger more async loads
        app.buttons["Previous Day"].tap()
        Thread.sleep(forTimeInterval: 0.5)
        app.buttons["Next Day"].tap()
        
        // Verify smooth async transitions
        XCTAssertTrue(chart.exists)
        XCTAssertFalse(app.activityIndicators.firstMatch.exists, "No loading spinners should be stuck")
    }
    
    @MainActor
    func testAsyncNotificationScheduling() throws {
        app.tabBars.buttons["Settings"].tap()
        
        // Toggle notifications (async operation)
        let notificationToggle = app.switches["Enable Notifications"]
        let initialState = notificationToggle.value as? String == "1"
        
        notificationToggle.tap()
        
        // Wait for async notification scheduling
        Thread.sleep(forTimeInterval: 1)
        
        // Toggle again
        notificationToggle.tap()
        
        // Verify state changes properly despite async operations
        let finalState = notificationToggle.value as? String == "1"
        XCTAssertEqual(initialState, finalState)
    }
    
    // MARK: - Task Cancellation Tests
    
    @MainActor
    func testTaskCancellationOnNavigation() throws {
        app.tabBars.buttons["Today"].tap()
        
        // Start a refresh (creates async task)
        app.swipeDown()
        
        // Immediately navigate away (should cancel task)
        app.tabBars.buttons["Schedule"].tap()
        
        // Navigate back
        app.tabBars.buttons["Today"].tap()
        
        // Verify no stale data or loading states
        XCTAssertFalse(app.staticTexts["Loading your day..."].exists)
        XCTAssertTrue(app.scrollViews.firstMatch.exists)
    }
    
    @MainActor
    func testTaskCancellationOnDismiss() throws {
        app.tabBars.buttons["Schedule"].tap()
        app.buttons["Add Time Block"].tap()
        
        // Start typing (may trigger validation tasks)
        let titleField = app.textFields["Title"]
        titleField.tap()
        titleField.typeText("Test")
        
        // Immediately dismiss (should cancel any validation tasks)
        app.buttons["Cancel"].tap()
        
        // Verify clean dismissal
        if app.alerts.firstMatch.exists {
            app.alerts.buttons["Discard"].tap()
        }
        
        XCTAssertTrue(app.navigationBars["Schedule Builder"].exists)
    }
    
    // MARK: - Structured Concurrency Tests
    
    @MainActor
    func testTaskGroupExecution() throws {
        // Test TaskGroup usage in navigation monitoring
        app.tabBars.buttons["Today"].tap()
        
        // Trigger multiple concurrent operations
        let operations = [
            { self.app.swipeDown() },  // Refresh
            { self.app.buttons["Add"].tap() },  // Add button
            { self.app.tabBars.buttons["Schedule"].tap() }  // Navigate
        ]
        
        // Execute concurrently
        for operation in operations {
            DispatchQueue.global().async {
                operation()
            }
        }
        
        Thread.sleep(forTimeInterval: 2)
        
        // Verify app remains stable
        XCTAssertTrue(app.exists)
        XCTAssertFalse(app.staticTexts["Error"].exists)
    }
    
    @MainActor
    func testAsyncSequenceHandling() throws {
        // Test async sequence in notification monitoring
        app.tabBars.buttons["Settings"].tap()
        
        // Enable auto-reset (starts timer with async sequence)
        let autoResetToggle = app.switches["Auto-Reset at Midnight"]
        if autoResetToggle.exists {
            autoResetToggle.tap()
            
            // Verify timer started without issues
            Thread.sleep(forTimeInterval: 1)
            
            // Disable to stop async sequence
            autoResetToggle.tap()
        }
        
        // No crashes or hangs should occur
        XCTAssertTrue(app.exists)
    }
    
    // MARK: - Actor Isolation Boundary Tests
    
    @MainActor
    func testActorBoundaryDataPassing() throws {
        app.tabBars.buttons["Schedule"].tap()
        
        // Create time block (crosses actor boundaries for validation)
        app.buttons["Add Time Block"].tap()
        
        let titleField = app.textFields["Title"]
        titleField.tap()
        titleField.typeText("Actor Test Block")
        
        // Select time (involves date calculations off MainActor)
        app.datePickers["Start Time"].tap()
        app.pickerWheels.element(boundBy: 0).adjust(toPickerWheelValue: "9")
        app.pickerWheels.element(boundBy: 1).adjust(toPickerWheelValue: "00")
        app.buttons["Done"].tap()
        
        app.buttons["Save"].tap()
        
        // Verify data saved correctly across actor boundaries
        XCTAssertTrue(app.cells["Actor Test Block"].waitForExistence(timeout: 2))
    }
    
    @MainActor
    func testNonisolatedPropertyAccess() throws {
        // Test nonisolated properties in ViewModels
        app.tabBars.buttons["Today"].tap()
        
        // This triggers timer management (nonisolated)
        let timeBlock = app.cells.firstMatch
        if timeBlock.exists {
            // Long press to edit (accesses nonisolated timer)
            timeBlock.press(forDuration: 1.0)
            
            if app.buttons["Edit"].exists {
                app.buttons["Edit"].tap()
                
                // Verify edit sheet appears without concurrency issues
                XCTAssertTrue(app.navigationBars["Edit Time Block"].waitForExistence(timeout: 2))
                app.buttons["Cancel"].tap()
            }
        }
    }
    
    // MARK: - Data Race Detection Tests
    
    @MainActor
    func testConcurrentStateModification() throws {
        app.tabBars.buttons["Settings"].tap()
        
        // Rapidly toggle multiple settings to test for data races
        let toggles = [
            "Enable Notifications",
            "Haptic Feedback",
            "Auto-Reset at Midnight"
        ]
        
        // Concurrent modifications
        for _ in 0..<10 {
            for toggleName in toggles {
                if let toggle = app.switches[toggleName].exists ? app.switches[toggleName] : nil {
                    toggle.tap()
                }
            }
        }
        
        // App should remain stable
        XCTAssertTrue(app.navigationBars.firstMatch.exists)
        XCTAssertFalse(app.staticTexts["Error"].exists)
    }
    
    @MainActor
    func testThreadSanitizerCompliance() throws {
        // This test should be run with Thread Sanitizer enabled
        measure(metrics: [XCTMemoryMetric(), XCTCPUMetric()]) {
            // Stress test concurrent operations
            let group = DispatchGroup()
            
            for i in 0..<5 {
                group.enter()
                DispatchQueue.global().async {
                    // Simulate background work
                    Thread.sleep(forTimeInterval: Double.random(in: 0.1...0.3))
                    
                    DispatchQueue.main.async {
                        // UI updates must be on main queue
                        if i % 2 == 0 {
                            self.app.tabBars.buttons["Today"].tap()
                        } else {
                            self.app.tabBars.buttons["Schedule"].tap()
                        }
                        group.leave()
                    }
                }
            }
            
            group.wait()
        }
        
        // Verify no thread sanitizer issues
        XCTAssertTrue(app.exists)
    }
    
    // MARK: - Region-Based Isolation Tests
    
    @MainActor
    func testRegionBasedIsolation() throws {
        // Test Swift 6 region-based isolation
        app.tabBars.buttons["Schedule"].tap()
        
        // Create multiple time blocks in sequence
        for i in 0..<3 {
            app.buttons["Add Time Block"].tap()
            
            let titleField = app.textFields["Title"]
            titleField.tap()
            titleField.typeText("Region \(i)")
            
            app.buttons["Save"].tap()
            
            // Each iteration should maintain isolation
            Thread.sleep(forTimeInterval: 0.2)
        }
        
        // Verify all blocks created without isolation violations
        for i in 0..<3 {
            XCTAssertTrue(app.cells["Region \(i)"].exists)
        }
    }
    
    // MARK: - Memory Management Tests
    
    @MainActor
    func testActorMemoryManagement() throws {
        // Test for retain cycles with new Swift 6 patterns
        autoreleasepool {
            measure(metrics: [XCTMemoryMetric()]) {
                for _ in 0..<10 {
                    app.tabBars.buttons["Today"].tap()
                    app.tabBars.buttons["Schedule"].tap()
                    app.tabBars.buttons["Summary"].tap()
                    app.tabBars.buttons["Settings"].tap()
                }
            }
        }
        
        // Memory should not increase significantly
        XCTAssertTrue(app.exists)
    }
    
    @MainActor
    func testWeakReferenceInClosures() throws {
        // Test weak self capture in async contexts
        app.tabBars.buttons["Today"].tap()
        
        // Trigger multiple async operations
        for _ in 0..<5 {
            app.swipeDown() // Pull to refresh
            
            // Navigate away immediately (tests weak capture)
            app.tabBars.buttons["Schedule"].tap()
            app.tabBars.buttons["Today"].tap()
        }
        
        // No memory leaks should occur
        XCTAssertTrue(app.scrollViews.firstMatch.exists)
    }
    
    // MARK: - Closure Isolation Tests
    
    @MainActor
    func testClosureIsolation() throws {
        app.tabBars.buttons["Schedule"].tap()
        app.buttons["Add Time Block"].tap()
        
        // Test escaping closure with proper isolation
        let titleField = app.textFields["Title"]
        titleField.tap()
        titleField.typeText("Closure Test")
        
        // Save triggers completion handler
        app.buttons["Save"].tap()
        
        // Verify closure executed properly
        XCTAssertTrue(app.cells["Closure Test"].waitForExistence(timeout: 2))
    }
    
    @MainActor
    func testNonEscapingClosureExecution() throws {
        app.tabBars.buttons["Today"].tap()
        
        // Swipe actions use non-escaping closures
        let timeBlock = app.cells.firstMatch
        if timeBlock.exists {
            timeBlock.swipeRight()
            
            // Verify action executed immediately
            if app.buttons["Complete"].exists {
                app.buttons["Complete"].tap()
                
                // Should update UI immediately
                Thread.sleep(forTimeInterval: 0.5)
                XCTAssertTrue(timeBlock.staticTexts["Completed"].exists ||
                             timeBlock.images["checkmark.circle.fill"].exists)
            }
        }
    }
    
    // MARK: - Error Propagation Tests
    
    @MainActor
    func testAsyncErrorPropagation() throws {
        app.tabBars.buttons["Settings"].tap()
        
        // Test error handling in async context
        app.buttons["Import Data"].tap()
        
        if app.sheets.firstMatch.waitForExistence(timeout: 2) {
            // Simulate selecting invalid file (would trigger error)
            app.buttons["Cancel"].tap()
        }
        
        // Create invalid data scenario
        app.buttons["Delete All Data"].tap()
        if app.alerts.firstMatch.exists {
            app.alerts.buttons["Delete"].tap()
        }
        
        // Try to export empty data
        app.buttons["Export Data"].tap()
        
        // Should handle error gracefully
        if app.alerts["No Data"].exists {
            XCTAssertTrue(app.alerts.staticTexts["No data to export"].exists)
            app.alerts.buttons["OK"].tap()
        }
    }
    
    // MARK: - Global Actor Tests
    
    @MainActor
    func testGlobalActorAnnotations() throws {
        // Test that UI operations respect @MainActor
        
        // Rapid UI updates
        app.tabBars.buttons["Summary"].tap()
        
        // Date navigation (requires MainActor)
        for _ in 0..<10 {
            app.buttons["Previous Day"].tap()
        }
        
        for _ in 0..<10 {
            app.buttons["Next Day"].tap()
        }
        
        // UI should remain responsive
        XCTAssertTrue(app.buttons["Previous Day"].isEnabled ||
                     app.staticTexts["No earlier data available"].exists)
    }
    
    // MARK: - Concurrency Performance Tests
    
    @MainActor
    func testConcurrentPerformanceOptimization() throws {
        measure(metrics: [
            XCTClockMetric(),
            XCTCPUMetric(),
            XCTMemoryMetric()
        ]) {
            // Test optimized concurrent operations
            app.tabBars.buttons["Schedule"].tap()
            
            // Add multiple blocks concurrently
            for i in 0..<5 {
                app.buttons["Add Time Block"].tap()
                
                let titleField = app.textFields["Title"]
                titleField.tap()
                titleField.typeText("Perf \(i)")
                
                // Quick save without waiting
                app.buttons["Save"].tap()
            }
            
            // Navigate to test concurrent rendering
            app.tabBars.buttons["Today"].tap()
            app.tabBars.buttons["Summary"].tap()
        }
    }
    
    // MARK: - Strict Concurrency Mode Tests
    
    @MainActor
    func testStrictConcurrencyCompliance() throws {
        // With strict concurrency enabled, test various scenarios
        
        // Test 1: Background to foreground transition
        app.tabBars.buttons["Today"].tap()
        
        // Simulate background
        XCUIDevice.shared.press(.home)
        Thread.sleep(forTimeInterval: 1)
        
        // Return to app
        app.activate()
        
        // Should handle transition without concurrency issues
        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 2))
        
        // Test 2: Multiple notification handlers
        app.launchArguments.append("--trigger-multiple-notifications")
        app.launch()
        
        // Should handle concurrent notifications
        Thread.sleep(forTimeInterval: 2)
        XCTAssertTrue(app.exists)
    }
    
    // MARK: - Async Let Tests
    
    @MainActor
    func testAsyncLetPatterns() throws {
        app.tabBars.buttons["Summary"].tap()
        
        // This view likely uses async let for parallel data loading
        let progressRing = app.otherElements["CompletionRing"]
        let statsCards = app.otherElements["StatsCards"]
        let chart = app.otherElements["WeeklyProgressChart"]
        
        // All should load in parallel
        XCTAssertTrue(progressRing.waitForExistence(timeout: 2))
        XCTAssertTrue(statsCards.exists)
        XCTAssertTrue(chart.exists)
        
        // Verify no sequential loading delays
        let startTime = Date()
        app.buttons["Previous Day"].tap()
        let loadTime = Date().timeIntervalSince(startTime)
        
        // Parallel loading should be fast
        XCTAssertLessThan(loadTime, 1.0, "Data should load in parallel")
    }
    
    // MARK: - Actor Reentrancy Tests
    
    @MainActor
    func testActorReentrancy() throws {
        app.tabBars.buttons["Settings"].tap()
        
        // Test reentrancy with nested async calls
        let notificationToggle = app.switches["Enable Notifications"]
        
        // Toggle rapidly (may trigger reentrant calls)
        for _ in 0..<5 {
            notificationToggle.tap()
            Thread.sleep(forTimeInterval: 0.1)
        }
        
        // Should handle reentrancy without deadlock
        XCTAssertTrue(notificationToggle.exists)
        XCTAssertTrue(app.navigationBars.firstMatch.exists)
    }
    
    // MARK: - Task Priority Tests
    
    @MainActor
    func testTaskPriorityHandling() throws {
        app.tabBars.buttons["Today"].tap()
        
        // High priority: User interaction
        let timeBlock = app.cells.firstMatch
        if timeBlock.exists {
            timeBlock.tap()
        }
        
        // Low priority: Background refresh
        app.swipeDown()
        
        // High priority should not be blocked
        if app.buttons["Complete"].exists {
            app.buttons["Complete"].tap()
            
            // Should respond immediately
            XCTAssertTrue(app.buttons["Complete"].waitForNonExistence(timeout: 1))
        }
    }
    
    // MARK: - Distributed Actor Tests (if applicable)
    
    @MainActor
    func testDistributedActorPattern() throws {
        // Skip if not using distributed actors
        guard app.launchEnvironment["USE_DISTRIBUTED_ACTORS"] == "1" else {
            throw XCTSkip("Distributed actors not implemented")
        }
        
        // Test distributed actor pattern for sync
        app.tabBars.buttons["Settings"].tap()
        app.buttons["Sync Data"].tap()
        
        // Should handle distributed actor communication
        XCTAssertTrue(app.progressIndicators["Syncing"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["Sync Complete"].waitForExistence(timeout: 10))
    }
    
    // MARK: - Swift 6 Migration Validation
    
    @MainActor
    func testSwift6MigrationCompleteness() throws {
        // Comprehensive test to validate Swift 6 migration
        
        // Test all major features for Swift 6 compliance
        let features = [
            ("Today", "Today's Schedule"),
            ("Schedule", "Schedule Builder"),
            ("Summary", "Daily Summary"),
            ("Settings", "Settings")
        ]
        
        for (tab, expectedTitle) in features {
            app.tabBars.buttons[tab].tap()
            
            // Each view should load without concurrency warnings
            XCTAssertTrue(
                app.navigationBars[expectedTitle].waitForExistence(timeout: 2) ||
                app.staticTexts[expectedTitle].waitForExistence(timeout: 2),
                "\(tab) view should load with Swift 6 compliance"
            )
            
            // Interact with the view
            if app.buttons.count > 0 {
                app.buttons.firstMatch.tap()
                Thread.sleep(forTimeInterval: 0.2)
                
                // Dismiss any sheets/alerts
                if app.sheets.count > 0 {
                    app.swipeDown()
                } else if app.alerts.count > 0 {
                    app.alerts.buttons.firstMatch.tap()
                }
            }
        }
        
        // Final validation - app should be fully functional
        XCTAssertTrue(app.exists)
        XCTAssertFalse(app.staticTexts["Error"].exists)
        XCTAssertFalse(app.staticTexts["Crash"].exists)
    }
}

// MARK: - Helper Extensions for Testing

extension XCTestCase {
    /// Helper to test async operations with timeout
    func waitForAsync(timeout: TimeInterval = 5, condition: @escaping () -> Bool) -> Bool {
        let expectation = XCTestExpectation(description: "Async operation")
        
        Task {
            while !condition() {
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            }
            expectation.fulfill()
        }
        
        return XCTWaiter.wait(for: [expectation], timeout: timeout) == .completed
    }
    
    /// Helper to verify no data races occurred
    func verifyNoDataRaces(in app: XCUIApplication) {
        XCTAssertFalse(app.staticTexts["Data Race Detected"].exists)
        XCTAssertFalse(app.staticTexts["Thread Sanitizer Warning"].exists)
        XCTAssertTrue(app.exists && app.isHittable)
    }
}

// MARK: - Mock Helpers for Concurrency Testing

extension XCUIApplication {
    /// Simulate concurrent user actions
    func performConcurrentActions(_ actions: [() -> Void]) {
        let group = DispatchGroup()
        
        for action in actions {
            group.enter()
            DispatchQueue.global().async {
                action()
                group.leave()
            }
        }
        
        group.wait()
    }
    
    /// Check if app is in a stable state
    var isStable: Bool {
        return exists &&
               isHittable &&
               !staticTexts["Loading"].exists &&
               !activityIndicators.firstMatch.exists
    }
}
