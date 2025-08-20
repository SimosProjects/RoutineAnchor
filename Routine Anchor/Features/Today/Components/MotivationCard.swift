//
//  MotivationCard.swift
//  Routine Anchor
//
//  Created by Christopher Simonson on 7/21/25.
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
                CompletionActions(onViewSummary: {
                    // Show summary
                }, onPlanTomorrow: {
                    // Plan tomorrow
                })
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

// MARK: - Completion Actions
struct CompletionActions: View {
    let onViewSummary: () -> Void
    let onPlanTomorrow: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Button(action: onViewSummary) {
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
            }
            
            Button(action: onPlanTomorrow) {
                HStack(spacing: 6) {
                    Image(systemName: "calendar.badge.plus")
                        .font(.system(size: 14, weight: .medium))
                    Text("Plan Tomorrow")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundStyle(Color.anchorBlue)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    Color.anchorBlue.opacity(0.15)
                )
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.anchorBlue.opacity(0.3), lineWidth: 1)
                )
            }
        }
    }
}
