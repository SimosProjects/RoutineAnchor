//
//  DesignedButton.swift
//  Routine Anchor
//
import SwiftUI
import UserNotifications

struct DesignedButton: View {
    let title: String
    var style: ButtonStyle = .primary
    let action: () -> Void
    
    @Environment(\.themeManager) private var themeManager
    @State private var isPressed = false
    
    enum ButtonStyle { case primary, gradient, secondary
        var themedStyle: ThemedButton.ButtonStyle {
            switch self {
            case .primary:  return .primary
            case .gradient: return .accent
            case .secondary:return .secondary
            }
        }
    }
    
    private var theme: Theme { themeManager?.currentTheme ?? Theme.defaultTheme }
    
    var body: some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { isPressed = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { isPressed = false }
                action()
            }
        } label: {
            Text(title)
                .font(.system(size: 19, weight: .semibold, design: .rounded))
                .foregroundStyle(theme.primaryTextColor)
                .frame(maxWidth: .infinity)
                .frame(height: 60)
                .background(backgroundGradient)
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(theme.colorScheme.border.color.opacity(0.8), lineWidth: 1)
                )
                .shadow(
                    color: shadowColor,
                    radius: isPressed ? 15 : 30, x: 0, y: isPressed ? 8 : 15
                )
                .scaleEffect(isPressed ? 0.97 : 1)
        }
    }
    
    // MARK: - Theme-driven styles
    private var backgroundGradient: LinearGradient {
        switch style {
        case .primary:
            return LinearGradient(
                colors: [theme.buttonPrimaryColor, theme.buttonSecondaryColor],
                startPoint: .leading, endPoint: .trailing
            )
        case .gradient:
            return LinearGradient(
                colors: [theme.colorScheme.workflowPrimary.color,
                         theme.colorScheme.organizationAccent.color],
                startPoint: .leading, endPoint: .trailing
            )
        case .secondary:
            return LinearGradient(
                colors: [theme.colorScheme.workflowPrimary.color,
                         theme.colorScheme.organizationAccent.color],
                startPoint: .leading, endPoint: .trailing
            )
        }
    }
    
    private var shadowColor: Color {
        switch style {
        case .primary:  return theme.buttonPrimaryColor.opacity(0.5)
        case .gradient: return theme.colorScheme.actionSuccess.color.opacity(0.5)
        case .secondary:return theme.colorScheme.workflowPrimary.color.opacity(0.5)
        }
    }
}
