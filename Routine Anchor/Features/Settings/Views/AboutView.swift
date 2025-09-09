//
//  AboutView.swift
//  Routine Anchor
//

import SwiftUI

struct AboutView: View {
    @Environment(\.themeManager) private var themeManager
    @Environment(\.dismiss) private var dismiss
    @State private var animationPhase = 0
    @State private var animationTask: Task<Void, Never>?
    @State private var showingAcknowledgments = false

    // Shorthand to the active theme
    private var theme: AppTheme { themeManager?.currentTheme ?? PredefinedThemes.classic }

    var body: some View {
        ZStack {
            ThemedAnimatedBackground()
            AnimatedMeshBackground().opacity(0.3).allowsHitTesting(false)
            ParticleEffectView().allowsHitTesting(false)

            ScrollView {
                VStack(spacing: 32) {
                    headerSection
                    appInfoSection
                    missionSection
                    featuresSection
                    developerSection
                    legalSection
                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            animationTask = Task { @MainActor in
                while !Task.isCancelled {
                    withAnimation(.easeInOut(duration: 2)) { animationPhase = 1 }
                    try? await Task.sleep(nanoseconds: 2_000_000_000)
                }
            }
        }
        .onDisappear { animationTask?.cancel(); animationTask = nil }
        .sheet(isPresented: $showingAcknowledgments) {
            AcknowledgmentsView()
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 16) {
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(theme.primaryTextColor.opacity(0.85))
                        .frame(width: 32, height: 32)
                        .background(
                            Circle()
                                .fill(.ultraThinMaterial)
                                .background(
                                    Circle().fill(theme.color.surface.card.opacity(0.7))
                                )
                        )
                }
                Spacer()
            }

            VStack(spacing: 16) {
                // App "icon" preview
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            LinearGradient(
                                colors: [theme.accentPrimaryColor, theme.accentSecondaryColor],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 80, height: 80)
                        .scaleEffect(animationPhase == 0 ? 1.0 : 1.05)
                        .shadow(color: theme.accentPrimaryColor.opacity(0.35), radius: 20, x: 0, y: 10)

                    Image(systemName: "clock.badge.checkmark")
                        .font(.system(size: 32, weight: .medium))
                        .foregroundStyle(theme.textInverted)
                }
                .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: animationPhase)

                VStack(spacing: 8) {
                    Text("Routine Anchor")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(theme.primaryTextColor)

                    Text("Version \(appVersion)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(theme.secondaryTextColor)

                    Text("Time-Blocked Productivity")
                        .font(.system(size: 14))
                        .foregroundStyle(theme.secondaryTextColor)
                }
            }
        }
    }

    // MARK: - Sections

    private var appInfoSection: some View {
        InfoCard(
            icon: "info.circle",
            title: "About Routine Anchor",
            content: "Build consistent daily routines through time-blocking. Create structured schedules, track progress, and develop habits that stick.",
            color: theme.accentPrimaryColor
        )
    }

    private var missionSection: some View {
        InfoCard(
            icon: "target",
            title: "Our Mission",
            content: "Live intentionally. Routine Anchor helps you take control of your time, build meaningful habits, and align life with your values.",
            color: theme.statusSuccessColor
        )
    }

    private var featuresSection: some View {
        VStack(spacing: 16) {
            Text("What Makes Us Different")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(theme.primaryTextColor)

            VStack(spacing: 12) {
                FeatureRow(icon: "lock.shield", title: "Privacy First", description: "All data stays on device")
                FeatureRow(icon: "wifi.slash", title: "Works Offline", description: "No internet required")
                FeatureRow(icon: "paintbrush", title: "Thoughtful Design", description: "Clean, intuitive interface")
                FeatureRow(icon: "bolt", title: "Native Speed", description: "SwiftUI, built for iOS")
            }
        }
        .padding(20)
    }

    private var developerSection: some View {
        InfoCard(
            icon: "person.circle",
            title: "Made with ❤️",
            content: "Crafted by Christopher Simonson. Indie developer, productivity nerd, and lover of beautiful software.",
            color: theme.accentSecondaryColor
        )
    }

    private var legalSection: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                Button(action: { showingAcknowledgments = true }) {
                    ActionButton(icon: "hand.thumbsup", title: "Acknowledgments", subtitle: "Open source libraries")
                }

                Button(action: writeReview) {
                    ActionButton(icon: "star", title: "Rate the App", subtitle: "Support development")
                }
            }

            Button(action: shareApp) {
                HStack(spacing: 8) {
                    Image(systemName: "square.and.arrow.up")
                    Text("Share Routine Anchor").font(.system(size: 15, weight: .medium))
                }
                .foregroundStyle(theme.textInverted)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(
                    LinearGradient(colors: [theme.accentPrimaryColor, theme.accentSecondaryColor],
                                   startPoint: .leading, endPoint: .trailing)
                )
                .cornerRadius(12)
                .shadow(color: theme.accentPrimaryColor.opacity(0.3), radius: 8, x: 0, y: 4)
            }

            Text("© 2025 Simo's Media & Tech, LLC. All rights reserved.")
                .font(.system(size: 12))
                .foregroundStyle(theme.subtleTextColor)
                .multilineTextAlignment(.center)
                .padding(.top, 8)
        }
    }

    // MARK: - Helpers

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    private func writeReview() {
        HapticManager.shared.lightImpact()
        if let url = URL(string: "https://apps.apple.com/") { UIApplication.shared.open(url) }
    }

    private func shareApp() {
        HapticManager.shared.lightImpact()
        let text = "Check out Routine Anchor — a beautiful time-blocking app!"
        let url = URL(string: "https://routineanchor.com")!
        let vc = UIActivityViewController(activityItems: [text, url], applicationActivities: nil)
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = scene.windows.first {
            window.rootViewController?.present(vc, animated: true)
        }
    }
}

// MARK: - Supporting Components

private struct InfoCard: View {
    @Environment(\.themeManager) private var themeManager
    let icon: String
    let title: String
    let content: String
    let color: Color

    private var theme: AppTheme { themeManager?.currentTheme ?? PredefinedThemes.classic }
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
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(theme.primaryTextColor)

                Spacer()
            }

            Text(content)
                .font(.system(size: 14))
                .foregroundStyle(theme.secondaryTextColor)
                .lineSpacing(2)
        }
        .padding(20)
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : 20)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
                isVisible = true
            }
        }
    }
}

private struct ActionButton: View {
    @Environment(\.themeManager) private var themeManager
    let icon: String
    let title: String
    let subtitle: String

    private var theme: AppTheme { themeManager?.currentTheme ?? PredefinedThemes.classic }

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .medium))
                .foregroundStyle(theme.accentPrimaryColor)

            VStack(spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(theme.primaryTextColor)

                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundStyle(theme.secondaryTextColor)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(theme.color.surface.card.opacity(0.7))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(theme.borderColor, lineWidth: 1)
        )
    }
}

// MARK: - Acknowledgments

private struct AcknowledgmentsView: View {
    @Environment(\.themeManager) private var themeManager
    @Environment(\.dismiss) private var dismiss
    private var theme: AppTheme { themeManager?.currentTheme ?? PredefinedThemes.classic }

    var body: some View {
        NavigationView {
            List {
                Section {
                    Text("Routine Anchor is built with the help of amazing open source libraries and tools.")
                        .foregroundStyle(theme.secondaryTextColor)
                        .listRowBackground(Color.clear)
                }
                Section("Dependencies") {
                    AcknowledgmentRow(name: "SwiftUI", description: "Apple’s modern UI framework")
                    AcknowledgmentRow(name: "SwiftData", description: "Local data persistence")
                }
            }
            .navigationTitle("Acknowledgments")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) { Button("Done") { dismiss() } }
            }
        }
    }
}

private struct AcknowledgmentRow: View {
    @Environment(\.themeManager) private var themeManager
    let name: String
    let description: String
    private var theme: AppTheme { themeManager?.currentTheme ?? PredefinedThemes.classic }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(name).font(.system(size: 14, weight: .semibold))
            Text(description).font(.system(size: 12)).foregroundStyle(theme.secondaryTextColor)
        }
        .padding(.vertical, 2)
    }
}

#Preview { AboutView() }
