//
//  Color+Extensions.swift
//  Routine Anchor
//
//  Design System Colors
//
import SwiftUI

extension Color {
    // MARK: - Brand Colors
    static let anchorBlue = Color(red: 0.4, green: 0.6, blue: 1.0)
    static let anchorPurple = Color(red: 0.6, green: 0.4, blue: 1.0)
    static let anchorGreen = Color(red: 0.2, green: 0.8, blue: 0.5)
    static let anchorTeal = Color(red: 0.2, green: 0.7, blue: 0.7)
    
    // MARK: - Gradient Colors
    static let gradientBlueStart = Color(red: 0.098, green: 0.224, blue: 0.894)
    static let gradientBlueEnd = Color(red: 0.427, green: 0.298, blue: 0.855)
    static let gradientPurpleStart = Color(red: 0.584, green: 0.345, blue: 0.698)
    static let gradientPurpleEnd = Color(red: 0.882, green: 0.443, blue: 0.792)
    
    // MARK: - Background Colors
    static let anchorBackground = Color(red: 0.051, green: 0.047, blue: 0.078)
    static let anchorBackgroundSecondary = Color(red: 0.071, green: 0.067, blue: 0.098)
    static let glassMorphism = Color.white.opacity(0.08)
    
    // MARK: - Semantic Colors
    static let anchorSuccess = Color(red: 0.204, green: 0.78, blue: 0.349)
    static let anchorWarning = Color(red: 1.0, green: 0.584, blue: 0.0)
    static let anchorError = Color(red: 1.0, green: 0.231, blue: 0.188)
    
    // MARK: - Text Colors for Dark Theme
    static let anchorTextPrimary = Color.white
    static let anchorTextSecondary = Color.white.opacity(0.7)
    static let anchorTextTertiary = Color.white.opacity(0.5)
    
    // MARK: - Glass Morphism Effects
    static var glassBackground: some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(.ultraThinMaterial)
            .background(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.05),
                        Color.white.opacity(0.02)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .cornerRadius(20)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.2),
                                Color.white.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
    }
    
    // MARK: - Gradient Definitions
    static let anchorGradient = LinearGradient(
        colors: [gradientBlueStart, gradientBlueEnd],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let successGradient = LinearGradient(
        colors: [anchorGreen, anchorTeal],
        startPoint: .leading,
        endPoint: .trailing
    )
    
    static let purpleGradient = LinearGradient(
        colors: [gradientPurpleStart, gradientPurpleEnd],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    // MARK: - Brand Colors
    static let appPrimary = anchorBlue
    static let appSuccess = anchorGreen
    static let appWarning = anchorWarning
    static let appError = anchorError
    
    // MARK: - Background Colors
    static let appBackgroundPrimary = anchorBackground
    static let appBackgroundSecondary = anchorBackgroundSecondary
    static let appBackgroundTertiary = Color(red: 0.09, green: 0.087, blue: 0.118)
    
    // MARK: - Text Colors
    static let textPrimary = anchorTextPrimary
    static let textSecondary = anchorTextSecondary
    static let textTertiary = anchorTextTertiary
    
    // MARK: - Original Status Colors
    static let blockCompleted = anchorGreen
    static let blockInProgress = anchorWarning
    static let blockUpcoming = Color.white.opacity(0.3)
    static let blockSkipped = anchorError
    
    // MARK: - UI Element Colors
    static let cardBackground = Color.white.opacity(0.06)
    static let cardShadow = Color.black.opacity(0.3)
    static let separatorColor = Color.white.opacity(0.1)
    static let progressTrack = Color.white.opacity(0.1)
    static let progressFill = anchorBlue
    
    // MARK: - Interactive Colors
    static let buttonPrimary = anchorBlue
    static let buttonSecondary = Color.white.opacity(0.15)
    static let buttonDestructive = anchorError
    
    // MARK: - Special Effects
    static let glowBlue = anchorBlue.opacity(0.6)
    static let glowPurple = anchorPurple.opacity(0.6)
    static let glowGreen = anchorGreen.opacity(0.6)
}

// MARK: - Color Convenience Methods
extension Color {
    /// Create a subtle glow effect
    func glow(radius: CGFloat = 20) -> some View {
        self
            .blur(radius: radius)
            .opacity(0.6)
    }
    
    /// Create a shadow
    func anchorShadow(radius: CGFloat = 20, y: CGFloat = 10) -> some View {
        self
            .shadow(color: self.opacity(0.3), radius: radius, x: 0, y: y)
    }
}

// MARK: - Gradient View Modifiers
extension View {
    /// Apply gradient background
    func anchorGradientBackground() -> some View {
        self.background(
            LinearGradient(
                colors: [
                    Color.gradientBlueStart,
                    Color.gradientBlueEnd
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
    
    /// Apply glass morphism effect
    func glassMorphism(cornerRadius: CGFloat = 20) -> some View {
        self
            .background(.ultraThinMaterial)
            .background(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.05),
                        Color.white.opacity(0.02)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.2),
                                Color.white.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
    }
}
