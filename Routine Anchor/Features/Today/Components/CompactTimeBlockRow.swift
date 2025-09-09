//
//  CompactTimeBlockRow.swift
//  Routine Anchor
//
//  Compact list row for a time block. Uses semantic Theme tokens.
//

import SwiftUI

struct CompactTimeBlockRow: View {
    @Environment(\.themeManager) private var themeManager

    let timeBlock: TimeBlock
    let isActive: Bool
    let isHighlighted: Bool
    let onTap: () -> Void
    let onComplete: () -> Void
    let onSkip: () -> Void

    private var theme: AppTheme { themeManager?.currentTheme ?? PredefinedThemes.classic }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Time
                Text(timeBlock.startTime, style: .time)
                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                    .foregroundStyle(isActive ? theme.accentPrimaryColor : theme.secondaryTextColor)
                    .frame(width: 60, alignment: .leading)

                // Icon + title
                HStack(spacing: 8) {
                    if let icon = timeBlock.icon {
                        Text(icon).font(.system(size: 16))
                    }
                    Text(timeBlock.title)
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundStyle(theme.primaryTextColor)
                        .lineLimit(1)
                }

                Spacer()

                // Status indicator
                Image(systemName: statusIcon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(statusTint)
                    .frame(width: 20, height: 20)
                    .background(statusTint.opacity(0.25))
                    .cornerRadius(4)

                // Quick actions
                if timeBlock.status == .notStarted || timeBlock.status == .inProgress {
                    HStack(spacing: 8) {
                        Button(action: onComplete) {
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(theme.statusSuccessColor)
                                .frame(width: 28, height: 28)
                                .background(theme.statusSuccessColor.opacity(0.15))
                                .cornerRadius(6)
                        }
                        Button(action: onSkip) {
                            Image(systemName: "forward.fill")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(theme.statusWarningColor)
                                .frame(width: 28, height: 28)
                                .background(theme.statusWarningColor.opacity(0.15))
                                .cornerRadius(6)
                        }
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill((isActive ? theme.surfaceCardColor.opacity(0.50)
                                    : theme.surfaceCardColor.opacity(0.25)))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isHighlighted ? theme.accentPrimaryColor
                                          : theme.borderColor.opacity(0.8),
                            lineWidth: isHighlighted ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
        .scaleEffect(isHighlighted ? 1.02 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHighlighted)
    }

    private var statusIcon: String {
        switch timeBlock.status {
        case .notStarted: return "clock"
        case .inProgress: return "play.fill"
        case .completed:  return "checkmark"
        case .skipped:    return "forward.fill"
        }
    }

    private var statusTint: Color {
        switch timeBlock.status {
        case .notStarted: return theme.secondaryTextColor
        case .inProgress: return theme.accentPrimaryColor
        case .completed:  return theme.statusSuccessColor
        case .skipped:    return theme.statusWarningColor
        }
    }
}
