//
//  PremiumFloat.swift
//  Routine Anchor
//
//  Premium floating animation modifier for smooth up/down movement
//
import SwiftUI

// MARK: - Premium Float Modifier
struct PremiumFloat: ViewModifier {
    @State private var isFloating = false
    let amplitude: CGFloat
    let duration: Double
    let delay: Double
    
    init(amplitude: CGFloat = 10, duration: Double = 3, delay: Double = 0) {
        self.amplitude = amplitude
        self.duration = duration
        self.delay = delay
    }
    
    func body(content: Content) -> some View {
        content
            .offset(y: isFloating ? -amplitude : amplitude)
            .onAppear {
                withAnimation(
                    .easeInOut(duration: duration)
                    .repeatForever(autoreverses: true)
                    .delay(delay)
                ) {
                    isFloating = true
                }
            }
    }
}

// MARK: - View Extension
extension View {
    /// Adds a smooth floating animation to any view
    /// - Parameters:
    ///   - amplitude: The distance the view moves up and down (default: 10)
    ///   - duration: The time for one complete cycle in seconds (default: 3)
    ///   - delay: Initial delay before animation starts (default: 0)
    /// - Returns: A view with floating animation applied
    func premiumFloat(
        amplitude: CGFloat = 10,
        duration: Double = 3,
        delay: Double = 0
    ) -> some View {
        modifier(PremiumFloat(
            amplitude: amplitude,
            duration: duration,
            delay: delay
        ))
    }
}

// MARK: - Variations
extension View {
    /// Gentle floating animation for subtle movement
    func gentleFloat() -> some View {
        premiumFloat(amplitude: 5, duration: 4)
    }
    
    /// Prominent floating animation for attention-grabbing elements
    func prominentFloat() -> some View {
        premiumFloat(amplitude: 15, duration: 2.5)
    }
    
    /// Slow floating animation for background elements
    func slowFloat() -> some View {
        premiumFloat(amplitude: 8, duration: 6)
    }
    
    /// Floating animation with random parameters for multiple elements
    func randomFloat() -> some View {
        let amplitude = CGFloat.random(in: 8...15)
        let duration = Double.random(in: 2.5...4.5)
        let delay = Double.random(in: 0...0.5)
        
        return premiumFloat(
            amplitude: amplitude,
            duration: duration,
            delay: delay
        )
    }
}

// MARK: - Preview
#Preview("Premium Float Examples") {
    ZStack {
        AnimatedGradientBackground()
            .ignoresSafeArea()
        
        VStack(spacing: 40) {
            // Basic float
            Image(systemName: "star.fill")
                .font(.system(size: 40))
                .foregroundStyle(Color.premiumWarning)
                .premiumFloat()
            
            // Gentle float
            Image(systemName: "heart.fill")
                .font(.system(size: 40))
                .foregroundStyle(Color.premiumError)
                .gentleFloat()
            
            // Prominent float
            Image(systemName: "bolt.fill")
                .font(.system(size: 40))
                .foregroundStyle(Color.premiumBlue)
                .prominentFloat()
            
            // Multiple elements with different delays
            HStack(spacing: 20) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(Color.premiumPurple)
                        .frame(width: 30, height: 30)
                        .premiumFloat(
                            amplitude: 10,
                            duration: 3,
                            delay: Double(index) * 0.3
                        )
                }
            }
        }
    }
}
