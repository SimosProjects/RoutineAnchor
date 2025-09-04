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
    
    var body: some View {
        NavigationStack {
            ZStack {
                ThemedAnimatedBackground()
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 32) {
                        // Header
                        headerSection
                        
                        // Instructions
                        instructionsSection
                        
                        // Import button
                        importButton
                        
                        // Info section
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
                    if result.isSuccess {
                        dismiss()
                    }
                }
            } message: { result in
                Text(result.summary)
            }
            .alert("Import Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") {
                    errorMessage = nil
                }
            } message: {
                Text(errorMessage ?? "")
            }
        }
        
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Close button
            HStack {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(Color(themeManager?.currentTheme.subtleTextColor ?? Theme.defaultTheme.subtleTextColor).opacity(0.6))
                        .background(
                            Circle()
                                .fill(.ultraThinMaterial)
                                .frame(width: 40, height: 40)
                        )
                }
                Spacer()
            }
            
            // Title and icon
            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [themeManager?.currentTheme.colorScheme.workflowPrimary.color ?? Theme.defaultTheme.colorScheme.workflowPrimary.color.opacity(0.3), themeManager?.currentTheme.colorScheme.organizationAccent.color ?? Theme.defaultTheme.colorScheme.organizationAccent.color.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 80, height: 80)
                        .blur(radius: 20)
                    
                    Image(systemName: "square.and.arrow.down")
                        .font(.system(size: 40, weight: .medium))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [themeManager?.currentTheme.colorScheme.workflowPrimary.color ?? Theme.defaultTheme.colorScheme.workflowPrimary.color, themeManager?.currentTheme.colorScheme.organizationAccent.color ?? Theme.defaultTheme.colorScheme.organizationAccent.color],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                
                VStack(spacing: 8) {
                    Text("Import Data")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(themeManager?.currentTheme.primaryTextColor ?? Theme.defaultTheme.primaryTextColor)
                    
                    Text("Restore from backup")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(themeManager?.currentTheme.secondaryTextColor ?? Theme.defaultTheme.secondaryTextColor).opacity(0.85)
                }
            }
        }
    }
    
    // MARK: - Instructions Section
    private var instructionsSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Supported Formats")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(themeManager?.currentTheme.primaryTextColor ?? Theme.defaultTheme.primaryTextColor)
            
            VStack(spacing: 16) {
                FormatRow(
                    icon: "doc.text",
                    title: "JSON",
                    description: "Complete data with all details",
                    color: themeManager?.currentTheme.colorScheme.workflowPrimary.color ?? Theme.defaultTheme.colorScheme.workflowPrimary.color
                )
                
                FormatRow(
                    icon: "tablecells",
                    title: "CSV",
                    description: "Spreadsheet format for basic data",
                    color: themeManager?.currentTheme.colorScheme.actionSuccess.color ?? Theme.defaultTheme.colorScheme.actionSuccess.color
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color(themeManager?.currentTheme.colorScheme.uiElementPrimary.color ?? Theme.defaultTheme.colorScheme.uiElementPrimary.color), lineWidth: 1)
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
            .foregroundStyle(themeManager?.currentTheme.primaryTextColor ?? Theme.defaultTheme.primaryTextColor)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                LinearGradient(
                    colors: [themeManager?.currentTheme.colorScheme.workflowPrimary.color ?? Theme.defaultTheme.colorScheme.workflowPrimary.color, themeManager?.currentTheme.colorScheme.organizationAccent.color ?? Theme.defaultTheme.colorScheme.organizationAccent.color],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(16)
            .shadow(color: themeManager?.currentTheme.colorScheme.workflowPrimary.color ?? Theme.defaultTheme.colorScheme.workflowPrimary.color.opacity(0.3), radius: 12, x: 0, y: 6)
        }
        .disabled(isImporting)
    }
    
    // MARK: - Info Section
    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.yellow.opacity(0.8))
                
                Text("Important")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(themeManager?.currentTheme.primaryTextColor ?? Theme.defaultTheme.primaryTextColor)
            }
            
            Text("• Imported time blocks will be added to your existing schedule\n• Duplicate entries will be skipped automatically\n• Make sure the file is in a supported format (JSON or CSV)")
                .font(.system(size: 12, weight: .regular))
                .foregroundStyle(themeManager?.currentTheme.secondaryTextColor ?? Theme.defaultTheme.secondaryTextColor)
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
    
    // MARK: - Helper Methods
    
    private func handleFileImport(result: Result<[URL], Error>) {
        Task { @MainActor in
            do {
                let urls = try result.get()
                guard let fileURL = urls.first else {
                    errorMessage = "No file selected"
                    return
                }
                
                isImporting = true
                
                // Use the existing importService.importData method
                let importResult = try await importService.importData(
                    from: fileURL,
                    modelContext: modelContext
                )
                
                self.importResult = importResult
                
                if importResult.isSuccess {
                    HapticManager.shared.anchorSuccess()
                    showingSuccessAlert = true
                } else if !importResult.errors.isEmpty {
                    HapticManager.shared.anchorError()
                    // Show all errors, not just the first one
                    errorMessage = importResult.errors
                        .map { $0.localizedDescription }
                        .joined(separator: "\n")
                } else {
                    // No data imported and no errors means empty file
                    errorMessage = "No valid data found in the file"
                }
                
            } catch let error as ImportError {
                // Handle specific import errors
                errorMessage = error.localizedDescription
                HapticManager.shared.anchorError()
            } catch {
                // Handle general errors (file access, etc.)
                errorMessage = "Failed to import: \(error.localizedDescription)"
                HapticManager.shared.anchorError()
            }
            
            isImporting = false
        }
    }
}

// MARK: - Format Row Component
struct FormatRow: View {
    @Environment(\.themeManager) private var themeManager
    let icon: String
    let title: String
    let description: String
    let color: Color
    
    private var themePrimaryText: Color {
        themeManager?.currentTheme.primaryTextColor ?? Theme.defaultTheme.primaryTextColor
    }
    
    private var themeSecondaryText: Color {
        themeManager?.currentTheme.secondaryTextColor ?? Theme.defaultTheme.secondaryTextColor
    }
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .medium))
                .foregroundStyle(color)
                .frame(width: 32, height: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(themePrimaryText)
                
                Text(description)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(themeSecondaryText)
            }
            
            Spacer()
        }
    }
}

// MARK: - Preview
#Preview {
    ImportDataView()
        .modelContainer(for: [TimeBlock.self, DailyProgress.self], inMemory: true)
}
