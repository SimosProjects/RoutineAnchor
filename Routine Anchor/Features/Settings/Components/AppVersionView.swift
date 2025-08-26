//
//  AppVersionView.swift
//  Routine Anchor
//
//  Created by Christopher Simonson on 8/9/25.
//
import SwiftUI

struct AppVersionView: View {
    @Environment(\.themeManager) private var themeManager
    
    private var themePrimaryText: Color {
        themeManager?.currentTheme.textPrimaryColor ?? Theme.defaultTheme.textPrimaryColor
    }
    
    private var themeSecondaryText: Color {
        themeManager?.currentTheme.textSecondaryColor ?? Theme.defaultTheme.textSecondaryColor
    }
    
    private var themeTertiaryText: Color {
        themeManager?.currentTheme.textTertiaryColor ?? Theme.defaultTheme.textTertiaryColor
    }
    
    var body: some View {
        ThemedCard {
            VStack(spacing: 8) {
                Text("Routine Anchor")
                    .font(TypographyConstants.Body.emphasized)
                    .foregroundStyle(themePrimaryText)

                Text("Version \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")")
                    .font(TypographyConstants.UI.caption)
                    .foregroundStyle(themeSecondaryText)

                Text("© 2025 Simo's Media & Tech, LLC.")
                    .font(TypographyConstants.UI.caption)
                    .foregroundStyle(themeTertiaryText)
            }
            .frame(maxWidth: .infinity)
            .themedGlassMorphism()
        }
    }
}

