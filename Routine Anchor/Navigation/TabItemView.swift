//
//  TabItemView.swift
//  Routine Anchor
//
//  Created by Christopher Simonson on 7/23/25.
//
import SwiftUI

struct TabItemView: View {
    let icon: String
    let selectedIcon: String
    let title: String
    let isSelected: Bool
    
    @Environment(\.themeManager) private var themeManager

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: isSelected ? selectedIcon : icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(
                    isSelected ?
                    LinearGradient(
                        colors: [
                            themeManager?.currentTheme.buttonPrimaryColor ?? themeManager?.currentTheme.colorScheme.workflowPrimary.color ?? Theme.defaultTheme.colorScheme.workflowPrimary.color,
                            themeManager?.currentTheme.buttonAccentColor ?? themeManager?.currentTheme.colorScheme.organizationAccent.color ?? Theme.defaultTheme.colorScheme.organizationAccent.color
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ) :
                    LinearGradient(
                        colors: [
                            themeManager?.currentTheme.secondaryTextColor ?? Theme.defaultTheme.secondaryTextColor,
                            themeManager?.currentTheme.secondaryTextColor ?? Theme.defaultTheme.secondaryTextColor
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .scaleEffect(isSelected ? 1.1 : 1.0)
                .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isSelected)

            Text(title)
                .font(.system(size: 10, weight: isSelected ? .semibold : .medium))
                .foregroundStyle(
                    isSelected ?
                    (themeManager?.currentTheme.buttonPrimaryColor ?? themeManager?.currentTheme.colorScheme.workflowPrimary.color ?? Theme.defaultTheme.colorScheme.workflowPrimary.color) :
                    (themeManager?.currentTheme.secondaryTextColor ?? Theme.defaultTheme.secondaryTextColor)
                )
        }
    }
}

