//
//  TimePicker.swift
//  Routine Anchor
//
//  Created by Christopher Simonson on 7/23/25.
//
import SwiftUI

struct TimePicker: View {
    @Environment(\.themeManager) private var themeManager
    let title: String
    @Binding var selection: Date
    let icon: String
    let isDisabled: Bool
    
    private var themePrimaryText: Color {
        themeManager?.currentTheme.primaryTextColor ?? Theme.defaultTheme.primaryTextColor
    }
    
    private var themeSecondaryText: Color {
        themeManager?.currentTheme.secondaryTextColor ?? Theme.defaultTheme.secondaryTextColor
    }

    init(title: String, selection: Binding<Date>, icon: String, isDisabled: Bool = false) {
        self.title = title
        self._selection = selection
        self.icon = icon
        self.isDisabled = isDisabled
    }

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(isDisabled ? themeSecondaryText.opacity(0.6) : themeManager?.currentTheme.colorScheme.success.color ?? Theme.defaultTheme.colorScheme.success.color)

                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(isDisabled ? themeSecondaryText.opacity(0.6) : themePrimaryText)
            }

            DatePicker("", selection: $selection, displayedComponents: .hourAndMinute)
                .datePickerStyle(.compact)
                .labelsHidden()
                .accentColor(themeManager?.currentTheme.colorScheme.success.color ?? Theme.defaultTheme.colorScheme.success.color)
                .colorScheme(.dark)
                .disabled(isDisabled)
                .opacity(isDisabled ? 0.6 : 1.0)
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isDisabled ? themeSecondaryText.opacity(0.1) : themeSecondaryText.opacity(0.2))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isDisabled ? themeSecondaryText.opacity(0.2) : themeSecondaryText.opacity(0.3), lineWidth: 1)
        )
    }
}

