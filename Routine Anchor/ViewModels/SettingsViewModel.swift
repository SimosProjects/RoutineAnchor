//
//  SettingsViewModel.swift
//  Routine Anchor
//
//  Created by Christopher Simonson on 7/21/25.
//
import SwiftUI
import SwiftData
import UserNotifications

@Observable
class SettingsViewModel {
    // MARK: - Published Properties
    var isLoading = false
    var errorMessage: String?
    var successMessage: String?
    var notificationPermissionStatus: UNAuthorizationStatus = .notDetermined
    
    // MARK: - Settings State
    var notificationsEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: "notificationsEnabled") }
        set {
            UserDefaults.standard.set(newValue, forKey: "notificationsEnabled")
            if newValue {
                requestNotificationPermissions()
            } else {
                clearAllNotifications()
            }
        }
    }
    
    var dailyReminderTime: Date {
        get {
            if let data = UserDefaults.standard.data(forKey: "dailyReminderTime"),
               let time = try? JSONDecoder().decode(Date.self, from: data) {
                return time
            }
            // Default to 8 PM
            let calendar = Calendar.current
            return calendar.date(bySettingHour: 20, minute: 0, second: 0, of: Date()) ?? Date()
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                UserDefaults.standard.set(data, forKey: "dailyReminderTime")
                if notificationsEnabled {
                    scheduleDailyReminder(at: newValue)
                }
            }
        }
    }
    
    var notificationSound: String {
        get { UserDefaults.standard.string(forKey: "notificationSound") ?? "Default" }
        set {
            UserDefaults.standard.set(newValue, forKey: "notificationSound")
            // Reschedule notifications with new sound
            if notificationsEnabled {
                rescheduleAllNotifications()
            }
        }
    }
    
    var hapticsEnabled: Bool {
        get { HapticManager.shared.isHapticsEnabled }
        set { HapticManager.shared.setHapticsEnabled(newValue) }
    }
    
    var autoResetEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: "autoResetEnabled") }
        set { UserDefaults.standard.set(newValue, forKey: "autoResetEnabled") }
    }
    
    // MARK: - Private Properties
    private let dataManager: DataManager
    private let notificationCenter = UNUserNotificationCenter.current()
    
    // MARK: - Initialization
    init(dataManager: DataManager) {
        self.dataManager = dataManager
        checkNotificationPermissions()
        checkForMidnightReset()
    }
    
    // MARK: - Notification Management
    
    /// Check current notification permission status
    func checkNotificationPermissions() {
        notificationCenter.getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.notificationPermissionStatus = settings.authorizationStatus
            }
        }
    }
    
    /// Request notification permissions
    func requestNotificationPermissions() {
        Task { @MainActor in
            do {
                let granted = try await notificationCenter.requestAuthorization(options: [.alert, .badge, .sound])
                
                self.notificationPermissionStatus = granted ? .authorized : .denied
                self.notificationsEnabled = granted
                
                if granted {
                    HapticManager.shared.premiumSuccess()
                    self.successMessage = "Notifications enabled successfully"
                    
                    // Schedule existing time block notifications
                    await self.scheduleTimeBlockNotifications()
                    
                    // Schedule daily reminder if set
                    self.scheduleDailyReminder(at: self.dailyReminderTime)
                } else {
                    HapticManager.shared.premiumError()
                    self.errorMessage = "Notification permissions were denied. You can enable them in iOS Settings."
                }
                
                self.clearMessages()
                
            } catch {
                self.errorMessage = "Failed to request notification permissions: \(error.localizedDescription)"
                HapticManager.shared.premiumError()
                self.clearMessages()
            }
        }
    }
    
    /// Schedule daily reminder notification
    func scheduleDailyReminder(at time: Date) {
        // Remove existing daily reminder
        notificationCenter.removePendingNotificationRequests(withIdentifiers: ["dailyReminder"])
        
        guard notificationPermissionStatus == .authorized else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Daily Check-in"
        content.body = "How did your routine go today? Review your progress and plan tomorrow!"
        content.sound = getNotificationSound()
        content.badge = 1
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: time)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        
        let request = UNNotificationRequest(
            identifier: "dailyReminder",
            content: content,
            trigger: trigger
        )
        
        notificationCenter.add(request) { error in
            if let error = error {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to schedule daily reminder: \(error.localizedDescription)"
                    self.clearMessages()
                }
            }
        }
    }
    
    /// Schedule notifications for all active time blocks
    private func scheduleTimeBlockNotifications() async {
        do {
            let timeBlocks = try dataManager.loadTodaysTimeBlocks()
            
            // Clear existing time block notifications
            let identifiers = timeBlocks.map { $0.id.uuidString }
            notificationCenter.removePendingNotificationRequests(withIdentifiers: identifiers)
            
            // Schedule new notifications for upcoming blocks
            for block in timeBlocks where block.status == .notStarted && block.startTime > Date() {
                await scheduleTimeBlockNotification(for: block)
            }
            
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to schedule time block notifications: \(error.localizedDescription)"
                self.clearMessages()
            }
        }
    }
    
    /// Schedule notification for a specific time block
    private func scheduleTimeBlockNotification(for timeBlock: TimeBlock) async {
        guard notificationPermissionStatus == .authorized else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Time Block Starting"
        content.body = "Your '\(timeBlock.title)' block is beginning now."
        content.sound = getNotificationSound()
        content.userInfo = ["timeBlockId": timeBlock.id.uuidString]
        
        // Schedule for 2 minutes before start time
        let reminderTime = timeBlock.startTime.addingTimeInterval(-120)
        guard reminderTime > Date() else { return }
        
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: reminderTime.timeIntervalSinceNow,
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: timeBlock.id.uuidString,
            content: content,
            trigger: trigger
        )
        
        do {
            try await notificationCenter.add(request)
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to schedule notification for '\(timeBlock.title)': \(error.localizedDescription)"
                self.clearMessages()
            }
        }
    }
    
    /// Get notification sound based on user preference
    private func getNotificationSound() -> UNNotificationSound {
        switch notificationSound {
        case "Bell":
            return .default
        case "Chime":
            return UNNotificationSound(named: UNNotificationSoundName("chime.aiff"))
        case "Glass":
            return UNNotificationSound(named: UNNotificationSoundName("glass.aiff"))
        case "Horn":
            return UNNotificationSound(named: UNNotificationSoundName("horn.aiff"))
        default:
            return .default
        }
    }
    
    /// Clear all pending notifications
    func clearAllNotifications() {
        notificationCenter.removeAllPendingNotificationRequests()
        HapticManager.shared.success()
        successMessage = "All notifications cleared"
        clearMessages()
    }
    
    /// Reschedule all notifications with updated settings
    private func rescheduleAllNotifications() {
        Task {
            await scheduleTimeBlockNotifications()
            scheduleDailyReminder(at: dailyReminderTime)
        }
    }
    
    // MARK: - Data Management
    
    /// Reset today's progress back to not started
    func resetTodaysProgress() {
        isLoading = true
        errorMessage = nil
        
        do {
            // Reset all time blocks for today
            let todaysBlocks = try dataManager.loadTodaysTimeBlocks()
            for block in todaysBlocks {
                try dataManager.updateTimeBlockStatus(block, to: .notStarted)
            }
            
            // Update daily progress to reflect reset
            let today = Date()
            if let dailyProgress = try? dataManager.loadDailyProgress(for: today) {
                // Reset the progress counters
                dailyProgress.completedBlocks = 0
                dailyProgress.skippedBlocks = 0
                dailyProgress.totalBlocks = todaysBlocks.count
            }
            
            // Reschedule notifications for reset blocks
            Task {
                await scheduleTimeBlockNotifications()
            }
            
            HapticManager.shared.premiumSuccess()
            successMessage = "Today's progress has been reset"
            
        } catch {
            errorMessage = "Failed to reset today's progress: \(error.localizedDescription)"
            HapticManager.shared.premiumError()
        }
        
        isLoading = false
        clearMessages()
    }
    
    /// Clear all app data (routines, progress, etc.)
    func clearAllData() {
        isLoading = true
        errorMessage = nil
        
        do {
            // Get all data
            let allTimeBlocks = try dataManager.loadAllTimeBlocks()
            let allProgress = try dataManager.loadDailyProgress(
                from: Date.distantPast,
                to: Date.distantFuture
            )
            
            // Delete all time blocks
            for block in allTimeBlocks {
                try dataManager.deleteTimeBlock(block)
            }
            
            // Delete all progress records
            for progress in allProgress {
                dataManager.modelContext.delete(progress)
            }
            
            // Save changes
            try dataManager.modelContext.save()
            
            // Clear user preferences
            clearUserPreferences()
            
            // Clear all notifications
            clearAllNotifications()
            
            HapticManager.shared.premiumSuccess()
            successMessage = "All data has been cleared"
            
        } catch {
            errorMessage = "Failed to clear all data: \(error.localizedDescription)"
            HapticManager.shared.premiumError()
        }
        
        isLoading = false
        clearMessages()
    }
    
    /// Export all user data as JSON
    func exportUserData() -> String {
        do {
            let timeBlocks = try dataManager.loadAllTimeBlocks()
            let progressRecords = try dataManager.loadDailyProgress(
                from: Date.distantPast,
                to: Date.distantFuture
            )
            
            var exportData: [String: Any] = [:]
            
            // App metadata
            exportData["exportInfo"] = [
                "exportDate": ISO8601DateFormatter().string(from: Date()),
                "appVersion": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0",
                "dataVersion": "1.0"
            ]
            
            // Export time blocks
            exportData["timeBlocks"] = timeBlocks.map { block in
                return [
                    "id": block.id.uuidString,
                    "title": block.title,
                    "startTime": ISO8601DateFormatter().string(from: block.startTime),
                    "endTime": ISO8601DateFormatter().string(from: block.endTime),
                    "status": block.status.rawValue,
                    "notes": block.notes ?? "",
                    "category": block.category ?? "",
                    "icon": block.icon ?? "",
                    "createdAt": ISO8601DateFormatter().string(from: block.createdAt),
                    "updatedAt": ISO8601DateFormatter().string(from: block.updatedAt)
                ]
            }
            
            // Export progress records
            exportData["dailyProgress"] = progressRecords.map { progress in
                return [
                    "date": progress.date,
                    "completedBlocks": progress.completedBlocks,
                    "totalBlocks": progress.totalBlocks,
                    "skippedBlocks": progress.skippedBlocks,
                    "dayRating": progress.dayRating,
                    "dayNotes": progress.dayNotes
                ]
            }
            
            // Export user settings
            exportData["settings"] = [
                "notificationsEnabled": notificationsEnabled,
                "notificationSound": notificationSound,
                "hapticsEnabled": hapticsEnabled,
                "autoResetEnabled": autoResetEnabled,
                "dailyReminderTime": ISO8601DateFormatter().string(from: dailyReminderTime)
            ]
            
            // Export statistics
            exportData["statistics"] = generateStatistics(timeBlocks: timeBlocks, progressRecords: progressRecords)
            
            // Convert to JSON
            let jsonData = try JSONSerialization.data(withJSONObject: exportData, options: .prettyPrinted)
            return String(data: jsonData, encoding: .utf8) ?? "Export failed: Unable to encode data"
            
        } catch {
            errorMessage = "Failed to export data: \(error.localizedDescription)"
            clearMessages()
            return "Export failed: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Auto-Reset Functionality
    
    /// Check if it's past midnight and auto-reset is enabled
    private func checkForMidnightReset() {
        guard autoResetEnabled else { return }
        
        let lastResetDate = UserDefaults.standard.object(forKey: "lastAutoReset") as? Date ?? Date.distantPast
        let calendar = Calendar.current
        
        if !calendar.isDate(lastResetDate, inSameDayAs: Date()) {
            // It's a new day, perform auto-reset
            Task { @MainActor in
                self.resetTodaysProgress()
                UserDefaults.standard.set(Date(), forKey: "lastAutoReset")
            }
        }
    }
    
    // MARK: - Helper Methods
    
    /// Clear user preferences (for data deletion)
    private func clearUserPreferences() {
        let preferences = [
            "notificationsEnabled",
            "notificationSound",
            "hapticsEnabled",
            "autoResetEnabled",
            "dailyReminderTime",
            "lastAutoReset"
        ]
        
        for preference in preferences {
            UserDefaults.standard.removeObject(forKey: preference)
        }
    }
    
    /// Generate statistics for export
    private func generateStatistics(timeBlocks: [TimeBlock], progressRecords: [DailyProgress]) -> [String: Any] {
        let totalBlocks = timeBlocks.count
        let completedBlocks = timeBlocks.filter { $0.status == .completed }.count
        let totalDays = progressRecords.count
        let completedDays = progressRecords.filter { $0.completedBlocks > 0 }.count
        
        let averageCompletion = totalBlocks > 0 ? Double(completedBlocks) / Double(totalBlocks) : 0.0
        let averageDailyBlocks = totalDays > 0 ? Double(totalBlocks) / Double(totalDays) : 0.0
        
        return [
            "totalTimeBlocks": totalBlocks,
            "completedTimeBlocks": completedBlocks,
            "totalTrackedDays": totalDays,
            "daysWithProgress": completedDays,
            "averageCompletionRate": averageCompletion,
            "averageDailyBlocks": averageDailyBlocks,
            "generatedAt": ISO8601DateFormatter().string(from: Date())
        ]
    }
    
    /// Clear success and error messages after delay
    private func clearMessages() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.successMessage = nil
            self.errorMessage = nil
        }
    }
    
    /// Clear any error messages
    func clearError() {
        errorMessage = nil
        dataManager.lastError = nil
    }
    
    /// Retry last failed operation
    func retryLastOperation() {
        clearError()
        // Could implement specific retry logic based on last action
    }
    
    // MARK: - App Store & Support Actions
    
    /// Open App Store for rating
    func rateApp() {
        HapticManager.shared.lightImpact()
        
        guard let url = URL(string: "https://apps.apple.com/app/routine-anchor/idXXXXXXXXX?action=write-review") else {
            errorMessage = "Unable to open App Store"
            clearMessages()
            return
        }
        
        UIApplication.shared.open(url)
    }
    
    /// Open email to contact support
    func contactSupport() {
        HapticManager.shared.lightImpact()
        
        let systemInfo = """
        
        ---
        App Version: \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown")
        iOS Version: \(UIDevice.current.systemVersion)
        Device Model: \(UIDevice.current.model)
        """
        
        let mailtoString = "mailto:support@routineanchor.com?subject=Support%20Request&body=\(systemInfo.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        
        guard let url = URL(string: mailtoString) else {
            errorMessage = "Unable to open email client"
            clearMessages()
            return
        }
        
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        } else {
            errorMessage = "No email client configured"
            clearMessages()
        }
    }
    
    /// Share the app
    func shareApp() -> [Any] {
        HapticManager.shared.lightImpact()
        
        let shareText = "Check out Routine Anchor - a beautiful time-blocking app that helps you build consistent routines!"
        let appURL = URL(string: "https://apps.apple.com/app/routine-anchor/idXXXXXXXXX")!
        
        return [shareText, appURL]
    }
}

// MARK: - Development/Debug Functions
#if DEBUG
extension SettingsViewModel {
    /// Add sample data for testing
    func addSampleData() {
        isLoading = true
        errorMessage = nil
        
        let calendar = Calendar.current
        let today = Date()
        
        let sampleBlocks = [
            TimeBlock(
                title: "Morning Routine",
                startTime: calendar.date(bySettingHour: 7, minute: 0, second: 0, of: today) ?? today,
                endTime: calendar.date(bySettingHour: 8, minute: 0, second: 0, of: today) ?? today,
                notes: "Start the day with intention",
                icon: "🌅",
                category: "Personal"
            ),
            TimeBlock(
                title: "Deep Work Session",
                startTime: calendar.date(bySettingHour: 9, minute: 0, second: 0, of: today) ?? today,
                endTime: calendar.date(bySettingHour: 11, minute: 0, second: 0, of: today) ?? today,
                notes: "Focus on most important tasks",
                icon: "💼",
                category: "Work"
            ),
            TimeBlock(
                title: "Exercise",
                startTime: calendar.date(bySettingHour: 17, minute: 0, second: 0, of: today) ?? today,
                endTime: calendar.date(bySettingHour: 18, minute: 0, second: 0, of: today) ?? today,
                notes: "Stay healthy and energized",
                icon: "💪",
                category: "Health"
            )
        ]
        
        do {
            for block in sampleBlocks {
                try dataManager.addTimeBlock(block)
            }
            
            HapticManager.shared.premiumSuccess()
            successMessage = "Sample data added successfully"
            
        } catch {
            errorMessage = "Failed to add sample data: \(error.localizedDescription)"
            HapticManager.shared.premiumError()
        }
        
        isLoading = false
        clearMessages()
    }
    
    /// Clear only sample data
    @MainActor
    func clearSampleData() {
        // Implementation for clearing just sample data
        resetTodaysProgress()
    }
}
#endif
