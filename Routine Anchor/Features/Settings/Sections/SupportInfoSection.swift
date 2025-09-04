//
//  SupportInfoSection.swift
//  Routine Anchor
//
//  Support and info section for Settings view
//
import SwiftUI

struct SupportInfoSection: View {
    @Environment(\.themeManager) private var themeManager
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
            color: themeManager?.currentTheme.colorScheme.creativeSecondary.color ?? Theme.defaultTheme.colorScheme.creativeSecondary.color
        ) {
            VStack(spacing: 16) {
                // Help & FAQ button
                SettingsButton(
                    title: "Help & FAQ",
                    subtitle: "Get answers to common questions",
                    icon: "questionmark.circle",
                    color: themeManager?.currentTheme.colorScheme.workflowPrimary.color ?? Theme.defaultTheme.colorScheme.workflowPrimary.color,
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
                    color: themeManager?.currentTheme.colorScheme.organizationAccent.color ?? Theme.defaultTheme.colorScheme.organizationAccent.color,
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
                    color: themeManager?.currentTheme.colorScheme.warningColor.color ?? Theme.defaultTheme.colorScheme.warningColor.color,
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
                    color: themeManager?.currentTheme.colorScheme.actionSuccess.color ?? Theme.defaultTheme.colorScheme.actionSuccess.color,
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
                .fill(themeManager?.currentTheme.colorScheme.uiElementSecondary.color ?? Theme.defaultTheme.colorScheme.uiElementSecondary.color)
                .frame(height: 1)
            
            Text("SUPPORT")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(themeManager?.currentTheme.secondaryTextColor ?? Theme.defaultTheme.secondaryTextColor)
                .tracking(1)
            
            Rectangle()
                .fill(themeManager?.currentTheme.colorScheme.uiElementSecondary.color ?? Theme.defaultTheme.colorScheme.uiElementSecondary.color)
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
                    .foregroundStyle(themeManager?.currentTheme.colorScheme.warningColor.color ?? Theme.defaultTheme.colorScheme.warningColor.color)
                
                Text("Quick Tips")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(themeManager?.currentTheme.primaryTextColor ?? Theme.defaultTheme.primaryTextColor)
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
                .fill(themeManager?.currentTheme.colorScheme.creativeSecondary.color ?? Theme.defaultTheme.colorScheme.creativeSecondary.color.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(themeManager?.currentTheme.colorScheme.creativeSecondary.color ?? Theme.defaultTheme.colorScheme.creativeSecondary.color.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Quick Tip Component
struct SupportingInfoQuickTip: View {
    @Environment(\.themeManager) private var themeManager
    let number: String
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text(number)
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(themeManager?.currentTheme.colorScheme.creativeSecondary.color ?? Theme.defaultTheme.colorScheme.creativeSecondary.color)
                .frame(width: 16, height: 16)
                .background(
                    Circle()
                        .fill(themeManager?.currentTheme.colorScheme.creativeSecondary.color ?? Theme.defaultTheme.colorScheme.creativeSecondary.color.opacity(0.2))
                )
            
            Text(text)
                .font(.system(size: 11, weight: .regular))
                .foregroundStyle(themeManager?.currentTheme.secondaryTextColor ?? Theme.defaultTheme.secondaryTextColor)
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
