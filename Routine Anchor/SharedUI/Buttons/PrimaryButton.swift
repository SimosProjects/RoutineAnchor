//
//  PrimaryButton.swift
//  Routine Anchor
//
//  Created by Christopher Simonson on 7/19/25.
//
import SwiftUI

struct PrimaryButton: View {
    // MARK: - Properties
    let title: String
    let action: () -> Void
    
    // Optional customization
    var icon: String? = nil
    var isEnabled: Bool = true
    var isLoading: Bool = false
    var fullWidth: Bool = true
    var size: ButtonSize = .large
    var style: ButtonStyle = .filled
    
    // MARK: - Body
    var body: some View {
        Button(action: {
            if isEnabled && !isLoading {
                // Haptic feedback
                HapticManager.shared.lightImpact()
                action()
            }
        }) {
            HStack(spacing: 8) {
                // Loading indicator
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(0.8)
                        .tint(textColor)
                }
                
                // Icon (if provided)
                if let icon = icon, !isLoading {
                    Image(systemName: icon)
                        .font(.system(size: iconSize, weight: .semibold))
                        .foregroundStyle(textColor)
                }
                
                // Button text
                if !isLoading {
                    Text(title)
                        .font(buttonFont)
                        .fontWeight(.semibold)
                        .foregroundStyle(textColor)
                }
            }
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .frame(height: buttonHeight)
            .padding(.horizontal, horizontalPadding)
            .background(
                LinearGradient(
                    colors: backgroundGradientColors,
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(cornerRadius)
            .overlay(
                // Border for outlined style
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(borderColor, lineWidth: borderWidth)
            )
            .shadow(
                color: shadowColor,
                radius: shadowRadius,
                x: 0,
                y: shadowOffset
            )
        }
        .disabled(!isEnabled || isLoading)
        .opacity(isEnabled ? 1.0 : 0.6)
        .scaleEffect(isEnabled ? 1.0 : 0.98)
        .animation(.easeInOut(duration: 0.1), value: isEnabled)
        .animation(.easeInOut(duration: 0.1), value: isLoading)
    }
    
    // MARK: - Computed Properties
    private var backgroundGradientColors: [Color] {
        switch style {
        case .filled:
            if isEnabled {
                return [Color.premiumBlue, Color.premiumBlue.opacity(0.8)]
            } else {
                return [Color.premiumBlue.opacity(0.6), Color.premiumBlue.opacity(0.4)]
            }
        case .outlined:
            return [Color.clear, Color.clear]
        }
    }
    
    private var textColor: Color {
        switch style {
        case .filled:
            return .white
        case .outlined:
            return Color.premiumBlue
        }
    }
    
    private var borderColor: Color {
        switch style {
        case .filled:
            return Color.clear
        case .outlined:
            return Color.premiumBlue
        }
    }
    
    private var borderWidth: CGFloat {
        switch style {
        case .filled: return 0
        case .outlined: return 2
        }
    }
    
    private var shadowColor: Color {
        switch style {
        case .filled:
            return isEnabled ? Color.premiumBlue.opacity(0.3) : Color.clear
        case .outlined:
            return Color.clear
        }
    }
    
    private var shadowRadius: CGFloat {
        switch style {
        case .filled: return isEnabled ? 4 : 0
        case .outlined: return 0
        }
    }
    
    private var shadowOffset: CGFloat {
        switch style {
        case .filled: return isEnabled ? 2 : 0
        case .outlined: return 0
        }
    }
    
    private var buttonHeight: CGFloat {
        switch size {
        case .small: return 36
        case .medium: return 44
        case .large: return 52
        }
    }
    
    private var horizontalPadding: CGFloat {
        switch size {
        case .small: return 16
        case .medium: return 20
        case .large: return 24
        }
    }
    
    private var cornerRadius: CGFloat {
        switch size {
        case .small: return 8
        case .medium: return 10
        case .large: return 12
        }
    }
    
    private var buttonFont: Font {
        switch size {
        case .small: return .system(size: 14, weight: .semibold)
        case .medium: return .system(size: 16, weight: .semibold)
        case .large: return .system(size: 18, weight: .semibold)
        }
    }
    
    private var iconSize: CGFloat {
        switch size {
        case .small: return 14
        case .medium: return 16
        case .large: return 18
        }
    }
}

// MARK: - Button Enums
extension PrimaryButton {
    enum ButtonSize {
        case small
        case medium
        case large
    }
    
    enum ButtonStyle {
        case filled
        case outlined
    }
}

// MARK: - Convenience Initializers
extension PrimaryButton {
    // Standard primary button
    init(
        _ title: String,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.action = action
    }
    
    // Primary button with icon
    init(
        title: String,
        icon: String? = nil,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.action = action
    }
    
    // Primary button with loading state
    init(
        _ title: String,
        isLoading: Bool,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.action = action
        self.isLoading = isLoading
    }
    
    // Primary button with enabled state
    init(
        _ title: String,
        isEnabled: Bool,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.action = action
        self.isEnabled = isEnabled
    }
    
    // Compact primary button (not full width)
    init(
        _ title: String,
        compact: Bool,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.action = action
        self.fullWidth = !compact
    }
}

// MARK: - View Modifiers
extension PrimaryButton {
    func buttonSize(_ size: ButtonSize) -> PrimaryButton {
        var button = self
        button.size = size
        return button
    }
    
    func buttonStyle(_ style: ButtonStyle) -> PrimaryButton {
        var button = self
        button.style = style
        return button
    }
    
    func loading(_ isLoading: Bool) -> PrimaryButton {
        var button = self
        button.isLoading = isLoading
        return button
    }
    
    func enabled(_ isEnabled: Bool) -> PrimaryButton {
        var button = self
        button.isEnabled = isEnabled
        return button
    }
    
    func fullWidth(_ fullWidth: Bool) -> PrimaryButton {
        var button = self
        button.fullWidth = fullWidth
        return button
    }
}

// MARK: - Previews
#Preview("Primary Button States") {
    ZStack {
        AnimatedGradientBackground()
            .ignoresSafeArea()
        
        ScrollView {
            VStack(spacing: 20) {
                Group {
                    // Standard states
                    PrimaryButton("Get Started") {}
                    
                    PrimaryButton("Loading...") {}
                        .loading(true)
                    
                    PrimaryButton("Disabled") {}
                        .enabled(false)
                    
                    // With icons
                    PrimaryButton(title: "Share", icon: "square.and.arrow.up") {}
                    
                    PrimaryButton(title: "Continue", icon: "arrow.right") {}
                    
                    // Different sizes
                    PrimaryButton("Large Button") {}
                        .buttonSize(.large)
                    
                    PrimaryButton("Medium Button") {}
                        .buttonSize(.medium)
                    
                    PrimaryButton("Small Button") {}
                        .buttonSize(.small)
                    
                    // Different styles
                    PrimaryButton("Filled Style") {}
                        .buttonStyle(.filled)
                    
                    PrimaryButton("Outlined Style") {}
                        .buttonStyle(.outlined)
                    
                    // Compact width
                    PrimaryButton("Compact") {}
                        .fullWidth(false)
                }
            }
            .padding(20)
        }
    }
}

#Preview("Dark Mode") {
    ZStack {
        AnimatedGradientBackground()
            .ignoresSafeArea()
        
        VStack(spacing: 20) {
            PrimaryButton("Get Started") {}
            PrimaryButton("Loading...") {}
                .loading(true)
            PrimaryButton("Outlined Style") {}
                .buttonStyle(.outlined)
            PrimaryButton(title: "Share Summary", icon: "square.and.arrow.up") {}
        }
        .padding(20)
    }
    .preferredColorScheme(.dark)
}
