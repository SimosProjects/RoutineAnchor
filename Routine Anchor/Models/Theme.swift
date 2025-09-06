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
    // Primary Colors
    let buttonPrimary: ColorHex
    let buttonSecondary: ColorHex
    let tertiary: ColorHex
    
    // Background Colors
    let appBackground: ColorHex
    let cardBackground: ColorHex
    let overlayBackground: ColorHex
    
    // UI Element Colors
    let uiElementPrimary: ColorHex
    let uiElementSecondary: ColorHex
    
    // Text Colors
    let primaryText: ColorHex
    let secondaryText: ColorHex
    let subtleText: ColorHex
    
    // Accent Colors
    let buttonAccent: ColorHex
    let warningColor: ColorHex
    let successColor: ColorHex
    let errorColor: ColorHex
    
    // Special Colors
    let workflowPrimary: ColorHex
    let actionSuccess: ColorHex
    let organizationAccent: ColorHex
    let creativeSecondary: ColorHex
    let socialAccent: ColorHex
    
    let surface0: ColorHex            // lowest elevation background
    let surface1: ColorHex
    let surface2: ColorHex
    let surface3: ColorHex
    
    let divider: ColorHex             // hairlines (usually with 60% alpha in use)
    let border: ColorHex              // emphasized borders (80% alpha in use)
    let focusRing: ColorHex           // focus/active outline
    
    let todayHeroTop: ColorHex        // Today hero gradient start
    let todayHeroBottom: ColorHex     // Today hero gradient end
    let todayHeroVignette: ColorHex   // subtle vignette hue
    let todayHeroVignetteOpacity: Double
    
    let progressTrack: ColorHex
    let progressFillStart: ColorHex
    let progressFillEnd: ColorHex

    let ringOuterAlpha: Double
    let ringInnerStartAlpha: Double
    let ringInnerEndAlpha: Double

    let scrim: ColorHex

    let chartPalette: [ColorHex]
    let chartGrid: ColorHex
    let chartLabel: ColorHex
    
    // Glass morphism effect
    let glassTint: ColorHex
    let glassOpacity: Double
    
    // Glow effect properties
    let glowIntensityPrimary: Double      // Main glow opacity (0.0-1.0)
    let glowIntensitySecondary: Double    // Secondary glow opacity
    let glowBlurRadius: Double            // Blur amount for glow effects
    let glowRadiusInner: Double           // Inner radius for radial gradients
    let glowRadiusOuter: Double           // Outer radius for radial gradients
    let glowAnimationScale: Double        // Scale factor for animations (1.0-2.0)
    
    // Gradient colors for backgrounds
    let gradientColors: [ColorHex]
    
    init(
        buttonPrimary: ColorHex,
        buttonSecondary: ColorHex,
        tertiary: ColorHex,
        appBackground: ColorHex,
        cardBackground: ColorHex,
        overlayBackground: ColorHex,
        uiElementPrimary: ColorHex,
        uiElementSecondary: ColorHex,
        primaryText: ColorHex,
        secondaryText: ColorHex,
        subtleText: ColorHex,
        buttonAccent: ColorHex,
        warningColor: ColorHex,
        successColor: ColorHex,
        errorColor: ColorHex,
        workflowPrimary: ColorHex,
        actionSuccess: ColorHex,
        organizationAccent: ColorHex,
        creativeSecondary: ColorHex,
        socialAccent: ColorHex,

        surface0: ColorHex = ColorHex("#0E1228"),
        surface1: ColorHex = ColorHex("#131834"),
        surface2: ColorHex = ColorHex("#1A2145"),
        surface3: ColorHex = ColorHex("#212A57"),

        divider: ColorHex = ColorHex("#2B3152"),
        border: ColorHex  = ColorHex("#3B4474"),
        focusRing: ColorHex = ColorHex("#7DB7FF"),

        todayHeroTop: ColorHex = ColorHex("#0F1630"),
        todayHeroBottom: ColorHex = ColorHex("#1D1C53"),
        todayHeroVignette: ColorHex = ColorHex("#2E0B5F"),
        todayHeroVignetteOpacity: Double = 0.18,

        progressTrack: ColorHex = ColorHex("#2B3152"),
        progressFillStart: ColorHex = ColorHex("#32D74B"),
        progressFillEnd: ColorHex = ColorHex("#64D2FF"),

        ringOuterAlpha: Double = 0.30,
        ringInnerStartAlpha: Double = 0.30,
        ringInnerEndAlpha: Double = 0.10,

        scrim: ColorHex = ColorHex("#000000"),

        chartPalette: [ColorHex] = [
            ColorHex("#0A84FF"), ColorHex("#6E5AE6"), ColorHex("#64D2FF"),
            ColorHex("#32D74B"), ColorHex("#FF9F0A"), ColorHex("#FFD66B"),
            ColorHex("#FF6B6B"), ColorHex("#F472B6")
        ],
        chartGrid: ColorHex = ColorHex("#2B3152"),
        chartLabel: ColorHex = ColorHex("#9AA4C0"),

        // glass / glow / bg gradient
        glassTint: ColorHex,
        glassOpacity: Double = 0.08,
        glowIntensityPrimary: Double = 0.35,
        glowIntensitySecondary: Double = 0.15,
        glowBlurRadius: Double = 30,
        glowRadiusInner: Double = 32,
        glowRadiusOuter: Double = 84,
        glowAnimationScale: Double = 1.4,
        gradientColors: [ColorHex]
    ) {
        self.buttonPrimary = buttonPrimary
        self.buttonSecondary = buttonSecondary
        self.tertiary = tertiary
        self.appBackground = appBackground
        self.cardBackground = cardBackground
        self.overlayBackground = overlayBackground
        self.uiElementPrimary = uiElementPrimary
        self.uiElementSecondary = uiElementSecondary
        self.primaryText = primaryText
        self.secondaryText = secondaryText
        self.subtleText = subtleText
        self.buttonAccent = buttonAccent
        self.warningColor = warningColor
        self.successColor = successColor
        self.errorColor = errorColor
        self.workflowPrimary = workflowPrimary
        self.actionSuccess = actionSuccess
        self.organizationAccent = organizationAccent
        self.creativeSecondary = creativeSecondary
        self.socialAccent = socialAccent

        self.surface0 = surface0
        self.surface1 = surface1
        self.surface2 = surface2
        self.surface3 = surface3

        self.divider = divider
        self.border = border
        self.focusRing = focusRing

        self.todayHeroTop = todayHeroTop
        self.todayHeroBottom = todayHeroBottom
        self.todayHeroVignette = todayHeroVignette
        self.todayHeroVignetteOpacity = todayHeroVignetteOpacity

        self.progressTrack = progressTrack
        self.progressFillStart = progressFillStart
        self.progressFillEnd = progressFillEnd

        self.ringOuterAlpha = ringOuterAlpha
        self.ringInnerStartAlpha = ringInnerStartAlpha
        self.ringInnerEndAlpha = ringInnerEndAlpha

        self.scrim = scrim

        self.chartPalette = chartPalette
        self.chartGrid = chartGrid
        self.chartLabel = chartLabel

        // glass / glow / bg gradient
        self.glassTint = glassTint
        self.glassOpacity = glassOpacity
        self.glowIntensityPrimary = glowIntensityPrimary
        self.glowIntensitySecondary = glowIntensitySecondary
        self.glowBlurRadius = glowBlurRadius
        self.glowRadiusInner = glowRadiusInner
        self.glowRadiusOuter = glowRadiusOuter
        self.glowAnimationScale = glowAnimationScale
        self.gradientColors = gradientColors
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
    
    var uiColor: UIColor {
        UIColor(hex: hex) ?? UIColor.clear
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
}

// MARK: - UIColor Extension
extension UIColor {
    convenience init?(hex: String) {
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
            return nil
        }

        self.init(
            red: CGFloat(r) / 255,
            green: CGFloat(g) / 255,
            blue: CGFloat(b) / 255,
            alpha: CGFloat(a) / 255
        )
    }
}

extension Theme {
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

// MARK: - Theme Extensions
extension Theme {
    // Computed properties for easy access to colors
    var buttonPrimaryColor: Color { colorScheme.buttonPrimary.color }
    var buttonSecondaryColor: Color { colorScheme.buttonSecondary.color }
    var tertiaryColor: Color { colorScheme.tertiary.color }
    var buttonAccentColor: Color { colorScheme.buttonAccent.color }
    
    var backgroundColors: [Color] {
        colorScheme.gradientColors.map { $0.color }
    }
    
    var cardBackgroundColor: Color { colorScheme.cardBackground.color }
    
    var primaryTextColor: Color { colorScheme.primaryText.color }
    var secondaryTextColor: Color { colorScheme.secondaryText.color }
    var subtleTextColor: Color { colorScheme.subtleText.color }
    var creativeSecondaryTextColor: Color { colorScheme.creativeSecondary.color }
    
    // Elevation
    var surface0Color: Color { colorScheme.surface0.color }
    var surface1Color: Color { colorScheme.surface1.color }
    var surface2Color: Color { colorScheme.surface2.color }
    var surface3Color: Color { colorScheme.surface3.color }
    
    // Lines / focus
    var dividerColor: Color { colorScheme.divider.color }
    var borderColor: Color { colorScheme.border.color }
    var focusRingColor: Color { colorScheme.focusRing.color }
    
    // Today hero background
    var todayHeroGradient: LinearGradient {
        LinearGradient(
            colors: [colorScheme.todayHeroTop.color, colorScheme.todayHeroBottom.color],
            startPoint: .top,
            endPoint: .bottom
        )
    }
    var todayHeroVignetteColor: Color { colorScheme.todayHeroVignette.color }
    var todayHeroVignetteOpacity: Double { colorScheme.todayHeroVignetteOpacity }
    
    // Progress / rings
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
    
    // Scrim
    var scrimColor: Color { colorScheme.scrim.color }

    // Charts
    var chartColors: [Color] { colorScheme.chartPalette.map { $0.color } }
    var chartGridColor: Color { colorScheme.chartGrid.color }
    var chartLabelColor: Color { colorScheme.chartLabel.color }
    
    // Gradient creation
    var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: backgroundColors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    var radialBackgroundGradient: RadialGradient {
        RadialGradient(
            colors: backgroundColors,
            center: .center,
            startRadius: 0,
            endRadius: 300
        )
    }
    
    var angularBackgroundGradient: AngularGradient {
        AngularGradient(
            colors: backgroundColors,
            center: .center
        )
    }
    
    // Glass morphism effect
    var glassEffect: (Color, Double) {
        (colorScheme.glassTint.color, colorScheme.glassOpacity)
    }
}

// MARK: - Theme Preview Helpers
extension Theme {
    static var preview: Theme {
        Theme.defaultTheme
    }
    
    var isLight: Bool {
        // Simple heuristic to determine if theme is light or dark
        let bg = colorScheme.appBackground.color
        return bg.luminance > 0.5
    }
}

// MARK: - Color Luminance Extension
extension Color {
    var luminance: Double {
        let uiColor = UIColor(self)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        // Calculate relative luminance
        let rL = red <= 0.03928 ? red / 12.92 : pow((red + 0.055) / 1.055, 2.4)
        let gL = green <= 0.03928 ? green / 12.92 : pow((green + 0.055) / 1.055, 2.4)
        let bL = blue <= 0.03928 ? blue / 12.92 : pow((blue + 0.055) / 1.055, 2.4)
        
        return 0.2126 * rL + 0.7152 * gL + 0.0722 * bL
    }
}
