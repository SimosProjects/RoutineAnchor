//
//  DesignedButton.swift
//  Routine Anchor
//
//  Created by Christopher Simonson on 7/20/25.
//
import SwiftUI
import UserNotifications

struct DesignedButton: View {
    let title: String
    var style: ButtonStyle = .primary
    let action: () -> Void
    
    @Environment(\.themeManager) private var themeManager
    @State private var isPressed = false
    
    enum ButtonStyle {
        case primary, gradient, secondary
        
        var themedStyle: ThemedButton.ButtonStyle {
            switch self {
            case .primary: return .primary
            case .gradient: return .accent
            case .secondary: return .secondary
            }
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
            Text(title)
                .font(.system(size: 19, weight: .semibold, design: .rounded))
                .foregroundStyle(textColor)
                .frame(maxWidth: .infinity)
                .frame(height: 60)
                .background(backgroundGradient)
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(borderColor, lineWidth: 1)
                )
                .shadow(
                    color: shadowColor,
                    radius: isPressed ? 15 : 30,
                    x: 0,
                    y: isPressed ? 8 : 15
                )
                .scaleEffect(isPressed ? 0.97 : 1)
        }
    }
    
    // MARK: - Computed Properties for Theme Colors
    
    private var textColor: Color {
        themeManager?.currentTheme.primaryTextColor ?? Theme.defaultTheme.primaryTextColor
    }
    
    private var backgroundGradient: LinearGradient {
        guard let theme = themeManager?.currentTheme else {
            return LinearGradient(
                colors: [Theme.defaultTheme.buttonPrimaryColor, Theme.defaultTheme.buttonSecondaryColor],
                startPoint: .leading,
                endPoint: .trailing
            )
        }
        
        switch style {
        case .primary:
            return LinearGradient(
                colors: [theme.buttonPrimaryColor, theme.buttonSecondaryColor],
                startPoint: .leading,
                endPoint: .trailing
            )
        case .gradient:
            // Use theme's accent colors for gradient style
            return LinearGradient(
                colors: [theme.colorScheme.actionSuccess.color, theme.colorScheme.creativeSecondary.color],
                startPoint: .leading,
                endPoint: .trailing
            )
        case .secondary:
            return LinearGradient(
                colors: [theme.colorScheme.workflowPrimary.color, theme.colorScheme.organizationAccent.color],
                startPoint: .leading,
                endPoint: .trailing
            )
        }
    }
    
    private var borderColor: Color {
        themeManager?.currentTheme.colorScheme.uiElementSecondary.color ??
        Theme.defaultTheme.colorScheme.uiElementSecondary.color
    }
    
    private var shadowColor: Color {
        guard let theme = themeManager?.currentTheme else {
            return Theme.defaultTheme.buttonPrimaryColor.opacity(0.5)
        }
        
        switch style {
        case .primary:
            return theme.buttonPrimaryColor.opacity(0.5)
        case .gradient:
            return theme.colorScheme.actionSuccess.color.opacity(0.5)
        case .secondary:
            return theme.colorScheme.workflowPrimary.color.opacity(0.5)
        }
    }
}
