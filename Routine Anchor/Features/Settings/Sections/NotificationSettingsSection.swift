//
//  NotificationSettingsSection.swift
//  Routine Anchor
//
//  Notification settings.
//

import SwiftUI

struct NotificationSettingsSection: View {
    @Environment(\.themeManager) private var themeManager

    @Binding var notificationsEnabled: Bool
    @Binding var dailyReminderTime: Date
    @Binding var notificationSound: String

    private var theme: AppTheme { themeManager?.currentTheme ?? PredefinedThemes.classic }

    @State private var togglePulse = false

    var body: some View {
        SettingsSection(
            title: "Notifications",
            icon: "bell",
            color: theme.accentPrimaryColor
        ) {
            VStack(spacing: 16) {

                // Master toggle
                SettingsToggle(
                    title: "Enable Notifications",
                    subtitle: "Get reminders for your time blocks",
                    isOn: $notificationsEnabled,
                    icon: "bell.badge"
                )
                .scaleEffect(togglePulse ? 1.02 : 1.0)
                .animation(.spring(response: 0.35, dampingFraction: 0.85), value: togglePulse)
                .onChange(of: notificationsEnabled) { _, _ in
                    withAnimation { togglePulse = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
                        withAnimation { togglePulse = false }
                    }
                }

                // Detail rows when enabled
                if notificationsEnabled {
                    VStack(spacing: 12) {
                        SettingsDatePicker(
                            title: "Daily Reminder",
                            subtitle: "Daily check-in notification",
                            selection: $dailyReminderTime,
                            icon: "clock"
                        )
                        .transition(.opacity.combined(with: .move(edge: .top)))

                        SettingsPicker(
                            title: "Notification Sound",
                            subtitle: notificationSound,
                            icon: "speaker.2",
                            options: NotificationSound.allCases.map { $0.rawValue },
                            selection: $notificationSound
                        )
                        .transition(.opacity.combined(with: .move(edge: .top)))

                        notificationInfoSection
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                    .animation(.spring(response: 0.45, dampingFraction: 0.85), value: notificationsEnabled)
                }
            }
        }
    }

    // MARK: - Info card

    private var notificationInfoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "info.circle")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(theme.accentPrimaryColor)

                Text("Notification Timing")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(theme.primaryTextColor)
            }

            Text("Time blocks notify 2 minutes before they start. Daily reminders help you review progress and plan ahead.")
                .font(.system(size: 12))
                .foregroundStyle(theme.secondaryTextColor)
                .lineSpacing(2)
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
            NotificationSettingsSection(
                notificationsEnabled: .constant(true),
                dailyReminderTime: .constant(Date()),
                notificationSound: .constant("Default")
            )
            .padding()
        }
    }
    .environment(\.themeManager, ThemeManager.preview())
    .preferredColorScheme(.dark)
}
