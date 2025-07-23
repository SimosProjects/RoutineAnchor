//
//  NotificationSettingsSection.swift
//  Routine Anchor
//
//  Notification settings section for Settings view
//
import SwiftUI

struct NotificationSettingsSection: View {
    @Binding var notificationsEnabled: Bool
    @Binding var dailyReminderTime: Date
    @Binding var notificationSound: String
    
    // MARK: - State
    @State private var showingTimePicker = false
    @State private var animateToggle = false
    
    var body: some View {
        SettingsSection(
            title: "Notifications",
            icon: "bell",
            color: Color.premiumBlue
        ) {
            VStack(spacing: 16) {
                // Master notification toggle
                SettingsToggle(
                    title: "Enable Notifications",
                    subtitle: "Get reminders for your time blocks",
                    isOn: $notificationsEnabled,
                    icon: "bell.badge"
                )
                .onChange(of: notificationsEnabled) { _, newValue in
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                        animateToggle = newValue
                    }
                }
                
                // Notification settings (shown when enabled)
                if notificationsEnabled {
                    VStack(spacing: 12) {
                        // Daily reminder time
                        SettingsDatePicker(
                            title: "Daily Reminder",
                            subtitle: "Daily check-in notification",
                            selection: $dailyReminderTime,
                            icon: "clock"
                        )
                        .transition(.opacity.combined(with: .move(edge: .top)))
                        
                        // Notification sound
                        SettingsPicker(
                            title: "Notification Sound",
                            subtitle: notificationSound,
                            icon: "speaker.2",
                            options: NotificationSound.allCases.map { $0.rawValue },
                            selection: $notificationSound
                        )
                        .transition(.opacity.combined(with: .move(edge: .top)))
                        
                        // Additional settings
                        notificationInfoSection
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: notificationsEnabled)
                }
            }
        }
    }
    
    // MARK: - Info Section
    private var notificationInfoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "info.circle")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.premiumBlue.opacity(0.8))
                
                Text("Notification Timing")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.premiumTextPrimary)
            }
            
            Text("Time blocks notify 2 minutes before they start. Daily reminders help you review progress and plan ahead.")
                .font(.system(size: 12, weight: .regular))
                .foregroundStyle(Color.premiumTextSecondary)
                .lineSpacing(2)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.premiumBlue.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.premiumBlue.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        AnimatedGradientBackground()
            .ignoresSafeArea()
        
        ScrollView {
            NotificationSettingsSection(
                notificationsEnabled: .constant(true),
                dailyReminderTime: .constant(Date()),
                notificationSound: .constant("Default")
            )
            .padding()
        }
    }
}
