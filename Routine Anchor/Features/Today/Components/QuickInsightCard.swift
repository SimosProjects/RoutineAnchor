//
//  QuickInsightCard.swift
//  Routine Anchor
//
//  Created by Christopher Simonson on 7/21/25.
//
import SwiftUI
import UserNotifications

// MARK: - Quick Insight Card
struct QuickInsightCard: View {
    let title: String
    let subtitle: String
    let timeText: String
    let color: Color
    
    @Environment(\.themeManager) private var themeManager
    @State private var isVisible = false
    
    var body: some View {
        ThemedCard(cornerRadius: 12) {
            HStack(spacing: 12) {
                // Icon
                ZStack {
                    Circle()
                        .fill(color.opacity(0.2))
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(color)
                }
                
                // Content
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(themeManager?.currentTheme.secondaryTextColor ??
                                         Theme.defaultTheme.secondaryTextColor)
                    
                    Text(subtitle)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(themeManager?.currentTheme.primaryTextColor ?? Theme.defaultTheme.primaryTextColor)
                        .lineLimit(1)
                }
                
                Spacer()
                
                // Time
                Text(timeText)
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundStyle(color)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(color.opacity(0.15))
                    )
            }
        }
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
