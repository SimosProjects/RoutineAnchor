//
//  ColorConstants.swift
//  Routine Anchor
//
//  Created by Christopher Simonson on 7/19/25.
//
import SwiftUI

struct ColorConstants {
    // MARK: - Brand Palette
    struct Palette {
        static let primary = Color.appPrimary
        static let success = Color.appSuccess
        static let warning = Color.appWarning
        static let error = Color.appError
        
        static let background = Color.appBackgroundPrimary
        static let surface = Color.appBackgroundSecondary
        
        // DEPRECATED: These should use theme colors instead
        // Kept for backward compatibility but should be migrated
        @available(*, deprecated, message: "Use themeManager.currentTheme.textPrimaryColor")
        static let onPrimary = Color(red: 1.0, green: 1.0, blue: 1.0)
        
        @available(*, deprecated, message: "Use themeManager.currentTheme.textPrimaryColor")
        static let onSuccess = Color(red: 1.0, green: 1.0, blue: 1.0)
        
        @available(*, deprecated, message: "Use themeManager.currentTheme.textPrimaryColor")
        static let onWarning = Color(red: 1.0, green: 1.0, blue: 1.0)
        
        @available(*, deprecated, message: "Use themeManager.currentTheme.textPrimaryColor")
        static let onError = Color(red: 1.0, green: 1.0, blue: 1.0)
    }
    
    // MARK: - Status Colors
    struct Status {
        static let completed = Color.blockCompleted
        static let inProgress = Color.blockInProgress
        static let upcoming = Color.blockUpcoming
        static let skipped = Color.blockSkipped
    }
    
    // MARK: - UI Element Colors
    struct UI {
        static let cardShadow = Color.cardShadow
        static let separator = Color.separatorColor
        static let progressTrack = Color.progressTrack
        static let progressFill = Color.progressFill
        
        // Additional UI colors - DEPRECATED
        @available(*, deprecated, message: "Use themeManager.currentTheme.colorScheme.surfacePrimary")
        static let cardBackground = Color.cardBackground
        
        @available(*, deprecated, message: "Use themeManager.currentTheme.textPrimaryColor")
        static let textPrimary = Color.textPrimary
        
        @available(*, deprecated, message: "Use themeManager.currentTheme.textSecondaryColor")
        static let textSecondary = Color.textSecondary
    }
    
    // MARK: - Button Colors
    struct Button {
        static let primary = Color.buttonPrimary
        static let secondary = Color.buttonSecondary
        static let destructive = Color.buttonDestructive
    }
}

// MARK: - Theme-Aware Color Helper
// This extension provides theme-aware color access
extension ColorConstants {
    /// Helper to get theme-aware text colors
    @MainActor
    struct ThemedText {
        @Environment(\.themeManager) private var themeManager
        
        var primary: Color {
            themeManager?.currentTheme.textPrimaryColor ?? Theme.defaultTheme.textPrimaryColor
        }
        
        var secondary: Color {
            themeManager?.currentTheme.textSecondaryColor ?? Theme.defaultTheme.textSecondaryColor
        }
        
        var tertiary: Color {
            themeManager?.currentTheme.textTertiaryColor ?? Theme.defaultTheme.textTertiaryColor
        }
    }
    
    /// Helper to get theme-aware surface colors
    @MainActor
    struct ThemedSurface {
        @Environment(\.themeManager) private var themeManager
        
        var primary: Color {
            themeManager?.currentTheme.colorScheme.surfacePrimary.color ??
            Theme.defaultTheme.colorScheme.surfacePrimary.color
        }
        
        var secondary: Color {
            themeManager?.currentTheme.colorScheme.surfaceSecondary.color ??
            Theme.defaultTheme.colorScheme.surfaceSecondary.color
        }
    }
}
