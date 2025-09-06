//
//  FeatureCard.swift
//  Routine Anchor
//

import SwiftUI

struct FeatureCard: View {
    @Environment(\.themeManager) private var themeManager

    let icon: String
    let title: String
    let description: String
    let tint: Color?
    let delay: Double

    @State private var isVisible = false
    @State private var isPressed = false

    // Theme helpers
    private var theme: Theme { themeManager?.currentTheme ?? Theme.defaultTheme }
    private var scheme: ThemeColorScheme { theme.colorScheme }

    private var iconGradient: LinearGradient {
        let base = tint ?? scheme.workflowPrimary.color
        let mate = tint == nil ? scheme.creativeSecondary.color : base.opacity(0.7)
        return LinearGradient(colors: [base, mate], startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    private var borderColor: Color {
        (tint ?? scheme.workflowPrimary.color).opacity(0.28)
    }

    var body: some View {
        ThemedCard(cornerRadius: 16) {
            HStack(spacing: 14) {
                // Icon blob
                RoundedRectangle(cornerRadius: 12)
                    .fill(iconGradient)
                    .frame(width: 48, height: 48)
                    .overlay(
                        Image(systemName: icon)
                            .font(.system(size: 22, weight: .medium))
                            .foregroundStyle(theme.primaryTextColor)
                    )
                    .shadow(color: (tint ?? scheme.workflowPrimary.color).opacity(0.35), radius: 10, x: 0, y: 6)

                // Copy
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundStyle(theme.primaryTextColor)

                    Text(description)
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundStyle(theme.secondaryTextColor)
                        .fixedSize(horizontal: false, vertical: true)
                        .lineLimit(3)
                }

                Spacer(minLength: 0)
            }
            .contentShape(Rectangle())
        }
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(borderColor, lineWidth: 1)
        )
        .scaleEffect(isPressed ? 0.98 : 1)
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : 18)
        .animation(.spring(response: 0.6, dampingFraction: 0.75).delay(delay), value: isVisible)
        .onAppear { isVisible = true }
        .onTapGesture {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { isPressed = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { isPressed = false }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title). \(description)")
    }
}
