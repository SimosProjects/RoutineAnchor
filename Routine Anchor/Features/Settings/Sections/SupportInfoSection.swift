//
//  SupportInfoSection.swift
//  Routine Anchor
//
//  Support and info section for Settings view
//
import SwiftUI

struct SupportInfoSection: View {
    let onShowHelp: () -> Void
    let onShowAbout: () -> Void
    let onRateApp: () -> Void
    let onContactSupport: () -> Void
    
    // MARK: - State
    @State private var animateRating = false
    @State private var showThankYou = false
    
    var body: some View {
        SettingsSection(
            title: "Support & Info",
            icon: "questionmark.circle",
            color: Color.anchorTeal
        ) {
            VStack(spacing: 16) {
                // Help & FAQ button
                SettingsButton(
                    title: "Help & FAQ",
                    subtitle: "Get answers to common questions",
                    icon: "questionmark.circle",
                    color: Color.anchorBlue,
                    action: {
                        HapticManager.shared.lightImpact()
                        onShowHelp()
                    }
                )
                
                // About button
                SettingsButton(
                    title: "About Routine Anchor",
                    subtitle: "App info and acknowledgments",
                    icon: "info.circle",
                    color: Color.anchorPurple,
                    action: {
                        HapticManager.shared.lightImpact()
                        onShowAbout()
                    }
                )
                
                // Divider with support heading
                supportDivider
                
                // Rate the app button
                SettingsButton(
                    title: "Rate the App",
                    subtitle: showThankYou ? "Thank you! ❤️" : "Support development",
                    icon: "star",
                    color: Color.anchorWarning,
                    action: {
                        HapticManager.shared.anchorSuccess()
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                            animateRating = true
                            showThankYou = true
                        }
                        onRateApp()
                        
                        // Reset after delay
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            animateRating = false
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            withAnimation {
                                showThankYou = false
                            }
                        }
                    }
                )
                .scaleEffect(animateRating ? 1.1 : 1.0)
                .animation(.spring(response: 0.5, dampingFraction: 0.6), value: animateRating)
                .onChange(of: animateRating) { _, newValue in
                    if newValue {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            animateRating = false
                        }
                    }
                }
                
                // Contact support button
                SettingsButton(
                    title: "Contact Support",
                    subtitle: "Get help from our team",
                    icon: "envelope",
                    color: Color.anchorGreen,
                    action: {
                        HapticManager.shared.lightImpact()
                        onContactSupport()
                    }
                )
                
                // Quick tips
                quickTipsSection
            }
        }
    }
    
    // MARK: - Support Divider
    private var supportDivider: some View {
        HStack(spacing: 12) {
            Rectangle()
                .fill(Color.separatorColor)
                .frame(height: 1)
            
            Text("SUPPORT")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(Color.anchorTextSecondary)
                .tracking(1)
            
            Rectangle()
                .fill(Color.separatorColor)
                .frame(height: 1)
        }
        .padding(.vertical, 4)
    }
    
    // MARK: - Quick Tips Section
    private var quickTipsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "lightbulb")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.anchorWarning)
                
                Text("Quick Tips")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.anchorTextPrimary)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                SupportingInfoQuickTip(
                    number: "1",
                    text: "Swipe to edit or delete time blocks"
                )
                
                SupportingInfoQuickTip(
                    number: "2",
                    text: "Long press FAB for quick add"
                )
                
                SupportingInfoQuickTip(
                    number: "3",
                    text: "Pull down to refresh your progress"
                )
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.anchorTeal.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.anchorTeal.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Quick Tip Component
struct SupportingInfoQuickTip: View {
    let number: String
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text(number)
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(Color.anchorTeal)
                .frame(width: 16, height: 16)
                .background(
                    Circle()
                        .fill(Color.anchorTeal.opacity(0.2))
                )
            
            Text(text)
                .font(.system(size: 11, weight: .regular))
                .foregroundStyle(Color.anchorTextSecondary)
                .lineLimit(2)
            
            Spacer()
        }
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        ThemedAnimatedBackground()
            .ignoresSafeArea()
        
        ScrollView {
            SupportInfoSection(
                onShowHelp: {
                    print("Show help")
                },
                onShowAbout: {
                    print("Show about")
                },
                onRateApp: {
                    print("Rate app")
                },
                onContactSupport: {
                    print("Contact support")
                }
            )
            .padding()
        }
    }
}
