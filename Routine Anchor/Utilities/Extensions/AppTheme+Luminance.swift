//
//  AppTheme+Luminance.swift
//  Routine Anchor
//
//  Adds light/dark heuristics for themes.
//

import SwiftUI

extension Color {
    /// WCAG relative luminance (0 = dark, 1 = light)
    var luminance: Double {
        let ui = UIColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 1
        guard ui.getRed(&r, green: &g, blue: &b, alpha: &a) else { return 0 }

        func toLinear(_ c: CGFloat) -> Double {
            let c = Double(c)
            return c <= 0.03928 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4)
        }

        let R = toLinear(r), G = toLinear(g), B = toLinear(b)
        return 0.2126 * R + 0.7152 * G + 0.0722 * B
    }
}

extension AppTheme {
    /// Simple heuristic based on the primary background color.
    var isLight: Bool { color.bg.primary.luminance > 0.5 }
    var isDark: Bool { !isLight }
}
