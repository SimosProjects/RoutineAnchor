//
//  QuickStatsView.swift
//  Routine Anchor
//
//  Lightweight stats sheet. Fully migrated to semantic theme tokens.
//

import SwiftUI

struct QuickStatsView: View {
    let viewModel: TodayViewModel
    @Environment(\.themeManager) private var themeManager
    @Environment(\.dismiss) private var dismiss

    private var theme: AppTheme { themeManager?.currentTheme ?? PredefinedThemes.classic }

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 24) {
                HStack {
                    Text("Quick Stats")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(theme.actionPrimaryGradient)

                    Spacer()

                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(theme.subtleTextColor.opacity(0.6))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, max(geometry.safeAreaInsets.top + 8, 20))

                // MARK: Stats Grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    StatCard(title: "Total Blocks",
                             value: "\(viewModel.timeBlocks.count)",
                             subtitle: "blocks",
                             color: theme.accentPrimaryColor,
                             icon: "square.stack")

                    StatCard(title: "Completed",
                             value: "\(viewModel.completedBlocksCount)",
                             subtitle: "blocks",
                             color: theme.statusSuccessColor,
                             icon: "checkmark.circle")

                    StatCard(title: "Progress",
                             value: "\(viewModel.progressPercentage)%",
                             subtitle: "blocks",
                             color: theme.accentSecondaryColor,
                             icon: "chart.pie")

                    StatCard(title: "Remaining",
                             value: "\(viewModel.upcomingBlocksCount)",
                             subtitle: "blocks",
                             color: theme.iconMutedColor, // neutral-ish accent
                             icon: "clock")
                }
                .padding(.horizontal, 24)

                // Current focus block
                if let currentBlock = viewModel.getCurrentBlock() {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Currently Working On")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(theme.secondaryTextColor.opacity(0.85))

                        Text(currentBlock.title)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(theme.primaryTextColor)

                        if let remaining = viewModel.remainingTimeForCurrentBlock() {
                            Text(remaining)
                                .font(.system(size: 14, weight: .medium, design: .monospaced))
                                .foregroundStyle(theme.statusSuccessColor)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(theme.surfaceCardColor.opacity(0.55))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(theme.borderColor.opacity(0.8), lineWidth: 1)
                    )
                    .padding(.horizontal, 24)
                }

                Spacer(minLength: geometry.safeAreaInsets.bottom + 16)
            }
            .background(
                theme.heroBackground.ignoresSafeArea()
            )
        }
        .ignoresSafeArea(.container, edges: .bottom)
    }
}
