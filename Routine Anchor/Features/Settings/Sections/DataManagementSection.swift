//
//  DataManagementSection.swift
//  Routine Anchor
//
//  Data management section for Settings view
//
import SwiftUI

struct DataManagementSection: View {
    let onExportData: () -> Void
    let onShowPrivacyPolicy: () -> Void
    let onDeleteAllData: () -> Void
    
    // MARK: - State
    @State private var showingDeleteConfirmation = false
    @State private var deleteButtonScale: CGFloat = 1.0
    
    var body: some View {
        SettingsSection(
            title: "Data & Privacy",
            icon: "shield.checkered",
            color: Color.premiumPurple
        ) {
            VStack(spacing: 16) {
                // Export data button
                SettingsButton(
                    title: "Export My Data",
                    subtitle: "Download your routine data",
                    icon: "square.and.arrow.up",
                    color: Color.premiumBlue,
                    action: {
                        HapticManager.shared.lightImpact()
                        onExportData()
                    }
                )
                
                // Privacy policy button
                SettingsButton(
                    title: "Privacy Policy",
                    subtitle: "How we protect your data",
                    icon: "hand.raised",
                    color: Color.premiumGreen,
                    action: {
                        HapticManager.shared.lightImpact()
                        onShowPrivacyPolicy()
                    }
                )
                
                // Data storage info
                dataStorageInfo
                
                // Divider
                Rectangle()
                    .fill(Color.separatorColor)
                    .frame(height: 1)
                    .padding(.vertical, 4)
                
                // Delete all data button
                SettingsButton(
                    title: "Delete All Data",
                    subtitle: "Permanently remove everything",
                    icon: "trash",
                    color: Color.premiumError,
                    action: {
                        HapticManager.shared.warning()
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            deleteButtonScale = 0.95
                        }
                        showingDeleteConfirmation = true
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            deleteButtonScale = 1.0
                        }
                    }
                )
                .scaleEffect(deleteButtonScale)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: deleteButtonScale)
            }
        }
        .confirmationDialog(
            "Delete All Data",
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete All Data", role: .destructive) {
                HapticManager.shared.premiumError()
                onDeleteAllData()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete all your routines, time blocks, and progress data. This action cannot be undone.")
        }
    }
    
    // MARK: - Data Storage Info
    private var dataStorageInfo: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.premiumPurple)
                
                Text("Your Data is Secure")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.premiumTextPrimary)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                DataPoint(
                    icon: "iphone",
                    text: "All data stored locally on device",
                    color: Color.premiumBlue
                )
                
                DataPoint(
                    icon: "wifi.slash",
                    text: "No cloud sync or external servers",
                    color: Color.premiumGreen
                )
                
                DataPoint(
                    icon: "person.crop.circle.badge.xmark",
                    text: "We never collect personal data",
                    color: Color.premiumPurple
                )
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.premiumPurple.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.premiumPurple.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Data Point Component
struct DataPoint: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(color)
                .frame(width: 16, height: 16)
            
            Text(text)
                .font(.system(size: 11, weight: .regular))
                .foregroundStyle(Color.premiumTextSecondary)
            
            Spacer()
        }
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        AnimatedGradientBackground()
            .ignoresSafeArea()
        
        ScrollView {
            DataManagementSection(
                onExportData: {
                    print("Export data")
                },
                onShowPrivacyPolicy: {
                    print("Show privacy policy")
                },
                onDeleteAllData: {
                    print("Delete all data")
                }
            )
            .padding()
        }
    }
}
