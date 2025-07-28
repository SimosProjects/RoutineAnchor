//
//  DeepLinkHandler.swift
//  Routine Anchor
//
//  Handles deep linking from notifications and URLs
//

import SwiftUI
import UserNotifications

enum DeepLink {
    case showTimeBlock(blockId: UUID)
    case completeTimeBlock(blockId: UUID)
    case skipTimeBlock(blockId: UUID)
    case showSchedule
    case showTemplates
    case showSummary
    case showSettings
}

@MainActor
class DeepLinkHandler: ObservableObject {
    static let shared = DeepLinkHandler()
    
    @Published var pendingDeepLink: DeepLink?
    @Published var activeTab: MainTabView.Tab = .today
    
    private init() {}
    
    // MARK: - Handle Notification Response
    
    func handleNotificationResponse(_ response: UNNotificationResponse) {
        let userInfo = response.notification.request.content.userInfo
        let actionIdentifier = response.actionIdentifier
        
        switch actionIdentifier {
        case NotificationAction.complete:
            if let blockIdString = userInfo["timeBlockId"] as? String,
               let blockId = UUID(uuidString: blockIdString) {
                pendingDeepLink = .completeTimeBlock(blockId: blockId)
                activeTab = .today
            }
            
        case NotificationAction.skip:
            if let blockIdString = userInfo["timeBlockId"] as? String,
               let blockId = UUID(uuidString: blockIdString) {
                pendingDeepLink = .skipTimeBlock(blockId: blockId)
                activeTab = .today
            }
            
        case NotificationAction.viewSummary:
            pendingDeepLink = .showSummary
            activeTab = .summary
            
        default:
            // User tapped on notification itself
            if let blockIdString = userInfo["timeBlockId"] as? String,
               let blockId = UUID(uuidString: blockIdString) {
                pendingDeepLink = .showTimeBlock(blockId: blockId)
                activeTab = .today
            }
        }
        
        // Process the deep link after a short delay to ensure UI is ready
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.processDeepLink()
        }
    }
    
    // MARK: - Handle URL Deep Links
    
    func handleURL(_ url: URL) -> Bool {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
              let host = components.host else {
            return false
        }
        
        switch host {
        case "schedule":
            pendingDeepLink = .showSchedule
            activeTab = .schedule
            
        case "templates":
            pendingDeepLink = .showTemplates
            activeTab = .schedule
            
        case "summary":
            pendingDeepLink = .showSummary
            activeTab = .summary
            
        case "settings":
            pendingDeepLink = .showSettings
            activeTab = .settings
            
        case "timeblock":
            if let blockIdString = components.queryItems?.first(where: { $0.name == "id" })?.value,
               let blockId = UUID(uuidString: blockIdString) {
                pendingDeepLink = .showTimeBlock(blockId: blockId)
                activeTab = .today
            }
            
        default:
            return false
        }
        
        processDeepLink()
        return true
    }
    
    // MARK: - Process Deep Links
    
    private func processDeepLink() {
        guard let deepLink = pendingDeepLink else { return }
        
        switch deepLink {
        case .showTimeBlock(let blockId):
            NotificationCenter.default.post(
                name: .showTimeBlock,
                object: nil,
                userInfo: ["blockId": blockId.uuidString]
            )
            
        case .completeTimeBlock(let blockId):
            NotificationCenter.default.post(
                name: .timeBlockCompleted,
                object: nil,
                userInfo: ["blockId": blockId]
            )
            
        case .skipTimeBlock(let blockId):
            NotificationCenter.default.post(
                name: .timeBlockSkipped,
                object: nil,
                userInfo: ["blockId": blockId]
            )
            
        case .showSchedule:
            NotificationCenter.default.post(name: .navigateToSchedule, object: nil)
            
        case .showTemplates:
            NotificationCenter.default.post(name: .showTemplates, object: nil)
            
        case .showSummary:
            // Summary tab is automatically selected via activeTab
            break
            
        case .showSettings:
            // Settings tab is automatically selected via activeTab
            break
        }
        
        // Clear the pending deep link
        pendingDeepLink = nil
    }
    
    // MARK: - Clear State
    
    func clearPendingDeepLink() {
        pendingDeepLink = nil
    }
}
