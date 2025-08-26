//
//  PredefinedThemes.swift
//  Routine Anchor
//
//  Predefined theme definitions with color schemes
//
import SwiftUI
import Foundation

// MARK: - Theme Repository
struct PredefinedThemes {
    
    // MARK: - Default Theme (Free)
    static let defaultTheme = Theme(
        id: "default",
        name: "Routine Classic",
        description: "The original Routine Anchor experience",
        isPremium: false,
        colorScheme: ThemeColorScheme(
            primary: ColorHex("#007AFF"),
            secondary: ColorHex("#5856D6"),
            tertiary: ColorHex("#AF52DE"),
            backgroundPrimary: ColorHex("#000000"),
            backgroundSecondary: ColorHex("#1C1C1E"),
            backgroundTertiary: ColorHex("#2C2C2E"),
            surfacePrimary: ColorHex("#1C1C1E"),
            surfaceSecondary: ColorHex("#2C2C2E"),
            textPrimary: ColorHex("#FFFFFF"),
            textSecondary: ColorHex("#EBEBF5CC"),
            textTertiary: ColorHex("#EBEBF599"),
            accent: ColorHex("#007AFF"),
            warning: ColorHex("#FF9500"),
            success: ColorHex("#30D158"),
            error: ColorHex("#FF3B30"),
            blue: ColorHex("#007AFF"),
            green: ColorHex("#30D158"),
            purple: ColorHex("#AF52DE"),
            teal: ColorHex("#5AC8FA"),
            orange: ColorHex("#FF9500"),
            glassTint: ColorHex("#FFFFFF"),
            glassOpacity: 0.1,
            gradientColors: [
                ColorHex("#007AFF"),
                ColorHex("#5856D6"),
                ColorHex("#AF52DE")
            ]
        ),
        gradientStyle: .linear,
        icon: "paintbrush.fill",
        category: .minimal
    )
    
    // MARK: - Premium Themes
    
    // Ocean Breeze Theme
    static let oceanBreeze = Theme(
        id: "ocean_breeze",
        name: "Ocean Breeze",
        description: "Calming blues and teals inspired by ocean waves",
        isPremium: true,
        colorScheme: ThemeColorScheme(
            primary: ColorHex("#0077BE"),
            secondary: ColorHex("#00A8CC"),
            tertiary: ColorHex("#40E0D0"),
            backgroundPrimary: ColorHex("#001B2E"),
            backgroundSecondary: ColorHex("#003459"),
            backgroundTertiary: ColorHex("#004D7A"),
            surfacePrimary: ColorHex("#003459"),
            surfaceSecondary: ColorHex("#004D7A"),
            textPrimary: ColorHex("#FFFFFF"),
            textSecondary: ColorHex("#B8E6FF"),
            textTertiary: ColorHex("#8DC8E8"),
            accent: ColorHex("#40E0D0"),
            warning: ColorHex("#FFB347"),
            success: ColorHex("#7FFFD4"),
            error: ColorHex("#FF6B6B"),
            blue: ColorHex("#0077BE"),
            green: ColorHex("#7FFFD4"),
            purple: ColorHex("#6A5ACD"),
            teal: ColorHex("#40E0D0"),
            orange: ColorHex("#FFB347"),
            glassTint: ColorHex("#40E0D0"),
            glassOpacity: 0.15,
            gradientColors: [
                ColorHex("#001B2E"),
                ColorHex("#003459"),
                ColorHex("#0077BE"),
                ColorHex("#40E0D0")
            ]
        ),
        gradientStyle: .radial,
        icon: "water.waves",
        category: .nature
    )
    
    // Sunset Glow Theme
    static let sunsetGlow = Theme(
        id: "sunset_glow",
        name: "Sunset Glow",
        description: "Warm oranges and pinks of a beautiful sunset",
        isPremium: true,
        colorScheme: ThemeColorScheme(
            primary: ColorHex("#FF6B35"),
            secondary: ColorHex("#F7931E"),
            tertiary: ColorHex("#FFD23F"),
            backgroundPrimary: ColorHex("#2D1B16"),
            backgroundSecondary: ColorHex("#4A2C20"),
            backgroundTertiary: ColorHex("#6B3E2A"),
            surfacePrimary: ColorHex("#4A2C20"),
            surfaceSecondary: ColorHex("#6B3E2A"),
            textPrimary: ColorHex("#FFFFFF"),
            textSecondary: ColorHex("#FFE4D6"),
            textTertiary: ColorHex("#D4B5A0"),
            accent: ColorHex("#FF6B35"),
            warning: ColorHex("#FFD23F"),
            success: ColorHex("#98D8C8"),
            error: ColorHex("#FF5757"),
            blue: ColorHex("#74A9CF"),
            green: ColorHex("#98D8C8"),
            purple: ColorHex("#C5A3FF"),
            teal: ColorHex("#7DD3C0"),
            orange: ColorHex("#FF6B35"),
            glassTint: ColorHex("#FF6B35"),
            glassOpacity: 0.12,
            gradientColors: [
                ColorHex("#2D1B16"),
                ColorHex("#4A2C20"),
                ColorHex("#FF6B35"),
                ColorHex("#FFD23F")
            ]
        ),
        gradientStyle: .angular,
        icon: "sun.max.fill",
        category: .vibrant
    )
    
    // Forest Twilight Theme
    static let forestTwilight = Theme(
        id: "forest_twilight",
        name: "Forest Twilight",
        description: "Deep greens and earthy tones of a mystical forest",
        isPremium: true,
        colorScheme: ThemeColorScheme(
            primary: ColorHex("#2D5016"),
            secondary: ColorHex("#4F7942"),
            tertiary: ColorHex("#7BA05B"),
            backgroundPrimary: ColorHex("#0F1A0A"),
            backgroundSecondary: ColorHex("#1E2F16"),
            backgroundTertiary: ColorHex("#2D4422"),
            surfacePrimary: ColorHex("#1E2F16"),
            surfaceSecondary: ColorHex("#2D4422"),
            textPrimary: ColorHex("#FFFFFF"),
            textSecondary: ColorHex("#D4E6C7"),
            textTertiary: ColorHex("#A8C99A"),
            accent: ColorHex("#7BA05B"),
            warning: ColorHex("#D4A574"),
            success: ColorHex("#7BA05B"),
            error: ColorHex("#C5705D"),
            blue: ColorHex("#6B9DC2"),
            green: ColorHex("#7BA05B"),
            purple: ColorHex("#8B7CA6"),
            teal: ColorHex("#5D8A72"),
            orange: ColorHex("#D4A574"),
            glassTint: ColorHex("#7BA05B"),
            glassOpacity: 0.18,
            gradientColors: [
                ColorHex("#0F1A0A"),
                ColorHex("#1E2F16"),
                ColorHex("#2D5016"),
                ColorHex("#7BA05B")
            ]
        ),
        gradientStyle: .linear,
        icon: "tree.fill",
        category: .nature
    )
    
    // Midnight Professional Theme
    static let midnightProfessional = Theme(
        id: "midnight_professional",
        name: "Midnight Professional",
        description: "Sleek dark theme perfect for focus and productivity",
        isPremium: true,
        colorScheme: ThemeColorScheme(
            primary: ColorHex("#1A1A1A"),
            secondary: ColorHex("#2A2A2A"),
            tertiary: ColorHex("#3A3A3A"),
            backgroundPrimary: ColorHex("#0A0A0A"),
            backgroundSecondary: ColorHex("#1A1A1A"),
            backgroundTertiary: ColorHex("#2A2A2A"),
            surfacePrimary: ColorHex("#1A1A1A"),
            surfaceSecondary: ColorHex("#2A2A2A"),
            textPrimary: ColorHex("#FFFFFF"),
            textSecondary: ColorHex("#B0B0B0"),
            textTertiary: ColorHex("#808080"),
            accent: ColorHex("#0099FF"),
            warning: ColorHex("#FF8C00"),
            success: ColorHex("#00CC66"),
            error: ColorHex("#FF4444"),
            blue: ColorHex("#0099FF"),
            green: ColorHex("#00CC66"),
            purple: ColorHex("#9966CC"),
            teal: ColorHex("#00CCAA"),
            orange: ColorHex("#FF8C00"),
            glassTint: ColorHex("#FFFFFF"),
            glassOpacity: 0.08,
            gradientColors: [
                ColorHex("#0A0A0A"),
                ColorHex("#1A1A1A"),
                ColorHex("#2A2A2A")
            ]
        ),
        gradientStyle: .linear,
        icon: "moon.fill",
        category: .professional
    )
    
    // Aurora Borealis Theme
    static let auroraBorealis = Theme(
        id: "aurora_borealis",
        name: "Aurora Borealis",
        description: "Magical greens and purples of the northern lights",
        isPremium: true,
        colorScheme: ThemeColorScheme(
            primary: ColorHex("#00FF7F"),
            secondary: ColorHex("#9370DB"),
            tertiary: ColorHex("#FF1493"),
            backgroundPrimary: ColorHex("#0D1B2A"),
            backgroundSecondary: ColorHex("#1B263B"),
            backgroundTertiary: ColorHex("#415A77"),
            surfacePrimary: ColorHex("#1B263B"),
            surfaceSecondary: ColorHex("#415A77"),
            textPrimary: ColorHex("#FFFFFF"),
            textSecondary: ColorHex("#E0AAFF"),
            textTertiary: ColorHex("#C77DFF"),
            accent: ColorHex("#00FF7F"),
            warning: ColorHex("#FFD23F"),
            success: ColorHex("#00FF7F"),
            error: ColorHex("#FF1493"),
            blue: ColorHex("#7209B7"),
            green: ColorHex("#00FF7F"),
            purple: ColorHex("#9370DB"),
            teal: ColorHex("#5DADE2"),
            orange: ColorHex("#FF6B35"),
            glassTint: ColorHex("#9370DB"),
            glassOpacity: 0.2,
            gradientColors: [
                ColorHex("#0D1B2A"),
                ColorHex("#1B263B"),
                ColorHex("#9370DB"),
                ColorHex("#00FF7F"),
                ColorHex("#FF1493")
            ]
        ),
        gradientStyle: .angular,
        icon: "sparkles",
        category: .gradient
    )
    
    // Cherry Blossom Theme
    static let cherryBlossom = Theme(
        id: "cherry_blossom",
        name: "Cherry Blossom",
        description: "Soft pinks and whites inspired by Japanese sakura",
        isPremium: true,
        colorScheme: ThemeColorScheme(
            primary: ColorHex("#FFB7C5"),
            secondary: ColorHex("#FFC0CB"),
            tertiary: ColorHex("#F8BBD9"),
            backgroundPrimary: ColorHex("#2C1B1F"),
            backgroundSecondary: ColorHex("#3D252A"),
            backgroundTertiary: ColorHex("#4E2F35"),
            surfacePrimary: ColorHex("#3D252A"),
            surfaceSecondary: ColorHex("#4E2F35"),
            textPrimary: ColorHex("#FFFFFF"),
            textSecondary: ColorHex("#FFE4E8"),
            textTertiary: ColorHex("#E8C2CA"),
            accent: ColorHex("#FFB7C5"),
            warning: ColorHex("#FFD700"),
            success: ColorHex("#98FB98"),
            error: ColorHex("#FA8072"),
            blue: ColorHex("#B0C4DE"),
            green: ColorHex("#98FB98"),
            purple: ColorHex("#DDA0DD"),
            teal: ColorHex("#AFEEEE"),
            orange: ColorHex("#FFDAB9"),
            glassTint: ColorHex("#FFB7C5"),
            glassOpacity: 0.15,
            gradientColors: [
                ColorHex("#2C1B1F"),
                ColorHex("#3D252A"),
                ColorHex("#FFB7C5"),
                ColorHex("#F8BBD9")
            ]
        ),
        gradientStyle: .radial,
        icon: "leaf.fill",
        category: .nature
    )
    
    // Electric Neon Theme
    static let electricNeon = Theme(
        id: "electric_neon",
        name: "Electric Neon",
        description: "Bold neons and electric colors for high energy",
        isPremium: true,
        colorScheme: ThemeColorScheme(
            primary: ColorHex("#00FFFF"),
            secondary: ColorHex("#FF00FF"),
            tertiary: ColorHex("#FFFF00"),
            backgroundPrimary: ColorHex("#0A0A0A"),
            backgroundSecondary: ColorHex("#1A0A1A"),
            backgroundTertiary: ColorHex("#2A0A2A"),
            surfacePrimary: ColorHex("#1A0A1A"),
            surfaceSecondary: ColorHex("#2A0A2A"),
            textPrimary: ColorHex("#FFFFFF"),
            textSecondary: ColorHex("#00FFFF"),
            textTertiary: ColorHex("#FF00FF"),
            accent: ColorHex("#00FFFF"),
            warning: ColorHex("#FFFF00"),
            success: ColorHex("#00FF00"),
            error: ColorHex("#FF0040"),
            blue: ColorHex("#0080FF"),
            green: ColorHex("#00FF00"),
            purple: ColorHex("#FF00FF"),
            teal: ColorHex("#00FFFF"),
            orange: ColorHex("#FF8000"),
            glassTint: ColorHex("#00FFFF"),
            glassOpacity: 0.25,
            gradientColors: [
                ColorHex("#0A0A0A"),
                ColorHex("#FF00FF"),
                ColorHex("#00FFFF"),
                ColorHex("#FFFF00")
            ]
        ),
        gradientStyle: .angular,
        icon: "bolt.fill",
        category: .vibrant
    )
    
    // MARK: - All Themes Collection
    static let allThemes: [Theme] = [
        defaultTheme,
        oceanBreeze,
        sunsetGlow,
        forestTwilight,
        midnightProfessional,
        auroraBorealis,
        cherryBlossom,
        electricNeon
    ]
    
    // MARK: - Free Themes
    static let freeThemes: [Theme] = {
        allThemes.filter { !$0.isPremium }
    }()
    
    // MARK: - Premium Themes
    static let premiumThemes: [Theme] = {
        allThemes.filter { $0.isPremium }
    }()
    
    // MARK: - Themes by Category
    static func themes(for category: ThemeCategory) -> [Theme] {
        allThemes.filter { $0.category == category }
    }
    
    // MARK: - Theme Lookup
    static func theme(withId id: String) -> Theme? {
        allThemes.first { $0.id == id }
    }
}

// MARK: - Theme Extensions for Default Values
extension Theme {
    static let defaultTheme = PredefinedThemes.defaultTheme
    
    static var allAvailable: [Theme] {
        PredefinedThemes.allThemes
    }
    
    static var freeThemes: [Theme] {
        PredefinedThemes.freeThemes
    }
    
    static var premiumThemes: [Theme] {
        PredefinedThemes.premiumThemes
    }
}
