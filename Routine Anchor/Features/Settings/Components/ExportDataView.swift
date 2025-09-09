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
    private var theme: AppTheme { themeManager?.currentTheme ?? PredefinedThemes.classic }

    var body: some View {
        NavigationStack {
            ZStack {
                ThemedAnimatedBackground()
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 32) {
                        headerSection
                        formatSection
                        optionsSection
                        exportButton
                        infoSection
                    }
                    .padding(24)
                }
            }
            .navigationBarHidden(true)
            .alert("Export Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") { errorMessage = nil }
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

    // MARK: - Header
    private var headerSection: some View {
        VStack(spacing: 16) {
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(theme.secondaryTextColor)
                        .frame(width: 30, height: 30)
                        .background(theme.surfaceCardColor.opacity(0.3))
                        .clipShape(Circle())
                }
                Spacer()
            }

            VStack(spacing: 12) {
                Image(systemName: "square.and.arrow.up.circle.fill")
                    .font(.system(size: 56, weight: .light))
                    .foregroundStyle(
                        LinearGradient(colors: [theme.accentPrimaryColor, theme.accentSecondaryColor],
                                       startPoint: .topLeading, endPoint: .bottomTrailing)
                    )

                Text("Export Your Data")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(theme.primaryTextColor)

                Text("Download your routines and progress")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(theme.secondaryTextColor)
            }
        }
    }

    // MARK: - Format
    private var formatSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Export Format")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(theme.primaryTextColor)

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
                    .foregroundStyle(selectedFormat == format ? theme.accentPrimaryColor : theme.secondaryTextColor)
                    .frame(width: 24, height: 24)

                VStack(alignment: .leading, spacing: 4) {
                    Text(format.rawValue)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(selectedFormat == format ? theme.primaryTextColor : theme.secondaryTextColor)

                    Text(descriptionForFormat(format))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(theme.secondaryTextColor)
                }

                Spacer()

                if selectedFormat == format {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(theme.accentPrimaryColor)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(theme.surfaceCardColor.opacity(selectedFormat == format ? 0.5 : 0.3))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(selectedFormat == format ? theme.accentPrimaryColor.opacity(0.5) : .clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Options
    private var optionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Include in Export")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(theme.primaryTextColor)

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
                        .progressViewStyle(.circular)
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 18, weight: .semibold))
                }

                Text(isExporting ? "Exporting..." : "Export Data")
                    .font(.system(size: 18, weight: .semibold))
            }
            .foregroundStyle(theme.invertedTextColor)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                LinearGradient(colors: [theme.accentPrimaryColor, theme.accentSecondaryColor],
                               startPoint: .leading, endPoint: .trailing)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: theme.accentPrimaryColor.opacity(0.3), radius: 12, x: 0, y: 6)
        }
        .disabled(isExporting)
    }

    // MARK: - Info
    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "info.circle")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(theme.accentPrimaryColor.opacity(0.8))

                Text("About Your Data")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(theme.primaryTextColor)
            }

            Text("Your exported data includes all time blocks\(includeProgress ? ", daily progress records" : "")\(includeSettings ? ", and app settings" : ""). The file will be saved to your device and can be shared or stored as a backup.")
                .font(.system(size: 12, weight: .regular))
                .foregroundStyle(theme.secondaryTextColor)
                .lineSpacing(2)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(theme.accentPrimaryColor.opacity(0.10))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(theme.accentPrimaryColor.opacity(0.20), lineWidth: 1)
        )
    }

    // MARK: - Helpers

    private func iconForFormat(_ format: ExportService.ExportFormat) -> String {
        switch format {
        case .json: return "doc.text"
        case .csv:  return "tablecells"
        case .text: return "doc.plaintext"
        }
    }

    private func descriptionForFormat(_ format: ExportService.ExportFormat) -> String {
        switch format {
        case .json: return "Structured data for developers"
        case .csv:  return "Spreadsheet compatible format"
        case .text: return "Human-readable plain text"
        }
    }

    private func fileExtensionForFormat(_ format: ExportService.ExportFormat) -> String {
        switch format {
        case .json: return "json"
        case .csv:  return "csv"
        case .text: return "txt"
        }
    }

    private func performExport() {
        isExporting = true
        HapticManager.shared.lightImpact()

        Task { @MainActor in
            do {
                let exportData: Data

                if includeProgress {
                    // (Progress & time blocks; settings flag is informational for now)
                    exportData = try exportService.exportAllData(
                        timeBlocks: timeBlocks,
                        dailyProgress: dailyProgress,
                        format: selectedFormat
                    )
                } else {
                    exportData = try exportService.exportTimeBlocks(
                        timeBlocks,
                        format: selectedFormat
                    )
                }

                let df = DateFormatter()
                df.dateFormat = "yyyy-MM-dd-HHmmss"
                let fileName = "routine-anchor-export-\(df.string(from: Date())).\(fileExtensionForFormat(selectedFormat))"
                let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
                try exportData.write(to: tempURL)

                exportedFileURL = tempURL
                isExporting = false
                showingShareSheet = true
                HapticManager.shared.anchorSuccess()

            } catch {
                errorMessage = error.localizedDescription
                isExporting = false
                HapticManager.shared.anchorError()
            }
        }
    }
}

// MARK: - Supporting View

struct ToggleOption: View {
    @Environment(\.themeManager) private var themeManager
    let title: String
    let subtitle: String
    @Binding var isOn: Bool
    let icon: String

    private var theme: AppTheme { themeManager?.currentTheme ?? PredefinedThemes.classic }

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(isOn ? theme.accentPrimaryColor : theme.secondaryTextColor)
                .frame(width: 24, height: 24)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(theme.primaryTextColor)

                Text(subtitle)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(theme.secondaryTextColor)
            }

            Spacer()

            Toggle("", isOn: $isOn)
                .toggleStyle(DesignedToggleStyle())
                .labelsHidden()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(theme.surfaceCardColor.opacity(0.30))
        )
    }
}

#Preview {
    ExportDataView()
        .modelContainer(for: [TimeBlock.self, DailyProgress.self], inMemory: true)
        .environment(\.themeManager, ThemeManager.preview())
        .preferredColorScheme(.dark)
}
