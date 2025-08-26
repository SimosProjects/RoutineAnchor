//
//  ExportDataView.swift
//  Routine Anchor
//
//  Export data view for Settings
//
import SwiftUI
import SwiftData

struct ExportDataView: View {
    @Environment(\.themeManager) private var themeManager
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var timeBlocks: [TimeBlock]
    @Query private var dailyProgress: [DailyProgress]
    
    @State private var selectedFormat: ExportService.ExportFormat = .json
    @State private var includeProgress = true
    @State private var includeSettings = true
    @State private var isExporting = false
    @State private var showingShareSheet = false
    @State private var exportedFileURL: URL?
    @State private var errorMessage: String?
    
    private let exportService = ExportService.shared
    
    var body: some View {
        NavigationStack {
            ZStack {
                ThemedAnimatedBackground()
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 32) {
                        // Header
                        headerSection
                        
                        // Format selection
                        formatSection
                        
                        // Options
                        optionsSection
                        
                        // Export button
                        exportButton
                        
                        // Info section
                        infoSection
                    }
                    .padding(24)
                }
            }
            .navigationBarHidden(true)
            .alert("Export Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") {
                    errorMessage = nil
                }
            } message: {
                Text(errorMessage ?? "")
            }
            .sheet(isPresented: $showingShareSheet) {
                if let url = exportedFileURL {
                    ShareSheet(items: [url])
                }
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 16) {
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.7))
                        .frame(width: 30, height: 30)
                        .background(Color.white.opacity(0.1))
                        .clipShape(Circle())
                }
                
                Spacer()
            }
            
            VStack(spacing: 12) {
                Image(systemName: "square.and.arrow.up.circle.fill")
                    .font(.system(size: 56, weight: .light))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.anchorBlue, Color.anchorPurple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                Text("Export Your Data")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(themeManager?.currentTheme.textPrimaryColor ?? Theme.defaultTheme.textPrimaryColor)
                
                Text("Download your routines and progress")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.7))
            }
        }
    }
    
    // MARK: - Format Section
    private var formatSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Export Format")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(themeManager?.currentTheme.textPrimaryColor ?? Theme.defaultTheme.textPrimaryColor)
            
            VStack(spacing: 12) {
                ForEach(ExportService.ExportFormat.allCases, id: \.self) { format in
                    formatOption(format)
                }
            }
        }
    }
    
    private func formatOption(_ format: ExportService.ExportFormat) -> some View {
        Button(action: { selectedFormat = format }) {
            HStack(spacing: 16) {
                Image(systemName: iconForFormat(format))
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(selectedFormat == format ? Color.anchorBlue : Color.white.opacity(0.6))
                    .frame(width: 24, height: 24)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(format.rawValue)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(selectedFormat == format ? .white : Color.white.opacity(0.8))
                    
                    Text(descriptionForFormat(format))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.6))
                }
                
                Spacer()
                
                if selectedFormat == format {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(Color.anchorBlue)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(selectedFormat == format ? Color.white.opacity(0.15) : Color.white.opacity(0.08))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(selectedFormat == format ? Color.anchorBlue.opacity(0.5) : Color.clear, lineWidth: 2)
            )
        }
    }
    
    // MARK: - Options Section
    private var optionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Include in Export")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(themeManager?.currentTheme.textPrimaryColor ?? Theme.defaultTheme.textPrimaryColor)
            
            VStack(spacing: 12) {
                ToggleOption(
                    title: "Daily Progress",
                    subtitle: "Include completion rates and reflections",
                    isOn: $includeProgress,
                    icon: "chart.line.uptrend.xyaxis"
                )
                
                ToggleOption(
                    title: "App Settings",
                    subtitle: "Include notification and preference settings",
                    isOn: $includeSettings,
                    icon: "gearshape"
                )
            }
        }
    }
    
    // MARK: - Export Button
    private var exportButton: some View {
        Button(action: performExport) {
            HStack(spacing: 12) {
                if isExporting {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 18, weight: .semibold))
                }
                
                Text(isExporting ? "Exporting..." : "Export Data")
                    .font(.system(size: 18, weight: .semibold))
            }
            .foregroundStyle(themeManager?.currentTheme.textPrimaryColor ?? Theme.defaultTheme.textPrimaryColor)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                LinearGradient(
                    colors: [Color.anchorBlue, Color.anchorPurple],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(16)
            .shadow(color: Color.anchorBlue.opacity(0.3), radius: 12, x: 0, y: 6)
        }
        .disabled(isExporting)
    }
    
    // MARK: - Info Section
    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "info.circle")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.anchorBlue.opacity(0.8))
                
                Text("About Your Data")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(themeManager?.currentTheme.textPrimaryColor ?? Theme.defaultTheme.textPrimaryColor)
            }
            
            Text("Your exported data includes all time blocks\(includeProgress ? ", daily progress records" : "")\(includeSettings ? ", and app settings" : ""). The file will be saved to your device and can be shared or stored as a backup.")
                .font(.system(size: 12, weight: .regular))
                .foregroundStyle(themeManager?.currentTheme.textSecondaryColor ?? Theme.defaultTheme.textSecondaryColor)
                .lineSpacing(2)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.anchorBlue.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.anchorBlue.opacity(0.2), lineWidth: 1)
        )
    }
    
    // MARK: - Helper Methods
    
    private func iconForFormat(_ format: ExportService.ExportFormat) -> String {
        switch format {
        case .json:
            return "doc.text"
        case .csv:
            return "tablecells"
        case .text:
            return "doc.plaintext"
        }
    }
    
    private func descriptionForFormat(_ format: ExportService.ExportFormat) -> String {
        switch format {
        case .json:
            return "Structured data for developers"
        case .csv:
            return "Spreadsheet compatible format"
        case .text:
            return "Human-readable plain text"
        }
    }
    
    private func fileExtensionForFormat(_ format: ExportService.ExportFormat) -> String {
        switch format {
        case .json:
            return "json"
        case .csv:
            return "csv"
        case .text:
            return "txt"
        }
    }
    
    private func performExport() {
        isExporting = true
        HapticManager.shared.lightImpact()
        
        Task { @MainActor in
            do {
                let exportData: Data
                
                if includeProgress && includeSettings {
                    // Export everything
                    exportData = try exportService.exportAllData(
                        timeBlocks: timeBlocks,
                        dailyProgress: dailyProgress,
                        format: selectedFormat
                    )
                } else if includeProgress {
                    // Export time blocks and progress only
                    exportData = try exportService.exportAllData(
                        timeBlocks: timeBlocks,
                        dailyProgress: dailyProgress,
                        format: selectedFormat
                    )
                } else {
                    // Export time blocks only
                    exportData = try exportService.exportTimeBlocks(
                        timeBlocks,
                        format: selectedFormat
                    )
                }
                
                // Create file
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd-HHmmss"
                let fileName = "routine-anchor-export-\(dateFormatter.string(from: Date())).\(fileExtensionForFormat(selectedFormat))"
                let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
                
                try exportData.write(to: tempURL)
                
                self.exportedFileURL = tempURL
                self.isExporting = false
                self.showingShareSheet = true
                HapticManager.shared.anchorSuccess()
                
            } catch {
                self.errorMessage = error.localizedDescription
                self.isExporting = false
                HapticManager.shared.anchorError()
            }
        }
    }
}

// MARK: - Supporting Views

struct ToggleOption: View {
    @Environment(\.themeManager) private var themeManager
    let title: String
    let subtitle: String
    @Binding var isOn: Bool
    let icon: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(isOn ? Color.anchorBlue : Color.white.opacity(0.6))
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(themeManager?.currentTheme.textPrimaryColor ?? Theme.defaultTheme.textPrimaryColor)
                
                Text(subtitle)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.6))
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .toggleStyle(DesignedToggleStyle())
                .labelsHidden()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.08))
        )
    }
}

// MARK: - Preview

#Preview {
    ExportDataView()
        .modelContainer(for: [TimeBlock.self, DailyProgress.self], inMemory: true)
}
