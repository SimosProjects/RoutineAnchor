//
//  IconChip.swift
//  Routine Anchor
//
//  Created by Christopher Simonson on 7/23/25.
//
import SwiftUI

struct IconChip: View {
    @Environment(\.themeManager) private var themeManager
    let icon: String?
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: {
            HapticManager.shared.lightImpact()
            action()
        }) {
            Group {
                if let icon = icon {
                    Text(icon)
                        .font(.system(size: 20))
                } else {
                    Image(systemName: "minus")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(themeManager?.currentTheme.textSecondaryColor ?? Theme.defaultTheme.textSecondaryColor)
                }
            }
            .frame(width: 44, height: 44)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.anchorTeal.opacity(0.3) :
                        (themeManager?.currentTheme.colorScheme.surfacePrimary.color ?? Theme.defaultTheme.colorScheme.surfacePrimary.color).opacity(0.3))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isSelected ? Color.anchorTeal :
                        (themeManager?.currentTheme.colorScheme.surfaceSecondary.color ?? Theme.defaultTheme.colorScheme.surfaceSecondary.color).opacity(0.4),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
        }
        .scaleEffect(isSelected ? 1.1 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}
