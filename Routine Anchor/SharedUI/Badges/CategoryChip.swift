//
//  CategoryChip.swift
//  Routine Anchor
//
//  Created by Christopher Simonson on 7/23/25.
//
import SwiftUI

struct CategoryChip: View {
    let title: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void
    
    @Environment(\.themeManager) private var themeManager

    var body: some View {
        Button(action: {
            HapticManager.shared.lightImpact()
            action()
        }) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(isSelected ?
                    (themeManager?.currentTheme.textPrimaryColor ?? Theme.defaultTheme.textPrimaryColor) :
                    color)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(isSelected ? color :
                            (themeManager?.currentTheme.colorScheme.surfacePrimary.color.opacity(0.3) ??
                             Color(themeManager?.currentTheme.colorScheme.surfacePrimary.color ?? Theme.defaultTheme.colorScheme.surfacePrimary.color)))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(color.opacity(0.5), lineWidth: 1)
                )
        }
        .scaleEffect(isSelected ? 1.0 : 0.95)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

