//
//  DeepLinkTypes.swift
//  Routine Anchor
//
//  Deep linking types with Sendable conformance for Swift 6
//

import Foundation

// MARK: - Tab Selection
// Tab enum that's Sendable for cross-actor communication

enum AppTab: String, CaseIterable, Sendable {
    case today = "today"
    case schedule = "schedule"
    case summary = "summary"
    case settings = "settings"
}

// MARK: - Timer Configuration
// Configuration for timers - Sendable

struct TimerConfiguration: Sendable {
    let identifier: String
    let interval: TimeInterval
    let repeats: Bool
}

// MARK: - User Preferences
// User preferences that might be passed between actors

struct UserPreferences: Codable, Sendable {
    let notificationsEnabled: Bool
    let soundEnabled: Bool
    let hapticsEnabled: Bool
    let autoResetEnabled: Bool
    let dailyReminderTime: Date?
    let themeMode: String
}

// MARK: - App State
// Application state that needs to be shared

struct AppState: Sendable {
    let isFirstLaunch: Bool
    let hasCompletedOnboarding: Bool
    let lastActiveDate: Date?
    let currentVersion: String
    let previousVersion: String?
}
