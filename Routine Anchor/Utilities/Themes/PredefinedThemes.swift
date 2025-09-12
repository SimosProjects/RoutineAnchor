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
            // Background Colors
            primaryBackground: ColorHex("#F8FAFC"), // full screen backgrounds
            secondaryBackground: ColorHex("#FFFFFF"), // stacked sections / sheets
            elevatedBackground: ColorHex("#F1F5F9"), // cards, popovers, glass layers
            backgroundColors: [
                ColorHex("#F8FAFC"),
                ColorHex("#EFF6FF")
            ],
            
            // Text Colors
            primaryText: ColorHex("#111827"), // titles
            secondaryText: ColorHex("#374151"), // body / description
            subtleText: ColorHex("#6B7280"),   // captions / meta
            invertedText: ColorHex("#FFFFFF"), // text on bold accents (e.g. buttons)
            
            // Accent Colors
            primaryAccent: ColorHex("#2563EB"),   // main accent (buttons, toggles)
            secondaryAccent: ColorHex("#3B82F6"), // secondary accent (charts, highlights)
            
            // Button Colors
            primaryButton:   ColorHex("#2563EB"),
            secondaryButton: ColorHex("#E5E7EB"),
            buttonAccent:    ColorHex("#10B981"),
            buttonGradient: [
                ColorHex("#2563EB"),
                ColorHex("#3B82F6")
            ],
            
            // Icon Colors
            normal: ColorHex("#374151"), // default icon tint (dark gray)
            muted:  ColorHex("#9CA3AF"), // disabled / secondary icon tint
            
            // Status Colors
            success: ColorHex("#10B981"), // emerald green
            warning: ColorHex("#F59E0B"), // amber
            error:   ColorHex("#EF4444"), // red
            info:    ColorHex("#3B82F6"), // blue
            
            // Lines & focus
            divider:   ColorHex("#E5E7EB"), // subtle divider
            border:    ColorHex("#D1D5DB"), // light gray border
            focusRing: ColorHex("#93C5FD"), // soft blue
            
            // Progress & rings
            progressTrack:      ColorHex("#E5E7EB"),
            progressFillStart:  ColorHex("#2563EB"),
            progressFillEnd:    ColorHex("#3B82F6"),
            ringOuterAlpha:     0.30,
            ringInnerStartAlpha:0.30,
            ringInnerEndAlpha:  0.10,
            
            // Glass / glow
            glassTint: ColorHex("#FFFFFF"),
            glassOpacity: 0.08,
            glowIntensityPrimary: 0.35,
            glowIntensitySecondary: 0.15,
            glowBlurRadius: 30,
            glowRadiusInner: 32,
            glowRadiusOuter: 84,
            glowAnimationScale: 1.4,
            
            // Charts
            chartPalette: [
                ColorHex("#3B82F6"), // blue
                ColorHex("#10B981"), // green
                ColorHex("#F59E0B"), // amber
                ColorHex("#EF4444"), // red
                ColorHex("#8B5CF6")  // purple
            ],
            chartGrid:  ColorHex("#E5E7EB"),
            chartLabel: ColorHex("#6B7280"),
            
            // Additional UI Elements
            primaryUIElement:   ColorHex("#2563EB"),
            secondaryUIElement: ColorHex("#E5E7EB")
            
            // View Specific Colors
            //TODO
            
            

            // FIGURE OUT NEW NAMING
            /*
            // Feature accents / categories
            normal:     ColorHex("#64D2FF"), // modern cyan used across Focus/Stats
            success:       ColorHex("#32D74B"),
            primaryAccent:  ColorHex("#6E5AE6"),
            secondaryUIElement:   ColorHex("#64D2FF"),
            socialAccent:        ColorHex("#FF9F0A"),
            
            // Elevation scale
            surface0: ColorHex("#0E1228"),
            primaryUIElement: ColorHex("#131834"),
            secondaryBackground: ColorHex("#1A2145"),
            elevatedBackground: ColorHex("#212A57"),

            // Today hero (used by ThemedAnimatedBackground on TodayView)
            todayHeroTop:             ColorHex("#0F1630"),
            todayHeroBottom:          ColorHex("#1D1C53"),
            todayHeroVignette:        ColorHex("#2E0B5F"),
            todayHeroVignetteOpacity: 0.18,

            // Scrim for sheets/menus
            scrim: ColorHex("#000000"),
             */
        ),
        gradientStyle: .linear,
        icon: "paintbrush.fill",
        category: .minimal
    )
    
    // MARK: - Premium Themes (Paid)
    
    static let auroraProTheme = Theme(
        id: "aurora-pro",
        name: "Aurora Pro",
        description: "Luminous depth with glass and glow for focused flow.",
        isPremium: true,
        colorScheme: ThemeColorScheme(
            // Background Colors
            primaryBackground: ColorHex("#0E1228"),   // canvas
            secondaryBackground: ColorHex("#131834"), // stacked sections / sheets
            elevatedBackground: ColorHex("#1A2145"),  // cards, popovers
            backgroundColors: [
                ColorHex("#0F1630"),
                ColorHex("#1D1C53"),
                ColorHex("#2E0B5F")
            ],

            // Text Colors
            primaryText: ColorHex("#F5F7FF"),  // titles
            secondaryText: ColorHex("#C8D1FF"),// body / description
            subtleText: ColorHex("#9AA4C0"),   // captions / meta
            invertedText: ColorHex("#0A1024"), // text on light/bright surfaces

            // Accent Colors
            primaryAccent: ColorHex("#64D2FF"), // cyan electric
            secondaryAccent: ColorHex("#A78BFA"), // violet

            // Button Colors
            primaryButton:   ColorHex("#6E5AE6"),
            secondaryButton: ColorHex("#2B3152"),
            buttonAccent:    ColorHex("#32D74B"),
            buttonGradient: [
                ColorHex("#6E5AE6"),
                ColorHex("#0A84FF"),
                ColorHex("#64D2FF")
            ],

            // Icon Colors
            normal: ColorHex("#D5DBFF"),
            muted:  ColorHex("#8A93C9"),

            // Status Colors
            success: ColorHex("#32D74B"),
            warning: ColorHex("#FF9F0A"),
            error:   ColorHex("#FF6B6B"),
            info:    ColorHex("#64D2FF"),

            // Lines & focus
            divider:   ColorHex("#2B3152"),
            border:    ColorHex("#3B4474"),
            focusRing: ColorHex("#7DB7FF"),

            // Progress & rings
            progressTrack:      ColorHex("#2B3152"),
            progressFillStart:  ColorHex("#32D74B"),
            progressFillEnd:    ColorHex("#64D2FF"),
            ringOuterAlpha:     0.30,
            ringInnerStartAlpha:0.30,
            ringInnerEndAlpha:  0.10,

            // Glass / glow
            glassTint: ColorHex("#9AA9FF"),
            glassOpacity: 0.12,              // slightly stronger than free theme
            glowIntensityPrimary: 0.45,      // richer premium glow
            glowIntensitySecondary: 0.22,
            glowBlurRadius: 36,
            glowRadiusInner: 36,
            glowRadiusOuter: 96,
            glowAnimationScale: 1.5,

            // Charts
            chartPalette: [
                ColorHex("#64D2FF"), // cyan
                ColorHex("#6E5AE6"), // indigo
                ColorHex("#32D74B"), // green
                ColorHex("#FF9F0A"), // amber
                ColorHex("#FF6B6B"), // red
                ColorHex("#F472B6")  // pink
            ],
            chartGrid:  ColorHex("#2B3152"),
            chartLabel: ColorHex("#9AA4C0"),

            // Additional UI Elements
            primaryUIElement:   ColorHex("#212A57"),
            secondaryUIElement: ColorHex("#2B3152")
        ),
        gradientStyle: .linear,
        icon: "sparkles",
        category: .minimal
    )

    
    // MARK: - All Themes Collection
    static let allThemes: [Theme] = [
        defaultTheme, auroraProTheme
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
