//
//  TabItemView.swift
//  Routine Anchor
//
//  Token-based rendering: selected icon uses theme.actionPrimaryGradient,
//  text/icon colors come from semantic text tokens.
//

import SwiftUI

struct TabItemView: View {
    let icon: String
    let selectedIcon: String
    let title: String
    let isSelected: Bool

    @Environment(\.themeManager) private var themeManager
    private var theme: AppTheme { themeManager?.currentTheme ?? PredefinedThemes.classic }

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: isSelected ? selectedIcon : icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(isSelected ? theme.actionPrimaryGradient
                                            : LinearGradient(colors: [theme.secondaryTextColor, theme.secondaryTextColor],
                                                             startPoint: .topLeading, endPoint: .bottomTrailing))
                .scaleEffect(isSelected ? 1.1 : 1.0)
                .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isSelected)

            Text(title)
                .font(.system(size: 10, weight: isSelected ? .semibold : .medium))
                .foregroundStyle(isSelected ? theme.accentPrimaryColor : theme.secondaryTextColor)
        }
    }
}
