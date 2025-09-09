//
//  BlockStatus.swift
//  Routine Anchor
//
//  Represents the lifecycle state of a time block.
//  Core enum is UI-agnostic; a SwiftUI-only section at the bottom
//  provides theme-aware colors and small status views.
//

import Foundation

/// Represents the current state of a time block in the user's schedule.
enum BlockStatus: String, CaseIterable, Codable, Sendable {
    case notStarted = "not_started"
    case inProgress = "in_progress"
    case completed  = "completed"
    case skipped    = "skipped"

    // MARK: - Display

    /// Human-readable name for the status (long).
    var displayName: String {
        switch self {
        case .notStarted: return "Upcoming"
        case .inProgress: return "In Progress"
        case .completed:  return "Completed"
        case .skipped:    return "Skipped"
        }
    }

    /// Compact name for small UI elements.
    var shortDisplayName: String {
        switch self {
        case .notStarted: return "Upcoming"
        case .inProgress: return "Active"
        case .completed:  return "Done"
        case .skipped:    return "Skipped"
        }
    }

    /// SF Symbol best representing the status.
    var iconName: String {
        switch self {
        case .notStarted: return "circle"
        case .inProgress: return "clock.fill"
        case .completed:  return "checkmark.circle.fill"
        case .skipped:    return "xmark.circle.fill"
        }
    }

    /// Emoji used occasionally in copy.
    var emoji: String {
        switch self {
        case .notStarted: return "⏰"
        case .inProgress: return "🔄"
        case .completed:  return "✅"
        case .skipped:    return "⏭️"
        }
    }

    // MARK: - State Logic

    /// Whether this is a completed state (counts as success in progress calculations).
    var isCompleted: Bool { self == .completed }

    /// Whether the user can actively interact with this state.
    var isActive: Bool { self == .inProgress }

    /// Whether no more actions should be available (terminal state).
    var isFinished: Bool { self == .completed || self == .skipped }

    /// Whether transitions are allowed out of this state.
    var canTransition: Bool {
        switch self {
        case .notStarted, .inProgress: return true
        case .completed, .skipped:     return false
        }
    }

    /// Allowed next states (for UI menus etc.).
    var availableTransitions: [BlockStatus] {
        switch self {
        case .notStarted: return [.inProgress, .completed, .skipped]
        case .inProgress: return [.completed, .skipped]
        case .completed, .skipped: return []
        }
    }

    /// Determine status based on current time window (non-destructive).
    static func determineStatus(
        startTime: Date,
        endTime: Date,
        currentStatus: BlockStatus,
        currentTime: Date = Date()
    ) -> BlockStatus {
        // Don't override terminal states.
        if currentStatus.isFinished { return currentStatus }

        // Auto-activate when we enter the time window.
        if currentTime >= startTime && currentTime <= endTime && currentStatus == .notStarted {
            return .inProgress
        }

        // If past end and still in progress, keep as-is (user decides complete/skip).
        return currentStatus
    }

    // MARK: - Sorting / Analytics

    /// Sort priority for list grouping (higher first).
    var sortPriority: Int {
        switch self {
        case .inProgress: return 3
        case .notStarted: return 2
        case .completed:  return 1
        case .skipped:    return 0
        }
    }

    /// Buckets for analytics.
    var analyticsCategory: String {
        switch self {
        case .notStarted: return "pending"
        case .inProgress: return "active"
        case .completed:  return "success"
        case .skipped:    return "abandoned"
        }
    }

    /// A rough numeric factor for progress visuals.
    var progressValue: Double {
        switch self {
        case .notStarted: return 0.0
        case .inProgress: return 0.5
        case .completed:  return 1.0
        case .skipped:    return 0.0
        }
    }

    // MARK: - Accessibility

    var accessibilityLabel: String {
        switch self {
        case .notStarted: return "Not started, upcoming task"
        case .inProgress: return "In progress, currently active"
        case .completed:  return "Completed successfully"
        case .skipped:    return "Skipped, not completed"
        }
    }

    var accessibilityHint: String? {
        switch self {
        case .notStarted: return "Task will become active at scheduled time"
        case .inProgress: return "Tap to mark as completed or skipped"
        case .completed:  return "Task completed successfully"
        case .skipped:    return "Task was skipped"
        }
    }
}

#if canImport(SwiftUI)
import SwiftUI

// MARK: - Theme-aware colors (SwiftUI-only)

extension BlockStatus {
    /// Main tint color for a status under a given theme.
    func tintColor(theme: AppTheme) -> Color {
        switch self {
        case .notStarted: return theme.subtleTextColor
        case .inProgress: return theme.statusWarningColor
        case .completed:  return theme.statusSuccessColor
        case .skipped:    return theme.statusErrorColor
        }
    }

    /// Background tint for chips/badges.
    func backgroundTint(theme: AppTheme) -> Color {
        switch self {
        case .notStarted: return .clear
        default:          return tintColor(theme: theme).opacity(0.12)
        }
    }
}

// MARK: - Minimal status UI helpers

struct StatusIndicatorView: View {
    @Environment(\.themeManager) private var themeManager
    let status: BlockStatus

    private var theme: AppTheme { themeManager?.currentTheme ?? PredefinedThemes.classic }

    var body: some View {
        Image(systemName: status.iconName)
            .foregroundStyle(status.tintColor(theme: theme))
            .font(.system(size: 16, weight: .medium))
            .accessibilityLabel(status.accessibilityLabel)
    }
}

struct StatusBadgeView: View {
    @Environment(\.themeManager) private var themeManager
    let status: BlockStatus

    private var theme: AppTheme { themeManager?.currentTheme ?? PredefinedThemes.classic }

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: status.iconName)
                .font(.system(size: 12, weight: .medium))
            Text(status.shortDisplayName)
                .font(.system(size: 12, weight: .medium))
        }
        .foregroundStyle(status.tintColor(theme: theme))
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(status.backgroundTint(theme: theme))
        .cornerRadius(6)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(status.accessibilityLabel)
    }
}
#endif
