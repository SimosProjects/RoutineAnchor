//
//  DesignedTextField.swift
//  Routine Anchor
//

import SwiftUI

/// Labeled text field that adapts to the active AppTheme.
struct DesignedTextField: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    let icon: String
    var isMultiline: Bool = false

    @Environment(\.themeManager) private var themeManager
    @FocusState private var isFocused: Bool

    private var theme: AppTheme { themeManager?.currentTheme ?? PredefinedThemes.classic }

    init(title: String,
         text: Binding<String>,
         placeholder: String,
         icon: String,
         isMultiline: Bool = false) {
        self.title = title
        self._text = text
        self.placeholder = placeholder
        self.icon = icon
        self.isMultiline = isMultiline
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Label
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(theme.accentPrimaryColor)

                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(theme.primaryTextColor)
            }

            // Field
            Group {
                if isMultiline {
                    TextField(placeholder, text: $text, axis: .vertical)
                        .lineLimit(2...4)
                } else {
                    TextField(placeholder, text: $text)
                }
            }
            .focused($isFocused)
            .font(.system(size: 16, weight: .medium))
            .foregroundStyle(theme.primaryTextColor)
            .tint(theme.accentPrimaryColor) // cursor / selection
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(theme.surfaceCardColor.opacity(0.35))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(isFocused ? theme.accentPrimaryColor : theme.borderColor.opacity(0.9), lineWidth: 1)
            )
            .animation(.easeInOut(duration: 0.15), value: isFocused)
        }
    }
}
