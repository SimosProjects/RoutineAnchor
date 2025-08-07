//
//  AboutView.swift
//  Routine Anchor
//  Swift 6 Compatible Version
//
//  Created by Christopher Simonson on 7/21/25.
//
import SwiftUI

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var animationPhase = 0
    // REMOVED: @State private var particleSystem = ParticleSystem()
    @State private var showingAcknowledgments = false
    
    var body: some View {
        ZStack {
            // Premium animated background
            AnimatedGradientBackground()
            AnimatedMeshBackground()
                .opacity(0.3)
                .allowsHitTesting(false)
            // CHANGED: Now using self-contained ParticleEffectView
            ParticleEffectView()
                .allowsHitTesting(false)
            
            ScrollView {
                VStack(spacing: 32) {
                    // Header
                    headerSection
                    
                    // App info
                    appInfoSection
                    
                    // Mission statement
                    missionSection
                    
                    // Features
                    featuresSection
                    
                    // Developer section
                    developerSection
                    
                    // Legal & acknowledgments
                    legalSection
                    
                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            // REMOVED: particleSystem.startEmitting()
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                animationPhase = 1  // CHANGED: Set to 1 instead of += 1
            }
        }
        .sheet(isPresented: $showingAcknowledgments) {
            AcknowledgmentsView()
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 16) {
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.8))
                        .frame(width: 32, height: 32)
                        .background(
                            Circle()
                                .fill(.ultraThinMaterial)
                                .background(
                                    Circle().fill(Color.white.opacity(0.1))
                                )
                        )
                }
                
                Spacer()
            }
            
            VStack(spacing: 16) {
                // App icon
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            LinearGradient(
                                colors: [Color.premiumBlue, Color.premiumPurple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 80, height: 80)
                        .scaleEffect(animationPhase == 0 ? 1.0 : 1.05)
                        .shadow(color: Color.premiumBlue.opacity(0.4), radius: 20, x: 0, y: 10)
                    
                    Image(systemName: "clock.badge.checkmark")
                        .font(.system(size: 32, weight: .medium))
                        .foregroundStyle(.white)
                }
                .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: animationPhase)
                
                VStack(spacing: 8) {
                    Text("Routine Anchor")
                        .font(TypographyConstants.Headers.welcome)
                        .foregroundStyle(Color.premiumTextPrimary)
                    
                    Text("Version \(appVersion)")
                        .font(TypographyConstants.Body.secondary)
                        .foregroundStyle(Color.premiumTextSecondary)
                    
                    Text("Time-Blocked Productivity")
                        .font(TypographyConstants.Body.description)
                        .foregroundStyle(Color.premiumTextSecondary)
                }
            }
        }
    }
    
    // MARK: - App Info Section
    private var appInfoSection: some View {
        InfoCard(
            icon: "info.circle",
            title: "About Routine Anchor",
            content: "Routine Anchor helps you build consistent daily routines through time-blocking. Create structured schedules, track your progress, and develop productive habits that stick.",
            color: Color.premiumBlue
        )
    }
    
    // MARK: - Mission Section
    private var missionSection: some View {
        InfoCard(
            icon: "target",
            title: "Our Mission",
            content: "We believe everyone deserves to live intentionally. Routine Anchor empowers you to take control of your time, build meaningful habits, and create a life aligned with your values.",
            color: Color.premiumGreen
        )
    }
    
    // MARK: - Features Section
    private var featuresSection: some View {
        VStack(spacing: 16) {
            Text("What Makes Us Different")
                .font(TypographyConstants.Headers.cardTitle)
                .foregroundStyle(Color.premiumTextPrimary)
            
            VStack(spacing: 12) {
                FeatureRow(icon: "lock.shield", title: "Privacy First", description: "All data stays on your device")
                FeatureRow(icon: "wifi.slash", title: "Works Offline", description: "No internet required")
                FeatureRow(icon: "paintbrush", title: "Beautifully Designed", description: "Thoughtful, intuitive interface")
                FeatureRow(icon: "bolt", title: "Lightning Fast", description: "Native performance")
            }
        }
        .padding(20)
        .glassMorphism()
    }
    
    // MARK: - Developer Section
    private var developerSection: some View {
        InfoCard(
            icon: "person.circle",
            title: "Made with ❤️",
            content: "Routine Anchor is crafted by Christopher Simonson, an indie developer passionate about productivity and beautiful software. Built with SwiftUI for iOS.",
            color: Color.premiumPurple
        )
    }
    
    // MARK: - Legal Section
    private var legalSection: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                Button(action: { showingAcknowledgments = true }) {
                    ActionButton(
                        icon: "hand.thumbsup",
                        title: "Acknowledgments",
                        subtitle: "Open source libraries"
                    )
                }
                
                Button(action: writeReview) {
                    ActionButton(
                        icon: "star",
                        title: "Rate the App",
                        subtitle: "Support development"
                    )
                }
            }
            
            Button(action: shareApp) {
                HStack(spacing: 8) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 16, weight: .medium))
                    
                    Text("Share Routine Anchor")
                        .font(TypographyConstants.UI.button)
                        .fontWeight(.medium)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(
                    LinearGradient(
                        colors: [Color.premiumBlue, Color.premiumPurple],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
                .shadow(color: Color.premiumBlue.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            
            Text("© 2025 Simo's Media & Tech, LLC. All rights reserved.")
                .font(TypographyConstants.UI.caption)
                .foregroundStyle(Color.premiumTextTertiary)
                .multilineTextAlignment(.center)
                .padding(.top, 8)
        }
    }
    
    // MARK: - Computed Properties
    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
    
    // MARK: - Actions
    private func writeReview() {
        HapticManager.shared.lightImpact()
        // Open App Store (temporary URL until app is live)
        if let url = URL(string: "https://apps.apple.com/") {
            UIApplication.shared.open(url)
        }
    }

    private func shareApp() {
        HapticManager.shared.lightImpact()
        
        let shareText = "Check out Routine Anchor - a beautiful time-blocking app that helps you build consistent routines!"
        // Use website URL until app is live on App Store
        let appURL = URL(string: "https://routineanchor.com")!
        
        let activityVC = UIActivityViewController(
            activityItems: [shareText, appURL],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(activityVC, animated: true)
        }
    }
}

// MARK: - Supporting Components

struct InfoCard: View {
    let icon: String
    let title: String
    let content: String
    let color: Color
    
    @State private var isVisible = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(color)
                    .frame(width: 32, height: 32)
                    .background(color.opacity(0.15))
                    .cornerRadius(8)
                
                Text(title)
                    .font(TypographyConstants.Headers.cardTitle)
                    .foregroundStyle(Color.premiumTextPrimary)
                
                Spacer()
            }
            
            Text(content)
                .font(TypographyConstants.Body.secondary)
                .foregroundStyle(Color.premiumTextSecondary)
                .lineSpacing(2)
        }
        .padding(20)
        .glassMorphism()
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : 20)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
                isVisible = true
            }
        }
    }
}

struct ActionButton: View {
    let icon: String
    let title: String
    let subtitle: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .medium))
                .foregroundStyle(Color.premiumBlue)
            
            VStack(spacing: 2) {
                Text(title)
                    .font(TypographyConstants.Body.emphasized)
                    .foregroundStyle(Color.premiumTextPrimary)
                
                Text(subtitle)
                    .font(TypographyConstants.UI.caption)
                    .foregroundStyle(Color.premiumTextSecondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(Color.cardBackground)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.separatorColor, lineWidth: 1)
        )
    }
}

// MARK: - Acknowledgments View
struct AcknowledgmentsView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    Text("Routine Anchor is built with the help of amazing open source libraries and tools.")
                        .font(TypographyConstants.Body.secondary)
                        .foregroundStyle(Color.premiumTextSecondary)
                        .listRowBackground(Color.clear)
                }
                
                Section("Dependencies") {
                    AcknowledgmentRow(name: "SwiftUI", description: "Apple's modern UI framework")
                    AcknowledgmentRow(name: "SwiftData", description: "Local data persistence")
                    // Add more dependencies as needed
                }
            }
            .navigationTitle("Acknowledgments")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct AcknowledgmentRow: View {
    let name: String
    let description: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(name)
                .font(TypographyConstants.Body.emphasized)
            Text(description)
                .font(TypographyConstants.UI.caption)
                .foregroundStyle(Color.premiumTextSecondary)
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Preview
#Preview {
    AboutView()
}
