//
//  MessageBanner.swift
//  Routine Anchor
//
//  Reusable message banner
//

import SwiftUI

struct MessageBanner: View {
    @Environment(\.themeManager) private var themeManager
    let message: String
    let type: MessageType

    private var theme: AppTheme { themeManager?.currentTheme ?? PredefinedThemes.classic }

    private var typeColor: Color {
        switch type {
        case .success: return theme.statusSuccessColor
        case .error:   return theme.statusErrorColor
        }
    }

    enum MessageType {
        case success, error
        var icon: String {
            switch self {
            case .success: return "checkmark.circle.fill"
            case .error:   return "exclamationmark.triangle.fill"
            }
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: type.icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(typeColor)

            Text(message)
                .font(TypographyConstants.Body.emphasized)
                .foregroundStyle(theme.primaryTextColor)
                .lineLimit(2)

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(typeColor.opacity(0.1))
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(typeColor.opacity(0.3), lineWidth: 1)
        )
        .shadow(color: typeColor.opacity(0.2), radius: 8, x: 0, y: 4)
        .padding(.horizontal, 24)
        .padding(.top, 8)
    }
}

#Preview("Message Banners") {
    VStack(spacing: 20) {
        MessageBanner(message: "Successfully saved your changes", type: .success)
        MessageBanner(message: "An error occurred. Please try again.", type: .error)
    }
    .padding()
    .background(Color.gray.opacity(0.1))
    .environment(\.themeManager, ThemeManager.preview())
    .preferredColorScheme(.dark)
}
