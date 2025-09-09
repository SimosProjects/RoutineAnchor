//
//  DesignedButton.swift
//  Routine Anchor
//
//  Opinionated, theme-aware button used across the app.
//  Supports gradient (CTA), surface (secondary), and destructive styles.
//

import SwiftUI

struct DesignedButton: View {
    // MARK: - Config
    let title: String
    var style: Style = .gradient
    var size: Size = .large
    var fullWidth: Bool = true
    var isEnabled: Bool = true
    var isLoading: Bool = false
    let action: () -> Void

    // Theme
    @Environment(\.themeManager) private var themeManager
    private var theme: AppTheme { themeManager?.currentTheme ?? PredefinedThemes.classic }

    // Press feedback
    @State private var isPressed = false

    // MARK: - Enums
    enum Style {
        /// Primary CTA gradient (preferred)
        case gradient
        /// Subtle filled surface (secondary)
        case surface
        /// Solid destructive/emphasis state
        case destructive

        /// Backward-compat alias; maps to `.gradient`
        case primary
    }

    enum Size { case small, medium, large }

    // MARK: - Init
    init(
        title: String,
        style: Style = .gradient,
        size: Size = .large,
        fullWidth: Bool = true,
        isEnabled: Bool = true,
        isLoading: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.style = style
        self.size = size
        self.fullWidth = fullWidth
        self.isEnabled = isEnabled
        self.isLoading = isLoading
        self.action = action
    }

    // MARK: - View
    var body: some View {
        Button {
            guard isEnabled && !isLoading else { return }
            withAnimation(.spring(response: 0.28, dampingFraction: 0.7)) { isPressed = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
                withAnimation(.spring(response: 0.28, dampingFraction: 0.7)) { isPressed = false }
                action()
            }
        } label: {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView().scaleEffect(0.9)
                }
                Text(title)
            }
            .font(font)
            .foregroundStyle(textColor)
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .frame(height: height)
            .padding(.horizontal, hPad)
            .background(backgroundStyle)
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .stroke(borderColor, lineWidth: borderWidth)
            )
            .shadow(color: shadowColor, radius: shadowRadius, x: 0, y: shadowY)
            .scaleEffect(isPressed ? 0.97 : 1.0)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled || isLoading)
        .opacity(isEnabled ? 1.0 : 0.6)
        .animation(.easeInOut(duration: 0.12), value: isLoading)
        .animation(.easeInOut(duration: 0.12), value: isEnabled)
    }

    // MARK: - Metrics by size
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

    // MARK: - Styles
    private var backgroundStyle: AnyShapeStyle {
        switch style {
        case .gradient, .primary:
            return AnyShapeStyle(theme.actionPrimaryGradient)
        case .surface:
            return AnyShapeStyle(theme.surfaceCardColor.opacity(0.92))
        case .destructive:
            return AnyShapeStyle(theme.statusErrorColor)
        }
    }

    private var textColor: Color {
        switch style {
        case .gradient, .primary, .destructive:
            return theme.invertedTextColor
        case .surface:
            return theme.primaryTextColor
        }
    }

    private var borderColor: Color {
        switch style {
        case .surface:
            return theme.borderColor.opacity(0.9)
        default:
            return .clear
        }
    }
    private var borderWidth: CGFloat { style == .surface ? 1 : 0 }

    private var shadowColor: Color {
        switch style {
        case .gradient, .primary:
            return theme.accentPrimaryColor.opacity(0.30)
        case .destructive:
            return theme.statusErrorColor.opacity(0.30)
        case .surface:
            return .clear
        }
    }
    private var shadowRadius: CGFloat {
        switch style {
        case .gradient, .primary, .destructive: return 10
        case .surface: return 0
        }
    }
    private var shadowY: CGFloat {
        switch style {
        case .gradient, .primary, .destructive: return 5
        case .surface: return 0
        }
    }
}

#Preview {
    VStack(spacing: 14) {
        DesignedButton(title: "Continue", style: .gradient) { }
        DesignedButton(title: "Try Premium", style: .gradient, size: .medium) { }
        DesignedButton(title: "Secondary", style: .surface, size: .medium) { }
        DesignedButton(title: "Delete", style: .destructive, size: .medium, fullWidth: false) { }
        // Back-compat alias:
        DesignedButton(title: "Primary (alias)", style: .primary) { }
        DesignedButton(title: "Loading", style: .gradient, isLoading: true) { }
    }
    .padding()
    .background(PredefinedThemes.classic.heroBackground.ignoresSafeArea())
    .environment(\.themeManager, ThemeManager.preview())
    .preferredColorScheme(.dark)
}
