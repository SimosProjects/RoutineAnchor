//
//  FloatModifier.swift
//  Routine Anchor
//
//  Floating animation modifier for smooth up/down movement
//
import SwiftUI

// MARK: - Float Modifier
struct FloatModifier: ViewModifier {
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
    func floatModifier(
        amplitude: CGFloat = 10,
        duration: Double = 3,
        delay: Double = 0
    ) -> some View {
        modifier(FloatModifier(
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
        floatModifier(amplitude: 5, duration: 4)
    }
    
    /// Prominent floating animation for attention-grabbing elements
    func prominentFloat() -> some View {
        floatModifier(amplitude: 15, duration: 2.5)
    }
    
    /// Slow floating animation for background elements
    func slowFloat() -> some View {
        floatModifier(amplitude: 8, duration: 6)
    }
    
    /// Floating animation with random parameters for multiple elements
    func randomFloat() -> some View {
        let amplitude = CGFloat.random(in: 8...15)
        let duration = Double.random(in: 2.5...4.5)
        let delay = Double.random(in: 0...0.5)
        
        return floatModifier(
            amplitude: amplitude,
            duration: duration,
            delay: delay
        )
    }
}
