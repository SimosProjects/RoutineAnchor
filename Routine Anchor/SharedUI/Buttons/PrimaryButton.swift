//
//  PrimaryButton.swift
//  Routine Anchor
//

import SwiftUI

/// Large call-to-action button with Filled / Outlined styles.
/// Uses AppTheme semantic tokens (gradient, text, surface, border).
struct PrimaryButton: View {
    @Environment(\.themeManager) private var themeManager

    // Public API
    let title: String
    let action: () -> Void
    var isEnabled: Bool
    var isLoading: Bool
    var fullWidth: Bool
    var size: ButtonSize
    var style: ButtonStyle

    // Theme
    private var theme: AppTheme { themeManager?.currentTheme ?? PredefinedThemes.classic }

    // MARK: - Init (no builder/ext methods needed)
    init(
        _ title: String,
        style: ButtonStyle = .filled,
        size: ButtonSize = .large,
        isLoading: Bool = false,
        isEnabled: Bool = true,
        fullWidth: Bool = true,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.action = action
        self.style = style
        self.size = size
        self.isLoading = isLoading
        self.isEnabled = isEnabled
        self.fullWidth = fullWidth
    }

    // MARK: - View
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
            .background(background) // AnyShapeStyle to unify types
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .stroke(borderColor, lineWidth: borderWidth)
            )
            .shadow(color: shadow, radius: style == .filled ? 10 : 0, x: 0, y: style == .filled ? 5 : 0)
        }
        .disabled(!isEnabled || isLoading)
        .opacity(isEnabled ? 1.0 : 0.6)
        .animation(.easeInOut(duration: 0.12), value: isLoading)
        .animation(.easeInOut(duration: 0.12), value: isEnabled)
    }

    // MARK: - Styling

    enum ButtonSize { case small, medium, large }
    enum ButtonStyle { case filled, outlined }

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

    // Use AnyShapeStyle so both branches conform (gradient vs. clear)
    private var background: AnyShapeStyle {
        switch style {
        case .filled:
            return AnyShapeStyle(theme.actionPrimaryGradient)
        case .outlined:
            return AnyShapeStyle(Color.clear)
        }
    }

    private var textColor: Color {
        switch style {
        case .filled:  return theme.invertedTextColor
        case .outlined:return theme.accentPrimaryColor
        }
    }

    private var borderColor: Color {
        style == .outlined ? theme.accentPrimaryColor : .clear
    }

    private var borderWidth: CGFloat { style == .outlined ? 2 : 0 }

    private var shadow: Color {
        style == .filled ? theme.accentPrimaryColor.opacity(0.25) : .clear
    }
}

#Preview {
    VStack(spacing: 14) {
        PrimaryButton("Get Started", action: { })

        PrimaryButton("Outlined",
                      style: .outlined,
                      action: { })

        PrimaryButton("Loading",
                      isLoading: true,
                      action: { })
    }
    .padding()
    .background(PredefinedThemes.classic.heroBackground.ignoresSafeArea())
    .environment(\.themeManager, ThemeManager.preview())
    .preferredColorScheme(.dark)
}
