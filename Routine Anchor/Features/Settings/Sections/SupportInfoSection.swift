//
//  SupportInfoSection.swift
//  Routine Anchor
//
//  Support & info.
//

import SwiftUI

struct SupportInfoSection: View {
    @Environment(\.themeManager) private var themeManager

    let onShowHelp: () -> Void
    let onShowAbout: () -> Void
    let onRateApp: () -> Void
    let onContactSupport: () -> Void

    private var theme: AppTheme { themeManager?.currentTheme ?? PredefinedThemes.classic }

    // State
    @State private var animateRating = false
    @State private var showThankYou = false

    var body: some View {
        SettingsSection(
            title: "Support & Info",
            icon: "questionmark.circle",
            color: theme.accentSecondaryColor
        ) {
            VStack(spacing: 16) {
                // Help & FAQ
                SettingsButton(
                    title: "Help & FAQ",
                    subtitle: "Get answers to common questions",
                    icon: "questionmark.circle",
                    color: theme.accentPrimaryColor,
                    action: { onShowHelp() }
                )

                // About
                SettingsButton(
                    title: "About Routine Anchor",
                    subtitle: "App info and acknowledgments",
                    icon: "info.circle",
                    color: theme.accentSecondaryColor,
                    action: { onShowAbout() }
                )

                // Divider
                supportDivider

                // Rate the app
                SettingsButton(
                    title: "Rate the App",
                    subtitle: showThankYou ? "Thank you! ❤️" : "Support development",
                    icon: "star",
                    color: theme.statusWarningColor,
                    action: {
                        HapticManager.shared.anchorSuccess()
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                            animateRating = true
                            showThankYou = true
                        }
                        onRateApp()

                        // Reset pulse quickly
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            animateRating = false
                        }
                        // Fade out the thank-you after a moment
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            withAnimation { showThankYou = false }
                        }
                    }
                )
                .scaleEffect(animateRating ? 1.1 : 1.0)
                .animation(.spring(response: 0.5, dampingFraction: 0.6), value: animateRating)

                // Contact support
                SettingsButton(
                    title: "Contact Support",
                    subtitle: "Get help from our team",
                    icon: "envelope",
                    color: theme.statusSuccessColor,
                    action: { onContactSupport() }
                )

                // Quick tips
                quickTipsSection
            }
        }
    }

    // MARK: - Support Divider

    private var supportDivider: some View {
        HStack(spacing: 12) {
            Rectangle()
                .fill(theme.borderColor.opacity(0.3))
                .frame(height: 1)

            Text("SUPPORT")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(theme.secondaryTextColor)
                .tracking(1)

            Rectangle()
                .fill(theme.borderColor.opacity(0.3))
                .frame(height: 1)
        }
        .padding(.vertical, 4)
    }

    // MARK: - Quick Tips Section

    private var quickTipsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "lightbulb")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(theme.statusWarningColor)

                Text("Quick Tips")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(theme.primaryTextColor)
            }

            VStack(alignment: .leading, spacing: 8) {
                SupportingInfoQuickTip(number: "1", text: "Swipe to edit or delete time blocks")
                SupportingInfoQuickTip(number: "2", text: "Long press FAB for quick add")
                SupportingInfoQuickTip(number: "3", text: "Pull down to refresh your progress")
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(theme.accentSecondaryColor.opacity(0.10))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(theme.accentSecondaryColor.opacity(0.20), lineWidth: 1)
        )
    }
}

// MARK: - Quick Tip Row

struct SupportingInfoQuickTip: View {
    @Environment(\.themeManager) private var themeManager
    private var theme: AppTheme { themeManager?.currentTheme ?? PredefinedThemes.classic }

    let number: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text(number)
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(theme.accentSecondaryColor)
                .frame(width: 16, height: 16)
                .background(
                    Circle()
                        .fill(theme.accentSecondaryColor.opacity(0.20))
                )

            Text(text)
                .font(.system(size: 11, weight: .regular))
                .foregroundStyle(theme.secondaryTextColor)
                .lineLimit(2)

            Spacer()
        }
    }
}

#Preview {
    ZStack {
        PredefinedThemes.classic.heroBackground.ignoresSafeArea()
        ScrollView {
            SupportInfoSection(
                onShowHelp: { print("Show help") },
                onShowAbout: { print("Show about") },
                onRateApp: { print("Rate app") },
                onContactSupport: { print("Contact support") }
            )
            .padding()
        }
    }
    .environment(\.themeManager, ThemeManager.preview())
    .preferredColorScheme(.dark)
}
