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
        
        static let onPrimary = Color.white
        static let onSuccess = Color.white
        static let onWarning = Color.white
        static let onError = Color.white
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
        
        // Additional UI colors
        static let cardBackground = Color.cardBackground
        static let textPrimary = Color.textPrimary
        static let textSecondary = Color.textSecondary
    }
    
    // MARK: - Button Colors
    struct Button {
        static let primary = Color.buttonPrimary
        static let secondary = Color.buttonSecondary
        static let destructive = Color.buttonDestructive
    }
}
