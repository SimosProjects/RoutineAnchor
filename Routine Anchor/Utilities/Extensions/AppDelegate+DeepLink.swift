//
//  AppDelegate+DeepLink.swift
//  Routine Anchor
//
//  App Delegate extension to handle deep linking
//  Swift 6 Compatible Version
//

import UIKit
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        // Set up notification delegate
        UNUserNotificationCenter.current().delegate = self
        
        // Check if app was launched from a notification
        if let notificationInfo = launchOptions?[.remoteNotification] as? [String: Any] {
            handleNotificationLaunch(userInfo: notificationInfo)
        }
        
        return true
    }
    
    // Handle URL schemes
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        return DeepLinkHandler.shared.handleURL(url)
    }
    
    // Handle universal links
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        guard userActivity.activityType == NSUserActivityTypeBrowsingWeb,
              let url = userActivity.webpageURL else {
            return false
        }
        
        return DeepLinkHandler.shared.handleURL(url)
    }
    
    private func handleNotificationLaunch(userInfo: [String: Any]) {
        // Create a mock notification response for launch handling
        if let blockIdString = userInfo["timeBlockId"] as? String {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                NotificationCenter.default.post(
                    name: .showTimeBlock,
                    object: nil,
                    userInfo: ["blockId": blockIdString]
                )
            }
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension AppDelegate: UNUserNotificationCenterDelegate {
    
    // This method is called when a notification arrives while app is in foreground
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Simply present the notification
        completionHandler([.banner, .badge, .sound])
    }
    
    // This method is called when user interacts with a notification
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        // Extract only Sendable data before crossing actor boundaries
        let actionIdentifier = response.actionIdentifier
        
        // Convert userInfo to a simple String dictionary for Sendability
        var stringUserInfo: [String: String] = [:]
        let userInfo = response.notification.request.content.userInfo
        
        for (key, value) in userInfo {
            if let stringKey = key as? String,
               let stringValue = value as? String {
                stringUserInfo[stringKey] = stringValue
            }
        }
        
        // Create Sendable data structure
        let notificationData = NotificationResponseData(
            actionIdentifier: actionIdentifier,
            userInfo: stringUserInfo
        )
        
        // Call completion handler immediately - this is critical for system expectations
        completionHandler()
        
        // Handle the notification on MainActor using Sendable data
        Task { @MainActor in
            DeepLinkHandler.shared.handleNotificationData(notificationData)
        }
    }
}
