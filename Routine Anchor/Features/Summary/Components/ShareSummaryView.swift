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
    
    var body: some View {
        NavigationStack {
            ZStack {
                ThemedAnimatedBackground()
                    .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // Header info
                    VStack(spacing: 12) {
                        Image(systemName: "square.and.arrow.up.circle.fill")
                            .font(.system(size: 48, weight: .light))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [themeManager?.currentTheme.colorScheme.workflowPrimary.color ?? Theme.defaultTheme.colorScheme.workflowPrimary.color, themeManager?.currentTheme.colorScheme.organizationAccent.color ?? Theme.defaultTheme.colorScheme.organizationAccent.color],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
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
                    
                    // Preview section
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
                                        .foregroundStyle(themeManager?.currentTheme.colorScheme.actionSuccess.color ?? Theme.defaultTheme.colorScheme.actionSuccess.color)
                                    
                                    Text("Copied!")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundStyle(themeManager?.currentTheme.colorScheme.actionSuccess.color ?? Theme.defaultTheme.colorScheme.actionSuccess.color)
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
                                                .fill(Color(themeManager?.currentTheme.colorScheme.uiElementPrimary.color ?? Theme.defaultTheme.colorScheme.uiElementPrimary.color).opacity(0.5))
                                        )
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color(themeManager?.currentTheme.colorScheme.uiElementSecondary.color ?? Theme.defaultTheme.colorScheme.uiElementSecondary.color), lineWidth: 1)
                                )
                        }
                        .frame(maxHeight: 300)
                    }
                    
                    Spacer()
                    
                    // Action buttons
                    VStack(spacing: 16) {
                        DesignedButton(
                            title: "Share Progress",
                            style: .gradient,
                            action: shareProgress
                        )
                        .disabled(isSharing)
                        
                        SecondaryActionButton(
                            title: "Copy to Clipboard",
                            icon: "doc.on.doc",
                            action: copyToClipboard
                        )
                    }
                    .padding(.bottom, 20)
                }
                .padding(.horizontal, 24)
            }
            .navigationTitle("Share Summary")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(themeManager?.currentTheme.colorScheme.workflowPrimary.color ?? Theme.defaultTheme.colorScheme.workflowPrimary.color)
                }
            }
        }
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
