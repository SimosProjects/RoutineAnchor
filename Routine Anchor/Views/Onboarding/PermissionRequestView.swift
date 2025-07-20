//
//  PermissionRequestView.swift
//  Routine Anchor
//
//  Created by Christopher Simonson on 7/19/25.
//
import SwiftUI
import UserNotifications

// MARK: - Permission Request View
struct PermissionRequestView: View {
    let onAllow: () -> Void
    let onSkip: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button("Skip") {
                    HapticManager.shared.lightImpact()
                    onSkip()
                }
                .font(TypographyConstants.UI.button)
                .foregroundColor(Color.textSecondary)
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            
            Spacer()
            
            // Content
            VStack(spacing: 32) {
                // Notification icon with animation
                ZStack {
                    Circle()
                        .fill(Color.primaryBlue.opacity(0.1))
                        .frame(width: 120, height: 120)
                    
                    Image(systemName: "bell.badge.fill")
                        .font(.system(size: 50, weight: .medium))
                        .foregroundColor(Color.primaryBlue)
                        .symbolRenderingMode(.hierarchical)
                }
                
                VStack(spacing: 16) {
                    Text("Stay on Track")
                        .font(TypographyConstants.Headers.screenTitle)
                        .foregroundColor(Color.textPrimary)
                    
                    Text("Routine Anchor sends gentle reminders when each time block begins, helping you stay focused on your goals.")
                        .font(TypographyConstants.Body.description)
                        .foregroundColor(Color.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(4)
                        .padding(.horizontal, 30)
                }
                
                // Benefits list
                VStack(spacing: 16) {
                    BenefitRow(
                        icon: "clock.fill",
                        text: "Never miss a scheduled activity"
                    )
                    
                    BenefitRow(
                        icon: "target",
                        text: "Stay focused on your daily goals"
                    )
                    
                    BenefitRow(
                        icon: "gear.circle.fill",
                        text: "Customize or disable anytime in Settings"
                    )
                }
                .padding(.horizontal, 40)
            }
            
            Spacer()
            
            // Action buttons
            VStack(spacing: 12) {
                PrimaryButton(title: "Enable Notifications") {
                    HapticManager.shared.lightImpact()
                    onAllow()
                }
                
                SecondaryButton(title: "Maybe Later") {
                    HapticManager.shared.lightImpact()
                    onSkip()
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
    }
}
