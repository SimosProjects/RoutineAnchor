//
//  CategoryChip.swift
//  Routine Anchor
//

import SwiftUI

struct CategoryChip: View {
    let title: String
    let isSelected: Bool
    let color: Color            // category accent passed in
    let action: () -> Void

    @Environment(\.themeManager) private var themeManager
    private var theme: AppTheme { themeManager?.currentTheme ?? PredefinedThemes.classic }

    private let corner: CGFloat = 10

    var body: some View {
        Button {
            HapticManager.shared.lightImpact()
            action()
        } label: {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(isSelected ? theme.invertedTextColor : color)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: corner, style: .continuous)
                        .fill(isSelected ? color : theme.surfaceCardColor.opacity(0.30))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: corner, style: .continuous)
                        .stroke(color.opacity(isSelected ? 0.9 : 0.5), lineWidth: isSelected ? 2 : 1)
                )
                .contentShape(RoundedRectangle(cornerRadius: corner, style: .continuous))
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 1.0 : 0.96)
        .animation(.spring(response: 0.30, dampingFraction: 0.75), value: isSelected)
        .accessibilityLabel("\(title) \(isSelected ? "selected" : "not selected")")
    }
}
