//
//  TimePicker.swift
//  Routine Anchor
//

import SwiftUI

/// Compact time picker row that respects theme tokens.
struct TimePicker: View {
    @Environment(\.themeManager) private var themeManager

    let title: String
    @Binding var selection: Date
    let icon: String
    var isDisabled: Bool = false

    private var theme: AppTheme { themeManager?.currentTheme ?? PredefinedThemes.classic }

    init(title: String, selection: Binding<Date>, icon: String, isDisabled: Bool = false) {
        self.title = title
        self._selection = selection
        self.icon = icon
        self.isDisabled = isDisabled
    }

    var body: some View {
        VStack(spacing: 8) {
            // Label
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(isDisabled ? theme.secondaryTextColor.opacity(0.6) : theme.statusSuccessColor)

                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(isDisabled ? theme.secondaryTextColor.opacity(0.6) : theme.primaryTextColor)
            }

            // Control
            DatePicker("", selection: $selection, displayedComponents: .hourAndMinute)
                .datePickerStyle(.compact)
                .labelsHidden()
                .tint(theme.statusSuccessColor)
                .disabled(isDisabled)
                .opacity(isDisabled ? 0.6 : 1.0)
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(theme.surfaceCardColor.opacity(isDisabled ? 0.28 : 0.35))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(theme.borderColor.opacity(isDisabled ? 0.6 : 0.9), lineWidth: 1)
        )
    }
}
