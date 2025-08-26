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
    let primary: ColorHex
    let secondary: ColorHex
    let tertiary: ColorHex
    
    // Background Colors
    let backgroundPrimary: ColorHex
    let backgroundSecondary: ColorHex
    let backgroundTertiary: ColorHex
    
    // Surface Colors
    let surfacePrimary: ColorHex
    let surfaceSecondary: ColorHex
    
    // Text Colors
    let textPrimary: ColorHex
    let textSecondary: ColorHex
    let textTertiary: ColorHex
    
    // Accent Colors
    let accent: ColorHex
    let warning: ColorHex
    let success: ColorHex
    let error: ColorHex
    
    // Special Colors
    let blue: ColorHex
    let green: ColorHex
    let purple: ColorHex
    let teal: ColorHex
    let orange: ColorHex
    
    // Glass morphism effect
    let glassTint: ColorHex
    let glassOpacity: Double
    
    // Gradient colors for backgrounds
    let gradientColors: [ColorHex]
    
    init(
        primary: ColorHex,
        secondary: ColorHex,
        tertiary: ColorHex,
        backgroundPrimary: ColorHex,
        backgroundSecondary: ColorHex,
        backgroundTertiary: ColorHex,
        surfacePrimary: ColorHex,
        surfaceSecondary: ColorHex,
        textPrimary: ColorHex,
        textSecondary: ColorHex,
        textTertiary: ColorHex,
        accent: ColorHex,
        warning: ColorHex,
        success: ColorHex,
        error: ColorHex,
        blue: ColorHex,
        green: ColorHex,
        purple: ColorHex,
        teal: ColorHex,
        orange: ColorHex,
        glassTint: ColorHex,
        glassOpacity: Double = 0.1,
        gradientColors: [ColorHex]
    ) {
        self.primary = primary
        self.secondary = secondary
        self.tertiary = tertiary
        self.backgroundPrimary = backgroundPrimary
        self.backgroundSecondary = backgroundSecondary
        self.backgroundTertiary = backgroundTertiary
        self.surfacePrimary = surfacePrimary
        self.surfaceSecondary = surfaceSecondary
        self.textPrimary = textPrimary
        self.textSecondary = textSecondary
        self.textTertiary = textTertiary
        self.accent = accent
        self.warning = warning
        self.success = success
        self.error = error
        self.blue = blue
        self.green = green
        self.purple = purple
        self.teal = teal
        self.orange = orange
        self.glassTint = glassTint
        self.glassOpacity = glassOpacity
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
            (a, r, g, b) = (1, 1, 1, 0)
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

// MARK: - Theme Extensions
extension Theme {
    // Computed properties for easy access to colors
    var primaryColor: Color { colorScheme.primary.color }
    var secondaryColor: Color { colorScheme.secondary.color }
    var tertiaryColor: Color { colorScheme.tertiary.color }
    var accentColor: Color { colorScheme.accent.color }
    
    var backgroundColors: [Color] {
        colorScheme.gradientColors.map { $0.color }
    }
    
    var textPrimaryColor: Color { colorScheme.textPrimary.color }
    var textSecondaryColor: Color { colorScheme.textSecondary.color }
    var textTertiaryColor: Color { colorScheme.textTertiary.color }
    
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
        let bg = colorScheme.backgroundPrimary.color
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
