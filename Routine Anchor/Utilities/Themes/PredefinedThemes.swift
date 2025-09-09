//
//  PredefinedThemes.swift
//  Routine Anchor
//
//  Minimal, semantic theme tokens. No brand palette assumptions.
//

import SwiftUI

// MARK: - Theme Model

/// A single app theme composed of semantic colors and a few gradient recipes.
struct AppTheme: Sendable, Equatable {
    var name: String
    var description: String

    // Core semantic colors (what they *mean* in the UI)
    var color: ColorSet
    var gradient: GradientSet

    // Premium flag for paywalled themes
    var isPremium: Bool = false

    // Optional radii & blur “feel” knobs to keep look consistent across components.
    var cornerRadius: CGFloat = 16
    var cardCornerRadius: CGFloat = 20
    var shadowOpacity: Double = 0.25
}

// MARK: - Token Groups

/// Canonical semantic colors used across the app.
struct ColorSet: Sendable, Equatable {
    // Backgrounds
    var bg: Background
    // Text
    var text: TextColors
    // Accents / statuses
    var accent: Accent
    var status: Status
    // UI component surfaces
    var surface: Surface
    // Icons
    var icon: Icon
    // Borders
    var border: Color
}

struct Background: Sendable, Equatable {
    var primary: Color      // full screen backgrounds
    var secondary: Color    // stacked sections / sheets
    var elevated: Color     // cards, popovers, glass layers
}

struct TextColors: Sendable, Equatable {
    var primary: Color   // titles
    var secondary: Color // body / descriptions
    var subtle: Color    // captions / meta
    var inverted: Color  // text on bold accents (e.g., buttons)
}

struct Accent: Sendable, Equatable {
    var primary: Color   // main accent (buttons, toggles)
    var secondary: Color // secondary accent (charts, highlights)
}

struct Status: Sendable, Equatable {
    var success: Color
    var warning: Color
    var error: Color
    var info: Color
}

struct Surface: Sendable, Equatable {
    var card: Color      // filled card background
    var glass: Color     // translucent card overlay tint
}

struct Icon: Sendable, Equatable {
    var normal: Color    // default icon tint
    var muted: Color     // disabled / secondary icon tint
}

/// Gradient recipes used repeatedly in the app.
struct GradientSet: Sendable, Equatable {
    // Large hero / screen backgrounds
    var heroTop: Color
    var heroBottom: Color
    var heroVignette: Color
    var heroVignetteOpacity: Double

    // Actionable elements
    var actionPrimaryStart: Color
    var actionPrimaryEnd: Color
}

// MARK: - Free and Premium Themes

enum PredefinedThemes {
    /// Default: “Routine Classic”
    static let classic = AppTheme(
        name: "Routine Classic",
        description: "Deep blue background with teal & purple accents.",
        color: .init(
            bg: .init(
                primary: Color(red: 9/255,  green: 16/255, blue: 40/255),   // #091028
                secondary: Color(red: 13/255, green: 23/255, blue: 54/255), // #0D1736
                elevated: Color(red: 16/255, green: 28/255, blue: 64/255)   // #101C40
            ),
            text: .init(
                primary:  Color.white.opacity(0.95),
                secondary: Color.white.opacity(0.80),
                subtle:    Color.white.opacity(0.60),
                inverted:  Color.white
            ),
            accent: .init(
                primary:  Color(hue: 0.53, saturation: 0.70, brightness: 0.85), // teal/blue
                secondary: Color(hue: 0.73, saturation: 0.62, brightness: 0.86) // purple
            ),
            status: .init(
                success: Color(hue: 0.36, saturation: 0.78, brightness: 0.82),
                warning: Color(hue: 0.12, saturation: 0.90, brightness: 0.95),
                error:   Color(hue: 0.98, saturation: 0.74, brightness: 0.90),
                info:    Color(hue: 0.56, saturation: 0.65, brightness: 0.88)
            ),
            surface: .init(
                card:  Color.white.opacity(0.06),
                glass: Color.white
            ),
            icon: .init(
                normal: Color.white.opacity(0.90),
                muted:  Color.white.opacity(0.55)
            ),
            border: Color.white.opacity(0.10)
        ),
        gradient: .init(
            heroTop:  Color(hue: 0.65, saturation: 0.70, brightness: 0.18),   // deep indigo/blue
            heroBottom: Color(hue: 0.60, saturation: 0.70, brightness: 0.10),
            heroVignette: Color.black,
            heroVignetteOpacity: 0.35,
            actionPrimaryStart: Color(hue: 0.53, saturation: 0.70, brightness: 0.85),
            actionPrimaryEnd:   Color(hue: 0.73, saturation: 0.62, brightness: 0.86)
        ),
        isPremium: false,
        cornerRadius: 16,
        cardCornerRadius: 20,
        shadowOpacity: 0.25
    )

    /// Premium: "Aurora Glow"
    static let auroraGlow = AppTheme(
        name: "Aurora Glow (Premium)",
        description: "Deep night hero with cyan–violet accents and crisp glass cards.",
        color: .init(
            bg: .init(
                primary: Color(hue: 0.67, saturation: 0.80, brightness: 0.10),
                secondary: Color(hue: 0.67, saturation: 0.72, brightness: 0.14),
                elevated: Color.white.opacity(0.08)
            ),
            text: .init(
                primary:  Color.white.opacity(0.96),
                secondary: Color.white.opacity(0.86),
                subtle:    Color.white.opacity(0.62),
                inverted:  Color.white
            ),
            accent: .init(
                primary:  Color(hue: 0.53, saturation: 0.86, brightness: 0.95),
                secondary: Color(hue: 0.77, saturation: 0.78, brightness: 0.96)
            ),
            status: .init(
                success: Color(hue: 0.37, saturation: 0.78, brightness: 0.88),
                warning: Color(hue: 0.11, saturation: 0.92, brightness: 0.96),
                error:   Color(hue: 0.98, saturation: 0.80, brightness: 0.92),
                info:    Color(hue: 0.58, saturation: 0.70, brightness: 0.92)
            ),
            surface: .init(
                card:  Color.white.opacity(0.08),
                glass: Color.white
            ),
            icon: .init(
                normal: Color.white.opacity(0.92),
                muted:  Color.white.opacity(0.58)
            ),
            border: Color.white.opacity(0.12)
        ),
        gradient: .init(
            heroTop:  Color(hue: 0.65, saturation: 0.75, brightness: 0.18),
            heroBottom: Color(hue: 0.62, saturation: 0.76, brightness: 0.08),
            heroVignette: Color(hue: 0.42, saturation: 0.70, brightness: 0.60),
            heroVignetteOpacity: 0.22,
            actionPrimaryStart: Color(hue: 0.53, saturation: 0.86, brightness: 0.95),
            actionPrimaryEnd:   Color(hue: 0.77, saturation: 0.78, brightness: 0.96)
        ),
        isPremium: true,
        cornerRadius: 16,
        cardCornerRadius: 20,
        shadowOpacity: 0.30
    )

    /// Catalog
    static let all: [AppTheme] = [ classic, auroraGlow ]
}
