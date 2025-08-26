//
//  DurationCard.swift
//  Routine Anchor
//
//  Created by Christopher Simonson on 7/23/25.
//
import SwiftUI

struct DurationCard: View {
    let minutes: Int
    let color: Color
    
    @Environment(\.themeManager) private var themeManager

    private var formattedDuration: String {
        let hours = minutes / 60
        let mins = minutes % 60

        if hours > 0 && mins > 0 {
            return "\(hours)h \(mins)m"
        } else if hours > 0 {
            return "\(hours)h"
        } else {
            return "\(mins)m"
        }
    }

    var body: some View {
        HStack {
            Image(systemName: "clock.badge")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(color)

            Text("Duration:")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(themeManager?.currentTheme.textPrimaryColor ?? Theme.defaultTheme.textPrimaryColor)

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
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
    }
}

