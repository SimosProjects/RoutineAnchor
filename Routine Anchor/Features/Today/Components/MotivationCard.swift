//
//  MotivationCard.swift
//  Routine Anchor
//
//  Enhanced with functional buttons and better styling
//
import SwiftUI
import UserNotifications

// MARK: - Motivational Card
struct MotivationalCard: View {
    let viewModel: TodayViewModel
    @State private var showConfetti = false
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text(viewModel.performanceLevel.emoji)
                    .font(.system(size: 32))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Daily Reflection")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.white.opacity(0.6))
                        .textCase(.uppercase)
                        .tracking(1)
                    
                    Text(viewModel.motivationalMessage)
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
            }
            
            if viewModel.isDayComplete {
                CompletionActions(
                    onViewSummary: {
                        // FIXED: Actually show the summary
                        NotificationCenter.default.post(name: .showDailySummary, object: nil)
                    },
                    onPlanTomorrow: {
                        // FIXED: Actually navigate to schedule for planning tomorrow
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
    
    @State private var isViewSummaryPressed = false
    @State private var isPlanTomorrowPressed = false
    
    var body: some View {
        HStack(spacing: 12) {
            // View Summary Button (keep existing good style, add press animation)
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
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(
                        colors: [Color.anchorGreen, Color.anchorTeal],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(10)
                .scaleEffect(isViewSummaryPressed ? 0.97 : 1)
                .shadow(color: Color.anchorGreen.opacity(0.3), radius: 6, x: 0, y: 3)
            }
            
            // FIXED: Plan Tomorrow Button - styled like the alternative solution
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
                .foregroundStyle(.white) // FIXED: Changed to white text
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    // FIXED: Changed to gradient like the alternative solution
                    LinearGradient(
                        colors: [Color.anchorBlue, Color.anchorPurple],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1) // FIXED: Added subtle border
                )
                .scaleEffect(isPlanTomorrowPressed ? 0.97 : 1) // FIXED: Added press animation
                .shadow(color: Color.anchorBlue.opacity(0.3), radius: 6, x: 0, y: 3) // FIXED: Added shadow
            }
        }
    }
}
