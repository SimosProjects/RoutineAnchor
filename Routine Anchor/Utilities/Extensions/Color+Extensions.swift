//
//  Color+Extensions.swift
//  Routine Anchor
//
//  Premium Design System Colors
//
import SwiftUI

extension Color {
    // MARK: - Premium Brand Colors
    static let premiumBlue = Color(red: 0.4, green: 0.6, blue: 1.0)
    static let premiumPurple = Color(red: 0.6, green: 0.4, blue: 1.0)
    static let premiumGreen = Color(red: 0.2, green: 0.8, blue: 0.5)
    static let premiumTeal = Color(red: 0.2, green: 0.7, blue: 0.7)
    static let premiumYellow = Color(red: 1.0, green: 0.85, blue: 0.4)
    
    // MARK: - Gradient Colors
    static let gradientBlueStart = Color(red: 0.098, green: 0.224, blue: 0.894)
    static let gradientBlueEnd = Color(red: 0.427, green: 0.298, blue: 0.855)
    static let gradientPurpleStart = Color(red: 0.584, green: 0.345, blue: 0.698)
    static let gradientPurpleEnd = Color(red: 0.882, green: 0.443, blue: 0.792)
    
    // MARK: - Background Colors
    static let premiumBackground = Color(red: 0.051, green: 0.047, blue: 0.078)
    static let premiumBackgroundSecondary = Color(red: 0.071, green: 0.067, blue: 0.098)
    static let glassMorphism = Color.white.opacity(0.08)
    
    // MARK: - Premium Semantic Colors
    static let premiumSuccess = Color(red: 0.204, green: 0.78, blue: 0.349)
    static let premiumWarning = Color(red: 1.0, green: 0.584, blue: 0.0)
    static let premiumError = Color(red: 1.0, green: 0.231, blue: 0.188)
    
    // MARK: - Text Colors for Dark Theme
    static let premiumTextPrimary = Color.white
    static let premiumTextSecondary = Color.white.opacity(0.7)
    static let premiumTextTertiary = Color.white.opacity(0.5)
    
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
    static let premiumGradient = LinearGradient(
        colors: [gradientBlueStart, gradientBlueEnd],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let successGradient = LinearGradient(
        colors: [premiumGreen, premiumTeal],
        startPoint: .leading,
        endPoint: .trailing
    )
    
    static let purpleGradient = LinearGradient(
        colors: [gradientPurpleStart, gradientPurpleEnd],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    // MARK: - Brand Colors (Updated for Premium)
    static let appPrimary = premiumBlue
    static let appSuccess = premiumGreen
    static let appWarning = premiumWarning
    static let appError = premiumError
    
    // MARK: - Background Colors (Updated for Dark Theme)
    static let appBackgroundPrimary = premiumBackground
    static let appBackgroundSecondary = premiumBackgroundSecondary
    static let appBackgroundTertiary = Color(red: 0.09, green: 0.087, blue: 0.118)
    
    // MARK: - Text Colors (Updated for Dark Theme)
    static let textPrimary = premiumTextPrimary
    static let textSecondary = premiumTextSecondary
    static let textTertiary = premiumTextTertiary
    
    // MARK: - Original Status Colors (Enhanced)
    static let blockCompleted = premiumGreen
    static let blockInProgress = premiumWarning
    static let blockUpcoming = Color.white.opacity(0.3)
    static let blockSkipped = premiumError
    
    // MARK: - UI Element Colors (Enhanced)
    static let cardBackground = Color.white.opacity(0.06)
    static let cardShadow = Color.black.opacity(0.3)
    static let separatorColor = Color.white.opacity(0.1)
    static let progressTrack = Color.white.opacity(0.1)
    static let progressFill = premiumBlue
    
    // MARK: - Interactive Colors (Enhanced)
    static let buttonPrimary = premiumBlue
    static let buttonSecondary = Color.white.opacity(0.15)
    static let buttonDestructive = premiumError
    
    // MARK: - Special Effects
    static let glowBlue = premiumBlue.opacity(0.6)
    static let glowPurple = premiumPurple.opacity(0.6)
    static let glowGreen = premiumGreen.opacity(0.6)
}

// MARK: - Color Convenience Methods
extension Color {
    /// Create a subtle glow effect
    func glow(radius: CGFloat = 20) -> some View {
        self
            .blur(radius: radius)
            .opacity(0.6)
    }
    
    /// Create a premium shadow
    func premiumShadow(radius: CGFloat = 20, y: CGFloat = 10) -> some View {
        self
            .shadow(color: self.opacity(0.3), radius: radius, x: 0, y: y)
    }
}

// MARK: - Gradient View Modifiers
extension View {
    /// Apply premium gradient background
    func premiumGradientBackground() -> some View {
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
    
    /// Apply premium card style
    func premiumCard(cornerRadius: CGFloat = 16) -> some View {
        self
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color.cardBackground)
                    .background(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(.ultraThinMaterial)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.15),
                                Color.white.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
    }
}
