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
    @State private var animateReset = false
    
    var body: some View {
        SettingsSection(
            title: "Preferences",
            icon: "slider.horizontal.3",
            color: Color.premiumGreen
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
                        HapticManager.shared.premiumImpact()
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
                
                // Reset today's progress button
                SettingsButton(
                    title: "Reset Today's Progress",
                    subtitle: "Start today over",
                    icon: "arrow.counterclockwise",
                    color: Color.premiumWarning,
                    action: {
                        HapticManager.shared.warning()
                        showingResetConfirmation = true
                    }
                )
                .scaleEffect(animateReset ? 0.98 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: animateReset)
                
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
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
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
                    .foregroundStyle(Color.premiumGreen.opacity(0.8))
                    .frame(width: 16, height: 16)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Haptic Feedback")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Color.premiumTextPrimary)
                    
                    Text("Provides tactile feedback for buttons and actions")
                        .font(.system(size: 10, weight: .regular))
                        .foregroundStyle(Color.premiumTextSecondary)
                }
                
                Spacer()
            }
            
            // Auto-reset info
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "moon.stars")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.premiumPurple.opacity(0.8))
                    .frame(width: 16, height: 16)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Midnight Reset")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Color.premiumTextPrimary)
                    
                    Text("Automatically clears progress at 12:00 AM daily")
                        .font(.system(size: 10, weight: .regular))
                        .foregroundStyle(Color.premiumTextSecondary)
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
