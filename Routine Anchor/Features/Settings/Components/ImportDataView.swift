//
//  ImportDataView.swift
//  Routine Anchor
//
//  Import data view for Settings
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct ImportDataView: View {
    @Environment(\.themeManager) private var themeManager
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var isImporting = false
    @State private var showingFilePicker = false
    @State private var importResult: ImportService.ImportResult?
    @State private var errorMessage: String?
    @State private var showingSuccessAlert = false

    private let importService = ImportService.shared
    private var theme: AppTheme { themeManager?.currentTheme ?? PredefinedThemes.classic }

    var body: some View {
        NavigationStack {
            ZStack {
                ThemedAnimatedBackground().ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 32) {
                        headerSection
                        instructionsSection
                        importButton
                        infoSection
                    }
                    .padding(24)
                }
            }
            .navigationBarHidden(true)
            .fileImporter(
                isPresented: $showingFilePicker,
                allowedContentTypes: [.json, .commaSeparatedText],
                allowsMultipleSelection: false
            ) { result in
                handleFileImport(result: result)
            }
            .alert("Import Complete", isPresented: $showingSuccessAlert, presenting: importResult) { result in
                Button("OK") {
                    if result.isSuccess { dismiss() }
                }
            } message: { result in
                Text(result.summary)
            }
            .alert("Import Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }

    // MARK: - Header
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Close button
            HStack {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(theme.subtleTextColor.opacity(0.6))
                        .background(
                            Circle()
                                .fill(.ultraThinMaterial)
                                .frame(width: 40, height: 40)
                        )
                }
                Spacer()
            }

            // Title & icon
            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(colors: [theme.accentPrimaryColor.opacity(0.3),
                                                    theme.accentSecondaryColor.opacity(0.3)],
                                           startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .frame(width: 80, height: 80)
                        .blur(radius: 20)

                    Image(systemName: "square.and.arrow.down")
                        .font(.system(size: 40, weight: .medium))
                        .foregroundStyle(
                            LinearGradient(colors: [theme.accentPrimaryColor, theme.accentSecondaryColor],
                                           startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                }

                VStack(spacing: 8) {
                    Text("Import Data")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(theme.primaryTextColor)

                    Text("Restore from backup")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(theme.secondaryTextColor).opacity(0.85)
                }
            }
        }
    }

    // MARK: - Instructions
    private var instructionsSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Supported Formats")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(theme.primaryTextColor)

            VStack(spacing: 16) {
                FormatRow(
                    icon: "doc.text",
                    title: "JSON",
                    description: "Complete data with all details",
                    color: theme.accentPrimaryColor
                )

                FormatRow(
                    icon: "tablecells",
                    title: "CSV",
                    description: "Spreadsheet format for basic data",
                    color: theme.statusSuccessColor
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(theme.surfaceCardColor, lineWidth: 1)
                )
        )
    }

    // MARK: - Import Button
    private var importButton: some View {
        Button {
            showingFilePicker = true
            HapticManager.shared.lightImpact()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "folder.badge.plus")
                    .font(.system(size: 20, weight: .semibold))

                Text("Choose File to Import")
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
        .disabled(isImporting)
    }

    // MARK: - Info
    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.yellow.opacity(0.8))

                Text("Important")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(theme.primaryTextColor)
            }

            Text("• Imported time blocks will be added to your existing schedule\n• Duplicate entries will be skipped automatically\n• Make sure the file is in a supported format (JSON or CSV)")
                .font(.system(size: 12, weight: .regular))
                .foregroundStyle(theme.secondaryTextColor)
                .lineSpacing(2)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.yellow.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.yellow.opacity(0.2), lineWidth: 1)
        )
    }

    // MARK: - Import

    private func handleFileImport(result: Result<[URL], Error>) {
        Task { @MainActor in
            do {
                let urls = try result.get()
                guard let fileURL = urls.first else {
                    errorMessage = "No file selected"
                    return
                }

                isImporting = true

                let importResult = try await importService.importData(from: fileURL, modelContext: modelContext)
                self.importResult = importResult

                if importResult.isSuccess {
                    HapticManager.shared.anchorSuccess()
                    showingSuccessAlert = true
                } else if !importResult.errors.isEmpty {
                    HapticManager.shared.anchorError()
                    errorMessage = importResult.errors.map { $0.localizedDescription }.joined(separator: "\n")
                } else {
                    errorMessage = "No valid data found in the file"
                }

            } catch let error as ImportError {
                errorMessage = error.localizedDescription
                HapticManager.shared.anchorError()
            } catch {
                errorMessage = "Failed to import: \(error.localizedDescription)"
                HapticManager.shared.anchorError()
            }

            isImporting = false
        }
    }
}

// MARK: - Format Row

struct FormatRow: View {
    @Environment(\.themeManager) private var themeManager
    let icon: String
    let title: String
    let description: String
    let color: Color

    private var theme: AppTheme { themeManager?.currentTheme ?? PredefinedThemes.classic }

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .medium))
                .foregroundStyle(color)
                .frame(width: 32, height: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(theme.primaryTextColor)

                Text(description)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(theme.secondaryTextColor)
            }

            Spacer()
        }
    }
}

#Preview {
    ImportDataView()
        .modelContainer(for: [TimeBlock.self, DailyProgress.self], inMemory: true)
        .environment(\.themeManager, ThemeManager.preview())
        .preferredColorScheme(.dark)
}
