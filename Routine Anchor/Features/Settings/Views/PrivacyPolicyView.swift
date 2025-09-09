//
//  PrivacyPolicyView.swift
//  Routine Anchor
//

import SwiftUI

struct PrivacyPolicyView: View {
    @Environment(\.themeManager) private var themeManager
    @Environment(\.dismiss) private var dismiss
    @State private var animationPhase = 0

    private var theme: AppTheme { themeManager?.currentTheme ?? PredefinedThemes.classic }

    var body: some View {
        ZStack {
            ThemedAnimatedBackground()
            AnimatedMeshBackground().opacity(0.3).allowsHitTesting(false)
            ParticleEffectView().allowsHitTesting(false)

            ScrollView {
                VStack(spacing: 24) {
                    headerSection
                    privacySections
                    contactSection
                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) { animationPhase = 1 }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 16) {
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(theme.primaryTextColor.opacity(0.85))
                        .frame(width: 32, height: 32)
                        .background(
                            Circle()
                                .fill(.ultraThinMaterial)
                                .background(Circle().fill(theme.color.surface.card.opacity(0.7)))
                        )
                }
                Spacer()
            }

            VStack(spacing: 12) {
                Image(systemName: "shield.checkered")
                    .font(.system(size: 48, weight: .light))
                    .foregroundStyle(
                        LinearGradient(colors: [theme.accentPrimaryColor, theme.accentSecondaryColor],
                                       startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .scaleEffect(animationPhase == 0 ? 1.0 : 1.1)
                    .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: animationPhase)

                Text("Privacy Policy")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(theme.primaryTextColor)

                Text("Your privacy is our priority")
                    .font(.system(size: 14))
                    .foregroundStyle(theme.secondaryTextColor)
                    .multilineTextAlignment(.center)
            }
        }
    }

    // MARK: - Sections

    private var privacySections: some View {
        VStack(spacing: 20) {
            PrivacySection(icon: "iphone",
                           title: "Local Storage First",
                           content: "Your routine data is stored locally on your device. We only collect email addresses when you voluntarily provide them for updates and courses.",
                           color: theme.statusSuccessColor)

            PrivacySection(icon: "envelope",
                           title: "Optional Email Collection",
                           content: "We may ask for your email to send tips, app updates, and course info. It's optional and you can unsubscribe anytime.",
                           color: theme.accentPrimaryColor)

            PrivacySection(icon: "bell.badge",
                           title: "Notification Permissions",
                           content: "We request notification permissions only to remind you about time blocks. You can disable these any time in Settings.",
                           color: theme.accentPrimaryColor)

            PrivacySection(icon: "lock.shield",
                           title: "Minimal Data Collection",
                           content: "If you provide your email, we store it securely and only for the purposes you agreed to. Your routine data remains private and local.",
                           color: theme.accentSecondaryColor)

            PrivacySection(icon: "externaldrive",
                           title: "No Third-Party Sharing",
                           content: "We don't share your email or any personal info with third parties for marketing purposes.",
                           color: theme.accentSecondaryColor.opacity(0.9))

            PrivacySection(icon: "trash",
                           title: "Data Deletion",
                           content: "Delete your email from our records via Settings. Removing the app permanently deletes all local data.",
                           color: theme.statusWarningColor)
        }
    }

    private var contactSection: some View {
        ThemedCard(cornerRadius: 16) {
            VStack(spacing: 16) {
                Text("Questions About Privacy?")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(theme.primaryTextColor)

                Text("If you have any questions about this policy or how we handle your data, please contact us.")
                    .font(.system(size: 14))
                    .foregroundStyle(theme.secondaryTextColor)
                    .multilineTextAlignment(.center)

                DesignedButton(
                    title: "Contact Support",
                    style: .gradient,
                    size: .medium,
                    fullWidth: false
                ) {
                    contactSupport()
                }
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

private struct PrivacySection: View {
    @Environment(\.themeManager) private var themeManager
    let icon: String
    let title: String
    let content: String
    let color: Color

    @State private var isVisible = false
    private var theme: AppTheme { themeManager?.currentTheme ?? PredefinedThemes.classic }

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            ZStack {
                Circle().fill(color.opacity(0.15)).frame(width: 48, height: 48)
                Image(systemName: icon).font(.system(size: 20, weight: .medium)).foregroundStyle(color)
            }
            VStack(alignment: .leading, spacing: 8) {
                Text(title).font(.system(size: 16, weight: .semibold)).foregroundStyle(theme.primaryTextColor)
                Text(content).font(.system(size: 14)).foregroundStyle(theme.secondaryTextColor).lineSpacing(2)
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
                                colors: [theme.color.surface.card.opacity(0.8), theme.color.surface.card.opacity(0.04)],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            )
                        )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(LinearGradient(colors: [color.opacity(0.3), color.opacity(0.1)],
                                       startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1)
        )
        .shadow(color: color.opacity(0.2), radius: 8, x: 0, y: 4)
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : 20)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) { isVisible = true }
        }
    }
}

#Preview { PrivacyPolicyView() }
