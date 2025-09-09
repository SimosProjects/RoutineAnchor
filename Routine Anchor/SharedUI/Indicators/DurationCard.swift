//
//  DurationCard.swift
//  Routine Anchor
//

import SwiftUI

/// Compact “Duration: Xh Ym” card that adopts the active theme.
/// Pass an accent `color` to match the context (status or category).
struct DurationCard: View {
    let minutes: Int
    let color: Color

    @Environment(\.themeManager) private var themeManager
    private var theme: AppTheme { themeManager?.currentTheme ?? PredefinedThemes.classic }

    private var formattedDuration: String {
        let hours = minutes / 60
        let mins = minutes % 60
        if hours > 0 && mins > 0 { return "\(hours)h \(mins)m" }
        if hours > 0             { return "\(hours)h" }
        return "\(mins)m"
        }
    
    var body: some View {
        HStack {
            Image(systemName: "clock.badge")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(color)

            Text("Duration:")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(theme.primaryTextColor)

            Spacer()

            Text(formattedDuration)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(color)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.15))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.30), lineWidth: 1)
        )
    }
}
