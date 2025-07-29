//
//  NotificationService.swift
//  Routine Anchor
//
//  Created by Christopher Simonson on 7/23/25.
//
import UserNotifications
import SwiftUI

@MainActor
class NotificationService: NSObject, ObservableObject {
    // MARK: - Singleton
    static let shared = NotificationService()
    
    // MARK: - Published Properties
    @Published var permissionStatus: UNAuthorizationStatus = .notDetermined
    @Published var isNotificationsEnabled: Bool = false
    @Published var pendingNotificationCount: Int = 0
    
    // MARK: - Private Properties
    private let notificationCenter = UNUserNotificationCenter.current()
    private var notificationQueue: [String] = []
    
    // MARK: - Constants
    private enum Constants {
        static let notificationLeadTime: TimeInterval = 120 // 2 minutes before
        static let dailyReminderId = "daily_reminder"
        static let welcomeNotificationId = "welcome_notification"
        static let maxBadgeCount = 99
    }
    
    // MARK: - Initialization
    private override init() {
        super.init()
        notificationCenter.delegate = self
        Task {
            await checkPermissionStatus()
            await updatePendingNotificationCount()
            registerNotificationCategories()
        }
    }
    
    // MARK: - Permission Management
    
    /// Request notification permissions from the user
    func requestPermission() async -> Bool {
        do {
            let granted = try await notificationCenter.requestAuthorization(
                options: [.alert, .badge, .sound]
            )
            
            await checkPermissionStatus()
            
            if granted {
                UIApplication.shared.registerForRemoteNotifications()
            }
            
            return granted
        } catch {
            print("Failed to request notification permission: \(error)")
            return false
        }
    }
    
    /// Check current notification permission status
    func checkPermissionStatus() async {
        let settings = await notificationCenter.notificationSettings()
        
        permissionStatus = settings.authorizationStatus
        isNotificationsEnabled = settings.authorizationStatus == .authorized
    }
    
    /// Open system settings for notifications
    func openNotificationSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
    
    // MARK: - Time Block Notifications
    
    /// Schedule notifications for multiple time blocks
    /// Schedule notifications for multiple time blocks
    func scheduleTimeBlockNotifications(for blocks: [TimeBlock]) async {
        // Remove existing time block notifications
        let existingIds = blocks.map { timeBlockIdentifier(for: $0.id) }
        removePendingNotifications(withIdentifiers: existingIds)
        
        // Schedule new notifications
        for block in blocks {
            do {
                try await scheduleTimeBlockNotification(for: block)
            } catch NotificationError.invalidTimeBlock {
                // Silently skip past or completed blocks - this is expected
                continue
            } catch {
                // Only log unexpected errors
                print("Failed to schedule notification for block '\(block.title)': \(error)")
            }
        }
        
        await updatePendingNotificationCount()
    }
    
    /// Schedule notification for a single time block
    func scheduleTimeBlockNotification(for block: TimeBlock) async throws {
        guard isNotificationsEnabled else {
            throw NotificationError.permissionDenied
        }
        
        // Don't schedule for past or completed blocks
        guard block.startTime > Date() && block.status == .notStarted else {
            throw NotificationError.invalidTimeBlock
        }
        
        let content = createTimeBlockContent(
            for: block,
            sound: getNotificationSound(for: UserDefaults.standard.string(forKey: "notificationSound") ?? "Default")
        )
        
        let notificationDate = notificationTime(for: block)
        guard notificationDate > Date() else {
            throw NotificationError.invalidTimeBlock
        }
        
        let dateComponents = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: notificationDate
        )
        
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: dateComponents,
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: timeBlockIdentifier(for: block.id),
            content: content,
            trigger: trigger
        )
        
        do {
            try await notificationCenter.add(request)
        } catch {
            throw NotificationError.schedulingFailed(error.localizedDescription)
        }
    }
    
    /// Cancel notification for a specific time block
    func cancelTimeBlockNotification(for blockId: UUID) {
        let identifier = timeBlockIdentifier(for: blockId)
        removePendingNotifications(withIdentifiers: [identifier])
    }
    
    /// Update an existing time block notification
    func updateTimeBlockNotification(for block: TimeBlock) async throws {
        cancelTimeBlockNotification(for: block.id)
        try await scheduleTimeBlockNotification(for: block)
    }
    
    // MARK: - Daily Reminder
        
    /// Schedule daily reminder at specified time
    func scheduleDailyReminder(at time: Date) async {
        // Remove any existing daily reminders
        removeDailyReminder()
        
        // Get notification sound preference
        let soundName = UserDefaults.standard.string(forKey: "notificationSound") ?? "Default"
        let notificationSound = NotificationSound(rawValue: soundName) ?? .default
        
        // Create notification content
        let content = UNMutableNotificationContent()
        content.title = "Daily Check-In 📊"
        content.body = "How did your routine go today? Take a moment to reflect and plan for tomorrow."
        content.categoryIdentifier = "DAILY_REMINDER"
        content.userInfo = ["type": "dailyReminder"]
        
        // Set sound based on user preference
        if let sound = notificationSound.sound {
            content.sound = sound
        }
        
        // Create daily trigger at the specified time
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: time)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        
        // Create request
        let request = UNNotificationRequest(
            identifier: "dailyReminder",
            content: content,
            trigger: trigger
        )
        
        // Schedule the notification
        do {
            try await notificationCenter.add(request)
            print("Daily reminder scheduled for \(components.hour ?? 0):\(components.minute ?? 0)")
        } catch {
            print("Failed to schedule daily reminder: \(error)")
        }
    }
    
    /// Remove daily reminder notification
    func removeDailyReminder() {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: ["dailyReminder"])
    }
    
    /// Cancel daily reminder
    func cancelDailyReminder() {
        removePendingNotifications(withIdentifiers: [Constants.dailyReminderId])
    }
    
    /// Check if daily reminder is scheduled
    func isDailyReminderScheduled() async -> Bool {
        let pendingRequests = await notificationCenter.pendingNotificationRequests()
        return pendingRequests.contains { $0.identifier == Constants.dailyReminderId }
    }
    
    // MARK: - Special Notifications
    
    /// Schedule midnight reset notification for auto-reset feature
    func scheduleMidnightReset() async {
        // Remove any existing midnight reset
        removeMidnightReset()
        
        // Create notification content (silent notification)
        let content = UNMutableNotificationContent()
        content.title = "New Day, Fresh Start! 🌅"
        content.body = "Your daily routine has been reset. Time to plan today's schedule!"
        content.sound = .none // Silent notification
        content.categoryIdentifier = "MIDNIGHT_RESET"
        content.userInfo = ["type": "midnightReset"]
        
        // Create trigger for midnight
        var dateComponents = DateComponents()
        dateComponents.hour = 0
        dateComponents.minute = 0
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        // Create request
        let request = UNNotificationRequest(
            identifier: "midnightReset",
            content: content,
            trigger: trigger
        )
        
        // Schedule the notification
        do {
            try await notificationCenter.add(request)
            print("Midnight reset scheduled")
        } catch {
            print("Failed to schedule midnight reset: \(error)")
        }
    }

    /// Remove midnight reset notification
    func removeMidnightReset() {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: ["midnightReset"])
    }
    
    /// Schedule welcome notification for new users
    func scheduleWelcomeNotification(delay: TimeInterval = 600) {
        guard isNotificationsEnabled else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Welcome to Routine Anchor!"
        content.body = "Ready to build your first daily routine? Tap to get started."
        content.sound = .default
        content.badge = 1
        
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: delay,
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: Constants.welcomeNotificationId,
            content: content,
            trigger: trigger
        )
        
        notificationCenter.add(request) { error in
            if let error = error {
                print("Failed to schedule welcome notification: \(error)")
            }
        }
    }
    
    /// Schedule achievement notification
    func scheduleAchievementNotification(title: String, body: String) {
        guard isNotificationsEnabled else { return }
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.categoryIdentifier = NotificationCategory.achievement
        content.sound = UNNotificationSound(named: UNNotificationSoundName("success.aiff"))
        
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: 1,
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: "achievement_\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )
        
        notificationCenter.add(request) { error in
            if let error = error {
                print("Failed to schedule achievement notification: \(error)")
            }
        }
    }
    
    // MARK: - Notification Management
    
    /// Remove all pending notifications
    func removeAllPendingNotifications() {
        notificationCenter.removeAllPendingNotificationRequests()
        Task {
            await updatePendingNotificationCount()
            await clearBadge()
        }
    }
    
    /// Remove specific notifications by identifiers
    func removePendingNotifications(withIdentifiers identifiers: [String]) {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: identifiers)
        Task {
            await updatePendingNotificationCount()
        }
    }
    
    /// Reschedule all notifications (used after settings change)
    func rescheduleAllNotifications(blocks: [TimeBlock], dailyReminderTime: Date?) async {
        // Clear all existing notifications
        removeAllPendingNotifications()
        
        // Schedule time block notifications
        await scheduleTimeBlockNotifications(for: blocks)
        
        // Schedule daily reminder if enabled
        if let reminderTime = dailyReminderTime {
            await scheduleDailyReminder(at: reminderTime)
        }
    }
    
    /// Get all pending notifications
    func getPendingNotifications() async -> [UNNotificationRequest] {
        return await notificationCenter.pendingNotificationRequests()
    }
    
    // MARK: - Sound Management
    
    /// Get notification sound from preference string
    func getNotificationSound(for soundName: String) -> NotificationSound {
        return NotificationSound(rawValue: soundName) ?? .default
    }
    
    // MARK: - Badge Management
    
    /// Update app badge count
    func updateBadgeCount(_ count: Int) async {
        let badgeCount = min(count, Constants.maxBadgeCount)
        
        // For iOS 16+
        if #available(iOS 16.0, *) {
            do {
                try await UNUserNotificationCenter.current().setBadgeCount(badgeCount)
            } catch {
                print("Failed to update badge count: \(error)")
            }
        } else {
            // For iOS 15 and earlier
            await MainActor.run {
                UIApplication.shared.applicationIconBadgeNumber = badgeCount
            }
        }
    }
    
    /// Clear app badge
    func clearBadge() async {
        // For iOS 16+
        if #available(iOS 16.0, *) {
            do {
                try await UNUserNotificationCenter.current().setBadgeCount(0)
            } catch {
                print("Failed to clear badge: \(error)")
            }
        } else {
            // For iOS 15 and earlier
            await MainActor.run {
                UIApplication.shared.applicationIconBadgeNumber = 0
            }
        }
    }
    
    /// Update badge based on incomplete blocks
    func updateBadgeForIncompleteBlocks(_ count: Int) async {
        guard isNotificationsEnabled else {
            await clearBadge()
            return
        }
        
        await updateBadgeCount(count)
    }
    
    // MARK: - Helper Methods
    
    /// Update the count of pending notifications
    private func updatePendingNotificationCount() async {
        let pendingRequests = await notificationCenter.pendingNotificationRequests()
        pendingNotificationCount = pendingRequests.count
    }
    
    /// Generate notification identifier for time block
    private func timeBlockIdentifier(for blockId: UUID) -> String {
        return "timeblock_\(blockId.uuidString)"
    }
    
    /// Create notification content for time block
    private func createTimeBlockContent(for block: TimeBlock, sound: NotificationSound) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        
        content.title = "Time Block Starting"
        content.body = "Your '\(block.title)' block is beginning now."
        content.categoryIdentifier = NotificationCategory.timeBlock
        content.threadIdentifier = "timeblocks"
        
        if let notificationSound = sound.sound {
            content.sound = notificationSound
        }
        
        // Add user info for handling
        content.userInfo = [
            "timeBlockId": block.id.uuidString,
            "title": block.title,
            "startTime": block.startTime.timeIntervalSince1970
        ]
        
        return content
    }
    
    /// Calculate notification time for block (with lead time)
    private func notificationTime(for block: TimeBlock) -> Date {
        let notificationDate = block.startTime.addingTimeInterval(-Constants.notificationLeadTime)
        
        // If notification time is in the past, schedule for 1 minute from now
        if notificationDate < Date() {
            return Date().addingTimeInterval(60)
        }
        
        return notificationDate
    }
    
    // MARK: - Notification Categories (for actions)
    
    /// Register notification categories for quick actions
    func registerNotificationCategories() {
        // Time Block Category
        let completeAction = UNNotificationAction(
            identifier: NotificationAction.complete,
            title: "Complete",
            options: .foreground
        )
        
        let skipAction = UNNotificationAction(
            identifier: NotificationAction.skip,
            title: "Skip",
            options: .destructive
        )
        
        let snoozeAction = UNNotificationAction(
            identifier: NotificationAction.snooze,
            title: "Snooze 5 min",
            options: []
        )
        
        let timeBlockCategory = UNNotificationCategory(
            identifier: NotificationCategory.timeBlock,
            actions: [completeAction, skipAction, snoozeAction],
            intentIdentifiers: [],
            options: .customDismissAction
        )
        
        // Daily Reminder Category
        let viewSummaryAction = UNNotificationAction(
            identifier: NotificationAction.viewSummary,
            title: "View Summary",
            options: .foreground
        )
        
        let dailyReminderCategory = UNNotificationCategory(
            identifier: NotificationCategory.dailyReminder,
            actions: [viewSummaryAction],
            intentIdentifiers: [],
            options: []
        )
        
        // Achievement Category
        let achievementCategory = UNNotificationCategory(
            identifier: NotificationCategory.achievement,
            actions: [],
            intentIdentifiers: [],
            options: []
        )
        
        // Register categories
        notificationCenter.setNotificationCategories([
            timeBlockCategory,
            dailyReminderCategory,
            achievementCategory
        ])
    }
}

// MARK: - Supporting Types

/// Notification sound options
enum NotificationSound: String, CaseIterable {
    case `default` = "Default"
    case bell = "Bell"
    case chime = "Chime"
    case glass = "Glass"
    case horn = "Horn"
    case none = "None"
    
    var sound: UNNotificationSound? {
        switch self {
        case .default:
            return .default
        case .bell:
            // Tritone - a pleasant three-note sound
            return UNNotificationSound(named: UNNotificationSoundName("Tritone"))
        case .chime:
            // Use the default sound (it's actually a nice chime)
            return .default
        case .glass:
            // Bamboo - has a glass-like quality
            return UNNotificationSound(named: UNNotificationSoundName("Bamboo"))
        case .horn:
            // Fanfare - more triumphant than a horn but works well
            return UNNotificationSound(named: UNNotificationSoundName("Fanfare"))
        case .none:
            return nil
        }
    }
    
    var displayName: String {
        return self.rawValue
    }
}

/// Notification category identifiers
enum NotificationCategory {
    static let timeBlock = "TIME_BLOCK"
    static let dailyReminder = "DAILY_REMINDER"
    static let achievement = "ACHIEVEMENT"
}

/// Notification action identifiers
enum NotificationAction {
    static let complete = "COMPLETE_ACTION"
    static let skip = "SKIP_ACTION"
    static let snooze = "SNOOZE_ACTION"
    static let viewSummary = "VIEW_SUMMARY_ACTION"
}

/// Custom notification error types
enum NotificationError: LocalizedError {
    case permissionDenied
    case invalidTimeBlock
    case schedulingFailed(String)
    case notificationNotFound
    
    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Notification permissions are required to schedule reminders"
        case .invalidTimeBlock:
            return "Cannot schedule notification for this time block"
        case .schedulingFailed(let reason):
            return "Failed to schedule notification: \(reason)"
        case .notificationNotFound:
            return "Notification not found"
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension NotificationService: UNUserNotificationCenterDelegate {
    /// Handle notification presentation while app is in foreground
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notifications even when app is in foreground
        completionHandler([.banner, .badge, .sound])
    }
    
    /// Handle notification response (user tapped on notification or action)
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        let actionIdentifier = response.actionIdentifier
        
        Task { @MainActor in
            switch actionIdentifier {
            case NotificationAction.complete:
                if let blockIdString = userInfo["timeBlockId"] as? String,
                   let blockId = UUID(uuidString: blockIdString) {
                    // Handle completion
                    print("Complete time block: \(blockId)")
                    // You can post a notification or call a delegate here
                    NotificationCenter.default.post(
                        name: .timeBlockCompleted,
                        object: nil,
                        userInfo: ["blockId": blockId]
                    )
                }
                
            case NotificationAction.skip:
                if let blockIdString = userInfo["timeBlockId"] as? String,
                   let blockId = UUID(uuidString: blockIdString) {
                    // Handle skip
                    print("Skip time block: \(blockId)")
                    NotificationCenter.default.post(
                        name: .timeBlockSkipped,
                        object: nil,
                        userInfo: ["blockId": blockId]
                    )
                }
                
            case NotificationAction.snooze:
                if let blockIdString = userInfo["timeBlockId"] as? String,
                   let title = userInfo["title"] as? String {
                    // Reschedule for 5 minutes later
                    await self.snoozeNotification(blockId: blockIdString, title: title)
                }
                
            case NotificationAction.viewSummary:
                // Navigate to summary view
                print("View summary requested")
                NotificationCenter.default.post(
                    name: .showDailySummary,
                    object: nil
                )
                
            default:
                // User tapped on notification itself
                print("Notification tapped")
                if let blockIdString = userInfo["timeBlockId"] as? String {
                    NotificationCenter.default.post(
                        name: .showTimeBlock,
                        object: nil,
                        userInfo: ["blockId": blockIdString]
                    )
                }
            }
        }
        
        completionHandler()
    }
    
    /// Helper to snooze a notification
    private func snoozeNotification(blockId: String, title: String) async {
        let content = UNMutableNotificationContent()
        content.title = "Time Block Starting (Snoozed)"
        content.body = "Your '\(title)' block is beginning now."
        content.sound = .default
        content.categoryIdentifier = NotificationCategory.timeBlock
        content.userInfo = ["timeBlockId": blockId, "title": title]
        
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: 300, // 5 minutes
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: "snooze_\(blockId)",
            content: content,
            trigger: trigger
        )
        
        try? await notificationCenter.add(request)
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let refreshTodayView = Notification.Name("refreshTodayView")
    static let refreshScheduleView = Notification.Name("refreshScheduleView")
    static let refreshSummaryView = Notification.Name("refreshSummaryView")
    static let tabDidChange = Notification.Name("tabDidChange")
    static let navigateToSchedule = Notification.Name("navigateToSchedule")
    static let showTemplates = Notification.Name("showTemplates")
    static let showAddTimeBlockFromTab = Notification.Name("showAddTimeBlockFromTab")
    static let timeBlockCompleted = Notification.Name("timeBlockCompleted")
    static let timeBlockSkipped = Notification.Name("timeBlockSkipped")
    static let showTimeBlock = Notification.Name("showTimeBlock")
}
