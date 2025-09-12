//
//  AppPreferencesSection.swift
//  Routine Anchor
//
//  App preferences section for Settings view
//

import SwiftUI

struct AppPreferencesSection: View {
    @Environment(\.themeManager) private var themeManager

    @Binding var hapticsEnabled: Bool
    @Binding var autoResetEnabled: Bool
    let onResetProgress: () -> Void

    // MARK: - Theme helpers
    private var theme: Theme { themeManager?.currentTheme ?? Theme.defaultTheme }
    private var scheme: ThemeColorScheme { theme.colorScheme }

    // MARK: - Local state
    @State private var showingResetConfirmation = false
    @State private var animateReset = false

    var body: some View {
        SettingsSection(
            title: "Preferences",
            icon: "slider.horizontal.3",
            color: scheme.success.color
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
                    .fill(scheme.secondaryUIElement.color.opacity(0.3))
                    .frame(height: 1)
                    .padding(.vertical, 4)

                // Reset today's progress (not destructive like delete; keep primary accent)
                SettingsButton(
                    title: "Reset Today's Progress",
                    subtitle: "Set all of today's blocks back to Not Started",
                    icon: "arrow.uturn.backward",
                    color: scheme.normal.color,
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
                    .foregroundStyle(scheme.success.color.opacity(0.85))
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
                    .foregroundStyle(scheme.primaryAccent.color.opacity(0.85))
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
                .fill(scheme.secondaryBackground.color.opacity(0.9))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(scheme.border.color.opacity(0.85), lineWidth: 1)
        )
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        ThemedAnimatedBackground().ignoresSafeArea()
        ScrollView {
            AppPreferencesSection(
                hapticsEnabled: .constant(true),
                autoResetEnabled: .constant(true),
                onResetProgress: { print("Reset progress") }
            )
            .padding()
        }
    }
}
