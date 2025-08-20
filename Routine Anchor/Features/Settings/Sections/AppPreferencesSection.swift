//
//  AppPreferencesSection.swift
//  Routine Anchor
//
//  App preferences section for Settings view
//
import SwiftUI

struct AppPreferencesSection: View {
    @Binding var hapticsEnabled: Bool
    @Binding var autoResetEnabled: Bool
    let onResetProgress: () -> Void
    
    // MARK: - State
    @State private var showingResetConfirmation = false
    @State private var showingClearTodayConfirmation = false
    @State private var animateReset = false
    @State private var animateClear = false
    
    var body: some View {
        SettingsSection(
            title: "Preferences",
            icon: "slider.horizontal.3",
            color: Color.anchorGreen
        ) {
            VStack(spacing: 16) {
                // Haptic feedback toggle
                SettingsToggle(
                    title: "Haptic Feedback",
                    subtitle: "Feel interactions and confirmations",
                    isOn: $hapticsEnabled,
                    icon: "hand.tap"
                )
                .onChange(of: hapticsEnabled) { _, newValue in
                    if newValue {
                        HapticManager.shared.impact()
                    }
                }
                
                // Auto-reset toggle
                SettingsToggle(
                    title: "Auto-Reset Daily",
                    subtitle: "Reset progress at midnight",
                    isOn: $autoResetEnabled,
                    icon: "arrow.clockwise"
                )
                
                // Divider
                Rectangle()
                    .fill(Color.separatorColor)
                    .frame(height: 1)
                    .padding(.vertical, 4)
                
                // Additional preferences info
                preferencesInfoSection
            }
        }
        .confirmationDialog(
            "Reset Today's Progress",
            isPresented: $showingResetConfirmation,
            titleVisibility: .visible
        ) {
            Button("Reset Progress", role: .destructive) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    animateReset = true
                }
                onResetProgress()
                
                // Reset animation after delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    animateReset = false
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will reset all time blocks back to 'Not Started' for today. This action cannot be undone.")
        }
    }
    
    // MARK: - Info Section
    private var preferencesInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Haptics info
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "hand.tap")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.anchorGreen.opacity(0.8))
                    .frame(width: 16, height: 16)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Haptic Feedback")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Color.anchorTextPrimary)
                    
                    Text("Provides tactile feedback for buttons and actions")
                        .font(.system(size: 10, weight: .regular))
                        .foregroundStyle(Color.anchorTextSecondary)
                }
                
                Spacer()
            }
            
            // Auto-reset info
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "moon.stars")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.anchorPurple.opacity(0.8))
                    .frame(width: 16, height: 16)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Midnight Reset")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Color.anchorTextPrimary)
                    
                    Text("Automatically clears progress at 12:00 AM daily")
                        .font(.system(size: 10, weight: .regular))
                        .foregroundStyle(Color.anchorTextSecondary)
                }
                
                Spacer()
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.05))
        )
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        AnimatedGradientBackground()
            .ignoresSafeArea()
        
        ScrollView {
            AppPreferencesSection(
                hapticsEnabled: .constant(true),
                autoResetEnabled: .constant(true),
                onResetProgress: {
                    print("Reset progress")
                }
            )
            .padding()
        }
    }
}
