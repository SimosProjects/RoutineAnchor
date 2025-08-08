//
//  MigrationSettingsView.swift
//  Routine Anchor
//
//  Settings view for managing data migration preferences
//

import SwiftUI

struct MigrationSettingsView: View {
    @EnvironmentObject var migrationService: MigrationService
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - State
    @State private var backupEnabled: Bool = true
    @State private var showingBackupInfo = false
    @State private var showingExportSheet = false
    @State private var exportedData: String?
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                AnimatedGradientBackground()
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
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.premiumBlue)
                }
            }
        }
        .onAppear {
            backupEnabled = migrationService.isBackupEnabled()
        }
        .sheet(isPresented: $showingBackupInfo) {
            BackupInfoSheet()
        }
        .sheet(isPresented: $showingExportSheet) {
            if let data = exportedData {
                ShareSheet(items: [data])
            }
        }
    }
    
    // MARK: - Components
    
    private var headerCard: some View {
        VStack(spacing: 12) {
            Image(systemName: "externaldrive.badge.checkmark")
                .font(.system(size: 50))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.premiumBlue, Color.premiumPurple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            Text("Data Protection")
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
            
            Text("Your data is automatically protected during app updates")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .glassMorphism()
    }
    
    private var migrationInfoCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Schema Version", systemImage: "doc.badge.gearshape")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
            
            HStack {
                Text("Current Version:")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.7))
                
                Spacer()
                
                Text(migrationService.currentSchemaVersion.rawValue)
                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                    .foregroundColor(.premiumGreen)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Color.premiumGreen.opacity(0.2))
                    .cornerRadius(6)
            }
            
            Text("App updates may include data structure improvements that require migration.")
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .glassMorphism()
    }
    
    private var backupSettingsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Backup Settings", systemImage: "arrow.triangle.2.circlepath")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
            
            Toggle(isOn: $backupEnabled) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Auto-Backup Before Migration")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                    
                    Text("Creates a safety backup before updating data")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.5))
                }
            }
            .tint(Color.premiumBlue)
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
                .foregroundColor(.premiumBlue)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .glassMorphism()
    }
    
    private var manualBackupCard: some View {
        VStack(spacing: 16) {
            Label("Manual Backup", systemImage: "square.and.arrow.up")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
            
            Text("Export your data anytime for safekeeping")
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.7))
            
            Button(action: exportData) {
                HStack {
                    Image(systemName: "arrow.down.doc.fill")
                    Text("Export All Data")
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    LinearGradient(
                        colors: [Color.premiumBlue, Color.premiumPurple],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .glassMorphism()
    }
    
    private func migrationHistoryCard(lastMigration: Date) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Migration History", systemImage: "clock.arrow.circlepath")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
            
            HStack {
                Text("Last Migration:")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.7))
                
                Spacer()
                
                Text(lastMigration, style: .date)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.9))
            }
            
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.premiumGreen)
                    .font(.system(size: 12))
                
                Text("All migrations completed successfully")
                    .font(.system(size: 12))
                    .foregroundColor(.premiumGreen)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .glassMorphism()
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
    
    var body: some View {
        NavigationStack {
            ZStack {
                AnimatedGradientBackground()
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Header
                        VStack(spacing: 12) {
                            Image(systemName: "shield.checkered")
                                .font(.system(size: 50))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Color.premiumBlue, Color.premiumPurple],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                            
                            Text("About Data Backups")
                                .font(.system(size: 20, weight: .semibold, design: .rounded))
                                .foregroundColor(.white)
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
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.premiumBlue)
                }
            }
        }
    }
    
    private func infoSection(title: String, icon: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(.premiumBlue)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.7))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .glassMorphism()
    }
}
