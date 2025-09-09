//
//  SettingsHeader.swift
//  Routine Anchor
//

import SwiftUI

struct SettingsHeader: View {
    @Environment(\.themeManager) private var themeManager
    let onDismiss: () -> Void
    @Binding var animationPhase: Int

    private var theme: AppTheme { themeManager?.currentTheme ?? PredefinedThemes.classic }

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Button(action: { onDismiss() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(theme.primaryTextColor.opacity(0.8))
                        .frame(width: 32, height: 32)
                        .background(
                            Circle()
                                .fill(.ultraThinMaterial)
                                .background(
                                    Circle().fill(theme.surfaceCardColor)
                                )
                        )
                }
                Spacer()
            }

            VStack(spacing: 12) {
                Image(systemName: "gear")
                    .font(.system(size: 48, weight: .light))
                    .foregroundStyle(
                        LinearGradient(colors: [theme.accentPrimaryColor, theme.accentSecondaryColor],
                                       startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .scaleEffect(animationPhase == 0 ? 1.0 : 1.1)
                    .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: animationPhase)

                Text("Settings")
                    .font(TypographyConstants.Headers.welcome)
                    .foregroundStyle(theme.primaryTextColor)

                Text("Customize your experience")
                    .font(TypographyConstants.Body.secondary)
                    .foregroundStyle(theme.secondaryTextColor)
            }
        }
    }
}
