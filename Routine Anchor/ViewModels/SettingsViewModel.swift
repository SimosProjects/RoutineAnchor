//
//  SettingsViewModel.swift
//  Routine Anchor
//
//  Created by Christopher Simonson on 7/19/25.
//
import SwiftUI
import SwiftData
import UserNotifications

@Observable
class SettingsViewModel {
    // MARK: - Published Properties
    var isLoading = false
    var errorMessage: String?
    var notificationPermissionStatus: UNAuthorizationStatus = .notDetermined
    
    // MARK: - Private Properties
    private let dataManager: DataManager
    
    // MARK: - Initialization
    init(dataManager: DataManager) {
        self.dataManager = dataManager
        checkNotificationPermissions()
    }
    
    // MARK: - Notification Management
    
    /// Check current notification permission status
    func checkNotificationPermissions() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.notificationPermissionStatus = settings.authorizationStatus
            }
        }
    }
    
    /// Request notification permissions
    func requestNotificationPermissions() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .badge, .sound])
            
            await MainActor.run {
                self.notificationPermissionStatus = granted ? .authorized : .denied
            }
            
            return granted
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to request notification permissions: \(error.localizedDescription)"
            }
            return false
        }
    }
    
    /// Schedule daily reminder notification
    func scheduleDailyReminder(at time: Date) {
        // Remove existing daily reminder
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["dailyReminder"])
        
        let content = UNMutableNotificationContent()
        content.title = "Daily Check-in"
        content.body = "How did your routine go today? Review your progress and plan tomorrow!"
        content.sound = .default
        content.badge = 1
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: time)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        
        let request = UNNotificationRequest(
            identifier: "dailyReminder",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to schedule daily reminder: \(error.localizedDescription)"
                }
            }
        }
    }
    
    /// Clear all pending notifications
    func clearAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        HapticManager.shared.success()
    }
    
    /// Update notification sound preference
    func updateNotificationSound(_ sound: String) {
        UserDefaults.standard.set(sound, forKey: "notificationSound")
        
        // Reschedule notifications with new sound if needed
        // This would integrate with your NotificationManager
    }
    
    // MARK: - Data Management
    
    /// Reset today's progress back to not started
    func resetTodaysProgress() {
        isLoading = true
        errorMessage = nil
        
        do {
            try dataManager.resetTimeBlocksStatus(for: Date())
            HapticManager.shared.success()
        } catch {
            errorMessage = "Failed to reset today's progress: \(error.localizedDescription)"
            HapticManager.shared.error()
        }
        
        isLoading = false
    }
    
    /// Clear all app data (routines, progress, etc.)
    func clearAllData() {
        isLoading = true
        errorMessage = nil
        
        do {
            // Get all time blocks and daily progress records
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
            
            // Clear user preferences
            clearUserPreferences()
            
            // Clear all notifications
            clearAllNotifications()
            
            HapticManager.shared.success()
            
        } catch {
            errorMessage = "Failed to clear all data: \(error.localizedDescription)"
            HapticManager.shared.error()
        }
        
        isLoading = false
    }
    
    /// Export all user data
    func exportUserData() -> String {
        do {
            let timeBlocks = try dataManager.loadAllTimeBlocks()
            let progressRecords = try dataManager.loadDailyProgress(
                from: Date.distantPast,
                to: Date.distantFuture
            )
            
            var exportData: [String: Any] = [:]
            
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
                return progress.exportData
            }
            
            // Export settings
            exportData["settings"] = [
                "notificationsEnabled": UserDefaults.standard.bool(forKey: "notificationsEnabled"),
                "notificationSound": UserDefaults.standard.string(forKey: "notificationSound") ?? "Default",
                "exportDate": ISO8601DateFormatter().string(from: Date())
            ]
            
            // Convert to JSON
            let jsonData = try JSONSerialization.data(withJSONObject: exportData, options: .prettyPrinted)
            return String(data: jsonData, encoding: .utf8) ?? "Export failed"
            
        } catch {
            errorMessage = "Failed to export data: \(error.localizedDescription)"
            return "Export failed: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Development/Debug Functions
    
    #if DEBUG
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
            ),
            TimeBlock(
                title: "Reading Time",
                startTime: calendar.date(bySettingHour: 20, minute: 0, second: 0, of: today) ?? today,
                endTime: calendar.date(bySettingHour: 21, minute: 0, second: 0, of: today) ?? today,
                notes: "Learn something new",
                icon: "📚",
                category: "Learning"
            )
        ]
        
        do {
            for block in sampleBlocks {
                try dataManager.addTimeBlock(block)
            }
            
            // Mark some blocks as completed for realistic data
            if sampleBlocks.count >= 2 {
                try dataManager.markTimeBlockCompleted(sampleBlocks[0])
                try dataManager.markTimeBlockCompleted(sampleBlocks[1])
            }
            
            if sampleBlocks.count >= 4 {
                try dataManager.markTimeBlockSkipped(sampleBlocks[3])
            }
            
            HapticManager.shared.success()
            
        } catch {
            errorMessage = "Failed to add sample data: \(error.localizedDescription)"
            HapticManager.shared.error()
        }
        
        isLoading = false
    }
    #endif
    
    // MARK: - Analytics & Statistics
    
    /// Get app usage statistics
    func getAppStatistics() async -> AppStatistics? {
        do {
            let allTimeBlocks = try dataManager.loadAllTimeBlocks()
            let allProgress = try dataManager.loadDailyProgress(
                from: Date.distantPast,
                to: Date.distantFuture
            )
            
            let totalBlocks = allTimeBlocks.count
            let completedBlocks = allTimeBlocks.filter { $0.status == .completed }.count
            let totalDays = allProgress.count
            let perfectDays = allProgress.filter { $0.completionPercentage == 1.0 }.count
            
            let averageCompletion = allProgress.isEmpty ? 0.0 :
                allProgress.map { $0.completionPercentage }.reduce(0, +) / Double(allProgress.count)
            
            let currentStreak = calculateCurrentStreak(from: allProgress)
            let longestStreak = calculateLongestStreak(from: allProgress)
            
            return AppStatistics(
                totalTimeBlocks: totalBlocks,
                completedTimeBlocks: completedBlocks,
                totalDaysTracked: totalDays,
                perfectDays: perfectDays,
                averageCompletionRate: averageCompletion,
                currentStreak: currentStreak,
                longestStreak: longestStreak,
                totalTimeSpent: calculateTotalTimeSpent(from: allTimeBlocks)
            )
            
        } catch {
            errorMessage = "Failed to load statistics: \(error.localizedDescription)"
            return nil
        }
    }
    
    // MARK: - User Preferences
    
    /// Save notification preferences
    func saveNotificationPreferences(enabled: Bool, sound: String, reminderTime: Date) {
        UserDefaults.standard.set(enabled, forKey: "notificationsEnabled")
        UserDefaults.standard.set(sound, forKey: "notificationSound")
        
        if let timeData = try? JSONEncoder().encode(reminderTime) {
            UserDefaults.standard.set(timeData, forKey: "dailyReminderTime")
        }
        
        if enabled {
            scheduleDailyReminder(at: reminderTime)
        } else {
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["dailyReminder"])
        }
    }
    
    /// Load notification preferences
    func loadNotificationPreferences() -> (enabled: Bool, sound: String, reminderTime: Date) {
        let enabled = UserDefaults.standard.bool(forKey: "notificationsEnabled")
        let sound = UserDefaults.standard.string(forKey: "notificationSound") ?? "Default"
        
        var reminderTime = Calendar.current.date(bySettingHour: 20, minute: 0, second: 0, of: Date()) ?? Date()
        
        if let timeData = UserDefaults.standard.object(forKey: "dailyReminderTime") as? Data,
           let savedTime = try? JSONDecoder().decode(Date.self, from: timeData) {
            reminderTime = savedTime
        }
        
        return (enabled, sound, reminderTime)
    }
    
    /// Clear all user preferences
    private func clearUserPreferences() {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: "notificationsEnabled")
        defaults.removeObject(forKey: "notificationSound")
        defaults.removeObject(forKey: "dailyReminderTime")
        defaults.removeObject(forKey: "hasCompletedOnboarding")
    }
    
    // MARK: - Error Handling
    
    /// Clear any error messages
    func clearError() {
        errorMessage = nil
        dataManager.clearError()
    }
    
    // MARK: - Private Helper Methods
    
    private func calculateCurrentStreak(from progressRecords: [DailyProgress]) -> Int {
        let sortedRecords = progressRecords.sorted { $0.date > $1.date }
        var streak = 0
        
        for progress in sortedRecords {
            if progress.completionPercentage >= 0.8 { // 80% completion counts as success
                streak += 1
            } else {
                break
            }
        }
        
        return streak
    }
    
    private func calculateLongestStreak(from progressRecords: [DailyProgress]) -> Int {
        let sortedRecords = progressRecords.sorted { $0.date < $1.date }
        var longestStreak = 0
        var currentStreak = 0
        
        for progress in sortedRecords {
            if progress.completionPercentage >= 0.8 {
                currentStreak += 1
                longestStreak = max(longestStreak, currentStreak)
            } else {
                currentStreak = 0
            }
        }
        
        return longestStreak
    }
    
    private func calculateTotalTimeSpent(from timeBlocks: [TimeBlock]) -> Int {
        return timeBlocks
            .filter { $0.status == .completed }
            .reduce(0) { $0 + $1.durationMinutes }
    }
}

// MARK: - App Statistics Model
struct AppStatistics {
    let totalTimeBlocks: Int
    let completedTimeBlocks: Int
    let totalDaysTracked: Int
    let perfectDays: Int
    let averageCompletionRate: Double
    let currentStreak: Int
    let longestStreak: Int
    let totalTimeSpent: Int // in minutes
    
    var completionPercentage: Double {
        guard totalTimeBlocks > 0 else { return 0.0 }
        return Double(completedTimeBlocks) / Double(totalTimeBlocks)
    }
    
    var formattedTotalTime: String {
        let hours = totalTimeSpent / 60
        let minutes = totalTimeSpent % 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    var formattedAverageCompletion: String {
        return String(format: "%.0f%%", averageCompletionRate * 100)
    }
}
