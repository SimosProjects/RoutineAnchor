//
//  TaskBreakdownRow.swift
//  Routine Anchor
//
//  Compact row used in Daily Summary's "Task Breakdown" card.
//  - Migrated to semantic Theme tokens
//

import SwiftUI

struct TaskBreakdownRow: View {
    @Environment(\.themeManager) private var themeManager
    let timeBlock: TimeBlock

    private var theme: AppTheme { themeManager?.currentTheme ?? PredefinedThemes.classic }

    var body: some View {
        HStack(spacing: 12) {
            // Status indicator
            StatusIndicatorView(status: timeBlock.status)
                .frame(width: 24, height: 24)

            // Content
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    if let icon = timeBlock.icon {
                        Text(icon).font(.system(size: 14))
                    }

                    Text(timeBlock.title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(theme.primaryTextColor)
                        .lineLimit(1)
                }

                Text(timeBlock.shortFormattedTimeRange)
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundStyle(theme.secondaryTextColor.opacity(0.85))
            }

            Spacer()

            // Duration and status
            VStack(alignment: .trailing, spacing: 2) {
                Text(timeBlock.formattedDuration)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(theme.secondaryTextColor.opacity(0.85))

                Text(timeBlock.status.shortDisplayName)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(statusColor(for: timeBlock.status))
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(theme.color.surface.card.opacity(0.55))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(statusColor(for: timeBlock.status).opacity(0.25), lineWidth: 1)
        )
    }

    // MARK: - Status → Color

    private func statusColor(for status: BlockStatus) -> Color {
        switch status {
        case .notStarted: return theme.secondaryTextColor
        case .inProgress: return theme.accentPrimaryColor
        case .completed:  return theme.statusSuccessColor
        case .skipped:    return theme.statusWarningColor
        }
    }
}
