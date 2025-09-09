//
//  ThemedCard.swift
//  Routine Anchor
//
//  A reusable card container that adapts to the current AppTheme.
//  - Uses theme.surfaceCardColor for the base
//  - Adds a subtle glass overlay for readability on hero backgrounds
//  - Applies a soft border and shadow consistent with the theme
//

import SwiftUI

struct ThemedCard<Content: View>: View {
    @Environment(\.themeManager) private var themeManager
    private var theme: AppTheme { themeManager?.currentTheme ?? PredefinedThemes.classic }

    let cornerRadius: CGFloat
    let contentPadding: CGFloat
    @ViewBuilder let content: Content

    init(
        cornerRadius: CGFloat = 20,
        contentPadding: CGFloat = 20,
        @ViewBuilder content: () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.contentPadding = contentPadding
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            content
        }
        .padding(contentPadding)
        .background(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(theme.surfaceCardColor.opacity(0.90))
                .overlay(
                    // Thin glass/tint to keep content legible over vivid backgrounds
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(theme.glassMaterialOverlay)
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(theme.borderColor.opacity(0.25), lineWidth: 1)
        )
        .shadow(color: .black.opacity(theme.shadowOpacity), radius: 12, x: 0, y: 6)
    }
}

#Preview {
    VStack(spacing: 16) {
        ThemedCard {
            VStack(alignment: .leading, spacing: 8) {
                Text("Today’s Overview")
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundStyle((Environment(\.themeManager).wrappedValue?.currentTheme ?? PredefinedThemes.classic).primaryTextColor)
                Text("A quick snapshot of your schedule and progress.")
                    .font(.system(size: 14))
                    .foregroundStyle((Environment(\.themeManager).wrappedValue?.currentTheme ?? PredefinedThemes.classic).secondaryTextColor)
            }
        }

        ThemedCard(cornerRadius: 16, contentPadding: 16) {
            HStack {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 20))
                    .foregroundStyle((Environment(\.themeManager).wrappedValue?.currentTheme ?? PredefinedThemes.classic).statusSuccessColor)
                Text("Keep it up! You’re on track.")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle((Environment(\.themeManager).wrappedValue?.currentTheme ?? PredefinedThemes.classic).primaryTextColor)
                Spacer()
            }
        }
    }
    .padding()
    .background(PredefinedThemes.classic.heroBackground.ignoresSafeArea())
    .environment(\.themeManager, ThemeManager.preview())
    .preferredColorScheme(.dark)
}
