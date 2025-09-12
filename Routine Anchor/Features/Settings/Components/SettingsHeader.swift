//
//  SettingsHeader.swift
//  Routine Anchor
//
//  Created by Christopher Simonson on 8/9/25.
//
import SwiftUI

struct SettingsHeader: View {
    @Environment(\.themeManager) private var themeManager
    let onDismiss: () -> Void
    @Binding var animationPhase: Int

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Button(action: { onDismiss() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Color(themeManager?.currentTheme.primaryTextColor ?? Theme.defaultTheme.primaryTextColor).opacity(0.8))
                        .frame(width: 32, height: 32)
                        .background(
                            Circle()
                                .fill(.ultraThinMaterial)
                                .background(
                                    Circle().fill(Color(themeManager?.currentTheme.colorScheme.primaryUIElement.color ?? Theme.defaultTheme.colorScheme.primaryUIElement.color))
                                )
                        )
                }
                Spacer()
            }

            VStack(spacing: 12) {
                Image(systemName: "gear")
                    .font(.system(size: 48, weight: .light))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [themeManager?.currentTheme.colorScheme.normal.color ?? Theme.defaultTheme.colorScheme.normal.color, themeManager?.currentTheme.colorScheme.primaryAccent.color ?? Theme.defaultTheme.colorScheme.primaryAccent.color],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .scaleEffect(animationPhase == 0 ? 1.0 : 1.1)
                    .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: animationPhase)

                Text("Settings")
                    .font(TypographyConstants.Headers.welcome)
                    .foregroundStyle(themeManager?.currentTheme.primaryTextColor ?? Theme.defaultTheme.primaryTextColor)

                Text("Customize your experience")
                    .font(TypographyConstants.Body.secondary)
                    .foregroundStyle(themeManager?.currentTheme.secondaryTextColor ?? Theme.defaultTheme.secondaryTextColor)
            }
        }
    }
}

