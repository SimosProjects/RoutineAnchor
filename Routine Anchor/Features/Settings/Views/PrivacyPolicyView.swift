//
//  PrivacyPolicyView.swift
//  Routine Anchor
//
//  Created by Christopher Simonson on 7/21/25.
//
import SwiftUI

struct PrivacyPolicyView: View {
    @Environment(\.themeManager) private var themeManager
    @Environment(\.dismiss) private var dismiss
    @State private var animationPhase = 0
    
    var body: some View {
        ZStack {
            ThemedAnimatedBackground()
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
                        .foregroundStyle((themeManager?.currentTheme.textPrimaryColor ?? Theme.defaultTheme.textPrimaryColor).opacity(0.8))
                        .frame(width: 32, height: 32)
                        .background(
                            Circle()
                                .fill(.ultraThinMaterial)
                                .background(
                                    Circle().fill(themeManager?.currentTheme.colorScheme.surfacePrimary.color ?? Theme.defaultTheme.colorScheme.surfacePrimary.color)
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
                            colors: [themeManager?.currentTheme.colorScheme.blue.color ?? Theme.defaultTheme.colorScheme.blue.color, themeManager?.currentTheme.colorScheme.purple.color ?? Theme.defaultTheme.colorScheme.purple.color],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .scaleEffect(animationPhase == 0 ? 1.0 : 1.1)
                    .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: animationPhase)
                
                Text("Privacy Policy")
                    .font(TypographyConstants.Headers.welcome)
                    .foregroundStyle(themeManager?.currentTheme.textPrimaryColor ?? Theme.defaultTheme.textPrimaryColor)
                    .multilineTextAlignment(.center)
                
                Text("Your privacy is our priority")
                    .font(TypographyConstants.Body.secondary)
                    .foregroundStyle(themeManager?.currentTheme.textSecondaryColor ?? Theme.defaultTheme.textSecondaryColor)
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    // MARK: - Privacy Sections
    private var privacySections: some View {
        VStack(spacing: 20) {
            PrivacySection(
                icon: "iphone",
                title: "Local Storage First",
                content: "Your routine data is stored locally on your device by default. We only collect email addresses when you voluntarily provide them for updates and courses.",
                color: themeManager?.currentTheme.colorScheme.green.color ?? Theme.defaultTheme.colorScheme.green.color
            )
            
            PrivacySection(
                icon: "envelope",
                title: "Optional Email Collection",
                content: "We may ask for your email to send productivity tips, app updates, and information about our app development courses. This is completely optional and you can unsubscribe anytime.",
                color: themeManager?.currentTheme.colorScheme.blue.color ?? Theme.defaultTheme.colorScheme.blue.color
            )
            
            PrivacySection(
                icon: "bell.badge",
                title: "Notification Permissions",
                content: "We only request notification permissions to send you helpful reminders about your time blocks. You can disable these at any time in Settings.",
                color: themeManager?.currentTheme.colorScheme.blue.color ?? Theme.defaultTheme.colorScheme.blue.color
            )
            
            PrivacySection(
                icon: "lock.shield",
                title: "Minimal Data Collection",
                content: "When you provide your email, we store it securely and only use it for the purposes you agreed to. Your routine data remains private and local to your device.",
                color: themeManager?.currentTheme.colorScheme.purple.color ?? Theme.defaultTheme.colorScheme.purple.color
            )
            
            PrivacySection(
                icon: "externaldrive",
                title: "No Third Party Sharing",
                content: "We don't share your email or any personal information with third parties for marketing purposes. Your data is used only to provide you with the services you requested.",
                color: themeManager?.currentTheme.colorScheme.teal.color ?? Theme.defaultTheme.colorScheme.teal.color
            )
            
            PrivacySection(
                icon: "trash",
                title: "Data Deletion",
                content: "You can delete your email from our records at any time through the Settings screen. When you delete the app, all local data is permanently removed.",
                color: themeManager?.currentTheme.colorScheme.warning.color ?? Theme.defaultTheme.colorScheme.warning.color
            )
        }
    }
    
    // MARK: - Contact Section
    private var contactSection: some View {
        ThemedCard(cornerRadius: 16) {
            VStack(spacing: 16) {
                Text("Questions About Privacy?")
                    .font(TypographyConstants.Headers.cardTitle)
                    .foregroundStyle(themeManager?.currentTheme.textPrimaryColor ?? Theme.defaultTheme.textPrimaryColor)
                
                Text("If you have any questions about this privacy policy or how we handle your data, please contact us.")
                    .font(TypographyConstants.Body.secondary)
                    .foregroundStyle(themeManager?.currentTheme.textSecondaryColor ?? Theme.defaultTheme.textSecondaryColor)
                    .multilineTextAlignment(.center)
                
                ThemedButton(
                    title: "Contact Support",
                    style: .primary,
                    action: contactSupport
                )
                .padding(.horizontal, 20)
            }
        }
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
    @Environment(\.themeManager) private var themeManager
    
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
                    .foregroundStyle(themeManager?.currentTheme.textPrimaryColor ?? Theme.defaultTheme.textPrimaryColor)
                
                Text(content)
                    .font(TypographyConstants.Body.secondary)
                    .foregroundStyle(themeManager?.currentTheme.textSecondaryColor ?? Theme.defaultTheme.textSecondaryColor)
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
                                    (themeManager?.currentTheme.colorScheme.surfacePrimary.color ?? Theme.defaultTheme.colorScheme.surfacePrimary.color).opacity(0.8),
                                    (themeManager?.currentTheme.colorScheme.surfaceSecondary.color ?? Theme.defaultTheme.colorScheme.surfaceSecondary.color).opacity(0.04)
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
