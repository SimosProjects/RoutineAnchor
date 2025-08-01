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
                // Premium background
                AnimatedGradientBackground()
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
                handleFileSelection(result)
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
                        .foregroundStyle(Color.white.opacity(0.3))
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
                                colors: [Color.premiumBlue.opacity(0.3), Color.premiumPurple.opacity(0.3)],
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
                                colors: [Color.premiumBlue, Color.premiumPurple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                
                VStack(spacing: 8) {
                    Text("Import Data")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(Color.white)
                    
                    Text("Restore from backup")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.6))
                }
            }
        }
    }
    
    // MARK: - Instructions Section
    private var instructionsSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Supported Formats")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(Color.white)
            
            VStack(spacing: 16) {
                FormatRow(
                    icon: "doc.text",
                    title: "JSON",
                    description: "Complete data with all details",
                    color: .premiumBlue
                )
                
                FormatRow(
                    icon: "tablecells",
                    title: "CSV",
                    description: "Spreadsheet format for basic data",
                    color: .premiumGreen
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
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
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                LinearGradient(
                    colors: [Color.premiumBlue, Color.premiumPurple],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(16)
            .shadow(color: Color.premiumBlue.opacity(0.3), radius: 12, x: 0, y: 6)
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
                    .foregroundStyle(Color.white.opacity(0.9))
            }
            
            Text("• Imported time blocks will be added to your existing schedule\n• Duplicate entries will be skipped automatically\n• Make sure the file was exported from Routine Anchor")
                .font(.system(size: 12, weight: .regular))
                .foregroundStyle(Color.white.opacity(0.6))
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
    
    private func handleFileSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let fileURL = urls.first else { return }
            performImport(from: fileURL)
        case .failure(let error):
            errorMessage = "Failed to select file: \(error.localizedDescription)"
        }
    }
    
    private func performImport(from fileURL: URL) {
        isImporting = true
        
        Task {
            do {
                let result = try await importService.importData(
                    from: fileURL,
                    modelContext: modelContext
                )
                
                await MainActor.run {
                    isImporting = false
                    importResult = result
                    
                    if result.isSuccess {
                        HapticManager.shared.premiumSuccess()
                        showingSuccessAlert = true
                    } else if !result.errors.isEmpty {
                        HapticManager.shared.premiumError()
                        errorMessage = result.errors.first?.localizedDescription ?? "Import failed"
                    }
                }
            } catch {
                await MainActor.run {
                    isImporting = false
                    errorMessage = error.localizedDescription
                    HapticManager.shared.premiumError()
                }
            }
        }
    }
}

// MARK: - Format Row Component
struct FormatRow: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .medium))
                .foregroundStyle(color)
                .frame(width: 32, height: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.white)
                
                Text(description)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(Color.white.opacity(0.6))
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
