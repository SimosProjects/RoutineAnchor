//
//  ProgressOverviewCard.swift
//  Routine Anchor
//
//  Overall progress ring + summary. Themed via semantic tokens.
//

import SwiftUI
import UserNotifications

struct ProgressOverviewCard: View {
    let viewModel: TodayViewModel
    @Environment(\.themeManager) private var themeManager
    @State private var animateProgress = false

    private var theme: AppTheme { themeManager?.currentTheme ?? PredefinedThemes.classic }

    var body: some View {
        ThemedCard(cornerRadius: 16) {
            HStack(spacing: 20) {
                // Circular progress
                ZStack {
                    // Track
                    Circle()
                        .stroke(theme.borderColor.opacity(0.6), lineWidth: 4)
                        .frame(width: 60, height: 60)

                    // Fill
                    Circle()
                        .trim(from: 0, to: animateProgress ? CGFloat(viewModel.progressPercentage) : 0)
                        .stroke(
                            theme.actionPrimaryGradient,
                            style: StrokeStyle(lineWidth: 4, lineCap: .round)
                        )
                        .frame(width: 60, height: 60)
                        .rotationEffect(.degrees(-90))

                    // Label
                    Text(viewModel.formattedProgressPercentage)
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(theme.primaryTextColor)
                }

                // Details
                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.completionSummary)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(theme.primaryTextColor)

                    Text(viewModel.timeSummary)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(theme.secondaryTextColor)

                    HStack(spacing: 6) {
                        Text(viewModel.performanceLevel.emoji).font(.system(size: 12))
                        Text(viewModel.performanceLevel.displayName)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(viewModel.performanceLevel.color(theme: theme))
                    }
                }

                Spacer()
            }
        }
        .onAppear {
            withAnimation(.spring(response: 1.2, dampingFraction: 0.8).delay(0.3)) {
                animateProgress = true
            }
        }
    }
}
