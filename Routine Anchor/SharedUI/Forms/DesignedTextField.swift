//
//  AnchorTextField.swift
//  Routine Anchor
//
//  Created by Christopher Simonson on 7/23/25.
//
import SwiftUI

struct DesignedTextField: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    let icon: String
    let isMultiline: Bool
    
    @Environment(\.themeManager) private var themeManager

    init(title: String, text: Binding<String>, placeholder: String, icon: String, isMultiline: Bool = false) {
        self.title = title
        self._text = text
        self.placeholder = placeholder
        self.icon = icon
        self.isMultiline = isMultiline
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(themeManager?.currentTheme.colorScheme.workflowPrimary.color ?? Theme.defaultTheme.colorScheme.workflowPrimary.color)

                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(themeManager?.currentTheme.primaryTextColor ?? Theme.defaultTheme.primaryTextColor)
            }

            Group {
                if isMultiline {
                    TextField(placeholder, text: $text, axis: .vertical)
                        .lineLimit(2...4)
                } else {
                    TextField(placeholder, text: $text)
                }
            }
            .font(.system(size: 16, weight: .medium))
            .foregroundStyle(themeManager?.currentTheme.primaryTextColor ?? Theme.defaultTheme.primaryTextColor)
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(themeManager?.currentTheme.colorScheme.uiElementPrimary.color ?? Theme.defaultTheme.colorScheme.uiElementPrimary.color))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(themeManager?.currentTheme.colorScheme.uiElementSecondary.color ?? Theme.defaultTheme.colorScheme.uiElementSecondary.color), lineWidth: 1)
            )
        }
    }
}

