//
//  TypographyConstants.swift
//  Routine Anchor
//
//  Created by Christopher Simonson on 7/19/25.
//
import SwiftUI

struct TypographyConstants {
    // MARK: - Text Styles
    struct Headers {
        static let welcome = Font.appLargeTitle
        static let screenTitle = Font.appTitle2
        static let sectionHeader = Font.appTitle3
        static let cardTitle = Font.appHeadline
    }
    
    struct Body {
        static let primary = Font.appBody
        static let secondary = Font.appSubheadline
        static let emphasized = Font.appBodyEmphasized
        static let description = Font.appSubheadline
    }
    
    struct UI {
        static let button = Font.appButton
        static let timeBlock = Font.timeDisplay
        static let progress = Font.progressText
        static let status = Font.statusLabel
        static let caption = Font.appCaption
    }
    
    // MARK: - Line Heights & Spacing
    struct Spacing {
        static let tight: CGFloat = 1.2
        static let normal: CGFloat = 1.4
        static let loose: CGFloat = 1.6
    }
}
