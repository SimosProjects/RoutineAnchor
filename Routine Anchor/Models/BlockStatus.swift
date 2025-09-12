//
//  BlockStatus.swift
//  Routine Anchor
//
//  Created by Christopher Simonson on 7/19/25.
//
import Foundation
import SwiftUI

/// Represents the current state of a time block in the user's schedule
enum BlockStatus: String, CaseIterable, Codable, Sendable {
    case notStarted = "not_started"
    case inProgress = "in_progress"
    case completed = "completed"
    case skipped = "skipped"
    
    // MARK: - Display Properties
    
    /// Human-readable name for the status
    var displayName: String {
        switch self {
        case .notStarted:
            return "Upcoming"
        case .inProgress:
            return "In Progress"
        case .completed:
            return "Completed"
        case .skipped:
            return "Skipped"
        }
    }
    
    /// Short display name for compact UI elements
    var shortDisplayName: String {
        switch self {
        case .notStarted:
            return "Upcoming"
        case .inProgress:
            return "Active"
        case .completed:
            return "Done"
        case .skipped:
            return "Skipped"
        }
    }
    
    /// Icon representing the status
    var iconName: String {
        switch self {
        case .notStarted:
            return "circle"
        case .inProgress:
            return "clock.fill"
        case .completed:
            return "checkmark.circle.fill"
        case .skipped:
            return "xmark.circle.fill"
        }
    }
    
    var statusEmoji: String {
        switch self {
        case .notStarted: return "⏰"
        case .inProgress: return "🔄"
        case .completed: return "✅"
        case .skipped: return "⏭️"
        }
    }
    
    // MARK: - State Logic
    
    /// Whether this status represents a completed state (for progress calculations)
    var isCompleted: Bool {
        return self == .completed
    }
    
    /// Whether this status represents an active state (user can interact)
    var isActive: Bool {
        return self == .inProgress
    }
    
    /// Whether this status represents a finished state (no more actions available)
    var isFinished: Bool {
        return self == .completed || self == .skipped
    }
    
    /// Whether this status can be changed to another status
    var canTransition: Bool {
        switch self {
        case .notStarted, .inProgress:
            return true
        case .completed, .skipped:
            return false // Once finished, cannot change (for data integrity)
        }
    }
    
    /// Available next states from current status
    var availableTransitions: [BlockStatus] {
        switch self {
        case .notStarted:
            return [.inProgress, .completed, .skipped]
        case .inProgress:
            return [.completed, .skipped]
        case .completed, .skipped:
            return [] // Final states
        }
    }
    
    // MARK: - Business Logic
    
    /// Determines the appropriate status based on current time and time block schedule
    static func determineStatus(
        startTime: Date,
        endTime: Date,
        currentStatus: BlockStatus,
        currentTime: Date = Date()
    ) -> BlockStatus {
        // Don't change status if already finished
        if currentStatus.isFinished {
            return currentStatus
        }
        
        // If current time is within the block timeframe and not started, mark as in progress
        if currentTime >= startTime && currentTime <= endTime && currentStatus == .notStarted {
            return .inProgress
        }
        
        // If current time is past the block and still in progress, keep as in progress
        // (let user manually mark as completed or skipped)
        
        return currentStatus
    }
    
    /// Whether a time block with this status should show action buttons
    var showsActionButtons: Bool {
        return self == .inProgress
    }
    
    /// Priority for sorting (higher number = higher priority in lists)
    var sortPriority: Int {
        switch self {
        case .inProgress: return 3
        case .notStarted: return 2
        case .completed: return 1
        case .skipped: return 0
        }
    }
    
    // MARK: - Accessibility
    
    /// Accessibility label for screen readers
    var accessibilityLabel: String {
        switch self {
        case .notStarted:
            return "Not started, upcoming task"
        case .inProgress:
            return "In progress, currently active"
        case .completed:
            return "Completed successfully"
        case .skipped:
            return "Skipped, not completed"
        }
    }
    
    /// Accessibility hint for actions
    var accessibilityHint: String? {
        switch self {
        case .notStarted:
            return "Task will become active at scheduled time"
        case .inProgress:
            return "Tap to mark as completed or skipped"
        case .completed:
            return "Task completed successfully"
        case .skipped:
            return "Task was skipped"
        }
    }
    
    // MARK: - Analytics & Metrics
    
    /// Category for analytics tracking
    var analyticsCategory: String {
        switch self {
        case .notStarted:
            return "pending"
        case .inProgress:
            return "active"
        case .completed:
            return "success"
        case .skipped:
            return "abandoned"
        }
    }
    
    /// Numeric value for progress calculations (0.0 to 1.0)
    var progressValue: Double {
        switch self {
        case .notStarted:
            return 0.0
        case .inProgress:
            return 0.5
        case .completed:
            return 1.0
        case .skipped:
            return 0.0
        }
    }
}

// MARK: - Theme-Aware View Extensions
extension View {
    /// Helper function to get color for a block status
    func statusColor(for status: BlockStatus, themeManager: ThemeManager?) -> Color {
        switch status {
        case .notStarted:
            return themeManager?.currentTheme.subtleTextColor ??
                   Theme.defaultTheme.subtleTextColor
        case .inProgress:
            return themeManager?.currentTheme.colorScheme.warning.color ??
                   Theme.defaultTheme.colorScheme.warning.color
        case .completed:
            return themeManager?.currentTheme.colorScheme.success.color ??
                   Theme.defaultTheme.colorScheme.success.color
        case .skipped:
            return themeManager?.currentTheme.colorScheme.error.color ??
                   Theme.defaultTheme.colorScheme.error.color
        }
    }
    
    /// Helper function to get background color for a block status
    func statusBackgroundColor(for status: BlockStatus, themeManager: ThemeManager?) -> Color {
        switch status {
        case .notStarted:
            return Color.clear
        case .inProgress:
            let color = themeManager?.currentTheme.colorScheme.warning.color ??
                       Theme.defaultTheme.colorScheme.warning.color
            return color.opacity(0.1)
        case .completed:
            let color = themeManager?.currentTheme.colorScheme.success.color ??
                       Theme.defaultTheme.colorScheme.success.color
            return color.opacity(0.1)
        case .skipped:
            let color = themeManager?.currentTheme.colorScheme.error.color ??
                       Theme.defaultTheme.colorScheme.error.color
            return color.opacity(0.1)
        }
    }
}

// MARK: - SwiftUI View Components
struct StatusIndicatorView: View {
    @Environment(\.themeManager) private var themeManager
    let status: BlockStatus
    
    var body: some View {
        Image(systemName: status.iconName)
            .foregroundStyle(statusColor(for: status, themeManager: themeManager))
            .font(.system(size: 16, weight: .medium))
    }
}

struct StatusBadgeView: View {
    @Environment(\.themeManager) private var themeManager
    let status: BlockStatus
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: status.iconName)
                .font(.system(size: 12, weight: .medium))
            
            Text(status.shortDisplayName)
                .font(.system(size: 12, weight: .medium))
        }
        .foregroundStyle(statusColor(for: status, themeManager: themeManager))
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(statusBackgroundColor(for: status, themeManager: themeManager))
        .cornerRadius(6)
    }
}
