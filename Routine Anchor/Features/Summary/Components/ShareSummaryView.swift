//
//  ShareSummaryView.swift
//  Routine Anchor
//
//  Share summary sheet for Daily Summary
//
import SwiftUI

struct ShareSummaryView: View {
    @Environment(\.themeManager) private var themeManager
    @Environment(\.dismiss) private var dismiss
    let viewModel: DailySummaryViewModel
    
    @State private var isSharing = false
    @State private var showCopiedMessage = false
    
    // PDF sharing state
    @State private var shareURL: URL?
    @State private var showingShare = false
    @State private var isRendering = false
    @State private var renderError: String?
    
    var body: some View {
        NavigationStack {
            ZStack {
                ThemedAnimatedBackground()
                    .ignoresSafeArea()

                VStack(spacing: 24) {
                    header
                    preview
                    Spacer()
                    actions
                }
                .padding(.horizontal, 24)

                if isRendering {
                    ProgressView("Preparing PDF…")
                        .padding()
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                }
            }
            .navigationTitle("Share Summary")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showingShare) {
                if let url = shareURL {
                    ShareSheet(items: [url])
                }
            }
            .alert("Couldn't Create PDF", isPresented: .constant(renderError != nil)) {
                Button("OK") { renderError = nil }
            } message: {
                Text(renderError ?? "")
            }
        }
    }
    
    private var header: some View {
        VStack(spacing: 12) {
            Image(systemName: "square.and.arrow.up.circle.fill")
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            themeManager?.currentTheme.colorScheme.normal.color ?? Theme.defaultTheme.colorScheme.normal.color,
                            themeManager?.currentTheme.colorScheme.primaryAccent.color ?? Theme.defaultTheme.colorScheme.primaryAccent.color
                        ],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                )

            Text("Share Your Progress")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(themeManager?.currentTheme.primaryTextColor ?? Theme.defaultTheme.primaryTextColor)

            Text("Inspire others with your journey")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Color(themeManager?.currentTheme.secondaryTextColor ?? Theme.defaultTheme.secondaryTextColor))
        }
        .padding(.top, 20)
    }
    
    private var preview: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Preview")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color(themeManager?.currentTheme.primaryTextColor ?? Theme.defaultTheme.primaryTextColor).opacity(0.8))
                Spacer()
                if showCopiedMessage {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(themeManager?.currentTheme.colorScheme.success.color ?? Theme.defaultTheme.colorScheme.success.color)
                        Text("Copied!")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(themeManager?.currentTheme.colorScheme.success.color ?? Theme.defaultTheme.colorScheme.success.color)
                    }
                    .transition(.scale.combined(with: .opacity))
                }
            }
            
            ScrollView {
                Text(viewModel.generateShareableText())
                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                    .foregroundStyle(themeManager?.currentTheme.primaryTextColor ?? Theme.defaultTheme.primaryTextColor)
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.ultraThinMaterial)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color(themeManager?.currentTheme.colorScheme.primaryUIElement.color ?? Theme.defaultTheme.colorScheme.primaryUIElement.color).opacity(0.5))
                            )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color(themeManager?.currentTheme.colorScheme.secondaryUIElement.color ?? Theme.defaultTheme.colorScheme.secondaryUIElement.color), lineWidth: 1)
                    )
            }
            .frame(maxHeight: 300)
        }
    }
    
    private var actions: some View {
        VStack(spacing: 16) {
            DesignedButton(
                title: "Share Progress",
                style: .gradient,
                action: {
                    Task { await shareProgressPDF() }
                }
            )
            .disabled(isSharing || isRendering)

            SecondaryActionButton(
                title: "Copy to Clipboard",
                icon: "doc.on.doc",
                action: copyToClipboard
            )
        }
        .padding(.bottom, 20)
    }
    
    private func shareProgress() {
        isSharing = true
        let text = viewModel.generateShareableText()
        
        let activityVC = UIActivityViewController(
            activityItems: [text],
            applicationActivities: nil
        )
        
        // Completion handler
        activityVC.completionWithItemsHandler = { _, _, _, _ in
            isSharing = false
        }
        
        HapticManager.shared.impact()
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(activityVC, animated: true)
        }
    }
    
    // MARK: - Actions

    @MainActor
    private func shareProgressPDF() async {
        isRendering = true
        defer { isRendering = false }

        // 1) Build display data from the VM you provided
        let df = DateFormatter()
        df.dateStyle = .full
        df.timeStyle = .none
        let dateTitle = df.string(from: viewModel.selectedDate)

        let completionPercent = Int((viewModel.completionPercentage).rounded() * 100)

        // Totals
        let totalBlocks = viewModel.safeDailyProgress?.totalBlocks
            ?? viewModel.todaysTimeBlocks.count
        let completedBlocks = viewModel.statusCounts.completed
        let skippedBlocks = viewModel.statusCounts.skipped

        // Categories summary: [String : Int]
        let topCategories: [String:Int] = {
            var counts: [String:Int] = [:]
            for cat in viewModel.todaysTimeBlocks.compactMap({ $0.category?.trimmingCharacters(in: .whitespacesAndNewlines) }).filter({ !$0.isEmpty }) {
                counts[cat, default: 0] += 1
            }
            return counts
        }()

        // Notes (reflection) if any
        let notes = viewModel.safeDailyProgress?.dayNotes

        // 2) Render the single-page PDF using your card view
        do {
            let url = try PDFRenderService.renderSinglePagePDF {
                ShareProgressCardView(
                    dateRangeTitle: dateTitle,
                    completionPercent: completionPercent,
                    totalBlocks: totalBlocks,
                    completedBlocks: completedBlocks,
                    skippedBlocks: skippedBlocks,
                    topCategories: topCategories,
                    notes: notes
                )
                .frame(width: 612, height: 792) // US Letter @ 72 dpi
                .padding(24)
                .background(Color.clear)
            }

            shareURL = url
            HapticManager.shared.impact()
            showingShare = true
        } catch {
            renderError = "Failed to generate PDF: \(error.localizedDescription)"
        }
    }

    
    private func copyToClipboard() {
        UIPasteboard.general.string = viewModel.generateShareableText()
        
        HapticManager.shared.anchorSuccess()
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            showCopiedMessage = true
        }
        
        // Hide message after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                showCopiedMessage = false
            }
        }
    }
}
