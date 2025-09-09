//
//  StatCard.swift
//  Routine Anchor
//
//  Compact stat tile used in Quick Stats and similar grids.
//

import SwiftUI

struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color          // accent tint for icon/overlay
    let icon: String

    @Environment(\.themeManager) private var themeManager
    @State private var isVisible = false

    private var theme: AppTheme { themeManager?.currentTheme ?? PredefinedThemes.classic }

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .medium))
                .foregroundStyle(color)

            VStack(spacing: 4) {
                Text(value)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(theme.primaryTextColor)

                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(theme.secondaryTextColor)
                    .textCase(.uppercase)
                    .tracking(0.5)

                Text(subtitle)
                    .font(.system(size: 11, weight: .regular))
                    .foregroundStyle(theme.subtleTextColor)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            // Glassy card base + subtle accent tint layer
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(theme.surfaceCardColor.opacity(0.9))
                RoundedRectangle(cornerRadius: 16)
                    .fill(color.opacity(0.08))
            }
        )
        .overlay(
            // Consistent border from theme tokens
            RoundedRectangle(cornerRadius: 16)
                .stroke(theme.borderColor.opacity(0.85), lineWidth: 1)
        )
        .scaleEffect(isVisible ? 1 : 0.8)
        .opacity(isVisible ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2)) {
                isVisible = true
            }
        }
    }
}

// MARK: - Preview

#Preview("Stat Cards") {
    StatCardsPreviewView()
}

private struct StatCardsPreviewView: View {
    @Environment(\.themeManager) private var themeManager

    private var theme: AppTheme { themeManager?.currentTheme ?? PredefinedThemes.classic }

    var body: some View {
        ZStack {
            // Uses the same hero background as Today
            ThemedAnimatedBackground().ignoresSafeArea()

            HStack(spacing: 12) {
                StatCard(
                    title: "Completed",
                    value: "8",
                    subtitle: "blocks",
                    color: theme.statusSuccessColor,
                    icon: "checkmark.circle.fill"
                )

                StatCard(
                    title: "Time",
                    value: "5h 30m",
                    subtitle: "tracked",
                    color: theme.accentPrimaryColor,
                    icon: "clock.fill"
                )

                StatCard(
                    title: "Skipped",
                    value: "2",
                    subtitle: "blocks",
                    color: theme.statusWarningColor,
                    icon: "forward.circle.fill"
                )
            }
            .padding()
        }
    }
}
