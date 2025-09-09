//
//  SecondaryButton.swift
//  Routine Anchor
//

import SwiftUI

/// Flexible secondary button with Filled / Outlined / Ghost styles and variants.
struct SecondaryButton: View {
    @Environment(\.themeManager) private var themeManager

    let title: String
    let action: () -> Void

    var isEnabled: Bool = true
    var isLoading: Bool = false
    var fullWidth: Bool = true
    var size: ButtonSize = .large
    var style: ButtonStyle = .outlined
    var variant: ButtonVariant = .neutral

    private var theme: AppTheme { themeManager?.currentTheme ?? PredefinedThemes.classic }

    var body: some View {
        Button {
            guard isEnabled && !isLoading else { return }
            HapticManager.shared.lightImpact()
            action()
        } label: {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView().scaleEffect(0.9)
                } else {
                    Text(title)
                }
            }
            .font(font)
            .foregroundStyle(textColor)
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .frame(height: height)
            .padding(.horizontal, hPad)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .stroke(borderColor, lineWidth: borderWidth)
            )
        }
        .disabled(!isEnabled || isLoading)
        .opacity(isEnabled ? 1.0 : 0.5)
        .animation(.easeInOut(duration: 0.12), value: isLoading)
        .animation(.easeInOut(duration: 0.12), value: isEnabled)
    }

    // MARK: - Styling

    enum ButtonSize { case small, medium, large }
    enum ButtonStyle { case filled, outlined }
    enum ButtonVariant { case neutral, destructive, success }

    private var height: CGFloat {
        switch size {
        case .small:  return 36
        case .medium: return 44
        case .large:  return 52
        }
    }

    private var hPad: CGFloat {
        switch size {
        case .small:  return 16
        case .medium: return 20
        case .large:  return 24
        }
    }

    private var radius: CGFloat {
        switch size {
        case .small:  return 10
        case .medium: return 12
        case .large:  return 14
        }
    }

    private var font: Font {
        switch size {
        case .small:  return .system(size: 14, weight: .semibold)
        case .medium: return .system(size: 16, weight: .semibold)
        case .large:  return .system(size: 18, weight: .semibold)
        }
    }

    private var roleColor: Color {
        switch variant {
        case .neutral:     return theme.accentSecondaryColor
        case .destructive: return theme.statusErrorColor
        case .success:     return theme.statusSuccessColor
        }
    }

    private var background: AnyShapeStyle {
        switch style {
        case .filled:
            return AnyShapeStyle(
                LinearGradient(colors: [roleColor, roleColor.opacity(0.85)],
                               startPoint: .leading, endPoint: .trailing)
            )
        case .outlined:
            return AnyShapeStyle(Color.clear)
        }
    }

    private var textColor: Color {
        switch style {
        case .filled:  return theme.invertedTextColor
        case .outlined:
            return roleColor
        }
    }

    private var borderColor: Color {
        switch style {
        case .outlined: return roleColor
        default:        return .clear
        }
    }

    private var borderWidth: CGFloat {
        style == .outlined ? 1.5 : 0
    }
}

// MARK: - Convenience

extension SecondaryButton {
    init(_ title: String, action: @escaping () -> Void) {
        self.title = title
        self.action = action
    }

    func buttonSize(_ s: ButtonSize) -> Self { var c = self; c.size = s; return c }
    func buttonStyle(_ s: ButtonStyle) -> Self { var c = self; c.style = s; return c }
    func variant(_ v: ButtonVariant) -> Self { var c = self; c.variant = v; return c }
    func loading(_ v: Bool) -> Self { var c = self; c.isLoading = v; return c }
    func enabled(_ v: Bool) -> Self { var c = self; c.isEnabled = v; return c }
    func fullWidth(_ v: Bool) -> Self { var c = self; c.fullWidth = v; return c }
}

#Preview {
    VStack(spacing: 12) {
        SecondaryButton("Neutral (Outlined)") {}
        SecondaryButton("Neutral (Filled)") {}.buttonStyle(.filled)
        SecondaryButton("Success") {}.variant(.success)
        SecondaryButton("Delete") {}.variant(.destructive).buttonStyle(.outlined)
    }
    .padding()
    .background(PredefinedThemes.classic.heroBackground.ignoresSafeArea())
    .environment(\.themeManager, ThemeManager.preview())
    .preferredColorScheme(.dark)
}
