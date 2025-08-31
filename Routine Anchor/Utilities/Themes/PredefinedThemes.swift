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
            textSecondary: ColorHex("#EBEBF5"),
            textTertiary: ColorHex("#EBEBF5"),
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
            glowIntensityPrimary: 0.2,
            glowIntensitySecondary: 0.1,
            glowBlurRadius: 15,
            glowRadiusInner: 25,
            glowRadiusOuter: 70,
            glowAnimationScale: 1.2,
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
    
    // MARK: - All Themes Collection
    static let allThemes: [Theme] = [
        defaultTheme
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
