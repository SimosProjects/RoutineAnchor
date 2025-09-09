//
//  FocusCard.swift
//  Routine Anchor
//
//  Shows current or next focus with time and optional progress.
//

import SwiftUI
import UserNotifications

struct FocusCard: View {
    let text: String
    let currentBlock: TimeBlock?
    let viewModel: TodayViewModel

    @Environment(\.themeManager) private var themeManager
    @State private var pulseScale: CGFloat = 1.0

    private var theme: AppTheme { themeManager?.currentTheme ?? PredefinedThemes.classic }

    var body: some View {
        HStack(spacing: 16) {
            // Focus icon with pulse
            ZStack {
                Circle()
                    .fill(theme.accentPrimaryColor.opacity(0.25))
                    .frame(width: 50, height: 50)
                    .scaleEffect(pulseScale)

                Image(systemName: "target")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(theme.accentPrimaryColor)
            }

            // Content
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Focus Mode")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(theme.secondaryTextColor.opacity(0.85))
                        .textCase(.uppercase)
                        .tracking(1)

                    Spacer()

                    if currentBlock != nil, let remainingTime = viewModel.remainingTimeForCurrentBlock() {
                        TimeIndicator(timeText: remainingTime, isActive: true)
                    } else if let nextTime = viewModel.timeUntilNextBlock() {
                        TimeIndicator(timeText: "in \(nextTime)", isActive: false)
                    }
                }

                Text(text)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(theme.primaryTextColor)
                    .lineLimit(2)

                // Progress bar when actively working
                if let currentBlock, currentBlock.isCurrentlyActive {
                    ProgressBar(
                        progress: currentBlock.currentProgress,
                        color: theme.accentPrimaryColor,
                        animated: true
                    )
                }
            }
        }
        .padding(20)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 16).fill(theme.surfaceCardColor.opacity(0.95))
                RoundedRectangle(cornerRadius: 16).fill(theme.glassMaterialOverlay)
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    LinearGradient(
                        colors: [theme.accentPrimaryColor.opacity(0.4),
                                 theme.accentPrimaryColor.opacity(0.1)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .onAppear {
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                pulseScale = 1.1
            }
        }
    }
}

// MARK: - Time Indicator (pill)

struct TimeIndicator: View {
    @Environment(\.themeManager) private var themeManager
    let timeText: String
    let isActive: Bool

    private var theme: AppTheme { themeManager?.currentTheme ?? PredefinedThemes.classic }

    var body: some View {
        let tint = isActive ? theme.statusSuccessColor : theme.accentPrimaryColor

        return HStack(spacing: 4) {
            Circle().fill(tint).frame(width: 6, height: 6)
            Text(timeText)
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundStyle(tint)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Capsule().fill(tint.opacity(0.15)))
    }
}
