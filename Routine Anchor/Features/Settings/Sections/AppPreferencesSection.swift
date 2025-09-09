//
//  AppPreferencesSection.swift
//  Routine Anchor
//
//  Preferences section used inside Settings.
//

import SwiftUI

struct AppPreferencesSection: View {
    @Environment(\.themeManager) private var themeManager

    @Binding var hapticsEnabled: Bool
    @Binding var autoResetEnabled: Bool
    let onResetProgress: () -> Void

    // Theme (fallback to Classic)
    private var theme: AppTheme { themeManager?.currentTheme ?? PredefinedThemes.classic }

    // Local state
    @State private var showingResetConfirmation = false
    @State private var animateReset = false

    var body: some View {
        SettingsSection(
            title: "Preferences",
            icon: "slider.horizontal.3",
            color: theme.statusSuccessColor
        ) {
            VStack(spacing: 16) {

                // Haptics toggle
                SettingsToggle(
                    title: "Haptic Feedback",
                    subtitle: "Feel interactions and confirmations",
                    isOn: $hapticsEnabled,
                    icon: "hand.tap"
                )
                .onChange(of: hapticsEnabled) { _, newValue in
                    if newValue { HapticManager.shared.lightImpact() }
                }

                // Auto-reset toggle
                SettingsToggle(
                    title: "Auto-Reset Daily",
                    subtitle: "Reset progress at midnight",
                    isOn: $autoResetEnabled,
                    icon: "arrow.clockwise"
                )

                // Divider
                Rectangle()
                    .fill(theme.borderColor.opacity(0.3))
                    .frame(height: 1)
                    .padding(.vertical, 4)

                // Reset today's progress
                SettingsButton(
                    title: "Reset Today's Progress",
                    subtitle: "Set all of today's blocks back to Not Started",
                    icon: "arrow.uturn.backward",
                    color: theme.accentPrimaryColor,
                    action: {
                        HapticManager.shared.lightImpact()
                        showingResetConfirmation = true
                    }
                )
                .scaleEffect(animateReset ? 0.98 : 1.0)
                .animation(.spring(response: 0.35, dampingFraction: 0.75), value: animateReset)

                // Info card
                preferencesInfoSection
            }
        }
        .confirmationDialog(
            "Reset Today's Progress",
            isPresented: $showingResetConfirmation,
            titleVisibility: .visible
        ) {
            Button("Reset Progress", role: .destructive) {
                withAnimation { animateReset = true }
                onResetProgress()
                // quick pulse, then return to normal
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation { animateReset = false }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will reset all time blocks back to 'Not Started' for today. This action cannot be undone.")
        }
    }

    // MARK: - Info

    private var preferencesInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {

            // Haptics info
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "hand.tap")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(theme.statusSuccessColor.opacity(0.85))
                    .frame(width: 16, height: 16)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Haptic Feedback")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(theme.primaryTextColor)

                    Text("Provides tactile feedback for buttons and actions")
                        .font(.system(size: 10))
                        .foregroundStyle(theme.secondaryTextColor)
                }

                Spacer()
            }

            // Auto-reset info
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "moon.stars")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(theme.accentSecondaryColor.opacity(0.85))
                    .frame(width: 16, height: 16)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Midnight Reset")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(theme.primaryTextColor)

                    Text("Automatically clears progress at 12:00 AM daily")
                        .font(.system(size: 10))
                        .foregroundStyle(theme.secondaryTextColor)
                }

                Spacer()
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(theme.surfaceCardColor.opacity(0.9))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(theme.borderColor.opacity(0.85), lineWidth: 1)
        )
    }
}

#Preview {
    ZStack {
        PredefinedThemes.classic.heroBackground.ignoresSafeArea()
        ScrollView {
            AppPreferencesSection(
                hapticsEnabled: .constant(true),
                autoResetEnabled: .constant(true),
                onResetProgress: { print("Reset progress") }
            )
            .padding()
        }
    }
    .environment(\.themeManager, ThemeManager.preview())
    .preferredColorScheme(.dark)
}
