//
//  PrivacyPolicyView.swift
//  Routine Anchor
//
//  Created by Christopher Simonson on 7/21/25.
//
import SwiftUI

struct PrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var animationPhase = 0
    
    var body: some View {
        ZStack {
            AnimatedGradientBackground()
            AnimatedMeshBackground()
                .opacity(0.3)
                .allowsHitTesting(false)
            ParticleEffectView()
                .allowsHitTesting(false)
            
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection
                    
                    // Privacy sections
                    privacySections
                    
                    // Contact section
                    contactSection
                    
                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                animationPhase = 1
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 16) {
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.8))
                        .frame(width: 32, height: 32)
                        .background(
                            Circle()
                                .fill(.ultraThinMaterial)
                                .background(
                                    Circle().fill(Color.white.opacity(0.1))
                                )
                        )
                }
                
                Spacer()
            }
            
            VStack(spacing: 12) {
                Image(systemName: "shield.checkered")
                    .font(.system(size: 48, weight: .light))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.anchorBlue, Color.anchorPurple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .scaleEffect(animationPhase == 0 ? 1.0 : 1.1)
                    .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: animationPhase)
                
                Text("Privacy Policy")
                    .font(TypographyConstants.Headers.welcome)
                    .foregroundStyle(Color.anchorTextPrimary)
                    .multilineTextAlignment(.center)
                
                Text("Your privacy is our priority")
                    .font(TypographyConstants.Body.secondary)
                    .foregroundStyle(Color.anchorTextSecondary)
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    // MARK: - Privacy Sections
    private var privacySections: some View {
        VStack(spacing: 20) {
            PrivacySection(
                icon: "iphone",
                title: "Local Storage Only",
                content: "All your routine data is stored locally on your device. We never collect, transmit, or store your personal information on external servers.",
                color: Color.anchorGreen
            )
            
            PrivacySection(
                icon: "bell.badge",
                title: "Notification Permissions",
                content: "We only request notification permissions to send you helpful reminders about your time blocks. You can disable these at any time in Settings.",
                color: Color.anchorBlue
            )
            
            PrivacySection(
                icon: "lock.shield",
                title: "No Data Collection",
                content: "Routine Anchor does not collect analytics, usage data, or any personal information. Your productivity data remains completely private.",
                color: Color.anchorPurple
            )
            
            PrivacySection(
                icon: "externaldrive",
                title: "No Third Parties",
                content: "We don't share data with third parties because we don't collect it in the first place. Your information never leaves your device.",
                color: Color.anchorTeal
            )
            
            PrivacySection(
                icon: "trash",
                title: "Data Deletion",
                content: "You can delete all your data at any time from the Settings screen. When you delete the app, all data is permanently removed.",
                color: Color.anchorWarning
            )
        }
    }
    
    // MARK: - Contact Section
    private var contactSection: some View {
        VStack(spacing: 16) {
            Text("Questions About Privacy?")
                .font(TypographyConstants.Headers.cardTitle)
                .foregroundStyle(Color.anchorTextPrimary)
            
            Text("If you have any questions about this privacy policy or how we handle your data, please contact us.")
                .font(TypographyConstants.Body.secondary)
                .foregroundStyle(Color.anchorTextSecondary)
                .multilineTextAlignment(.center)
            
            Button(action: contactSupport) {
                HStack(spacing: 8) {
                    Image(systemName: "envelope")
                        .font(.system(size: 16, weight: .medium))
                    
                    Text("Contact Support")
                        .font(TypographyConstants.UI.button)
                        .fontWeight(.medium)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(
                    LinearGradient(
                        colors: [Color.anchorBlue, Color.anchorPurple],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
                .shadow(color: Color.anchorBlue.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .padding(.horizontal, 20)
        }
        .padding(20)
        .glassMorphism()
    }
    
    // MARK: - Actions
    private func contactSupport() {
        HapticManager.shared.lightImpact()
        
        if let url = URL(string: "mailto:support@routineanchor.com?subject=Privacy%20Question") {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Privacy Section Component
struct PrivacySection: View {
    let icon: String
    let title: String
    let content: String
    let color: Color
    
    @State private var isVisible = false
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 48, height: 48)
                
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(color)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(TypographyConstants.Headers.cardTitle)
                    .foregroundStyle(Color.anchorTextPrimary)
                
                Text(content)
                    .font(TypographyConstants.Body.secondary)
                    .foregroundStyle(Color.anchorTextSecondary)
                    .lineSpacing(2)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.08),
                                    Color.white.opacity(0.04)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    LinearGradient(
                        colors: [
                            color.opacity(0.3),
                            color.opacity(0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: color.opacity(0.2), radius: 8, x: 0, y: 4)
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : 20)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
                isVisible = true
            }
        }
    }
}

// MARK: - Preview
#Preview {
    PrivacyPolicyView()
}
