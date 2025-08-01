//
//  ShareSummaryView.swift
//  Routine Anchor
//
//  Share summary sheet for Daily Summary
//
import SwiftUI

struct ShareSummaryView: View {
    @Environment(\.dismiss) private var dismiss
    let viewModel: DailySummaryViewModel
    
    @State private var isSharing = false
    @State private var showCopiedMessage = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                AnimatedGradientBackground()
                    .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // Header info
                    VStack(spacing: 12) {
                        Image(systemName: "square.and.arrow.up.circle.fill")
                            .font(.system(size: 48, weight: .light))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color.premiumBlue, Color.premiumPurple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        
                        Text("Share Your Progress")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        
                        Text("Inspire others with your journey")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(Color.white.opacity(0.7))
                    }
                    .padding(.top, 20)
                    
                    // Preview section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Preview")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(Color.white.opacity(0.8))
                            
                            Spacer()
                            
                            if showCopiedMessage {
                                HStack(spacing: 4) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 12))
                                        .foregroundStyle(Color.premiumGreen)
                                    
                                    Text("Copied!")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundStyle(Color.premiumGreen)
                                }
                                .transition(.scale.combined(with: .opacity))
                            }
                        }
                        
                        ScrollView {
                            Text(viewModel.generateShareableText())
                                .font(.system(size: 14, weight: .medium, design: .monospaced))
                                .foregroundStyle(.white)
                                .padding(20)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(.ultraThinMaterial)
                                        .background(
                                            RoundedRectangle(cornerRadius: 16)
                                                .fill(Color.white.opacity(0.05))
                                        )
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                )
                        }
                        .frame(maxHeight: 300)
                    }
                    
                    Spacer()
                    
                    // Action buttons
                    VStack(spacing: 16) {
                        PremiumButton(
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
                    .foregroundStyle(Color.premiumBlue)
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
        
        HapticManager.shared.premiumImpact()
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(activityVC, animated: true)
        }
    }
    
    private func copyToClipboard() {
        UIPasteboard.general.string = viewModel.generateShareableText()
        
        HapticManager.shared.premiumSuccess()
        
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
