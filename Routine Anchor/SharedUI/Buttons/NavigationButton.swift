//
//  NavigationButton.swift
//  Routine Anchor
//
//  Created by Christopher Simonson on 7/21/25.
//
import SwiftUI
import UserNotifications

// MARK: - Navigation Button
struct NavigationButton: View {
    let icon: String
    let style: NavigationButtonStyle
    let action: () -> Void
    
    @Environment(\.themeManager) private var themeManager
    @State private var isPressed = false
    
    enum NavigationButtonStyle {
        case primary
        case secondary
        case accent
        case success
        
        // Map to ThemedButton style
        var themedButtonStyle: ThemedButton.ButtonStyle {
            switch self {
            case .primary, .success:
                return .primary
            case .secondary:
                return .secondary
            case .accent:
                return .accent
            }
        }
    }
    
    // Theme color helpers
    private var themePrimaryText: Color {
        themeManager?.currentTheme.textPrimaryColor ?? Theme.defaultTheme.textPrimaryColor
    }
    
    private var themeGradient: LinearGradient {
        guard let theme = themeManager?.currentTheme else {
            return Theme.defaultTheme.backgroundGradient
        }
        
        switch style {
        case .primary:
            return LinearGradient(
                colors: [theme.primaryColor, theme.secondaryColor],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .secondary:
            return LinearGradient(
                colors: [theme.colorScheme.surfacePrimary.color, theme.colorScheme.surfaceSecondary.color],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .accent:
            return LinearGradient(
                colors: [theme.accentColor, theme.primaryColor],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .success:
            return LinearGradient(
                colors: [theme.colorScheme.green.color, theme.colorScheme.teal.color],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    private var shadowColor: Color {
        guard let theme = themeManager?.currentTheme else {
            return Theme.defaultTheme.primaryColor.opacity(0.3)
        }
        
        switch style {
        case .primary:
            return theme.primaryColor.opacity(0.3)
        case .secondary:
            return theme.colorScheme.surfacePrimary.color.opacity(0.3)
        case .accent:
            return theme.accentColor.opacity(0.3)
        case .success:
            return theme.colorScheme.green.color.opacity(0.3)
        }
    }
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isPressed = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    isPressed = false
                }
                action()
            }
        }) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(themePrimaryText)
                .frame(width: 40, height: 40)
                .background(themeGradient)
                .cornerRadius(12)
                .shadow(color: shadowColor, radius: 8, x: 0, y: 4)
                .scaleEffect(isPressed ? 0.95 : 1)
        }
    }
}

// MARK: - Convenience Initializers
extension NavigationButton {
    // Primary navigation button (default)
    init(
        icon: String,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.style = .primary
        self.action = action
    }
    
    // Secondary navigation button
    static func secondary(
        icon: String,
        action: @escaping () -> Void
    ) -> NavigationButton {
        NavigationButton(icon: icon, style: .secondary, action: action)
    }
    
    // Accent navigation button
    static func accent(
        icon: String,
        action: @escaping () -> Void
    ) -> NavigationButton {
        NavigationButton(icon: icon, style: .accent, action: action)
    }
    
    static func success(
        icon: String,
        action: @escaping () -> Void
    ) -> NavigationButton {
        NavigationButton(icon: icon, style: .success, action: action)
    }
}
