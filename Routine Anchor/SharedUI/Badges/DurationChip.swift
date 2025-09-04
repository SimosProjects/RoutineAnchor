//
//  DurationChip.swift
//  Routine Anchor
//
//  Created by Christopher Simonson on 7/23/25.
//
import SwiftUI

struct DurationChip: View {
    let minutes: Int
    let isSelected: Bool
    let action: () -> Void
    
    @Environment(\.themeManager) private var themeManager
    @State private var isPressed = false
    
    var displayText: String {
        if minutes < 60 {
            return "\(minutes)m"
        } else {
            let hours = minutes / 60
            let mins = minutes % 60
            if mins == 0 {
                return "\(hours)h"
            } else {
                return "\(hours)h \(mins)m"
            }
        }
    }
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                action()
            }
        }) {
            Text(displayText)
                .font(.system(size: 14, weight: isSelected ? .bold : .semibold))
                .foregroundStyle(isSelected ? (themeManager?.currentTheme.primaryTextColor ?? Theme.defaultTheme.primaryTextColor) : themeManager?.currentTheme.colorScheme.warningColor.color ?? Theme.defaultTheme.colorScheme.warningColor.color)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(
                            isSelected
                                ? LinearGradient(
                                    colors: [themeManager?.currentTheme.colorScheme.warningColor.color ?? Theme.defaultTheme.colorScheme.warningColor.color, themeManager?.currentTheme.colorScheme.warningColor.color ?? Theme.defaultTheme.colorScheme.warningColor.color.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                  )
                                : LinearGradient(
                                    colors: [themeManager?.currentTheme.colorScheme.warningColor.color ?? Theme.defaultTheme.colorScheme.warningColor.color.opacity(0.15)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                  )
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(
                            isSelected ? themeManager?.currentTheme.colorScheme.warningColor.color ?? Theme.defaultTheme.colorScheme.warningColor.color : themeManager?.currentTheme.colorScheme.warningColor.color ?? Theme.defaultTheme.colorScheme.warningColor.color.opacity(0.3),
                            lineWidth: isSelected ? 2 : 1
                        )
                )
                .shadow(
                    color: isSelected ? themeManager?.currentTheme.colorScheme.warningColor.color ?? Theme.defaultTheme.colorScheme.warningColor.color.opacity(0.3) : Color.clear,
                    radius: 8,
                    x: 0,
                    y: 4
                )
        }
        .scaleEffect(isPressed ? 0.95 : (isSelected ? 1.05 : 1.0))
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        .animation(.spring(response: 0.2, dampingFraction: 0.8), value: isPressed)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity) { pressing in
            isPressed = pressing
        } perform: {
            // Long press action if needed
        }
    }
}

