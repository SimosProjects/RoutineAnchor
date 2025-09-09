//
//  NavigationButton.swift
//  Routine Anchor
//

import SwiftUI

/// Small icon button for toolbars / floating actions.
struct NavigationButton: View {
    let icon: String
    let style: Style
    let action: () -> Void

    @Environment(\.themeManager) private var themeManager
    @State private var isPressed = false

    enum Style { case primary, secondary, accent, success }

    private var theme: AppTheme { themeManager?.currentTheme ?? PredefinedThemes.classic }

    var body: some View {
        Button {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) { isPressed = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
                withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) { isPressed = false }
                action()
            }
        } label: {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(foreground)
                .frame(width: 40, height: 40)
                .background(background)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(border, lineWidth: borderWidth)
                )
                .shadow(color: shadow, radius: isPressed ? 6 : 10, x: 0, y: isPressed ? 3 : 5)
                .scaleEffect(isPressed ? 0.94 : 1.0)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Style mapping

    private var background: AnyShapeStyle {
        switch style {
        case .primary:
            return AnyShapeStyle(theme.actionPrimaryGradient)
        case .accent:
            return AnyShapeStyle(
                LinearGradient(colors: [theme.accentPrimaryColor, theme.accentSecondaryColor],
                               startPoint: .topLeading, endPoint: .bottomTrailing)
            )
        case .success:
            return AnyShapeStyle(
                LinearGradient(colors: [theme.statusSuccessColor, theme.accentSecondaryColor],
                               startPoint: .topLeading, endPoint: .bottomTrailing)
            )
        case .secondary:
            return AnyShapeStyle(theme.surfaceCardColor.opacity(0.35))
        }
    }

    private var foreground: Color {
        switch style {
        case .secondary: return theme.primaryTextColor
        default:         return theme.invertedTextColor
        }
    }

    private var border: Color {
        style == .secondary ? theme.borderColor.opacity(0.9) : .clear
    }

    private var borderWidth: CGFloat {
        style == .secondary ? 1 : 0
    }

    private var shadow: Color {
        switch style {
        case .primary:  return theme.accentPrimaryColor.opacity(0.35)
        case .accent:   return theme.accentSecondaryColor.opacity(0.35)
        case .success:  return theme.statusSuccessColor.opacity(0.35)
        case .secondary:return .black.opacity(0.18)
        }
    }
}

// Convenience initializers
extension NavigationButton {
    init(icon: String, action: @escaping () -> Void) {
        self.icon = icon
        self.style = .primary
        self.action = action
    }

    static func secondary(icon: String, action: @escaping () -> Void) -> NavigationButton {
        NavigationButton(icon: icon, style: .secondary, action: action)
    }
    static func accent(icon: String, action: @escaping () -> Void) -> NavigationButton {
        NavigationButton(icon: icon, style: .accent, action: action)
    }
    static func success(icon: String, action: @escaping () -> Void) -> NavigationButton {
        NavigationButton(icon: icon, style: .success, action: action)
    }
}

#Preview {
    HStack(spacing: 12) {
        NavigationButton(icon: "arrow.right") {}
        NavigationButton.secondary(icon: "gear") {}
        NavigationButton.accent(icon: "star") {}
        NavigationButton.success(icon: "checkmark") {}
    }
    .padding()
    .background(PredefinedThemes.classic.heroBackground.ignoresSafeArea())
    .environment(\.themeManager, ThemeManager.preview())
    .preferredColorScheme(.dark)
}
