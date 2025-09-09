//
//  WelcomeView.swift
//  Routine Anchor
//

import SwiftUI

// MARK: - Welcome View
struct WelcomeView: View {
    let onContinue: () -> Void

    @Environment(\.themeManager) private var themeManager
    @State private var appearAnimation = false
    @State private var floatingAnimation = false

    private var theme: AppTheme { themeManager?.currentTheme ?? PredefinedThemes.classic }

    var body: some View {
        ZStack {
            ThemedAnimatedBackground().ignoresSafeArea()

            GeometryReader { geometry in
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        Spacer().frame(height: max(geometry.safeAreaInsets.top, 20))

                        VStack(spacing: 24) {
                            // Logo / hero animation
                            ZStack {
                                Circle()
                                    .fill(
                                        RadialGradient(
                                            colors: [theme.accentPrimaryColor.opacity(0.55),
                                                     theme.accentPrimaryColor.opacity(0.25),
                                                     .clear],
                                            center: .center, startRadius: 30, endRadius: 120
                                        )
                                    )
                                    .frame(width: 160, height: 160)
                                    .blur(radius: 30)
                                    .scaleEffect(appearAnimation ? 1.25 : 0.85)

                                Circle()
                                    .fill(
                                        RadialGradient(
                                            colors: [theme.accentSecondaryColor.opacity(0.4), .clear],
                                            center: .center, startRadius: 20, endRadius: 90
                                        )
                                    )
                                    .frame(width: 160, height: 160)
                                    .blur(radius: 22)
                                    .scaleEffect(appearAnimation ? 1.08 : 0.92)

                                Image(systemName: "target")
                                    .font(.system(size: 92, weight: .thin))
                                    .foregroundStyle(
                                        LinearGradient(colors: [theme.accentPrimaryColor, theme.accentSecondaryColor],
                                                       startPoint: .topLeading, endPoint: .bottomTrailing)
                                    )
                                    .rotation3DEffect(.degrees(floatingAnimation ? 10 : -10), axis: (x: 0, y: 1, z: 0))
                                    .shadow(color: theme.accentPrimaryColor.opacity(0.45), radius: 30, x: 0, y: 15)
                            }
                            .scaleEffect(appearAnimation ? 1 : 0.5)
                            .opacity(appearAnimation ? 1 : 0)

                            // Titles
                            VStack(spacing: 12) {
                                Text("Welcome to")
                                    .font(.system(size: 26, weight: .medium, design: .rounded))
                                    .foregroundStyle(theme.primaryTextColor.opacity(0.85))

                                Text("Routine Anchor")
                                    .font(.system(size: 46, weight: .bold, design: .rounded))
                                    .foregroundStyle(
                                        LinearGradient(colors: [theme.accentPrimaryColor, theme.accentSecondaryColor],
                                                       startPoint: .leading, endPoint: .trailing)
                                    )

                                Text("Transform your daily chaos into\npeaceful productivity")
                                    .font(.system(size: 20, weight: .regular, design: .rounded))
                                    .foregroundStyle(theme.secondaryTextColor)
                                    .multilineTextAlignment(.center)
                                    .lineSpacing(6)
                            }
                            .opacity(appearAnimation ? 1 : 0)
                            .offset(y: appearAnimation ? 0 : 20)
                        }

                        Spacer(minLength: 28)

                        // Feature cards
                        VStack(spacing: 12) {
                            FeatureCard(
                                icon: "bell.badge",
                                title: "Smart Reminders",
                                description: "AI-powered notifications that adapt to your rhythm",
                                tint: theme.accentPrimaryColor,
                                delay: 0.15
                            )
                            FeatureCard(
                                icon: "chart.line.uptrend.xyaxis",
                                title: "Visual Progress",
                                description: "Beautiful insights that motivate you daily",
                                tint: theme.accentSecondaryColor,
                                delay: 0.25
                            )
                            FeatureCard(
                                icon: "sparkles",
                                title: "Mindful Design",
                                description: "Crafted to reduce stress, not add to it",
                                tint: theme.statusInfoColor,
                                delay: 0.35
                            )
                        }
                        .padding(.horizontal, 28)

                        Spacer(minLength: 38)

                        // CTA
                        VStack(spacing: 20) {
                            DesignedButton(title: "Begin Your Journey") {
                                HapticManager.shared.mediumImpact()
                                onContinue()
                            }
                            Text("Join thousands building better habits")
                                .font(.system(size: 15, weight: .medium, design: .rounded))
                                .foregroundStyle(theme.subtleTextColor)
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 20)
                    }
                    .frame(minHeight: geometry.size.height)
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.05)) { appearAnimation = true }
            withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) { floatingAnimation = true }
        }
    }
}
