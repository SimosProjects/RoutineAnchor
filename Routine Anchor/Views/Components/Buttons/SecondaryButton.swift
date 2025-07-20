//
//  SecondaryButton.swift
//  Routine Anchor
//
//  Created by Christopher Simonson on 7/19/25.
//
import SwiftUI

struct SecondaryButton: View {
    // MARK: - Properties
    let title: String
    let action: () -> Void
    
    // Optional customization
    var isEnabled: Bool = true
    var isLoading: Bool = false
    var fullWidth: Bool = true
    var size: ButtonSize = .large
    var style: ButtonStyle = .outlined
    var variant: ButtonVariant = .neutral
    
    // MARK: - Body
    var body: some View {
        Button(action: {
            if isEnabled && !isLoading {
                // Lighter haptic feedback for secondary actions
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
                        .foregroundColor(textColor)
                }
                
                // Button text
                if !isLoading {
                    Text(title)
                        .font(buttonFont)
                        .fontWeight(.medium)
                        .foregroundColor(textColor)
                }
            }
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .frame(height: buttonHeight)
            .padding(.horizontal, horizontalPadding)
            .background(backgroundColor)
            .cornerRadius(cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(borderColor, lineWidth: borderWidth)
            )
        }
        .disabled(!isEnabled || isLoading)
        .opacity(isEnabled ? 1.0 : 0.5)
        .scaleEffect(isEnabled ? 1.0 : 0.98)
        .animation(.easeInOut(duration: 0.1), value: isEnabled)
        .animation(.easeInOut(duration: 0.1), value: isLoading)
    }
    
    // MARK: - Computed Properties
    private var backgroundColor: Color {
        switch style {
        case .filled:
            switch variant {
            case .neutral: return Color.appBackgroundSecondary
            case .destructive: return Color.errorRed
            case .success: return Color.successGreen
            }
        case .outlined, .ghost:
            return Color.clear
        }
    }
    
    private var textColor: Color {
        switch style {
        case .filled:
            switch variant {
            case .neutral: return Color.textPrimary
            case .destructive, .success: return Color.white
            }
        case .outlined, .ghost:
            switch variant {
            case .neutral: return Color.textSecondary
            case .destructive: return Color.errorRed
            case .success: return Color.successGreen
            }
        }
    }
    
    private var borderColor: Color {
        switch style {
        case .filled:
            return Color.clear
        case .outlined:
            switch variant {
            case .neutral: return Color.separatorColor
            case .destructive: return Color.errorRed
            case .success: return Color.successGreen
            }
        case .ghost:
            return Color.clear
        }
    }
    
    private var borderWidth: CGFloat {
        switch style {
        case .filled, .ghost: return 0
        case .outlined: return 1.5
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
        case .small: return .system(size: 14, weight: .medium)
        case .medium: return .system(size: 16, weight: .medium)
        case .large: return .system(size: 18, weight: .medium)
        }
    }
}

// MARK: - Button Enums
extension SecondaryButton {
    enum ButtonSize {
        case small
        case medium
        case large
    }
    
    enum ButtonStyle {
        case filled    // Background filled with color
        case outlined  // Border with transparent background
        case ghost     // No border, no background (text only)
    }
    
    enum ButtonVariant {
        case neutral     // Default gray/neutral colors
        case destructive // Red for delete/cancel actions
        case success     // Green for positive actions
    }
}

// MARK: - Convenience Initializers
extension SecondaryButton {
    // Standard secondary button
    init(
        _ title: String,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.action = action
    }
    
    // Secondary button with loading state
    init(
        _ title: String,
        isLoading: Bool,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.action = action
        self.isLoading = isLoading
    }
    
    // Secondary button with enabled state
    init(
        _ title: String,
        isEnabled: Bool,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.action = action
        self.isEnabled = isEnabled
    }
    
    // Destructive secondary button (for delete/cancel actions)
    init(
        _ title: String,
        destructive: Bool,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.action = action
        self.variant = destructive ? .destructive : .neutral
    }
    
    // Ghost button (text only, no background/border)
    init(
        _ title: String,
        ghost: Bool,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.action = action
        self.style = ghost ? .ghost : .outlined
    }
    
    // Compact secondary button (not full width)
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
extension SecondaryButton {
    func buttonSize(_ size: ButtonSize) -> SecondaryButton {
        var button = self
        button.size = size
        return button
    }
    
    func buttonStyle(_ style: ButtonStyle) -> SecondaryButton {
        var button = self
        button.style = style
        return button
    }
    
    func variant(_ variant: ButtonVariant) -> SecondaryButton {
        var button = self
        button.variant = variant
        return button
    }
    
    func loading(_ isLoading: Bool) -> SecondaryButton {
        var button = self
        button.isLoading = isLoading
        return button
    }
    
    func enabled(_ isEnabled: Bool) -> SecondaryButton {
        var button = self
        button.isEnabled = isEnabled
        return button
    }
    
    func fullWidth(_ fullWidth: Bool) -> SecondaryButton {
        var button = self
        button.fullWidth = fullWidth
        return button
    }
}

// MARK: - Convenience Methods for Common Use Cases
extension SecondaryButton {
    // Cancel button (common pattern)
    static func cancel(action: @escaping () -> Void) -> SecondaryButton {
        SecondaryButton("Cancel", action: action)
            .variant(.neutral)
            .buttonStyle(.ghost)
    }
    
    // Skip button (common in onboarding)
    static func skip(action: @escaping () -> Void) -> SecondaryButton {
        SecondaryButton("Skip", action: action)
            .variant(.neutral)
            .buttonStyle(.ghost)
            .buttonSize(.medium)
    }
    
    // Delete button (destructive action)
    static func delete(action: @escaping () -> Void) -> SecondaryButton {
        SecondaryButton("Delete", action: action)
            .variant(.destructive)
            .buttonStyle(.outlined)
    }
    
    // Maybe Later button (common in permissions)
    static func maybeLater(action: @escaping () -> Void) -> SecondaryButton {
        SecondaryButton("Maybe Later", action: action)
            .variant(.neutral)
            .buttonStyle(.outlined)
    }
}

// MARK: - Previews
#Preview("Secondary Button States") {
    VStack(spacing: 20) {
        Group {
            // Standard states
            SecondaryButton("Maybe Later") {}
            
            SecondaryButton("Loading...") {}
                .loading(true)
            
            SecondaryButton("Disabled") {}
                .enabled(false)
            
            // Different variants
            SecondaryButton("Neutral") {}
                .variant(.neutral)
            
            SecondaryButton("Destructive") {}
                .variant(.destructive)
            
            SecondaryButton("Success") {}
                .variant(.success)
            
            // Different styles
            SecondaryButton("Outlined") {}
                .buttonStyle(.outlined)
            
            SecondaryButton("Filled") {}
                .buttonStyle(.filled)
            
            SecondaryButton("Ghost") {}
                .buttonStyle(.ghost)
            
            // Different sizes
            SecondaryButton("Large") {}
                .buttonSize(.large)
            
            SecondaryButton("Medium") {}
                .buttonSize(.medium)
            
            SecondaryButton("Small") {}
                .buttonSize(.small)
            
            // Common patterns
            SecondaryButton.cancel {}
            SecondaryButton.skip {}
            SecondaryButton.delete {}
            SecondaryButton.maybeLater {}
        }
    }
    .padding(20)
    .background(Color.appBackgroundSecondary)
}

#Preview("Button Combinations") {
    VStack(spacing: 16) {
        // Primary + Secondary combination (common pattern)
        VStack(spacing: 12) {
            PrimaryButton("Get Started") {}
            SecondaryButton("Maybe Later") {}
        }
        
        Divider()
        
        // Action + Cancel combination
        HStack(spacing: 12) {
            SecondaryButton("Cancel") {}
                .buttonStyle(.ghost)
            
            PrimaryButton("Save Changes") {}
        }
        
        Divider()
        
        // Destructive action pattern
        VStack(spacing: 12) {
            SecondaryButton("Delete Routine") {}
                .variant(.destructive)
                .buttonStyle(.outlined)
            
            SecondaryButton("Cancel") {}
                .buttonStyle(.ghost)
        }
    }
    .padding(20)
    .background(Color.appBackgroundSecondary)
}

#Preview("Dark Mode") {
    VStack(spacing: 20) {
        SecondaryButton("Maybe Later") {}
        SecondaryButton("Delete") {}
            .variant(.destructive)
        SecondaryButton("Cancel") {}
            .buttonStyle(.ghost)
    }
    .padding(20)
    .background(Color.appBackgroundSecondary)
    .preferredColorScheme(.dark)
}
