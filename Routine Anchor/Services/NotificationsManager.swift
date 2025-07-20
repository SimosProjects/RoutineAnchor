//
//  NotificationsManager.swift
//  Routine Anchor
//
//  Created by Christopher Simonson on 7/19/25.
//
import UserNotifications
import Foundation

class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    
    func requestPermission() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .badge, .sound])
            return granted
        } catch {
            return false
        }
    }
    
    func scheduleTimeBlockNotifications(for blocks: [TimeBlock]) {
        // Cancel existing notifications
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        
        // Schedule new notifications
        for block in blocks {
            scheduleNotification(for: block)
        }
    }
    
    private func scheduleNotification(for block: TimeBlock) {
        let content = UNMutableNotificationContent()
        content.title = "Time Block Starting"
        content.body = "Your '\(block.title)' block is beginning now."
        content.sound = .default
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: block.startTime)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        
        let request = UNNotificationRequest(
            identifier: block.id.uuidString,
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request)
    }
}
