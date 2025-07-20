//
//  OnboardingCompleteView.swift
//  Routine Anchor
//
//  Created by Christopher Simonson on 7/19/25.
//
import SwiftUI
import UserNotifications

// MARK: - Setup Complete View
struct OnboardingCompleteView: View {
    let onFinish: () -> Void
    @State private var showCheckmark = false
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            VStack(spacing: 32) {
                // Success animation
                ZStack {
                    Circle()
                        .fill(Color.successGreen.opacity(0.1))
                        .frame(width: 120, height: 120)
                        .scaleEffect(showCheckmark ? 1.0 : 0.8)
                    
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 60, weight: .medium))
                        .foregroundColor(Color.successGreen)
                        .scaleEffect(showCheckmark ? 1.0 : 0.5)
                        .opacity(showCheckmark ? 1.0 : 0.0)
                }
                .animation(.spring(response: 0.6, dampingFraction: 0.6), value: showCheckmark)
                
                VStack(spacing: 16) {
                    Text("You're All Set!")
                        .font(TypographyConstants.Headers.screenTitle)
                        .foregroundColor(Color.textPrimary)
                    
                    Text("Ready to build consistent daily habits? Create your first routine to get started with time-blocked productivity.")
                        .font(TypographyConstants.Body.description)
                        .foregroundColor(Color.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(4)
                        .padding(.horizontal, 30)
                }
                
                // Next steps
                VStack(spacing: 16) {
                    NextStepRow(
                        number: "1",
                        title: "Create Your Routine",
                        description: "Set up time blocks for your day"
                    )
                    
                    NextStepRow(
                        number: "2",
                        title: "Follow Your Schedule",
                        description: "Get reminders and check off completed tasks"
                    )
                    
                    NextStepRow(
                        number: "3",
                        title: "Track Your Progress",
                        description: "See how well you're sticking to your goals"
                    )
                }
                .padding(.horizontal, 30)
            }
            
            Spacer()
            
            // Finish button
            PrimaryButton(title: "Start Building Habits") {
                HapticManager.shared.success()
                onFinish()
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
        .onAppear {
            // Trigger checkmark animation after a delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                showCheckmark = true
            }
        }
    }
}
