//
//  Color+Extensions.swift
//  Routine Anchor
//
//  Created by Christopher Simonson on 7/19/25.
//
import SwiftUI

extension Color {
    // MARK: - Brand Colors (from Assets.xcassets)
    static let appPrimary = Color("PrimaryBlue")
    static let appSuccess = Color("SuccessGreen")
    static let appWarning = Color("WarningOrange")
    static let appError = Color("ErrorRed")
    
    // MARK: - Background Colors (System colors for proper dark mode support)
    static let appBackgroundPrimary = Color(.systemBackground)
    static let appBackgroundSecondary = Color(.secondarySystemBackground)
    static let appBackgroundTertiary = Color(.tertiarySystemBackground)
    
    // MARK: - Text Colors (System colors for accessibility)
    static let textPrimary = Color(.label)
    static let textSecondary = Color(.secondaryLabel)
    static let textTertiary = Color(.tertiaryLabel)
    
    // MARK: - Status Colors (semantic mapping)
    static let blockCompleted = appSuccess
    static let blockInProgress = appWarning
    static let blockUpcoming = Color(.systemGray3)
    static let blockSkipped = appError
    
    // MARK: - UI Element Colors
    static let cardBackground = Color(.systemBackground)
    static let cardShadow = Color.black.opacity(0.1)
    static let separatorColor = Color(.separator)
    static let progressTrack = Color(.systemGray5)
    static let progressFill = appPrimary
    
    // MARK: - Interactive Colors
    static let buttonPrimary = appPrimary
    static let buttonSecondary = Color(.systemGray4)
    static let buttonDestructive = appError
}
