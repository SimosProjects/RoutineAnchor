//
//  TodayEmptyStateView.swift
//  Routine Anchor
//
import SwiftUI

struct TodayEmptyStateView: View {
    let onCreateRoutine: () -> Void
    let onUseTemplate: () -> Void
    
    @Environment(\.themeManager) private var themeManager
    @State private var appearAnimation = false
    @State private var floatingOffset: CGFloat = 0
    @State private var sparkleOpacity: Double = 0
    @State private var pulseScale: CGFloat = 1.0
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    Spacer().frame(height: max(geometry.safeAreaInsets.top, 80))
                    
                    // Hero illustration
                    ZStack {
                        // Floating particles
                        FloatingParticlesView()
                            .opacity(sparkleOpacity)
                        
                        // Main illustration
                        ZStack {
                            // Glow effect
                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: [
                                            themeManager?.currentTheme.colorScheme.blue.color ?? Theme.defaultTheme.colorScheme.blue.color.opacity(0.4),
                                            themeManager?.currentTheme.colorScheme.purple.color ?? Theme.defaultTheme.colorScheme.purple.color.opacity(0.2),
                                            Color.clear
                                        ],
                                        center: .center,
                                        startRadius: 50,
                                        endRadius: 150
                                    )
                                )
                                .frame(width: 200, height: 200)
                                .blur(radius: 30)
                                .scaleEffect(pulseScale)
                            
                            // Calendar icon with time blocks
                            CalendarIllustrationView()
                                .scaleEffect(appearAnimation ? 1 : 0.8)
                                .offset(y: floatingOffset)
                        }
                    }
                    .frame(height: 200)
                    .padding(.bottom, 40)
                    
                    // Content section
                    VStack(spacing: 24) {
                        // Title and description
                        VStack(spacing: 16) {
                            Text("Ready to Start?")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [themeManager?.currentTheme.colorScheme.blue.color ?? Theme.defaultTheme.colorScheme.blue.color, themeManager?.currentTheme.colorScheme.purple.color ?? Theme.defaultTheme.colorScheme.purple.color],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .opacity(appearAnimation ? 1 : 0)
                                .offset(y: appearAnimation ? 0 : 20)
                            
                            Text("Transform your day with intentional time blocks that keep you focused and productive")
                                .font(.system(size: 18, weight: .regular, design: .rounded))
                                .foregroundStyle(themeManager?.currentTheme.textSecondaryColor ?? Theme.defaultTheme.textSecondaryColor)
                                .multilineTextAlignment(.center)
                                .lineSpacing(4)
                                .padding(.horizontal, 20)
                                .opacity(appearAnimation ? 1 : 0)
                                .offset(y: appearAnimation ? 0 : 20)
                        }
                        
                        // Benefits section
                        VStack(spacing: 16) {
                            BenefitCard(
                                icon: "brain.head.profile",
                                title: "Focused Mind",
                                description: "Clear time boundaries eliminate decision fatigue",
                                color: themeManager?.currentTheme.colorScheme.blue.color ?? Theme.defaultTheme.colorScheme.blue.color,
                                delay: 0.2
                            )
                            
                            BenefitCard(
                                icon: "chart.line.uptrend.xyaxis",
                                title: "Visible Progress",
                                description: "Watch your consistency build momentum",
                                color: themeManager?.currentTheme.colorScheme.green.color ?? Theme.defaultTheme.colorScheme.green.color,
                                delay: 0.3
                            )
                            
                            BenefitCard(
                                icon: "heart.fill",
                                title: "Balanced Life",
                                description: "Protect time for what matters most",
                                color: themeManager?.currentTheme.colorScheme.purple.color ?? Theme.defaultTheme.colorScheme.purple.color,
                                delay: 0.4
                            )
                        }
                        .padding(.horizontal, 24)
                    }
                    
                    Spacer(minLength: 60)
                    
                    // Action buttons
                    VStack(spacing: 16) {
                        DesignedButton(
                            title: "Create My First Routine",
                            style: .gradient,
                            action: {
                                HapticManager.shared.anchorSuccess()
                                onCreateRoutine()
                            }
                        )
                        
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
                                .foregroundStyle(themeManager?.currentTheme.textSecondaryColor ?? Theme.defaultTheme.textSecondaryColor)
                            
                            Text("Most people begin with just 3-4 time blocks")
                                .font(.system(size: 12, weight: .regular))
                                .foregroundStyle(themeManager?.currentTheme.textTertiaryColor ?? Theme.defaultTheme.textTertiaryColor)
                        }
                        .opacity(appearAnimation ? 1 : 0)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
                .frame(minHeight: geometry.size.height)
            }
        }
        .onAppear {
            startAnimations()
        }
    }
    
    private func startAnimations() {
        // Main appearance animation
        withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.1)) {
            appearAnimation = true
        }
        
        // Floating animation
        withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
            floatingOffset = -10
        }
        
        // Sparkle animation
        withAnimation(.easeInOut(duration: 2).delay(0.5)) {
            sparkleOpacity = 1
        }
        
        // Pulse animation
        withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
            pulseScale = 1.3
        }
    }
}

// MARK: - Calendar Illustration
struct CalendarIllustrationView: View {
    @Environment(\.themeManager) private var themeManager
    @State private var blockAnimations: [Bool] = Array(repeating: false, count: 4)
    
    var body: some View {
        ZStack {
            // Calendar base - use themed glass morphism
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            LinearGradient(
                                colors: [
                                    surfaceColor.opacity(0.15),
                                    surfaceColor.opacity(0.05)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .frame(width: 140, height: 160)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    surfaceColor.opacity(0.3),
                                    surfaceColor.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
            
            // Calendar header
            VStack(spacing: 12) {
                // Top bar with dots
                HStack(spacing: 8) {
                    ForEach(0..<3) { _ in
                        Circle()
                            .fill((themeManager?.currentTheme.colorScheme.blue.color ?? Theme.defaultTheme.colorScheme.blue.color).opacity(0.6))
                            .frame(width: 6, height: 6)
                    }
                }
                .padding(.top, 20)
                
                Spacer()
                
                // Time blocks
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
    
    private var surfaceColor: Color {
        themeManager?.currentTheme.colorScheme.surfacePrimary.color ?? Theme.defaultTheme.colorScheme.surfacePrimary.color
    }
    
    // Changed from 'let' to computed 'var'
    private var blockColors: [Color] {
        [
            themeManager?.currentTheme.colorScheme.blue.color ?? Theme.defaultTheme.colorScheme.blue.color,
            themeManager?.currentTheme.colorScheme.green.color ?? Theme.defaultTheme.colorScheme.green.color,
            themeManager?.currentTheme.colorScheme.purple.color ?? Theme.defaultTheme.colorScheme.purple.color,
            themeManager?.currentTheme.colorScheme.teal.color ?? Theme.defaultTheme.colorScheme.teal.color
        ]
    }
    
    private let blockWidths: [CGFloat] = [80, 60, 90, 70]
}

// MARK: - Time Block Preview
struct TimeBlockPreview: View {
    let color: Color
    let width: CGFloat
    let isAnimated: Bool
    
    var body: some View {
        RoundedRectangle(cornerRadius: 6)
            .fill(
                LinearGradient(
                    colors: [color, color.opacity(0.7)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(width: isAnimated ? width : 20, height: 12)
            .animation(.spring(response: 0.8, dampingFraction: 0.7), value: isAnimated)
    }
}

// MARK: - Floating Particles
struct FloatingParticlesView: View {
    @State private var particles: [FloatingParticle] = []
    @State private var animationTick = 0
    
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
                startFloatingAnimation(in: geometry.size)
            }
            .onChange(of: animationTick) { _, _ in
                updateParticles(in: geometry.size)
            }
        }
    }
    
    private func createParticles(in size: CGSize) {
        for _ in 0..<15 {
            particles.append(FloatingParticle(screenSize: size))
        }
    }
    
    private func startFloatingAnimation(in size: CGSize) {
        // Use SwiftUI's TimelineView for animation instead of Timer
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

// MARK: - Floating Particle
struct FloatingParticle: Identifiable, Sendable {
    let id = UUID()
    var position: CGPoint
    let color: Color
    let size: CGFloat
    let speed: CGFloat
    let opacity: Double
    
    init(screenSize: CGSize, themeColors: [Color]? = nil) {
        self.position = CGPoint(
            x: CGFloat.random(in: 0...screenSize.width),
            y: CGFloat.random(in: 0...screenSize.height)
        )
        
        // Use provided theme colors or fall back to defaults
        let availableColors = themeColors ?? [
            Theme.defaultTheme.colorScheme.blue.color,
            Theme.defaultTheme.colorScheme.purple.color,
            Theme.defaultTheme.colorScheme.green.color
        ]
        
        self.color = availableColors.randomElement()!
        self.size = CGFloat.random(in: 2...4)
        self.speed = CGFloat.random(in: 0.2...0.8)
        self.opacity = Double.random(in: 0.3...0.7)
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
    @State private var isVisible = false
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 48, height: 48)
                
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(color)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(themeManager?.currentTheme.textPrimaryColor ?? Theme.defaultTheme.textPrimaryColor)
                
                Text(description)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(themeManager?.currentTheme.textSecondaryColor ?? Theme.defaultTheme.textSecondaryColor)
                    .lineLimit(2)
            }
            
            Spacer()
        }
        .padding(16)
        .themedGlassMorphism(cornerRadius: 16)
        .shadow(color: color.opacity(0.2), radius: 8, x: 0, y: 4)
        .opacity(isVisible ? 1 : 0)
        .offset(x: isVisible ? 0 : -20)
        .scaleEffect(isVisible ? 1 : 0.95)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(delay)) {
                isVisible = true
            }
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
    
    private var themeSecondaryText: Color {
        themeManager?.currentTheme.textSecondaryColor ?? Theme.defaultTheme.textSecondaryColor
    }
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isPressed = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    isPressed = false
                }
                action()
            }
        }) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                
                Text(title)
                    .font(.system(size: 16, weight: .medium, design: .rounded))
            }
            .foregroundStyle(themeSecondaryText)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .themedGlassMorphism(cornerRadius: 16)
            .scaleEffect(isPressed ? 0.98 : 1)
            .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
        }
    }
}
