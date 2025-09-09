//
//  MotivationCard.swift
//  Routine Anchor
//
//  Daily reflection + completion actions. Uses Theme tokens.
//

import SwiftUI
import UserNotifications

struct MotivationalCard: View {
    let viewModel: TodayViewModel
    @Environment(\.themeManager) private var themeManager
    @State private var showConfetti = false

    private var theme: AppTheme { themeManager?.currentTheme ?? PredefinedThemes.classic }

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text(viewModel.performanceLevel.emoji)
                    .font(.system(size: 32))

                VStack(alignment: .leading, spacing: 4) {
                    Text("Daily Reflection")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(theme.secondaryTextColor.opacity(0.85))
                        .textCase(.uppercase)
                        .tracking(1)

                    Text(viewModel.motivationalMessage)
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundStyle(theme.primaryTextColor)
                        .multilineTextAlignment(.leading)
                }

                Spacer()
            }

            if viewModel.isDayComplete {
                CompletionActions(
                    onViewSummary: {
                        NotificationCenter.default.post(name: .showDailySummary, object: nil)
                    },
                    onPlanTomorrow: {
                        NotificationCenter.default.post(name: .navigateToSchedule, object: nil)
                    }
                )
            }
        }
        .padding(20)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 16).fill(theme.surfaceCardColor.opacity(0.95))
                // Subtle performance tint + glass overlay
                RoundedRectangle(cornerRadius: 16).fill(
                    LinearGradient(
                        colors: [
                            theme.surfaceGlassColor,
                            theme.surfaceGlassColor
                        ],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                )
                RoundedRectangle(cornerRadius: 16).fill(theme.glassMaterialOverlay)
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(theme.borderColor.opacity(0.8), lineWidth: 1)
        )
        .overlay(ConfettiView(isActive: $showConfetti).allowsHitTesting(false))
        .onAppear {
            if viewModel.isDayComplete && viewModel.progressPercentage >= 0.8 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showConfetti = true
                }
            }
        }
    }
}

// MARK: - Completion Actions

struct CompletionActions: View {
    let onViewSummary: () -> Void
    let onPlanTomorrow: () -> Void

    @Environment(\.themeManager) private var themeManager
    @State private var isViewSummaryPressed = false
    @State private var isPlanTomorrowPressed = false

    private var theme: AppTheme { themeManager?.currentTheme ?? PredefinedThemes.classic }

    var body: some View {
        HStack(spacing: 12) {
            // View Summary
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { isViewSummaryPressed = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { isViewSummaryPressed = false }
                    HapticManager.shared.lightImpact()
                    onViewSummary()
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "chart.pie.fill").font(.system(size: 14, weight: .medium))
                    Text("View Summary").font(.system(size: 14, weight: .semibold))
                }
                .foregroundStyle(theme.invertedTextColor)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(
                        colors: [theme.statusSuccessColor, theme.accentSecondaryColor],
                        startPoint: .leading, endPoint: .trailing
                    )
                )
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(theme.borderColor.opacity(0.8), lineWidth: 1)
                )
                .scaleEffect(isViewSummaryPressed ? 0.97 : 1)
                .shadow(color: theme.statusSuccessColor.opacity(0.3), radius: 6, x: 0, y: 3)
            }

            // Plan Tomorrow
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { isPlanTomorrowPressed = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { isPlanTomorrowPressed = false }
                    HapticManager.shared.impact()
                    onPlanTomorrow()
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "calendar.badge.plus").font(.system(size: 14, weight: .medium))
                    Text("Plan Tomorrow").font(.system(size: 14, weight: .semibold))
                }
                .foregroundStyle(theme.invertedTextColor)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(
                        colors: [theme.accentPrimaryColor, theme.accentSecondaryColor],
                        startPoint: .leading, endPoint: .trailing
                    )
                )
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(theme.borderColor.opacity(0.8), lineWidth: 1)
                )
                .scaleEffect(isPlanTomorrowPressed ? 0.97 : 1)
                .shadow(color: theme.accentPrimaryColor.opacity(0.3), radius: 6, x: 0, y: 3)
            }
        }
    }
}
