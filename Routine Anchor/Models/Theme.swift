//
//  Theme.swift
//  Routine Anchor
//
//  Theme data model with color schemes
//
import SwiftUI
import Foundation

// MARK: - Theme Model
struct Theme: Codable, Identifiable, Equatable {
    let id: String
    let name: String
    let description: String
    let isPremium: Bool
    let colorScheme: ThemeColorScheme
    let gradientStyle: GradientStyle
    let icon: String
    let category: ThemeCategory
    
    init(
        id: String,
        name: String,
        description: String,
        isPremium: Bool,
        colorScheme: ThemeColorScheme,
        gradientStyle: GradientStyle = .linear,
        icon: String,
        category: ThemeCategory
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.isPremium = isPremium
        self.colorScheme = colorScheme
        self.gradientStyle = gradientStyle
        self.icon = icon
        self.category = category
    }
}

// MARK: - Theme Category
enum ThemeCategory: String, Codable, CaseIterable {
    case minimal = "minimal"
    case vibrant = "vibrant"
    case nature = "nature"
    case gradient = "gradient"
    case dark = "dark"
    case professional = "professional"
    
    var displayName: String {
        switch self {
        case .minimal: return "Minimal"
        case .vibrant: return "Vibrant"
        case .nature: return "Nature"
        case .gradient: return "Gradient"
        case .dark: return "Dark"
        case .professional: return "Professional"
        }
    }
}

// MARK: - Gradient Style
enum GradientStyle: String, Codable {
    case linear = "linear"
    case radial = "radial"
    case angular = "angular"
    case mesh = "mesh"
}

// MARK: - Theme Color Scheme
struct ThemeColorScheme: Codable, Equatable {
    // Background Colors
    let primaryBackground: ColorHex
    let secondaryBackground: ColorHex
    let elevatedBackground: ColorHex
    let backgroundColors: [ColorHex]
    
    // Text Colors
    let primaryText: ColorHex
    let secondaryText: ColorHex
    let subtleText: ColorHex
    let invertedText: ColorHex
    
    // Accent Colors
    let primaryAccent: ColorHex
    let secondaryAccent: ColorHex
    
    // Button Colors
    let primaryButton: ColorHex
    let secondaryButton: ColorHex
    let buttonAccent: ColorHex
    let buttonGradient: [ColorHex]
    
    // Icon Colors
    let normal: ColorHex
    let muted: ColorHex
    
    // Status Colors
    let success: ColorHex
    let warning: ColorHex
    let error: ColorHex
    let info: ColorHex
    
    // Lines & focus
    let divider: ColorHex
    let border: ColorHex
    let focusRing: ColorHex
    
    // Progress & rings
    let progressTrack: ColorHex
    let progressFillStart: ColorHex
    let progressFillEnd: ColorHex
    let ringOuterAlpha: Double
    let ringInnerStartAlpha: Double
    let ringInnerEndAlpha: Double
    
    // Glass / glow
    let glassTint: ColorHex
    let glassOpacity: Double
    let glowIntensityPrimary: Double      // Main glow opacity (0.0-1.0)
    let glowIntensitySecondary: Double    // Secondary glow opacity
    let glowBlurRadius: Double            // Blur amount for glow effects
    let glowRadiusInner: Double           // Inner radius for radial gradients
    let glowRadiusOuter: Double           // Outer radius for radial gradients
    let glowAnimationScale: Double        // Scale factor for animations (1.0-2.0)

    // Charts (Analytics + QuickStats)
    let chartPalette: [ColorHex]
    let chartGrid: ColorHex
    let chartLabel: ColorHex
    
    // Additional Colors
    let primaryUIElement: ColorHex
    let secondaryUIElement: ColorHex
    
    init(
        primaryBackground: ColorHex,
        secondaryBackground: ColorHex,
        elevatedBackground: ColorHex,
        backgroundColors: [ColorHex],
        
        primaryText: ColorHex,
        secondaryText: ColorHex,
        subtleText: ColorHex,
        invertedText: ColorHex,
        
        primaryAccent: ColorHex,
        secondaryAccent: ColorHex,
        
        primaryButton: ColorHex,
        secondaryButton: ColorHex,
        buttonAccent: ColorHex,
        buttonGradient: [ColorHex],
        
        normal: ColorHex,
        muted: ColorHex,
        
        success: ColorHex,
        warning: ColorHex,
        error: ColorHex,
        info: ColorHex,
        
        divider: ColorHex,
        border: ColorHex,
        focusRing: ColorHex,
        
        progressTrack: ColorHex,
        progressFillStart: ColorHex,
        progressFillEnd: ColorHex,
        ringOuterAlpha: Double,
        ringInnerStartAlpha: Double,
        ringInnerEndAlpha: Double,
        
        glassTint: ColorHex,
        glassOpacity: Double = 0.08,
        glowIntensityPrimary: Double = 0.35,
        glowIntensitySecondary: Double = 0.15,
        glowBlurRadius: Double = 30,
        glowRadiusInner: Double = 32,
        glowRadiusOuter: Double = 84,
        glowAnimationScale: Double = 1.4,
        
        chartPalette: [ColorHex] = [
            ColorHex("#0A84FF"), ColorHex("#6E5AE6"), ColorHex("#64D2FF"),
            ColorHex("#32D74B"), ColorHex("#FF9F0A"), ColorHex("#FFD66B"),
            ColorHex("#FF6B6B"), ColorHex("#F472B6")
        ],
        chartGrid: ColorHex,
        chartLabel: ColorHex,
        
        primaryUIElement: ColorHex,
        secondaryUIElement: ColorHex
    ) {
        self.primaryBackground = primaryBackground
        self.secondaryBackground = secondaryBackground
        self.elevatedBackground = elevatedBackground
        self.backgroundColors = backgroundColors
        
        self.primaryText = primaryText
        self.secondaryText = secondaryText
        self.subtleText = subtleText
        self.invertedText = invertedText
        
        self.primaryAccent = primaryAccent
        self.secondaryAccent = secondaryAccent
        
        self.primaryButton = primaryButton
        self.secondaryButton = secondaryButton
        self.buttonAccent = buttonAccent
        self.buttonGradient = buttonGradient
        
        self.normal = normal
        self.muted = muted
        
        self.success = success
        self.warning = warning
        self.error = error
        self.info = info
        
        self.divider = divider
        self.border = border
        self.focusRing = focusRing
        
        self.progressTrack = progressTrack
        self.progressFillStart = progressFillStart
        self.progressFillEnd = progressFillEnd
        self.ringOuterAlpha = ringOuterAlpha
        self.ringInnerStartAlpha = ringInnerStartAlpha
        self.ringInnerEndAlpha = ringInnerEndAlpha
        
        self.glassTint = glassTint
        self.glassOpacity = glassOpacity
        self.glowIntensityPrimary = glowIntensityPrimary
        self.glowIntensitySecondary = glowIntensitySecondary
        self.glowBlurRadius = glowBlurRadius
        self.glowRadiusInner = glowRadiusInner
        self.glowRadiusOuter = glowRadiusOuter
        self.glowAnimationScale = glowAnimationScale
        
        self.chartPalette = chartPalette
        self.chartGrid = chartGrid
        self.chartLabel = chartLabel
        
        self.primaryUIElement = primaryUIElement
        self.secondaryUIElement = secondaryUIElement
    }
}

// MARK: - Color Hex Helper
struct ColorHex: Codable, Equatable {
    let hex: String
    
    init(_ hex: String) {
        self.hex = hex.hasPrefix("#") ? hex : "#\(hex)"
    }
    
    var color: Color {
        Color(hex: hex)
    }
}

// MARK: - SwiftUI Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 255, 255, 255)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
    
    /// WCAG relative luminance in sRGB [0, 1]
    var luminance: Double {
        #if canImport(UIKit)
        let c = UIColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        guard c.getRed(&r, green: &g, blue: &b, alpha: &a) else { return 0.0 }
        #elseif canImport(AppKit)
        let c = NSColor(self).usingColorSpace(.sRGB) ?? .white
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        c.getRed(&r, green: &g, blue: &b, alpha: &a)
        #endif

        func lin(_ v: CGFloat) -> Double {
            let v = Double(v)
            return v <= 0.03928 ? v / 12.92 : pow((v + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * lin(r) + 0.7152 * lin(g) + 0.0722 * lin(b)
    }

    var isLight: Bool { luminance >= 0.5 }
}

// MARK: - Theme Extensions

extension Theme {
    // MARK: - Buttons
    var buttonPrimaryColor: Color { colorScheme.primaryButton.color }
    var buttonSecondaryColor: Color { colorScheme.secondaryButton.color }
    var buttonAccentColor: Color { colorScheme.buttonAccent.color }
    var buttonGradient: LinearGradient {
        LinearGradient(
            colors: colorScheme.buttonGradient.map { $0.color },
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // MARK: - Backgrounds
    var primaryBackgroundColor: Color { colorScheme.primaryBackground.color }
    var secondaryBackgroundColor: Color { colorScheme.secondaryBackground.color }
    var elevatedBackgroundColor: Color { colorScheme.elevatedBackground.color }
    var backgroundColorsGradient: [Color] { colorScheme.backgroundColors.map { $0.color }}

    // MARK: - Text
    var primaryTextColor: Color { colorScheme.primaryText.color }
    var secondaryTextColor: Color { colorScheme.secondaryText.color }
    var subtleTextColor: Color { colorScheme.subtleText.color }
    var invertedTextColor: Color { colorScheme.invertedText.color }

    // MARK: - Accents & Icons
    var primaryAccentColor: Color { colorScheme.primaryAccent.color }
    var secondaryAccentColor: Color { colorScheme.secondaryAccent.color }
    var iconNormalColor: Color { colorScheme.normal.color }
    var iconMutedColor: Color { colorScheme.muted.color }
    
    // Status Colors
    var success: Color { colorScheme.success.color }
    var warning: Color { colorScheme.warning.color }
    var error: Color { colorScheme.error.color }
    var infoColor: Color { colorScheme.info.color }

    // MARK: - Lines / Focus
    var dividerColor: Color { colorScheme.divider.color }
    var borderColor: Color { colorScheme.border.color }
    var focusRingColor: Color { colorScheme.focusRing.color }

    // MARK: - Progress / Rings
    var progressTrackColor: Color { colorScheme.progressTrack.color }
    var progressFillGradient: LinearGradient {
        LinearGradient(
            colors: [colorScheme.progressFillStart.color, colorScheme.progressFillEnd.color],
            startPoint: .topTrailing,
            endPoint: .bottomLeading
        )
    }
    var ringOuterAlpha: Double { colorScheme.ringOuterAlpha }
    var ringInnerStartAlpha: Double { colorScheme.ringInnerStartAlpha }
    var ringInnerEndAlpha: Double { colorScheme.ringInnerEndAlpha }

    // MARK: - Charts
    var chartColors: [Color] { colorScheme.chartPalette.map { $0.color } }
    var chartGridColor: Color { colorScheme.chartGrid.color }
    var chartLabelColor: Color { colorScheme.chartLabel.color }

    // MARK: - Background Gradients
    var backgroundColorsLinear: LinearGradient {
        LinearGradient(
            colors: backgroundColorsGradient,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    var backgroundColorsLinearRadial: RadialGradient {
        RadialGradient(
            colors: backgroundColorsGradient,
            center: .center,
            startRadius: 0,
            endRadius: 300
        )
    }
    var backgroundColorsLinearAngular: AngularGradient {
        AngularGradient(
            colors: backgroundColorsGradient,
            center: .center
        )
    }

    // MARK: - Glass / Glow
    var glassEffect: (Color, Double) { (colorScheme.glassTint.color, colorScheme.glassOpacity) }
    var glowIntensityPrimary: Double { colorScheme.glowIntensityPrimary }
    var glowIntensitySecondary: Double { colorScheme.glowIntensitySecondary }
    var glowBlurRadius: Double { colorScheme.glowBlurRadius }
    var glowRadiusInner: Double { colorScheme.glowRadiusInner }
    var glowRadiusOuter: Double { colorScheme.glowRadiusOuter }
    var glowAnimationScale: Double { colorScheme.glowAnimationScale }

    // MARK: - UI Elements
    var primaryUIElementColor: Color { colorScheme.primaryUIElement.color }
    var secondaryUIElementColor: Color { colorScheme.secondaryUIElement.color }
    
    var glowEffect: (primary: Double, secondary: Double, blur: Double, innerRadius: Double, outerRadius: Double, animationScale: Double) {
        return (
            primary: colorScheme.glowIntensityPrimary,
            secondary: colorScheme.glowIntensitySecondary,
            blur: colorScheme.glowBlurRadius,
            innerRadius: colorScheme.glowRadiusInner,
            outerRadius: colorScheme.glowRadiusOuter,
            animationScale: colorScheme.glowAnimationScale
        )
    }
}
