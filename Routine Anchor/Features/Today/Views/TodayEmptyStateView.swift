//
//  TodayEmptyStateView.swift
//  Routine Anchor
//
//  Empty state for Today. Uses hero illustration + benefits + primary/secondary actions,
//  updated to new Theme tokens.
//

import SwiftUI

struct TodayEmptyStateView: View {
    let onCreateRoutine: () -> Void
    let onUseTemplate: () -> Void

    @Environment(\.themeManager) private var themeManager

    // Animations
    @State private var appearAnimation = false
    @State private var floatingOffset: CGFloat = 0
    @State private var sparkleOpacity: Double = 0
    @State private var pulseScale: CGFloat = 1.0

    private var theme: AppTheme { themeManager?.currentTheme ?? PredefinedThemes.classic }

    var body: some View {
        GeometryReader { geometry in
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    Spacer().frame(height: max(geometry.safeAreaInsets.top, 80))

                    // MARK: Hero illustration
                    ZStack {
                        FloatingParticlesView() // uses current theme colors internally (see below)
                            .opacity(sparkleOpacity)

                        ZStack {
                            // Soft background glow using semantic accents
                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: [theme.accentPrimaryColor.opacity(0.40),
                                                 theme.accentSecondaryColor.opacity(0.20),
                                                 .clear],
                                        center: .center, startRadius: 50, endRadius: 150
                                    )
                                )
                                .frame(width: 200, height: 200)
                                .blur(radius: 30)
                                .scaleEffect(pulseScale)

                            CalendarIllustrationView()
                                .scaleEffect(appearAnimation ? 1 : 0.8)
                                .offset(y: floatingOffset)
                        }
                    }
                    .frame(height: 200)
                    .padding(.bottom, 40)

                    // MARK: Content section
                    VStack(spacing: 24) {
                        VStack(spacing: 16) {
                            Text("Ready to Start?")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundStyle(theme.actionPrimaryGradient)
                                .opacity(appearAnimation ? 1 : 0)
                                .offset(y: appearAnimation ? 0 : 20)

                            Text("Transform your day with intentional time blocks that keep you focused and productive")
                                .font(.system(size: 18, weight: .regular, design: .rounded))
                                .foregroundStyle(theme.secondaryTextColor)
                                .multilineTextAlignment(.center)
                                .lineSpacing(4)
                                .padding(.horizontal, 20)
                                .opacity(appearAnimation ? 1 : 0)
                                .offset(y: appearAnimation ? 0 : 20)
                        }

                        // Benefits (kept lightweight)
                        VStack(spacing: 16) {
                            BenefitCard(
                                icon: "brain.head.profile",
                                title: "Focused Mind",
                                description: "Clear time boundaries eliminate decision fatigue",
                                color: theme.accentPrimaryColor,
                                delay: 0.2
                            )
                            BenefitCard(
                                icon: "chart.line.uptrend.xyaxis",
                                title: "Visible Progress",
                                description: "Watch your consistency build momentum",
                                color: theme.statusSuccessColor,
                                delay: 0.3
                            )
                            BenefitCard(
                                icon: "heart.fill",
                                title: "Balanced Life",
                                description: "Protect time for what matters most",
                                color: theme.accentSecondaryColor,
                                delay: 0.4
                            )
                        }
                        .padding(.horizontal, 24)
                    }

                    Spacer(minLength: 60)

                    // MARK: Actions
                    VStack(spacing: 16) {
                        // Primary gradient CTA
                        Button {
                            HapticManager.shared.anchorSuccess()
                            onCreateRoutine()
                        } label: {
                            Text("Create My First Routine")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundStyle(theme.invertedTextColor)
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .background(
                                    RoundedRectangle(cornerRadius: 16).fill(theme.actionPrimaryGradient)
                                )
                        }

                        // Secondary “glass” CTA
                        SecondaryActionButton(
                            title: "Browse Templates",
                            icon: "sparkles",
                            action: {
                                HapticManager.shared.impact()
                                onUseTemplate()
                            }
                        )

                        // Gentle encouragement
                        VStack(spacing: 8) {
                            Text("✨ Start small, think big")
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundStyle(theme.secondaryTextColor)

                            Text("Most people begin with just 3–4 time blocks")
                                .font(.system(size: 12, weight: .regular))
                                .foregroundStyle(theme.subtleTextColor)
                        }
                        .opacity(appearAnimation ? 1 : 0)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
                .frame(minHeight: geometry.size.height)
            }
        }
        .onAppear { startAnimations() }
    }

    private func startAnimations() {
        withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.1)) { appearAnimation = true }
        withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) { floatingOffset = -10 }
        withAnimation(.easeInOut(duration: 2).delay(0.5)) { sparkleOpacity = 1 }
        withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) { pulseScale = 1.3 }
    }
}

// MARK: - Calendar Illustration

struct CalendarIllustrationView: View {
    @Environment(\.themeManager) private var themeManager
    private var theme: AppTheme { themeManager?.currentTheme ?? PredefinedThemes.classic }

    @State private var blockAnimations: [Bool] = Array(repeating: false, count: 4)

    var body: some View {
        ZStack {
            // “Glassy” calendar base
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .background(
                    RoundedRectangle(cornerRadius: 20).fill(
                        LinearGradient(
                            colors: [
                                theme.surfaceGlassColor.opacity(0.15),
                                theme.surfaceGlassColor.opacity(0.05)
                            ],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )
                )
                .frame(width: 140, height: 160)
                .overlay(
                    RoundedRectangle(cornerRadius: 20).stroke(
                        LinearGradient(
                            colors: [theme.borderColor.opacity(0.3), theme.borderColor.opacity(0.1)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
                )
                .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)

            VStack(spacing: 12) {
                // Top dots
                HStack(spacing: 8) {
                    ForEach(0..<3) { _ in
                        Circle()
                            .fill(theme.accentPrimaryColor.opacity(0.6))
                            .frame(width: 6, height: 6)
                    }
                }
                .padding(.top, 20)

                Spacer()

                // Animated time blocks
                VStack(spacing: 6) {
                    ForEach(0..<4, id: \.self) { index in
                        TimeBlockPreview(
                            color: blockColors[index],
                            width: blockWidths[index],
                            isAnimated: blockAnimations[index]
                        )
                    }
                }
                .padding(.bottom, 20)
            }
        }
        .onAppear {
            for index in 0..<4 {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(Double(index) * 0.2 + 0.8)) {
                    blockAnimations[index] = true
                }
            }
        }
    }

    private var blockColors: [Color] {
        [theme.accentPrimaryColor, theme.statusSuccessColor, theme.accentSecondaryColor, theme.accentPrimaryColor]
    }

    private let blockWidths: [CGFloat] = [80, 60, 90, 70]
}

// Small gradient pill used in the illustration.
struct TimeBlockPreview: View {
    let color: Color
    let width: CGFloat
    let isAnimated: Bool

    var body: some View {
        RoundedRectangle(cornerRadius: 6)
            .fill(LinearGradient(colors: [color, color.opacity(0.7)], startPoint: .leading, endPoint: .trailing))
            .frame(width: isAnimated ? width : 20, height: 12)
            .animation(.spring(response: 0.8, dampingFraction: 0.7), value: isAnimated)
    }
}

// MARK: - Floating Particles (theme-aware)

struct FloatingParticlesView: View {
    @Environment(\.themeManager) private var themeManager
    @State private var particles: [FloatingParticle] = []
    @State private var animationTick = 0

    private var theme: AppTheme { themeManager?.currentTheme ?? PredefinedThemes.classic }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(particles) { particle in
                    Circle()
                        .fill(particle.color.opacity(particle.opacity))
                        .frame(width: particle.size, height: particle.size)
                        .position(particle.position)
                        .blur(radius: 1)
                }
            }
            .onAppear {
                createParticles(in: geometry.size)
                startFloatingAnimation()
            }
            .onChange(of: animationTick) { _, _ in
                updateParticles(in: geometry.size)
            }
        }
    }

    private func createParticles(in size: CGSize) {
        let themeColors = [theme.accentPrimaryColor, theme.accentSecondaryColor, theme.statusSuccessColor]
        for _ in 0..<15 {
            particles.append(FloatingParticle(screenSize: size, themeColors: themeColors))
        }
    }

    private func startFloatingAnimation() {
        withAnimation(.linear(duration: 0.1).repeatForever(autoreverses: false)) {
            animationTick = 1
        }
    }

    private func updateParticles(in size: CGSize) {
        for index in particles.indices {
            particles[index].position.y -= particles[index].speed
            particles[index].position.x += sin(particles[index].position.y * 0.01) * 0.5

            if particles[index].position.y < -50 {
                particles[index].position.y = size.height + 50
                particles[index].position.x = CGFloat.random(in: 0...size.width)
            }
        }
    }
}

struct FloatingParticle: Identifiable, Sendable {
    let id = UUID()
    var position: CGPoint
    let color: Color
    let size: CGFloat
    let speed: CGFloat
    let opacity: Double

    init(screenSize: CGSize, themeColors: [Color]) {
        self.position = CGPoint(x: .random(in: 0...screenSize.width), y: .random(in: 0...screenSize.height))
        self.color = themeColors.randomElement() ?? .white
        self.size = .random(in: 2...4)
        self.speed = .random(in: 0.2...0.8)
        self.opacity = .random(in: 0.3...0.7)
    }
}

// MARK: - Benefit Card

struct BenefitCard: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    let delay: Double

    @Environment(\.themeManager) private var themeManager
    private var theme: AppTheme { themeManager?.currentTheme ?? PredefinedThemes.classic }

    @State private var isVisible = false

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle().fill(color.opacity(0.2)).frame(width: 48, height: 48)
                Image(systemName: icon).font(.system(size: 20, weight: .medium)).foregroundStyle(color)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(theme.primaryTextColor)

                Text(description)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(theme.secondaryTextColor)
                    .lineLimit(2)
            }

            Spacer()
        }
        .padding(16)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 16).fill(theme.surfaceCardColor.opacity(0.95))
                RoundedRectangle(cornerRadius: 16).fill(theme.glassMaterialOverlay)
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16).stroke(theme.borderColor.opacity(0.6), lineWidth: 1)
        )
        .shadow(color: color.opacity(0.2), radius: 8, x: 0, y: 4)
        .opacity(isVisible ? 1 : 0)
        .offset(x: isVisible ? 0 : -20)
        .scaleEffect(isVisible ? 1 : 0.95)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(delay)) { isVisible = true }
        }
    }
}

// MARK: - Secondary Action Button

struct SecondaryActionButton: View {
    @Environment(\.themeManager) private var themeManager
    let title: String
    let icon: String
    let action: () -> Void

    @State private var isPressed = false
    private var theme: AppTheme { themeManager?.currentTheme ?? PredefinedThemes.classic }

    var body: some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { isPressed = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { isPressed = false }
                action()
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: icon).font(.system(size: 16, weight: .medium))
                Text(title).font(.system(size: 16, weight: .medium, design: .rounded))
            }
            .foregroundStyle(theme.secondaryTextColor)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 16).fill(theme.surfaceCardColor.opacity(0.95))
                    RoundedRectangle(cornerRadius: 16).fill(theme.glassMaterialOverlay)
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16).stroke(theme.borderColor.opacity(0.6), lineWidth: 1)
            )
            .scaleEffect(isPressed ? 0.98 : 1)
            .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
        }
    }
}
