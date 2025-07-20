//
//  WelcomeView.swift
//  Routine Anchor
//
//  Created by Christopher Simonson on 7/19/25.
//
import SwiftUI
import UserNotifications

// MARK: - Welcome View
struct WelcomeView: View {
    let onContinue: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Hero section
            VStack(spacing: 24) {
                // App icon/logo
                Image(systemName: "target")
                    .font(.system(size: 80, weight: .thin))
                    .foregroundColor(Color.primaryBlue)
                    .symbolRenderingMode(.hierarchical)
                
                VStack(spacing: 12) {
                    Text("Welcome to")
                        .font(TypographyConstants.Headers.screenTitle)
                        .foregroundColor(Color.textSecondary)
                    
                    Text("Routine Anchor")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(Color.primaryBlue)
                        .multilineTextAlignment(.center)
                }
                
                Text("Build consistent daily habits with time-blocked routines and gentle accountability.")
                    .font(TypographyConstants.Body.description)
                    .foregroundColor(Color.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .padding(.horizontal, 20)
            }
            
            Spacer()
            
            // Features showcase
            VStack(spacing: 20) {
                FeatureRow(
                    icon: "bell.fill",
                    title: "Smart Reminders",
                    description: "Get notified when each time block begins"
                )
                
                FeatureRow(
                    icon: "checkmark.circle.fill",
                    title: "Simple Check-ins",
                    description: "Mark tasks as completed or skipped honestly"
                )
                
                FeatureRow(
                    icon: "chart.bar.fill",
                    title: "Progress Tracking",
                    description: "See your daily productivity at a glance"
                )
            }
            .padding(.horizontal, 40)
            
            Spacer()
            
            // Action buttons
            VStack(spacing: 16) {
                PrimaryButton(title: "Get Started") {
                    HapticManager.shared.lightImpact()
                    onContinue()
                }
                
                // Privacy policy link
                Button(action: {
                    // Show privacy policy
                }) {
                    Text("By continuing, you agree to our \(Text("Privacy Policy").fontWeight(.bold))")
                        .font(TypographyConstants.UI.caption)
                        .foregroundColor(Color.textSecondary)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
    }
}
