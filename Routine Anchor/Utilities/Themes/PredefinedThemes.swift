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
            // Core actions
            buttonPrimary:    ColorHex("#0A84FF"),
            buttonSecondary:  ColorHex("#6E5AE6"),
            tertiary:         ColorHex("#B084F5"),

            // Base surfaces
            appBackground:    ColorHex("#000000"),  // OLED black
            cardBackground:   ColorHex("#131834"),  // kept for back-compat (== surface1)
            overlayBackground:ColorHex("#1C1F2E"),

            // UI “element” surfaces (kept for back-compat)
            uiElementPrimary:   ColorHex("#1A2145"),
            uiElementSecondary: ColorHex("#212A57"),

            // Text
            primaryText:     ColorHex("#FFFFFF"),
            secondaryText:   ColorHex("#D7E0FF"),
            subtleText:      ColorHex("#9AA4C0"),   // ↑ contrast vs old #B8BED6

            // Accents / status
            buttonAccent:    ColorHex("#64D2FF"),
            warningColor:    ColorHex("#FF9F0A"),
            successColor:    ColorHex("#32D74B"),
            errorColor:      ColorHex("#FF453A"),

            // Feature accents / categories
            workflowPrimary:     ColorHex("#64D2FF"), // modern cyan used across Focus/Stats
            actionSuccess:       ColorHex("#32D74B"),
            organizationAccent:  ColorHex("#6E5AE6"),
            creativeSecondary:   ColorHex("#64D2FF"),
            socialAccent:        ColorHex("#FF9F0A"),
            
            // Elevation scale
            surface0: ColorHex("#0E1228"),
            surface1: ColorHex("#131834"),
            surface2: ColorHex("#1A2145"),
            surface3: ColorHex("#212A57"),

            // Lines & focus
            divider:   ColorHex("#2B3152"),
            border:    ColorHex("#3B4474"),
            focusRing: ColorHex("#7DB7FF"),

            // Today hero (used by ThemedAnimatedBackground on TodayView)
            todayHeroTop:             ColorHex("#0F1630"),
            todayHeroBottom:          ColorHex("#1D1C53"),
            todayHeroVignette:        ColorHex("#2E0B5F"),
            todayHeroVignetteOpacity: 0.18,

            // Progress & rings (used in FocusCard / ProgressOverview / Time blocks)
            progressTrack:      ColorHex("#2B3152"),
            progressFillStart:  ColorHex("#32D74B"),
            progressFillEnd:    ColorHex("#64D2FF"),
            ringOuterAlpha:     0.30,
            ringInnerStartAlpha:0.30,
            ringInnerEndAlpha:  0.10,

            // Scrim for sheets/menus
            scrim: ColorHex("#000000"),

            // Charts (for Analytics + QuickStats)
            chartPalette: [
                ColorHex("#0A84FF"),
                ColorHex("#6E5AE6"),
                ColorHex("#64D2FF"),
                ColorHex("#32D74B"),
                ColorHex("#FF9F0A"),
                ColorHex("#FFD66B"),
                ColorHex("#FF6B6B"),
                ColorHex("#F472B6")
            ],
            chartGrid:  ColorHex("#2B3152"),
            chartLabel: ColorHex("#9AA4C0"),

            // Glass / glow
            glassTint:         ColorHex("#9AA9FF"),
            glassOpacity:      0.08,
            glowIntensityPrimary:   0.35,
            glowIntensitySecondary: 0.15,
            glowBlurRadius:    30,
            glowRadiusInner:   32,
            glowRadiusOuter:   84,
            glowAnimationScale:1.4,

            // Background gradients (general use)
            gradientColors: [
                ColorHex("#0A84FF"),
                ColorHex("#6E5AE6"),
                ColorHex("#B084F5")
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
