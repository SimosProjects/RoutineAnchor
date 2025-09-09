//
//  Theme.swift
//  Routine Anchor
//
//  Semantic sugar + helpers layered on top of AppTheme / PredefinedThemes.
//

import SwiftUI

// MARK: - Semantic sugar (used throughout the UI)

extension AppTheme {
    // Text
    var primaryTextColor: Color   { color.text.primary }
    var secondaryTextColor: Color { color.text.secondary }
    var subtleTextColor: Color    { color.text.subtle }
    var invertedTextColor: Color  { color.text.inverted }

    /// Temporary alias (if any views still use `textInverted`)
    var textInverted: Color { invertedTextColor }

    // Accents
    var accentPrimaryColor: Color   { color.accent.primary }
    var accentSecondaryColor: Color { color.accent.secondary }

    // Status
    var statusSuccessColor: Color { color.status.success }
    var statusWarningColor: Color { color.status.warning }
    var statusErrorColor: Color   { color.status.error }
    var statusInfoColor: Color    { color.status.info }

    // Surfaces / borders / icons
    var surfaceCardColor: Color  { color.surface.card }
    var surfaceGlassColor: Color { color.surface.glass }
    var borderColor: Color       { color.border }
    var iconNormalColor: Color   { color.icon.normal }
    var iconMutedColor: Color    { color.icon.muted }

    // Corner defaults (for components that want a single knob)
    var defaultCornerRadius: CGFloat { cornerRadius }
}

// MARK: - Gradients & Backgrounds

extension AppTheme {
    /// Primary action gradient (buttons/FAB).
    var actionPrimaryGradient: LinearGradient {
        LinearGradient(colors: [gradient.actionPrimaryStart, gradient.actionPrimaryEnd],
                       startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    /// Screen-wide hero background (use as a View in ZStacks).
    var heroBackground: some View {
        ZStack {
            heroBackgroundGradient
            RadialGradient(colors: [gradient.heroVignette.opacity(gradient.heroVignetteOpacity), .clear],
                           center: .center, startRadius: 0, endRadius: 520)
        }
    }

    /// Gradient-only variant for shape fills: `.fill(theme.heroBackgroundGradient)`.
    var heroBackgroundGradient: LinearGradient {
        LinearGradient(colors: [gradient.heroTop, gradient.heroBottom],
                       startPoint: .top, endPoint: .bottom)
    }

    /// Subtle glass-morphism tint overlay for cards on busy backgrounds.
    var glassMaterialOverlay: LinearGradient {
        LinearGradient(colors: [color.surface.glass.opacity(0.15), color.surface.glass.opacity(0.05)],
                       startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

// MARK: - (Optional) Color helpers kept for safety

extension Color {
    /// Create a Color from a hex string like "#FFAA33" or "FFAA33".
    init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch cleaned.count {
        case 3: (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 255, 255, 255)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
    }
}

extension UIColor {
    convenience init(_ color: Color) {
        self.init(cgColor: color.resolve(in: .init()).cgColor)
    }
    convenience init?(hex: String) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch cleaned.count {
        case 3: (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: return nil
        }
        self.init(red: CGFloat(r) / 255, green: CGFloat(g) / 255, blue: CGFloat(b) / 255, alpha: CGFloat(a) / 255)
    }
}
