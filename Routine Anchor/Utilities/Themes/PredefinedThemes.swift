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
            buttonPrimary: ColorHex("#007AFF"), //primary
            buttonSecondary: ColorHex("#5856D6"), //secondary
            tertiary: ColorHex("#AF52DE"), //tertiary - keep for gradient completion
            appBackground: ColorHex("#000000"), //backgroundPrimary
            cardBackground: ColorHex("#1C1C1E"), //backgroundSecondary - dark cards
            overlayBackground: ColorHex("#2C2C2E"), //backgroundTertiary - modal backgrounds
            uiElementPrimary: ColorHex("#1C1C2E"), //surfacePrimary
            uiElementSecondary: ColorHex("#2C2C3E"), //surfaceSecondary
            primaryText: ColorHex("#FFFFFF"), //textPrimary
            secondaryText: ColorHex("#E5E5E7"), //textSecondary
            subtleText: ColorHex("#AEAEB2"), //textTertiary
            buttonAccent: ColorHex("#007AFF"), //accent
            warningColor: ColorHex("#FF9500"), //warning
            successColor: ColorHex("#30D158"), //success
            errorColor: ColorHex("#FF3B30"), //error
            workflowPrimary: ColorHex("#007AFF"), //blue
            actionSuccess: ColorHex("#32D74B"), //green
            organizationAccent: ColorHex("#5856D6"), //purple
            creativeSecondary: ColorHex("#64D2FF"), //teal
            socialAccent: ColorHex("#FF9500"), //orange
            glassTint: ColorHex("#FFFFFF"), //glassTint - for glass effects
            glassOpacity: 0.1, //0.1 - restore for glass effects
            glowIntensityPrimary: 0.2, //0.2 - restore for button glows
            glowIntensitySecondary: 0.1, //0.1 - restore for subtle glows
            glowBlurRadius: 15, //15 - restore for glow effects
            glowRadiusInner: 25, //25 - restore for radial effects
            glowRadiusOuter: 70, //70 - restore for outer glow
            glowAnimationScale: 1.2, //1.2 - restore for animations
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
    /*
    static let arcticDawnTheme = Theme(
        id: "arctic-dawn",
        name: "Arctic Dawn",
        description: "Crisp winter morning vibes with cool blues and pristine whites",
        isPremium: true,
        colorScheme: ThemeColorScheme(
            primary: ColorHex("#000000"),
            secondary: ColorHex("#000000"),
            tertiary: ColorHex("#000000"),
            backgroundPrimary: ColorHex("#000000"),
            backgroundSecondary: ColorHex("#000000"),
            backgroundTertiary: ColorHex("#000000"),
            surfacePrimary: ColorHex("#000000"),
            surfaceSecondary: ColorHex("#000000"),
            textPrimary: ColorHex("#000000"),
            textSecondary: ColorHex("#000000"),
            textTertiary: ColorHex("#000000"),
            accent: ColorHex("#000000"),
            warning: ColorHex("#000000"),
            success: ColorHex("#000000"),
            error: ColorHex("#000000"),
            blue: ColorHex("#000000"),
            green: ColorHex("#000000"),
            purple: ColorHex("#000000"),
            teal: ColorHex("#000000"),
            orange: ColorHex("#000000"),
            glassTint: ColorHex("#000000"),
            glassOpacity: 0.0, //0.1
            glowIntensityPrimary: 0.0,  //0.2
            glowIntensitySecondary: 0.0, //0.1
            glowBlurRadius: 0, //15
            glowRadiusInner: 0, //25
            glowRadiusOuter: 0, //70
            glowAnimationScale: 0, //1.2
            gradientColors: [
                ColorHex("#E3F2FD"),
                ColorHex("#64B5F6"),
                ColorHex("#1976D2")
            ]
        ),
        gradientStyle: .linear,
        icon: "snow",
        category: .minimal
    )
    
    static let forestSanctuaryTheme = Theme(
        id: "forest-sanctuary",
        name: "Forest Sanctuary",
        description: "Find focus in nature's calm - deep greens and earthy tones",
        isPremium: true,
        colorScheme: ThemeColorScheme(
            primary: ColorHex("#000000"),
            secondary: ColorHex("#000000"),
            tertiary: ColorHex("#000000"),
            backgroundPrimary: ColorHex("#000000"),
            backgroundSecondary: ColorHex("#000000"),
            backgroundTertiary: ColorHex("#000000"),
            surfacePrimary: ColorHex("#000000"),
            surfaceSecondary: ColorHex("#000000"),
            textPrimary: ColorHex("#000000"),
            textSecondary: ColorHex("#000000"),
            textTertiary: ColorHex("#000000"),
            accent: ColorHex("#000000"),
            warning: ColorHex("#000000"),
            success: ColorHex("#000000"),
            error: ColorHex("#000000"),
            blue: ColorHex("#000000"),
            green: ColorHex("#000000"),
            purple: ColorHex("#000000"),
            teal: ColorHex("#000000"),
            orange: ColorHex("#000000"),
            glassTint: ColorHex("#000000"),
            glassOpacity: 0.0, //0.1
            glowIntensityPrimary: 0.0,  //0.2
            glowIntensitySecondary: 0.0, //0.1
            glowBlurRadius: 0, //15
            glowRadiusInner: 0, //25
            glowRadiusOuter: 0, //70
            glowAnimationScale: 0, //1.2
            gradientColors: [
                ColorHex("#E8F5E8"),
                ColorHex("#4CAF50"),
                ColorHex("#1B5E20")
            ]
        ),
        gradientStyle: .linear,
        icon: "leaf.fill",
        category: .nature
    )
    
    static let sunsetHarborTheme = Theme(
        id: "sunset-harbor",
        name: "Sunset Harbor",
        description: "Golden hour productivity with warm oranges flowing to deep purples",
        isPremium: true,
        colorScheme: ThemeColorScheme(
            primary: ColorHex("#000000"),
            secondary: ColorHex("#000000"),
            tertiary: ColorHex("#000000"),
            backgroundPrimary: ColorHex("#000000"),
            backgroundSecondary: ColorHex("#000000"),
            backgroundTertiary: ColorHex("#000000"),
            surfacePrimary: ColorHex("#000000"),
            surfaceSecondary: ColorHex("#000000"),
            textPrimary: ColorHex("#000000"),
            textSecondary: ColorHex("#000000"),
            textTertiary: ColorHex("#000000"),
            accent: ColorHex("#000000"),
            warning: ColorHex("#000000"),
            success: ColorHex("#000000"),
            error: ColorHex("#000000"),
            blue: ColorHex("#000000"),
            green: ColorHex("#000000"),
            purple: ColorHex("#000000"),
            teal: ColorHex("#000000"),
            orange: ColorHex("#000000"),
            glassTint: ColorHex("#000000"),
            glassOpacity: 0.0, //0.1
            glowIntensityPrimary: 0.0,  //0.2
            glowIntensitySecondary: 0.0, //0.1
            glowBlurRadius: 0, //15
            glowRadiusInner: 0, //25
            glowRadiusOuter: 0, //70
            glowAnimationScale: 0, //1.2
            gradientColors: [
                ColorHex("#FFE0B2"),
                ColorHex("#FF9800"),
                ColorHex("#673AB7")
            ]
        ),
        gradientStyle: .linear,
        icon: "leaf.fill",
        category: .vibrant
    )
    
    static let midnightFocusTheme = Theme(
        id: "midnight-focus",
        name: "Midnight Focus",
        description: "Deep focus for night owls - rich purples and cosmic blues",
        isPremium: true,
        colorScheme: ThemeColorScheme(
            primary: ColorHex("#000000"),
            secondary: ColorHex("#000000"),
            tertiary: ColorHex("#000000"),
            backgroundPrimary: ColorHex("#000000"),
            backgroundSecondary: ColorHex("#000000"),
            backgroundTertiary: ColorHex("#000000"),
            surfacePrimary: ColorHex("#000000"),
            surfaceSecondary: ColorHex("#000000"),
            textPrimary: ColorHex("#000000"),
            textSecondary: ColorHex("#000000"),
            textTertiary: ColorHex("#000000"),
            accent: ColorHex("#000000"),
            warning: ColorHex("#000000"),
            success: ColorHex("#000000"),
            error: ColorHex("#000000"),
            blue: ColorHex("#000000"),
            green: ColorHex("#000000"),
            purple: ColorHex("#000000"),
            teal: ColorHex("#000000"),
            orange: ColorHex("#000000"),
            glassTint: ColorHex("#000000"),
            glassOpacity: 0.0, //0.1
            glowIntensityPrimary: 0.0,  //0.2
            glowIntensitySecondary: 0.0, //0.1
            glowBlurRadius: 0, //15
            glowRadiusInner: 0, //25
            glowRadiusOuter: 0, //70
            glowAnimationScale: 0, //1.2
            gradientColors: [
                ColorHex("#1A1A2E"),
                ColorHex("#16213E"),
                ColorHex("#0F3460")
            ]
        ),
        gradientStyle: .radial,
        icon: "moon.stars.fill",
        category: .dark
    )
    
    static let roseGoldStudioTheme = Theme(
        id: "rose-gold-studio",
        name: "Rose Gold Studio",
        description: "Creative elegance with soft pinks and metallic accents",
        isPremium: true,
        colorScheme: ThemeColorScheme(
            primary: ColorHex("#000000"),
            secondary: ColorHex("#000000"),
            tertiary: ColorHex("#000000"),
            backgroundPrimary: ColorHex("#000000"),
            backgroundSecondary: ColorHex("#000000"),
            backgroundTertiary: ColorHex("#000000"),
            surfacePrimary: ColorHex("#000000"),
            surfaceSecondary: ColorHex("#000000"),
            textPrimary: ColorHex("#000000"),
            textSecondary: ColorHex("#000000"),
            textTertiary: ColorHex("#000000"),
            accent: ColorHex("#000000"),
            warning: ColorHex("#000000"),
            success: ColorHex("#000000"),
            error: ColorHex("#000000"),
            blue: ColorHex("#000000"),
            green: ColorHex("#000000"),
            purple: ColorHex("#000000"),
            teal: ColorHex("#000000"),
            orange: ColorHex("#000000"),
            glassTint: ColorHex("#000000"),
            glassOpacity: 0.0, //0.1
            glowIntensityPrimary: 0.0,  //0.2
            glowIntensitySecondary: 0.0, //0.1
            glowBlurRadius: 0, //15
            glowRadiusInner: 0, //25
            glowRadiusOuter: 0, //70
            glowAnimationScale: 0, //1.2
            gradientColors: [
                ColorHex("#FCE4EC"),
                ColorHex("#F06292"),
                ColorHex("#AD1457")
            ]
        ),
        gradientStyle: .linear,
        icon: "paintpalette.fill",
        category: .gradient
    )
    
    static let oceanDepthsTheme = Theme(
        id: "ocean-depths",
        name: "Ocean Depths",
        description: "Corporate confidence with deep teals and professional blues",
        isPremium: true,
        colorScheme: ThemeColorScheme(
            primary: ColorHex("#000000"),
            secondary: ColorHex("#000000"),
            tertiary: ColorHex("#000000"),
            backgroundPrimary: ColorHex("#000000"),
            backgroundSecondary: ColorHex("#000000"),
            backgroundTertiary: ColorHex("#000000"),
            surfacePrimary: ColorHex("#000000"),
            surfaceSecondary: ColorHex("#000000"),
            textPrimary: ColorHex("#000000"),
            textSecondary: ColorHex("#000000"),
            textTertiary: ColorHex("#000000"),
            accent: ColorHex("#000000"),
            warning: ColorHex("#000000"),
            success: ColorHex("#000000"),
            error: ColorHex("#000000"),
            blue: ColorHex("#000000"),
            green: ColorHex("#000000"),
            purple: ColorHex("#000000"),
            teal: ColorHex("#000000"),
            orange: ColorHex("#000000"),
            glassTint: ColorHex("#000000"),
            glassOpacity: 0.0, //0.1
            glowIntensityPrimary: 0.0,  //0.2
            glowIntensitySecondary: 0.0, //0.1
            glowBlurRadius: 0, //15
            glowRadiusInner: 0, //25
            glowRadiusOuter: 0, //70
            glowAnimationScale: 0, //1.2
            gradientColors: [
                ColorHex("#E0F2F1"),
                ColorHex("#26A69A"),
                ColorHex("#004D40")
            ]
        ),
        gradientStyle: .linear,
        icon: "water.waves",
        category: .professional
    )
    
    static let solarFlareTheme = Theme(
        id: "solar-flare",
        name: "Solar Flare",
        description: "Energizing brightness with yellow to orange fire gradients",
        isPremium: true,
        colorScheme: ThemeColorScheme(
            primary: ColorHex("#000000"),
            secondary: ColorHex("#000000"),
            tertiary: ColorHex("#000000"),
            backgroundPrimary: ColorHex("#000000"),
            backgroundSecondary: ColorHex("#000000"),
            backgroundTertiary: ColorHex("#000000"),
            surfacePrimary: ColorHex("#000000"),
            surfaceSecondary: ColorHex("#000000"),
            textPrimary: ColorHex("#000000"),
            textSecondary: ColorHex("#000000"),
            textTertiary: ColorHex("#000000"),
            accent: ColorHex("#000000"),
            warning: ColorHex("#000000"),
            success: ColorHex("#000000"),
            error: ColorHex("#000000"),
            blue: ColorHex("#000000"),
            green: ColorHex("#000000"),
            purple: ColorHex("#000000"),
            teal: ColorHex("#000000"),
            orange: ColorHex("#000000"),
            glassTint: ColorHex("#000000"),
            glassOpacity: 0.0, //0.1
            glowIntensityPrimary: 0.0,  //0.2
            glowIntensitySecondary: 0.0, //0.1
            glowBlurRadius: 0, //15
            glowRadiusInner: 0, //25
            glowRadiusOuter: 0, //70
            glowAnimationScale: 0, //1.2
            gradientColors: [
                ColorHex("#FFF9C4"),
                ColorHex("#FFEB3B"),
                ColorHex("#FF6F00")
            ]
        ),
        gradientStyle: .radial,
        icon: "sun.max.fill",
        category: .vibrant
    )
    
    static let lavenderDreamsTheme = Theme(
        id: "lavender-dreams",
        name: "Lavender Dreams",
        description: "Soft focus and gentle productivity with calming purple tones",
        isPremium: true,
        colorScheme: ThemeColorScheme(
            primary: ColorHex("#000000"),
            secondary: ColorHex("#000000"),
            tertiary: ColorHex("#000000"),
            backgroundPrimary: ColorHex("#000000"),
            backgroundSecondary: ColorHex("#000000"),
            backgroundTertiary: ColorHex("#000000"),
            surfacePrimary: ColorHex("#000000"),
            surfaceSecondary: ColorHex("#000000"),
            textPrimary: ColorHex("#000000"),
            textSecondary: ColorHex("#000000"),
            textTertiary: ColorHex("#000000"),
            accent: ColorHex("#000000"),
            warning: ColorHex("#000000"),
            success: ColorHex("#000000"),
            error: ColorHex("#000000"),
            blue: ColorHex("#000000"),
            green: ColorHex("#000000"),
            purple: ColorHex("#000000"),
            teal: ColorHex("#000000"),
            orange: ColorHex("#000000"),
            glassTint: ColorHex("#000000"),
            glassOpacity: 0.0, //0.1
            glowIntensityPrimary: 0.0,  //0.2
            glowIntensitySecondary: 0.0, //0.1
            glowBlurRadius: 0, //15
            glowRadiusInner: 0, //25
            glowRadiusOuter: 0, //70
            glowAnimationScale: 0, //1.2
            gradientColors: [
                ColorHex("#F3E5F5"),
                ColorHex("#BA68C8"),
                ColorHex("#6A1B9A")
            ]
        ),
        gradientStyle: .mesh,
        icon: "cloud.drizzle.fill",
        category: .gradient
    )
     */
    
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
