//
//  Font+Extensions.swift
//  Routine Anchor
//
//  Created by Christopher Simonson on 7/19/25.
//
import SwiftUI

extension Font {
    // MARK: - App Typography Scale
    
    // Headers
    static let appLargeTitle = Font.largeTitle.weight(.bold)
    static let appTitle = Font.title.weight(.semibold)
    static let appTitle2 = Font.title2.weight(.semibold)
    static let appTitle3 = Font.title3.weight(.medium)
    
    // Body Text
    static let appHeadline = Font.headline.weight(.semibold)
    static let appSubheadline = Font.subheadline.weight(.medium)
    static let appBody = Font.body
    static let appBodyEmphasized = Font.body.weight(.medium)
    
    // UI Elements
    static let appButton = Font.headline.weight(.semibold)
    static let appCaption = Font.caption
    static let appCaption2 = Font.caption2
    
    // Custom Sizes
    static let timeDisplay = Font.system(size: 16, weight: .medium, design: .monospaced)
    static let progressText = Font.system(size: 14, weight: .medium)
    static let statusLabel = Font.system(size: 12, weight: .medium)
}
