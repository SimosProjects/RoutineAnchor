//
//  MotivationCard.swift
//  Routine Anchor
//
//
import SwiftUI
import UserNotifications

// MARK: - Motivational Card
struct MotivationalCard: View {
    let viewModel: TodayViewModel
    @Environment(\.themeManager) private var themeManager
    @State private var showConfetti = false
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text(viewModel.performanceLevel.emoji)
                    .font(.system(size: 32))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Daily Reflection")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color(themeManager?.currentTheme.secondaryTextColor ?? Theme.defaultTheme.secondaryTextColor).opacity(0.85))
                        .textCase(.uppercase)
                        .tracking(1)
                    
                    Text(viewModel.motivationalMessage)
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundStyle(themeManager?.currentTheme.primaryTextColor ?? Theme.defaultTheme.primaryTextColor)
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
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .background(
                    LinearGradient(
                        colors: [
                            viewModel.performanceLevel.color.opacity(0.1),
                            Color.clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .cornerRadius(16)
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    LinearGradient(
                        colors: [
                            viewModel.performanceLevel.color.opacity(0.3),
                            viewModel.performanceLevel.color.opacity(0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .overlay(
            // Confetti overlay
            ConfettiView(isActive: $showConfetti)
                .allowsHitTesting(false)
        )
        .onAppear {
            if viewModel.isDayComplete && viewModel.progressPercentage >= 0.8 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showConfetti = true
                }
            }
        }
    }
}

// MARK: - Enhanced Completion Actions
struct CompletionActions: View {
    let onViewSummary: () -> Void
    let onPlanTomorrow: () -> Void
    
    @Environment(\.themeManager) private var themeManager
    @State private var isViewSummaryPressed = false
    @State private var isPlanTomorrowPressed = false
    
    var body: some View {
        HStack(spacing: 12) {
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    isViewSummaryPressed = true
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        isViewSummaryPressed = false
                    }
                    HapticManager.shared.lightImpact()
                    onViewSummary()
                }
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "chart.pie.fill")
                        .font(.system(size: 14, weight: .medium))
                    Text("View Summary")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundStyle(themeManager?.currentTheme.primaryTextColor ?? Theme.defaultTheme.primaryTextColor)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(
                        colors: [themeManager?.currentTheme.colorScheme.actionSuccess.color ?? Theme.defaultTheme.colorScheme.actionSuccess.color, themeManager?.currentTheme.colorScheme.creativeSecondary.color ?? Theme.defaultTheme.colorScheme.creativeSecondary.color],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(10)
                .scaleEffect(isViewSummaryPressed ? 0.97 : 1)
                .shadow(color: themeManager?.currentTheme.colorScheme.actionSuccess.color ?? Theme.defaultTheme.colorScheme.actionSuccess.color.opacity(0.3), radius: 6, x: 0, y: 3)
            }
            
            // Plan Tomorrow Button
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    isPlanTomorrowPressed = true
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        isPlanTomorrowPressed = false
                    }
                    HapticManager.shared.impact()
                    onPlanTomorrow()
                }
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "calendar.badge.plus")
                        .font(.system(size: 14, weight: .medium))
                    Text("Plan Tomorrow")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundStyle(themeManager?.currentTheme.primaryTextColor ?? Theme.defaultTheme.primaryTextColor)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(
                        colors: [themeManager?.currentTheme.colorScheme.workflowPrimary.color ?? Theme.defaultTheme.colorScheme.workflowPrimary.color, themeManager?.currentTheme.colorScheme.organizationAccent.color ?? Theme.defaultTheme.colorScheme.organizationAccent.color],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color(themeManager?.currentTheme.colorScheme.uiElementSecondary.color ?? Theme.defaultTheme.colorScheme.uiElementSecondary.color), lineWidth: 1)
                )
                .scaleEffect(isPlanTomorrowPressed ? 0.97 : 1)
                .shadow(color: themeManager?.currentTheme.colorScheme.workflowPrimary.color ?? Theme.defaultTheme.colorScheme.workflowPrimary.color.opacity(0.3), radius: 6, x: 0, y: 3)
            }
        }
    }
}
