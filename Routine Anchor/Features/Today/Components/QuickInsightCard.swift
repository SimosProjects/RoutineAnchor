//
//  QuickInsightCard.swift
//  Routine Anchor
//
//  Tiny “what’s next/current” insight card. Fully tokenized.
//

import SwiftUI
import UserNotifications

struct QuickInsightCard: View {
    let title: String
    let subtitle: String
    let timeText: String
    let color: Color

    @Environment(\.themeManager) private var themeManager
    @State private var isVisible = false

    private var theme: AppTheme { themeManager?.currentTheme ?? PredefinedThemes.classic }

    var body: some View {
        ThemedCard(cornerRadius: 12) {
            HStack(spacing: 12) {
                // Icon
                ZStack {
                    Circle()
                        .fill(color.opacity(0.25))
                        .frame(width: 36, height: 36)
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(color)
                }

                // Content
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(theme.secondaryTextColor)
                        .lineLimit(1)

                    Text(subtitle)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(theme.primaryTextColor)
                        .lineLimit(1)
                }

                Spacer()

                // Time pill
                Text(timeText)
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundStyle(color)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(color.opacity(0.15)))
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(theme.borderColor.opacity(0.8), lineWidth: 1)
        )
        .scaleEffect(isVisible ? 1 : 0.8)
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : 20)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2)) {
                isVisible = true
            }
        }
    }
}
