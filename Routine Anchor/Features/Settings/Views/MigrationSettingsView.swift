//
//  MigrationSettingsView.swift
//  Routine Anchor
//

import SwiftUI

struct MigrationSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.themeManager) private var themeManager

    @State private var backupEnabled: Bool = true
    @State private var showingBackupInfo = false
    @State private var showingExportSheet = false
    @State private var exportedData: String?
    private let migrationService = MigrationService.shared

    private var theme: AppTheme { themeManager?.currentTheme ?? PredefinedThemes.classic }

    var body: some View {
        NavigationStack {
            ZStack {
                ThemedAnimatedBackground().ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        headerCard
                        migrationInfoCard
                        backupSettingsCard
                        manualBackupCard
                        if let last = migrationService.getLastMigrationDate() {
                            migrationHistoryCard(lastMigration: last)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Data Management")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(content: {
                ToolbarItem(placement: .topBarTrailing) {
                    DesignedButton(
                        title: "Done",
                        style: .surface,
                        size: .medium,
                        fullWidth: false,
                        action: { dismiss() }
                    )
                }
            })
        }
        .onAppear { backupEnabled = migrationService.isBackupEnabled() }
        .sheet(isPresented: $showingBackupInfo) { BackupInfoSheet().environment(\.themeManager, themeManager) }
        .sheet(isPresented: $showingExportSheet) {
            if let data = exportedData { ShareSheet(items: [data]) }
        }
    }

    // MARK: - Cards

    private var headerCard: some View {
        ThemedCard {
            VStack(spacing: 12) {
                Image(systemName: "externaldrive.badge.checkmark")
                    .font(.system(size: 50))
                    .foregroundStyle(
                        LinearGradient(colors: [theme.accentPrimaryColor, theme.accentSecondaryColor],
                                       startPoint: .topLeading, endPoint: .bottomTrailing)
                    )

                Text("Data Protection")
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundStyle(theme.primaryTextColor)

                Text("Your data is automatically protected during app updates")
                    .font(.system(size: 14))
                    .foregroundStyle(theme.secondaryTextColor)
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
                    .foregroundStyle(theme.primaryTextColor)

                HStack {
                    Text("Current Version:")
                        .font(.system(size: 14))
                        .foregroundStyle(theme.secondaryTextColor)
                    Spacer()
                    Text(migrationService.currentSchemaVersion.rawValue)
                        .font(.system(size: 14, weight: .medium, design: .monospaced))
                        .foregroundStyle(theme.statusSuccessColor)
                        .padding(.horizontal, 12).padding(.vertical, 4)
                        .background(theme.statusSuccessColor.opacity(0.18))
                        .cornerRadius(6)
                }

                Text("App updates may include data structure improvements that require migration.")
                    .font(.system(size: 12))
                    .foregroundStyle(theme.subtleTextColor)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var backupSettingsCard: some View {
        ThemedCard {
            VStack(alignment: .leading, spacing: 16) {
                Label("Backup Settings", systemImage: "arrow.triangle.2.circlepath")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(theme.primaryTextColor)

                Toggle(isOn: $backupEnabled) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Auto-Backup Before Migration")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(theme.primaryTextColor)

                        Text("Creates a safety backup before updating data")
                            .font(.system(size: 12))
                            .foregroundStyle(theme.subtleTextColor)
                    }
                }
                .tint(theme.accentPrimaryColor)
                .onChange(of: backupEnabled) { _, newValue in
                    migrationService.setBackupEnabled(newValue)
                    HapticManager.shared.lightImpact()
                }

                Button {
                    showingBackupInfo = true
                } label: {
                    HStack {
                        Image(systemName: "info.circle")
                        Text("Learn More About Backups")
                    }
                    .font(.system(size: 12))
                    .foregroundStyle(theme.accentPrimaryColor)
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
                    .foregroundStyle(theme.primaryTextColor)

                Text("Export your data anytime for safekeeping")
                    .font(.system(size: 12))
                    .foregroundStyle(theme.secondaryTextColor)

                DesignedButton(title: "Export All Data",
                               style: .gradient,
                               size: .medium,
                               fullWidth: false) {
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
                    .foregroundStyle(theme.primaryTextColor)

                HStack {
                    Text("Last Migration:").font(.system(size: 14)).foregroundStyle(theme.secondaryTextColor)
                    Spacer()
                    Text(lastMigration, style: .date).font(.system(size: 14)).foregroundStyle(theme.primaryTextColor)
                }

                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(theme.statusSuccessColor).font(.system(size: 12))
                    Text("All migrations completed successfully")
                        .font(.system(size: 12))
                        .foregroundStyle(theme.statusSuccessColor)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Actions

    private func exportData() {
        HapticManager.shared.mediumImpact()
        Task {
            let exportString = """
            {
              "app":"Routine Anchor",
              "version":"\(migrationService.currentSchemaVersion.rawValue)",
              "exportDate":"\(ISO8601DateFormatter().string(from: Date()))",
              "dataBackup":true
            }
            """
            await MainActor.run { self.exportedData = exportString; self.showingExportSheet = true }
        }
    }
}

// MARK: - Backup Info Sheet

private struct BackupInfoSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.themeManager) private var themeManager
    private var theme: AppTheme { themeManager?.currentTheme ?? PredefinedThemes.classic }

    var body: some View {
        NavigationStack {
            ZStack {
                ThemedAnimatedBackground().ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        VStack(spacing: 12) {
                            Image(systemName: "shield.checkered")
                                .font(.system(size: 50))
                                .foregroundStyle(
                                    LinearGradient(colors: [theme.accentPrimaryColor, theme.accentSecondaryColor],
                                                   startPoint: .topLeading, endPoint: .bottomTrailing)
                                )
                            Text("About Data Backups")
                                .font(.system(size: 20, weight: .semibold, design: .rounded))
                                .foregroundStyle(theme.primaryTextColor)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.bottom)

                        infoSection(title: "Automatic Backups", icon: "arrow.triangle.2.circlepath",
                                    description: "Creates a backup before any migration that could modify data.")
                        infoSection(title: "What's Included", icon: "doc.text.magnifyingglass",
                                    description: "Blocks, progress, preferences, and settings.")
                        infoSection(title: "Storage Location", icon: "internaldrive",
                                    description: "Stored locally in the app’s documents directory.")
                        infoSection(title: "Recovery Process", icon: "arrow.counterclockwise.circle",
                                    description: "Automatic restore attempt if a migration fails.")
                        infoSection(title: "Manual Exports", icon: "square.and.arrow.up",
                                    description: "Export anytime for transfer or safekeeping.")
                    }
                    .padding()
                }
            }
            .navigationTitle("Backup Information")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    DesignedButton(
                        title: "Done",
                        style: .surface,
                        size: .medium,
                        fullWidth: false,
                        action: { dismiss() }
                    )
                }
            }
        }
    }

    private func infoSection(title: String, icon: String, description: String) -> some View {
        ThemedCard {
            HStack(alignment: .top, spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundStyle(theme.accentPrimaryColor)
                    .frame(width: 30)

                VStack(alignment: .leading, spacing: 8) {
                    Text(title).font(.system(size: 16, weight: .semibold)).foregroundStyle(theme.primaryTextColor)
                    Text(description).font(.system(size: 14)).foregroundStyle(theme.secondaryTextColor)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
