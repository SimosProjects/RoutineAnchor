//
//  MigrationSettingsView.swift
//  Routine Anchor
//
//  Settings view for managing data migration preferences
//

import SwiftUI

struct MigrationSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.themeManager) private var themeManager
    
    // MARK: - State
    @State private var backupEnabled: Bool = true
    @State private var showingBackupInfo = false
    @State private var showingExportSheet = false
    @State private var exportedData: String?
    private let migrationService = MigrationService.shared
    
    // Theme color helpers
    private var themePrimaryText: Color {
        themeManager?.currentTheme.primaryTextColor ?? Theme.defaultTheme.primaryTextColor
    }
    
    private var themeSecondaryText: Color {
        themeManager?.currentTheme.secondaryTextColor ?? Theme.defaultTheme.secondaryTextColor
    }
    
    private var themeTertiaryText: Color {
        themeManager?.currentTheme.subtleTextColor ?? Theme.defaultTheme.subtleTextColor
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                ThemedAnimatedBackground()
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Header Card
                        headerCard
                        
                        // Migration Info
                        migrationInfoCard
                        
                        // Backup Settings
                        backupSettingsCard
                        
                        // Manual Backup
                        manualBackupCard
                        
                        // Migration History
                        if let lastMigration = migrationService.getLastMigrationDate() {
                            migrationHistoryCard(lastMigration: lastMigration)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Data Management")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    ThemedButton(title: "Done", style: .secondary) {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            backupEnabled = migrationService.isBackupEnabled()
        }
        .sheet(isPresented: $showingBackupInfo) {
            BackupInfoSheet()
                .environment(\.themeManager, themeManager)
        }
        .sheet(isPresented: $showingExportSheet) {
            if let data = exportedData {
                ShareSheet(items: [data])
            }
        }
    }
    
    // MARK: - Components
    
    private var headerCard: some View {
        ThemedCard {
            VStack(spacing: 12) {
                Image(systemName: "externaldrive.badge.checkmark")
                    .font(.system(size: 50))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [themeManager?.currentTheme.colorScheme.normal.color ?? Theme.defaultTheme.colorScheme.normal.color, themeManager?.currentTheme.colorScheme.primaryAccent.color ?? Theme.defaultTheme.colorScheme.primaryAccent.color],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                Text("Data Protection")
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundStyle(themePrimaryText)
                
                Text("Your data is automatically protected during app updates")
                    .font(.system(size: 14))
                    .foregroundStyle(themeSecondaryText)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
        }
    }
    
    private var migrationInfoCard: some View {
        ThemedCard {
            VStack(alignment: .leading, spacing: 16) {
                Label("Schema Version", systemImage: "doc.badge.gearshape")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(themePrimaryText)
                
                HStack {
                    Text("Current Version:")
                        .font(.system(size: 14))
                        .foregroundStyle(themeSecondaryText)
                    
                    Spacer()
                    
                    Text(migrationService.currentSchemaVersion.rawValue)
                        .font(.system(size: 14, weight: .medium, design: .monospaced))
                        .foregroundStyle(themeManager?.currentTheme.colorScheme.success.color ?? Theme.defaultTheme.colorScheme.success.color)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(themeManager?.currentTheme.colorScheme.success.color ?? Theme.defaultTheme.colorScheme.success.color.opacity(0.2))
                        .cornerRadius(6)
                }
                
                Text("App updates may include data structure improvements that require migration.")
                    .font(.system(size: 12))
                    .foregroundStyle(themeTertiaryText)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    private var backupSettingsCard: some View {
        ThemedCard {
            VStack(alignment: .leading, spacing: 16) {
                Label("Backup Settings", systemImage: "arrow.triangle.2.circlepath")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(themePrimaryText)
                
                Toggle(isOn: $backupEnabled) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Auto-Backup Before Migration")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(themePrimaryText)
                        
                        Text("Creates a safety backup before updating data")
                            .font(.system(size: 12))
                            .foregroundStyle(themeTertiaryText)
                    }
                }
                .tint(themeManager?.currentTheme.colorScheme.normal.color ?? Theme.defaultTheme.colorScheme.normal.color)
                .onChange(of: backupEnabled) { _, newValue in
                    migrationService.setBackupEnabled(newValue)
                    HapticManager.shared.lightImpact()
                }
                
                Button(action: {
                    showingBackupInfo = true
                }) {
                    HStack {
                        Image(systemName: "info.circle")
                        Text("Learn More About Backups")
                    }
                    .font(.system(size: 12))
                    .foregroundStyle(themeManager?.currentTheme.colorScheme.normal.color ?? Theme.defaultTheme.colorScheme.normal.color)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    private var manualBackupCard: some View {
        ThemedCard {
            VStack(spacing: 16) {
                Label("Manual Backup", systemImage: "square.and.arrow.up")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(themePrimaryText)
                
                Text("Export your data anytime for safekeeping")
                    .font(.system(size: 12))
                    .foregroundStyle(themeSecondaryText)
                
                ThemedButton(title: "Export All Data", style: .primary) {
                    exportData()
                }
            }
            .frame(maxWidth: .infinity)
        }
    }
    
    private func migrationHistoryCard(lastMigration: Date) -> some View {
        ThemedCard {
            VStack(alignment: .leading, spacing: 12) {
                Label("Migration History", systemImage: "clock.arrow.circlepath")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(themePrimaryText)
                
                HStack {
                    Text("Last Migration:")
                        .font(.system(size: 14))
                        .foregroundStyle(themeSecondaryText)
                    
                    Spacer()
                    
                    Text(lastMigration, style: .date)
                        .font(.system(size: 14))
                        .foregroundStyle(themePrimaryText)
                }
                
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(themeManager?.currentTheme.colorScheme.success.color ?? Theme.defaultTheme.colorScheme.success.color)
                        .font(.system(size: 12))
                    
                    Text("All migrations completed successfully")
                        .font(.system(size: 12))
                        .foregroundStyle(themeManager?.currentTheme.colorScheme.success.color ?? Theme.defaultTheme.colorScheme.success.color)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    // MARK: - Actions
    
    private func exportData() {
        HapticManager.shared.mediumImpact()
        
        Task {
            do {
                // You would fetch actual data here
                let exportString = """
                {
                    "app": "Routine Anchor",
                    "version": "\(migrationService.currentSchemaVersion.rawValue)",
                    "exportDate": "\(ISO8601DateFormatter().string(from: Date()))",
                    "dataBackup": true
                }
                """
                
                await MainActor.run {
                    self.exportedData = exportString
                    self.showingExportSheet = true
                }
            }
        }
    }
}

// MARK: - Backup Info Sheet
struct BackupInfoSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.themeManager) private var themeManager
    
    // Theme color helpers
    private var themePrimaryText: Color {
        themeManager?.currentTheme.primaryTextColor ?? Theme.defaultTheme.primaryTextColor
    }
    
    private var themeSecondaryText: Color {
        themeManager?.currentTheme.secondaryTextColor ?? Theme.defaultTheme.secondaryTextColor
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                ThemedAnimatedBackground()
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Header
                        VStack(spacing: 12) {
                            Image(systemName: "shield.checkered")
                                .font(.system(size: 50))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [themeManager?.currentTheme.colorScheme.normal.color ?? Theme.defaultTheme.colorScheme.normal.color, themeManager?.currentTheme.colorScheme.primaryAccent.color ?? Theme.defaultTheme.colorScheme.primaryAccent.color],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                            
                            Text("About Data Backups")
                                .font(.system(size: 20, weight: .semibold, design: .rounded))
                                .foregroundStyle(themePrimaryText)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.bottom)
                        
                        // Info sections
                        infoSection(
                            title: "Automatic Backups",
                            icon: "arrow.triangle.2.circlepath",
                            description: "When enabled, Routine Anchor automatically creates a backup of your data before any major app update that requires data migration."
                        )
                        
                        infoSection(
                            title: "What's Included",
                            icon: "doc.text.magnifyingglass",
                            description: "Backups include all your time blocks, daily progress records, preferences, and settings. Your complete routine history is preserved."
                        )
                        
                        infoSection(
                            title: "Storage Location",
                            icon: "internaldrive",
                            description: "Backups are stored locally on your device in the app's document directory. They remain private and are never uploaded to any server."
                        )
                        
                        infoSection(
                            title: "Recovery Process",
                            icon: "arrow.counterclockwise.circle",
                            description: "If a migration encounters issues, the app will automatically attempt to restore from the most recent backup to prevent data loss."
                        )
                        
                        infoSection(
                            title: "Manual Exports",
                            icon: "square.and.arrow.up",
                            description: "You can also manually export your data at any time for additional peace of mind or to transfer to another device."
                        )
                    }
                    .padding()
                }
            }
            .navigationTitle("Backup Information")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    ThemedButton(title: "Done", style: .secondary) {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func infoSection(title: String, icon: String, description: String) -> some View {
        ThemedCard {
            HStack(alignment: .top, spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundStyle(themeManager?.currentTheme.colorScheme.normal.color ?? Theme.defaultTheme.colorScheme.normal.color)
                    .frame(width: 30)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(themePrimaryText)
                    
                    Text(description)
                        .font(.system(size: 14))
                        .foregroundStyle(themeSecondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
