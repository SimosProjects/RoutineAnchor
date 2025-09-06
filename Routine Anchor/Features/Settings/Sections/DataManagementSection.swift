//
//  DataManagementSection.swift
//  Routine Anchor
//

import SwiftUI

struct DataManagementSection: View {
    @Environment(\.themeManager) private var themeManager
    
    let onExportData: () -> Void
    let onImportData: () -> Void
    let onShowPrivacyPolicy: () -> Void
    let onClearTodaysSchedule: () -> Void
    let onDeleteAllData: () -> Void
    
    /// If false, taps will call actions immediately without showing confirmations.
    var showsConfirmations: Bool = true
    
    // MARK: - State
    @State private var showingClearTodayConfirmation = false
    @State private var showingDeleteConfirmation = false
    @State private var deleteButtonScale: CGFloat = 1.0
    @State private var clearTodayButtonScale: CGFloat = 1.0
    
    var body: some View {
        SettingsSection(
            title: "Data & Privacy",
            icon: "shield.checkered",
            color: themeManager?.currentTheme.colorScheme.organizationAccent.color
                ?? Theme.defaultTheme.colorScheme.organizationAccent.color
        ) {
            VStack(spacing: 16) {
                // Export data button
                SettingsButton(
                    title: "Export My Data",
                    subtitle: "Download your routine data",
                    icon: "square.and.arrow.up",
                    color: themeManager?.currentTheme.colorScheme.workflowPrimary.color
                        ?? Theme.defaultTheme.colorScheme.workflowPrimary.color,
                    action: {
                        HapticManager.shared.lightImpact()
                        onExportData()
                    }
                )
                
                // Import data button
                SettingsButton(
                    title: "Import Data",
                    subtitle: "Restore from backup file",
                    icon: "square.and.arrow.down",
                    color: themeManager?.currentTheme.colorScheme.actionSuccess.color
                        ?? Theme.defaultTheme.colorScheme.actionSuccess.color,
                    action: {
                        HapticManager.shared.lightImpact()
                        onImportData()
                    }
                )
                
                // Privacy policy button
                SettingsButton(
                    title: "Privacy Policy",
                    subtitle: "How we protect your data",
                    icon: "hand.raised",
                    color: themeManager?.currentTheme.colorScheme.actionSuccess.color
                        ?? Theme.defaultTheme.colorScheme.actionSuccess.color,
                    action: {
                        HapticManager.shared.lightImpact()
                        onShowPrivacyPolicy()
                    }
                )
                
                // Data storage info
                dataStorageInfo
                
                // Divider
                Rectangle()
                    .fill(
                        themeManager?.currentTheme.colorScheme.uiElementSecondary.color
                            ?? Theme.defaultTheme.colorScheme.uiElementSecondary.color
                    )
                    .frame(height: 1)
                    .padding(.vertical, 4)
                
                // Clear Today's Schedule button
                SettingsButton(
                    title: "Clear Today's Schedule",
                    subtitle: "Delete all time blocks for today",
                    icon: "calendar.badge.minus",
                    color: themeManager?.currentTheme.colorScheme.warningColor.color
                        ?? Theme.defaultTheme.colorScheme.warningColor.color,
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
                
                // Delete all data button
                SettingsButton(
                    title: "Delete All Data",
                    subtitle: "Permanently remove everything",
                    icon: "trash",
                    color: themeManager?.currentTheme.colorScheme.errorColor.color
                        ?? Theme.defaultTheme.colorScheme.errorColor.color,
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
        let wp = (themeManager?.currentTheme.colorScheme.workflowPrimary.color
                  ?? Theme.defaultTheme.colorScheme.workflowPrimary.color)
        
        return HStack(spacing: 12) {
            Image(systemName: "internaldrive")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(wp.opacity(0.8)) // fixed precedence
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Local Storage Only")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(themeManager?.currentTheme.primaryTextColor
                                     ?? Theme.defaultTheme.primaryTextColor)
                
                Text("All data is stored securely on your device")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundStyle(themeManager?.currentTheme.secondaryTextColor
                                     ?? Theme.defaultTheme.secondaryTextColor)
            }
            
            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(wp.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(wp.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        ThemedAnimatedBackground()
            .ignoresSafeArea()
        
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
}
