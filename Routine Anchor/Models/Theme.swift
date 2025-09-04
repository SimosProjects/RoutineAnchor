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
        glassTint: ColorHex,
        glassOpacity: Double = 0.1,
        glowIntensityPrimary: Double = 0.15,
        glowIntensitySecondary: Double = 0.08,
        glowBlurRadius: Double = 10,
        glowRadiusInner: Double = 20,
        glowRadiusOuter: Double = 60,
        glowAnimationScale: Double = 1.15,
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
    
    var primaryTextColor: Color { colorScheme.primaryText.color }
    var secondaryTextColor: Color { colorScheme.secondaryText.color }
    var subtleTextColor: Color { colorScheme.subtleText.color }
    
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
