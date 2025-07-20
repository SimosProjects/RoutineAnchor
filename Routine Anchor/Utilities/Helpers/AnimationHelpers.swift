//
//  AnimationHelpers.swift
//  Routine Anchor
//
//  Premium Animation Effects and Transitions
//
import SwiftUI

// MARK: - Custom Animations
extension Animation {
    static let premiumSpring = Animation.spring(response: 0.6, dampingFraction: 0.8)
    static let premiumBounce = Animation.spring(response: 0.5, dampingFraction: 0.6)
    static let premiumSmooth = Animation.easeInOut(duration: 0.8)
    
    static func premiumDelay(_ delay: Double) -> Animation {
        Animation.spring(response: 0.6, dampingFraction: 0.7).delay(delay)
    }
}

// MARK: - View Transitions
extension AnyTransition {
    static var premiumSlide: AnyTransition {
        AnyTransition.asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        )
    }
    
    static var premiumScale: AnyTransition {
        AnyTransition.scale(scale: 0.8).combined(with: .opacity)
    }
    
    static var premiumPop: AnyTransition {
        AnyTransition.scale(scale: 1.2).combined(with: .opacity)
    }
}

// MARK: - Animated View Modifiers
struct PremiumPulse: ViewModifier {
    @State private var isPulsing = false
    let duration: Double
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isPulsing ? 1.05 : 1.0)
            .opacity(isPulsing ? 0.8 : 1.0)
            .onAppear {
                withAnimation(.easeInOut(duration: duration).repeatForever(autoreverses: true)) {
                    isPulsing = true
                }
            }
    }
}

struct PremiumFloat: ViewModifier {
    @State private var isFloating = false
    let amplitude: CGFloat
    let duration: Double
    
    func body(content: Content) -> some View {
        content
            .offset(y: isFloating ? -amplitude : amplitude)
            .onAppear {
                withAnimation(.easeInOut(duration: duration).repeatForever(autoreverses: true)) {
                    isFloating = true
                }
            }
    }
}

struct PremiumShimmer: ViewModifier {
    @State private var phase: CGFloat = 0
    let duration: Double
    
    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    colors: [
                        Color.clear,
                        Color.white.opacity(0.3),
                        Color.clear
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .rotationEffect(.degrees(30))
                .offset(x: phase * 200 - 100)
                .mask(content)
            )
            .onAppear {
                withAnimation(.linear(duration: duration).repeatForever(autoreverses: false)) {
                    phase = 1
                }
            }
    }
}

struct PremiumGlow: ViewModifier {
    let color: Color
    let radius: CGFloat
    @State private var isGlowing = false
    
    func body(content: Content) -> some View {
        content
            .shadow(
                color: color.opacity(isGlowing ? 0.6 : 0.3),
                radius: isGlowing ? radius * 1.5 : radius,
                x: 0,
                y: isGlowing ? radius / 2 : radius / 4
            )
            .onAppear {
                withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                    isGlowing = true
                }
            }
    }
}

struct PremiumRotation3D: ViewModifier {
    @State private var rotation: Double = 0
    let duration: Double
    let axis: (x: CGFloat, y: CGFloat, z: CGFloat)
    
    func body(content: Content) -> some View {
        content
            .rotation3DEffect(
                .degrees(rotation),
                axis: axis
            )
            .onAppear {
                withAnimation(.easeInOut(duration: duration).repeatForever(autoreverses: true)) {
                    rotation = 10
                }
            }
    }
}

// MARK: - View Extensions
extension View {
    func premiumPulse(duration: Double = 2) -> some View {
        modifier(PremiumPulse(duration: duration))
    }
    
    func premiumFloat(amplitude: CGFloat = 10, duration: Double = 3) -> some View {
        modifier(PremiumFloat(amplitude: amplitude, duration: duration))
    }
    
    func premiumShimmer(duration: Double = 3) -> some View {
        modifier(PremiumShimmer(duration: duration))
    }
    
    func premiumGlow(color: Color = .blue, radius: CGFloat = 20) -> some View {
        modifier(PremiumGlow(color: color, radius: radius))
    }
    
    func premiumRotation3D(duration: Double = 4, axis: (x: CGFloat, y: CGFloat, z: CGFloat) = (0, 1, 0)) -> some View {
        modifier(PremiumRotation3D(duration: duration, axis: axis))
    }
}

// MARK: - Haptic Feedback Manager (Enhanced)
extension HapticManager {
    func premiumImpact() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred(intensity: 0.8)
    }
    
    func premiumSuccess() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        // Double tap for emphasis
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            generator.notificationOccurred(.success)
        }
    }
    
    func premiumSelection() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
}

// MARK: - Animated Number Display
struct AnimatedNumber: View {
    let value: Double
    let format: String
    @State private var animatedValue: Double = 0
    
    var body: some View {
        Text(String(format: format, animatedValue))
            .onAppear {
                withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                    animatedValue = value
                }
            }
            .onChange(of: value) { _, newValue in
                withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                    animatedValue = newValue
                }
            }
    }
}

// MARK: - Morphing Shape
struct MorphingCircle: Shape {
    var morphProgress: CGFloat
    
    var animatableData: CGFloat {
        get { morphProgress }
        set { morphProgress = newValue }
    }
    
    func path(in rect: CGRect) -> Path {
        let radius = min(rect.width, rect.height) / 2
        let center = CGPoint(x: rect.midX, y: rect.midY)
        
        var path = Path()
        
        for angle in stride(from: CGFloat(0), to: CGFloat(360), by: CGFloat(10)) {
            let radians = angle * .pi / 180
            let variation = sin(radians * 3 + morphProgress * .pi * 2) * 10 * morphProgress
            let adjustedRadius = radius + variation
            
            let x = center.x + adjustedRadius * cos(radians)
            let y = center.y + adjustedRadius * sin(radians)
            
            if angle == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        
        path.closeSubpath()
        return path
    }
}

// MARK: - Animated Background Mesh
struct AnimatedMeshBackground: View {
    @State private var phase: CGFloat = 0
    
    var body: some View {
        Canvas { context, size in
            let gridSize = 30
            let dotSize: CGFloat = 2
            
            for x in stride(from: 0, to: Int(size.width), by: gridSize) {
                for y in stride(from: 0, to: Int(size.height), by: gridSize) {
                    let xPos = CGFloat(x)
                    let yPos = CGFloat(y)
                    
                    let distance = sqrt(pow(xPos - size.width/2, 2) + pow(yPos - size.height/2, 2))
                    let wave = sin(distance * 0.01 - phase) * 0.5 + 0.5
                    
                    context.fill(
                        Path(ellipseIn: CGRect(
                            x: xPos - dotSize/2,
                            y: yPos - dotSize/2,
                            width: dotSize,
                            height: dotSize
                        )),
                        with: .color(.white.opacity(0.1 * wave))
                    )
                }
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 4).repeatForever(autoreverses: false)) {
                phase = .pi * 2
            }
        }
    }
}

struct AnimatedGradientBackground: View {
    @State private var animateGradient = false
    
    var body: some View {
        LinearGradient(
            colors: [
                Color(red: 0.05, green: 0.05, blue: 0.15),
                Color(red: 0.08, green: 0.05, blue: 0.2),
                Color(red: 0.05, green: 0.08, blue: 0.25)
            ],
            startPoint: animateGradient ? .topLeading : .bottomLeading,
            endPoint: animateGradient ? .bottomTrailing : .topTrailing
        )
        .ignoresSafeArea()
        .overlay(
            RadialGradient(
                colors: [
                    Color(red: 0.2, green: 0.3, blue: 0.8).opacity(0.3),
                    Color.clear
                ],
                center: .top,
                startRadius: 100,
                endRadius: 400
            )
            .ignoresSafeArea()
        )
        .onAppear {
            withAnimation(.easeInOut(duration: 5).repeatForever(autoreverses: true)) {
                animateGradient.toggle()
            }
        }
    }
}

// MARK: - Particle System
struct ParticleSystem {
    var particles: [Particle] = []
    
    mutating func startEmitting() {
        for _ in 0..<20 {
            particles.append(Particle())
        }
    }
}

struct Particle: Identifiable {
    let id = UUID()
    var position: CGPoint = CGPoint(
        x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
        y: CGFloat.random(in: 0...UIScreen.main.bounds.height)
    )
    var opacity: Double = Double.random(in: 0.1...0.3)
    var scale: CGFloat = CGFloat.random(in: 0.5...1.5)
}

struct ParticleEffectView: View {
    let system: ParticleSystem
    @State private var animate = false
    
    var body: some View {
        GeometryReader { geometry in
            ForEach(system.particles) { particle in
                Circle()
                    .fill(Color.blue.opacity(particle.opacity))
                    .frame(width: 4 * particle.scale, height: 4 * particle.scale)
                    .position(particle.position)
                    .blur(radius: 2)
                    .offset(y: animate ? -geometry.size.height : 0)
                    .animation(
                        .linear(duration: Double.random(in: 20...40))
                        .repeatForever(autoreverses: false),
                        value: animate
                    )
            }
        }
        .onAppear {
            animate = true
        }
    }
}


// MARK: - Confetti View
struct ConfettiView: View {
    @Binding var isActive: Bool
    @State private var particles: [ConfettiParticle] = []
    
    var body: some View {
        GeometryReader { geometry in
            ForEach(particles) { particle in
                Image(systemName: particle.symbol)
                    .font(.system(size: particle.size))
                    .foregroundStyle(particle.color)
                    .position(particle.position)
                    .rotationEffect(.degrees(particle.rotation))
                    .opacity(particle.opacity)
                    .animation(
                        .easeOut(duration: particle.duration),
                        value: particle.position
                    )
            }
        }
        .onChange(of: isActive) { _, newValue in
            if newValue {
                createParticles()
            }
        }
    }
    
    private func createParticles() {
        let symbols = ["star.fill", "heart.fill", "sparkle", "circle.fill"]
        let colors: [Color] = [.blue, .purple, .green, .yellow, .pink]
        
        for _ in 0..<30 {
            let particle = ConfettiParticle(
                symbol: symbols.randomElement()!,
                color: colors.randomElement()!,
                position: CGPoint(
                    x: UIScreen.main.bounds.width / 2,
                    y: UIScreen.main.bounds.height / 2
                ),
                targetPosition: CGPoint(
                    x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                    y: CGFloat.random(in: -100...UIScreen.main.bounds.height + 100)
                ),
                size: CGFloat.random(in: 10...20),
                duration: Double.random(in: 1.5...3),
                rotation: Double.random(in: 0...360),
                opacity: 1.0
            )
            
            particles.append(particle)
        }
        
        // Fade out particles
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            for index in particles.indices {
                withAnimation(.easeOut(duration: particles[index].duration)) {
                    particles[index].position = particles[index].targetPosition
                    particles[index].opacity = 0
                }
            }
        }
        
        // Clean up
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            particles.removeAll()
            isActive = false
        }
    }
}

struct ConfettiParticle: Identifiable {
    let id = UUID()
    let symbol: String
    let color: Color
    var position: CGPoint
    var targetPosition: CGPoint
    let size: CGFloat
    let duration: Double
    let rotation: Double
    var opacity: Double
}
