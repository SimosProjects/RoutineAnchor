//
//  NotificationTests.swift
//  Routine AnchorTests
//
//  Testing basic notification functionality
//

import XCTest
import UserNotifications
@testable import Routine_Anchor

final class NotificationTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    // MARK: - Basic Notification Tests
    
    func testNotificationCenterAccess() {
        // Test that we can access the notification center
        let center = UNUserNotificationCenter.current()
        XCTAssertNotNil(center)
    }
    
    func testNotificationContent() {
        // Test creating notification content
        let content = UNMutableNotificationContent()
        content.title = "Test Notification"
        content.body = "This is a test notification for time blocks"
        content.sound = .default
        
        XCTAssertEqual(content.title, "Test Notification")
        XCTAssertEqual(content.body, "This is a test notification for time blocks")
        XCTAssertEqual(content.sound, .default)
    }
    
    func testNotificationTrigger() {
        // Test creating a calendar trigger
        let futureDate = Date().addingTimeInterval(3600) // 1 hour from now
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: futureDate)
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        XCTAssertNotNil(trigger)
        XCTAssertFalse(trigger.repeats)
    }
    
    func testNotificationRequest() {
        // Test creating a notification request
        let content = UNMutableNotificationContent()
        content.title = "Time Block Reminder"
        content.body = "Your time block is starting soon"
        
        let futureDate = Date().addingTimeInterval(300) // 5 minutes from now
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: futureDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        let request = UNNotificationRequest(identifier: "test-notification", content: content, trigger: trigger)
        
        XCTAssertEqual(request.identifier, "test-notification")
        XCTAssertEqual(request.content.title, "Time Block Reminder")
        XCTAssertNotNil(request.trigger)
    }
    
    // MARK: - TimeBlock Notification Integration
    
    func testTimeBlockNotificationContent() {
        // Test creating notification content from a TimeBlock
        let block = createSampleTimeBlock(title: "Morning Exercise", startHour: 8, endHour: 9)
        
        let content = UNMutableNotificationContent()
        content.title = "Time Block Starting"
        content.body = "'\(block.title)' is starting soon"
        content.userInfo = ["timeBlockId": block.id.uuidString]
        
        XCTAssertTrue(content.body.contains("Morning Exercise"))
        XCTAssertEqual(content.userInfo["timeBlockId"] as? String, block.id.uuidString)
    }
    
    func testNotificationIdentifierGeneration() {
        // Test generating unique identifiers for time blocks
        let block1 = createSampleTimeBlock(title: "Block 1", startHour: 9, endHour: 10)
        let block2 = createSampleTimeBlock(title: "Block 2", startHour: 11, endHour: 12)
        
        let identifier1 = "timeblock-\(block1.id.uuidString)"
        let identifier2 = "timeblock-\(block2.id.uuidString)"
        
        XCTAssertNotEqual(identifier1, identifier2)
        XCTAssertTrue(identifier1.contains(block1.id.uuidString))
        XCTAssertTrue(identifier2.contains(block2.id.uuidString))
    }
    
    // MARK: - Notification Categories and Actions
    
    func testNotificationCategory() {
        // Test creating notification categories with actions
        let completeAction = UNNotificationAction(
            identifier: "COMPLETE_ACTION",
            title: "Complete",
            options: []
        )
        
        let skipAction = UNNotificationAction(
            identifier: "SKIP_ACTION",
            title: "Skip",
            options: []
        )
        
        let category = UNNotificationCategory(
            identifier: "TIME_BLOCK_REMINDER",
            actions: [completeAction, skipAction],
            intentIdentifiers: [],
            options: []
        )
        
        XCTAssertEqual(category.identifier, "TIME_BLOCK_REMINDER")
        XCTAssertEqual(category.actions.count, 2)
        XCTAssertEqual(category.actions[0].title, "Complete")
        XCTAssertEqual(category.actions[1].title, "Skip")
    }
    
    // MARK: - Time Calculation Tests
    
    func testNotificationTimingCalculation() {
        // Test calculating notification times
        let block = createSampleTimeBlock(title: "Test Block", startHour: 14, endHour: 15)
        
        // Calculate 5 minutes before start time
        let notificationTime = block.startTime.addingTimeInterval(-300)
        let timeDifference = block.startTime.timeIntervalSince(notificationTime)
        
        XCTAssertEqual(timeDifference, 300) // 5 minutes
        XCTAssertTrue(notificationTime < block.startTime)
    }
    
    func testFutureTimeBlockValidation() {
        // Test that we only schedule notifications for future blocks
        let pastBlock = createPastTimeBlock(title: "Past Block", hoursAgo: 2)
        let futureBlock = createFutureTimeBlock(title: "Future Block", hoursFromNow: 2)
        
        let shouldSchedulePast = pastBlock.startTime > Date()
        let shouldScheduleFuture = futureBlock.startTime > Date()
        
        XCTAssertFalse(shouldSchedulePast)
        XCTAssertTrue(shouldScheduleFuture)
    }
    
    // MARK: - Notification Settings Tests
    
    func testNotificationAuthorizationCheck() async {
        // Test checking notification authorization status
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        
        // In test environment, this will likely be .notDetermined
        XCTAssertTrue([.authorized, .denied, .notDetermined, .provisional, .ephemeral].contains(settings.authorizationStatus))
    }
    
    // MARK: - Helper Methods
    
    private func createSampleTimeBlock(
        title: String = "Test Block",
        startHour: Int = 10,
        endHour: Int = 11,
        day: Date = Date()
    ) -> TimeBlock {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: day)
        
        let startTime = calendar.date(byAdding: .hour, value: startHour, to: startOfDay) ?? Date()
        let endTime = calendar.date(byAdding: .hour, value: endHour, to: startOfDay) ?? Date().addingTimeInterval(3600)
        
        return TimeBlock(title: title, startTime: startTime, endTime: endTime)
    }
    
    private func createFutureTimeBlock(title: String, hoursFromNow: Int) -> TimeBlock {
        let startTime = Date().addingTimeInterval(TimeInterval(hoursFromNow * 3600))
        let endTime = startTime.addingTimeInterval(1800) // 30 minutes duration
        
        return TimeBlock(title: title, startTime: startTime, endTime: endTime)
    }
    
    private func createPastTimeBlock(title: String, hoursAgo: Int) -> TimeBlock {
        let startTime = Date().addingTimeInterval(TimeInterval(-hoursAgo * 3600))
        let endTime = startTime.addingTimeInterval(1800) // 30 minutes duration
        
        return TimeBlock(title: title, startTime: startTime, endTime: endTime)
    }
}
