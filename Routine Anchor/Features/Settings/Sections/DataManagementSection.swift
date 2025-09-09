//
//  DataManagementSection.swift
//  Routine Anchor
//
//  Data & privacy actions.
//

import SwiftUI

struct DataManagementSection: View {
    @Environment(\.themeManager) private var themeManager

    let onExportData: () -> Void
    let onImportData: () -> Void
    let onShowPrivacyPolicy: () -> Void
    let onClearTodaysSchedule: () -> Void
    let onDeleteAllData: () -> Void

    /// If false, taps call actions immediately without confirmations.
    var showsConfirmations: Bool = true

    // Theme
    private var theme: AppTheme { themeManager?.currentTheme ?? PredefinedThemes.classic }

    // State
    @State private var showingClearTodayConfirmation = false
    @State private var showingDeleteConfirmation = false
    @State private var deleteButtonScale: CGFloat = 1.0
    @State private var clearTodayButtonScale: CGFloat = 1.0

    var body: some View {
        SettingsSection(
            title: "Data & Privacy",
            icon: "shield.checkered",
            color: theme.accentSecondaryColor
        ) {
            VStack(spacing: 16) {
                // Export
                SettingsButton(
                    title: "Export My Data",
                    subtitle: "Download your routine data",
                    icon: "square.and.arrow.up",
                    // old: workflowPrimary → new: accentPrimary
                    color: theme.accentPrimaryColor,
                    action: {
                        HapticManager.shared.lightImpact()
                        onExportData()
                    }
                )

                // Import
                SettingsButton(
                    title: "Import Data",
                    subtitle: "Restore from backup file",
                    icon: "square.and.arrow.down",
                    color: theme.statusSuccessColor,
                    action: {
                        HapticManager.shared.lightImpact()
                        onImportData()
                    }
                )

                // Privacy policy
                SettingsButton(
                    title: "Privacy Policy",
                    subtitle: "How we protect your data",
                    icon: "hand.raised",
                    color: theme.statusInfoColor,
                    action: {
                        HapticManager.shared.lightImpact()
                        onShowPrivacyPolicy()
                    }
                )

                // Data storage info
                dataStorageInfo

                // Divider
                Rectangle()
                    .fill(theme.borderColor.opacity(0.5))
                    .frame(height: 1)
                    .padding(.vertical, 4)

                // Clear today's schedule
                SettingsButton(
                    title: "Clear Today's Schedule",
                    subtitle: "Delete all time blocks for today",
                    icon: "calendar.badge.minus",
                    color: theme.statusWarningColor,
                    action: {
                        HapticManager.shared.warning()
                        if showsConfirmations {
                            showingClearTodayConfirmation = true
                        } else {
                            onClearTodaysSchedule()
                        }
                    }
                )
                .accessibilityIdentifier("ClearTodaysScheduleButton")
                .scaleEffect(clearTodayButtonScale)

                // Delete all data
                SettingsButton(
                    title: "Delete All Data",
                    subtitle: "Permanently remove everything",
                    icon: "trash",
                    color: theme.statusErrorColor,
                    action: {
                        HapticManager.shared.warning()
                        if showsConfirmations {
                            showingDeleteConfirmation = true
                        } else {
                            onDeleteAllData()
                        }
                    }
                )
                .accessibilityIdentifier("DeleteAllDataButton")
                .scaleEffect(deleteButtonScale)
            }
        }
        .confirmationDialog(
            "Clear Today's Schedule",
            isPresented: $showingClearTodayConfirmation,
            titleVisibility: .visible
        ) {
            Button("Clear Schedule", role: .destructive) {
                HapticManager.shared.anchorError()
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    clearTodayButtonScale = 0.95
                }
                onClearTodaysSchedule()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    clearTodayButtonScale = 1.0
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete all time blocks for today. This will give you a completely fresh start for the day. This action cannot be undone.")
        }
        .confirmationDialog(
            "Delete All Data",
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete All Data", role: .destructive) {
                HapticManager.shared.anchorError()
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    deleteButtonScale = 0.95
                }
                onDeleteAllData()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    deleteButtonScale = 1.0
                }
            }
            .accessibilityIdentifier("ConfirmDeleteAllData")

            Button("Cancel", role: .cancel) {}
        }
    }

    // MARK: - Data Storage Info

    private var dataStorageInfo: some View {
        let accent = theme.accentPrimaryColor

        return HStack(spacing: 12) {
            Image(systemName: "internaldrive")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(accent.opacity(0.8))

            VStack(alignment: .leading, spacing: 4) {
                Text("Local Storage Only")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(theme.primaryTextColor)

                Text("All data is stored securely on your device")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundStyle(theme.secondaryTextColor)
            }

            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(accent.opacity(0.10))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(accent.opacity(0.20), lineWidth: 1)
        )
    }
}

#Preview {
    ZStack {
        PredefinedThemes.classic.heroBackground.ignoresSafeArea()
        ScrollView {
            DataManagementSection(
                onExportData: { print("Export data") },
                onImportData: { print("Import data") },
                onShowPrivacyPolicy: { print("Show privacy policy") },
                onClearTodaysSchedule: { print("Clear today's schedule") },
                onDeleteAllData: { print("Delete all data") },
                showsConfirmations: true
            )
            .padding()
        }
    }
    .environment(\.themeManager, ThemeManager.preview())
    .preferredColorScheme(.dark)
}
