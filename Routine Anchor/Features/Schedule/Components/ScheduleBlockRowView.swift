//
//  ScheduleBlockRowView.swift
//  Routine Anchor
//
//  Row used in Schedule views to display a single time block with
//  status, time range, title/notes, and edit/delete actions.
//

import SwiftUI

struct ScheduleBlockRowView: View {
    let timeBlock: TimeBlock
    let onEdit: () -> Void
    let onDelete: () -> Void

    @Environment(\.themeManager) private var themeManager
    @State private var isVisible = false

    private var theme: AppTheme { themeManager?.currentTheme ?? PredefinedThemes.classic }

    var body: some View {
        ThemedCard(cornerRadius: 20) {
            HStack(spacing: 16) {
                // Status + time cluster
                VStack(spacing: 8) {
                    // Status indicator
                    ZStack {
                        Circle()
                            .fill(statusColor.opacity(0.20))
                            .frame(width: 32, height: 32)

                        Image(systemName: timeBlock.status.iconName)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(statusColor)
                    }

                    // Time range
                    VStack(spacing: 2) {
                        Text(timeBlock.shortFormattedTimeRange)
                            .font(.system(size: 11, weight: .semibold, design: .monospaced))
                            .foregroundStyle(theme.secondaryTextColor)

                        Text(timeBlock.formattedDuration)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(theme.subtleTextColor)
                    }
                }

                // Content
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        if let icon = timeBlock.icon {
                            Text(icon).font(.system(size: 18))
                        }
                        Text(timeBlock.title)
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundStyle(theme.primaryTextColor)
                            .lineLimit(1)
                    }

                    if let notes = timeBlock.notes, !notes.isEmpty {
                        Text(notes)
                            .font(.system(size: 14))
                            .foregroundStyle(theme.secondaryTextColor)
                            .lineLimit(2)
                    }

                    if let category = timeBlock.category {
                        HStack(spacing: 4) {
                            Image(systemName: "folder")
                                .font(.system(size: 10, weight: .medium))
                            Text(category)
                                .font(.system(size: 12, weight: .medium))
                        }
                        .foregroundStyle(theme.subtleTextColor)
                    }
                }

                Spacer()

                // Actions
                HStack(spacing: 8) {
                    Button(action: onEdit) {
                        Image(systemName: "pencil")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(theme.accentPrimaryColor)
                            .frame(width: 36, height: 36)
                            .background(theme.accentPrimaryColor.opacity(0.15))
                            .cornerRadius(10)
                    }

                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(theme.statusErrorColor)
                            .frame(width: 36, height: 36)
                            .background(theme.statusErrorColor.opacity(0.15))
                            .cornerRadius(10)
                    }
                }
            }
        }
        .overlay(
            // Subtle, status-tinted border to keep the card crisp
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    LinearGradient(
                        colors: [statusColor.opacity(0.30), statusColor.opacity(0.10)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: Color.black.opacity(0.20), radius: 10, x: 0, y: 5)
        .opacity(isVisible ? 1 : 0)
        .offset(x: isVisible ? 0 : 50)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.1)) {
                isVisible = true
            }
        }
    }

    // MARK: - Status Mapping (Theme tokens)

    private var statusColor: Color {
        switch timeBlock.status {
        case .notStarted: return theme.secondaryTextColor
        case .inProgress: return theme.accentPrimaryColor
        case .completed:  return theme.statusSuccessColor
        case .skipped:    return theme.statusWarningColor
        }
    }
}
