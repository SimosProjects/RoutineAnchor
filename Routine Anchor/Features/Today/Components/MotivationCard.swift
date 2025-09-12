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
        // Pull scheme/text once
        let scheme = (themeManager?.currentTheme.colorScheme ?? Theme.defaultTheme.colorScheme)
        let primaryText = (themeManager?.currentTheme.primaryTextColor ?? Theme.defaultTheme.primaryTextColor)
        let secondaryText = (themeManager?.currentTheme.secondaryTextColor ?? Theme.defaultTheme.secondaryTextColor)
        
        return VStack(spacing: 16) {
            HStack {
                Text(viewModel.performanceLevel.emoji)
                    .font(.system(size: 32))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Daily Reflection")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(secondaryText.opacity(0.85))
                        .textCase(.uppercase)
                        .tracking(1)
                    
                    Text(viewModel.motivationalMessage)
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundStyle(primaryText)
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
        // Glass base using theme tokens
        .themedGlassMorphism(cornerRadius: 16)
        // Subtle performance tint behind the glass (lets the color glow through)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [
                            viewModel.performanceLevel.color.opacity(0.10),
                            .clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        // Border uses theme border token for consistency
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(scheme.border.color.opacity(0.8), lineWidth: 1)
        )
        // Confetti overlay
        .overlay(
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
        let scheme = (themeManager?.currentTheme.colorScheme ?? Theme.defaultTheme.colorScheme)
        let primaryText = (themeManager?.currentTheme.primaryTextColor ?? Theme.defaultTheme.primaryTextColor)
        
        return HStack(spacing: 12) {
            // View Summary
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { isViewSummaryPressed = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { isViewSummaryPressed = false }
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
                .foregroundStyle(primaryText)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(
                        colors: [scheme.success.color, scheme.secondaryUIElement.color],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(scheme.border.color.opacity(0.8), lineWidth: 1)
                )
                .scaleEffect(isViewSummaryPressed ? 0.97 : 1)
                .shadow(color: scheme.success.color.opacity(0.3), radius: 6, x: 0, y: 3)
            }
            
            // Plan Tomorrow
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { isPlanTomorrowPressed = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { isPlanTomorrowPressed = false }
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
                .foregroundStyle(primaryText)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(
                        colors: [scheme.normal.color, scheme.primaryAccent.color],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(scheme.border.color.opacity(0.8), lineWidth: 1)
                )
                .scaleEffect(isPlanTomorrowPressed ? 0.97 : 1)
                .shadow(color: scheme.normal.color.opacity(0.3), radius: 6, x: 0, y: 3)
            }
        }
    }
}
