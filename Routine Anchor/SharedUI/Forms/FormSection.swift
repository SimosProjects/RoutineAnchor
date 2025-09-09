//
//  FormSection.swift
//  Routine Anchor
//

import SwiftUI

/// A titled card container for form groups.
struct FormSection<Content: View>: View {
    let title: String
    let icon: String
    let color: Color
    let content: Content

    @Environment(\.themeManager) private var themeManager
    @State private var isVisible = false

    private var theme: AppTheme { themeManager?.currentTheme ?? PredefinedThemes.classic }

    init(title: String, icon: String, color: Color, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.color = color
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(color)
                    .frame(width: 28, height: 28)

                Text(title)
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundStyle(theme.primaryTextColor)

                Spacer()
            }

            content
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(theme.surfaceCardColor.opacity(0.9))
        )
        .overlay(
            // Subtle colorized border for affordance
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [color.opacity(0.30), color.opacity(0.10)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: .black.opacity(0.18), radius: 10, x: 0, y: 6)
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : 20)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.15)) {
                isVisible = true
            }
        }
    }
}
