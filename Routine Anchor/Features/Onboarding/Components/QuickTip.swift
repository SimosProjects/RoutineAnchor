//
//  QuickTip.swift
//  Routine Anchor
//

import SwiftUI
import UserNotifications

struct QuickTip: View {
    let number: String
    let text: String
    let delay: Double

    @Environment(\.themeManager) private var themeManager
    @State private var isVisible = false

    private var theme: AppTheme { themeManager?.currentTheme ?? PredefinedThemes.classic }

    var body: some View {
        HStack(spacing: 12) {
            Text(number)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(theme.invertedTextColor)
                .frame(width: 28, height: 28)
                .background(
                    Circle().fill(
                        LinearGradient(colors: [theme.statusSuccessColor, theme.accentSecondaryColor],
                                       startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                )

            Text(text)
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundStyle(theme.primaryTextColor)

            Spacer()
        }
        .opacity(isVisible ? 1 : 0)
        .offset(x: isVisible ? 0 : -20)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(delay)) {
                isVisible = true
            }
        }
    }
}
