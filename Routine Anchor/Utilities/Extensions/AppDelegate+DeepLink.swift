//
//  AppDelegate+DeepLink.swift
//  Routine Anchor
//
//  App Delegate extension to handle deep linking
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

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // No need for @MainActor or Task — just call directly
        completionHandler([.banner, .badge, .sound])
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        Task { @MainActor in
            DeepLinkHandler.shared.handleNotificationResponse(response)
            completionHandler()
        }
    }
}

