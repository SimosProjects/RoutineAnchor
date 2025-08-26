//
//  MessageBanner.swift
//  Routine Anchor
//
//  Reusable message banner component
//
import SwiftUI

struct MessageBanner: View {
    @Environment(\.themeManager) private var themeManager
    let message: String
    let type: MessageType
    
    private var themePrimaryText: Color {
        themeManager?.currentTheme.textPrimaryColor ?? Theme.defaultTheme.textPrimaryColor
    }
    
    enum MessageType {
        case success, error
        
        var color: Color {
            switch self {
            case .success: return Color.anchorGreen
            case .error: return Color.anchorError
            }
        }
        
        var icon: String {
            switch self {
            case .success: return "checkmark.circle.fill"
            case .error: return "exclamationmark.triangle.fill"
            }
        }
    }
    
    var body: some View {
        ThemedCard(cornerRadius: 12) {
            HStack(spacing: 12) {
                Image(systemName: type.icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(type.color)
                
                Text(message)
                    .font(TypographyConstants.Body.emphasized)
                    .foregroundStyle(themePrimaryText)
                    .lineLimit(2)
                
                Spacer()
            }
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(type.color.opacity(0.1))
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(type.color.opacity(0.3), lineWidth: 1)
            )
            .shadow(color: type.color.opacity(0.2), radius: 8, x: 0, y: 4)
            .padding(.horizontal, 24)
            .padding(.top, 8)
        }
    }
}
