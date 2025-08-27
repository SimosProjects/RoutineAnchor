//
//  WelcomeView.swift
//  Routine Anchor
//
//  Created by Christopher Simonson on 7/19/25.
//
import SwiftUI
import UserNotifications

// MARK: - Welcome View
struct WelcomeView: View {
    let onContinue: () -> Void
    @Environment(\.themeManager) private var themeManager
    @State private var appearAnimation = false
    @State private var floatingAnimation = false

    var body: some View {
        GeometryReader { geometry in
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    Spacer().frame(height: max(geometry.safeAreaInsets.top, 20))

                    VStack(spacing: 24) {
                        // Logo animation
                        ZStack {
                            Circle()
                                .fill(
                                    RadialGradient(
                                        gradient: Gradient(colors: [
                                            Color(red: 0.4, green: 0.6, blue: 1.0).opacity(0.6),
                                            Color(red: 0.4, green: 0.6, blue: 1.0).opacity(0.3),
                                            Color.clear
                                        ]),
                                        center: .center,
                                        startRadius: 30,
                                        endRadius: 120
                                    )
                                )
                                .frame(width: 160, height: 160)
                                .blur(radius: 30)
                                .scaleEffect(appearAnimation ? 1.3 : 0.8)

                            Circle()
                                .fill(
                                    RadialGradient(
                                        gradient: Gradient(colors: [
                                            Color(red: 0.6, green: 0.4, blue: 1.0).opacity(0.4),
                                            Color.clear
                                        ]),
                                        center: .center,
                                        startRadius: 20,
                                        endRadius: 80
                                    )
                                )
                                .frame(width: 160, height: 160)
                                .blur(radius: 20)
                                .scaleEffect(appearAnimation ? 1.1 : 0.9)

                            Image(systemName: "target")
                                .font(.system(size: 90, weight: .thin))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Color(red: 0.6, green: 0.8, blue: 1.0), Color(red: 0.8, green: 0.6, blue: 1.0)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .symbolRenderingMode(.hierarchical)
                                .rotation3DEffect(
                                    .degrees(floatingAnimation ? 10 : -10),
                                    axis: (x: 0, y: 1, z: 0)
                                )
                                .shadow(color: Color(red: 0.4, green: 0.6, blue: 1.0).opacity(0.5), radius: 30, x: 0, y: 15)
                        }
                        .scaleEffect(appearAnimation ? 1 : 0.5)
                        .opacity(appearAnimation ? 1 : 0)

                        // Title section
                        VStack(spacing: 12) {
                            Text("Welcome to")
                                .font(.system(size: 26, weight: .medium, design: .rounded))
                                .foregroundStyle(Color.white.opacity(0.8))
                                .opacity(appearAnimation ? 1 : 0)
                                .offset(y: appearAnimation ? 0 : 20)

                            Text("Routine Anchor")
                                .font(.system(size: 46, weight: .bold, design: .rounded))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Color(red: 0.4, green: 0.6, blue: 1.0), Color(red: 0.6, green: 0.4, blue: 1.0)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .opacity(appearAnimation ? 1 : 0)
                                .offset(y: appearAnimation ? 0 : 20)

                            Text("Transform your daily chaos into\npeaceful productivity")
                                .font(.system(size: 20, weight: .regular, design: .rounded))
                                .foregroundStyle(themeManager?.currentTheme.textSecondaryColor ??
                                                 Theme.defaultTheme.textSecondaryColor)
                                .multilineTextAlignment(.center)
                                .lineSpacing(6)
                                .opacity(appearAnimation ? 1 : 0)
                                .offset(y: appearAnimation ? 0 : 20)
                        }
                    }

                    Spacer(minLength: 30)

                    // Feature cards with reduced height
                    VStack(spacing: 12) {
                        FeatureCard(
                            icon: "bell.badge",
                            title: "Smart Reminders",
                            description: "AI-powered notifications that adapt to your rhythm",
                            delay: 0.2
                        )

                        FeatureCard(
                            icon: "chart.line.uptrend.xyaxis",
                            title: "Visual Progress",
                            description: "Beautiful insights that motivate you daily",
                            delay: 0.3
                        )

                        FeatureCard(
                            icon: "sparkles",
                            title: "Mindful Design",
                            description: "Crafted to reduce stress, not add to it",
                            delay: 0.4
                        )
                    }
                    .padding(.horizontal, 28)

                    Spacer(minLength: 40)

                    // CTA section
                    VStack(spacing: 24) {
                        DesignedButton(
                            title: "Begin Your Journey",
                            action: {
                                HapticManager.shared.mediumImpact()
                                onContinue()
                            }
                        )

                        Text("Join 100,000+ people building better habits")
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .foregroundStyle(themeManager?.currentTheme.textTertiaryColor ??
                                             Theme.defaultTheme.textTertiaryColor)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 20)
                }
                .frame(minHeight: geometry.size.height)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.1)) {
                appearAnimation = true
            }
            withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                floatingAnimation = true
            }
        }
    }
}
