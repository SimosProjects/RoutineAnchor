//
//  IconChip.swift
//  Routine Anchor
//

import SwiftUI

struct IconChip: View {
    @Environment(\.themeManager) private var themeManager
    let icon: String?     // emoji or nil for “no icon”
    let isSelected: Bool
    let action: () -> Void

    private var theme: AppTheme { themeManager?.currentTheme ?? PredefinedThemes.classic }

    private let side: CGFloat = 44
    private let corner: CGFloat = 12

    var body: some View {
        Button {
            HapticManager.shared.lightImpact()
            action()
        } label: {
            Group {
                if let icon = icon {
                    Text(icon)
                        .font(.system(size: 20))
                } else {
                    Image(systemName: "minus")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(theme.secondaryTextColor)
                }
            }
            .frame(width: side, height: side)
            .background(
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .fill(
                        isSelected
                        ? theme.accentSecondaryColor.opacity(0.22)
                        : theme.surfaceCardColor.opacity(0.30)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .stroke(
                        (isSelected ? theme.accentSecondaryColor : theme.borderColor.opacity(0.40)), 
                        lineWidth: isSelected ? 2 : 1
                    )
            )
            .contentShape(RoundedRectangle(cornerRadius: corner, style: .continuous))
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 1.1 : 1.0)
        .animation(.spring(response: 0.30, dampingFraction: 0.75), value: isSelected)
        .accessibilityLabel(icon ?? "No icon")
    }
}
