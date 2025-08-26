//
//  FeatureCard.swift
//  Routine Anchor
//
//  Created by Christopher Simonson on 7/20/25.
//
import SwiftUI
import UserNotifications

struct FeatureCard: View {
    @Environment(\.themeManager) private var themeManager
    let icon: String
    let title: String
    let description: String
    let delay: Double
    
    @State private var isVisible = false
    @State private var isHovered = false
    
    // Theme color helpers
    private var themePrimaryText: Color {
        themeManager?.currentTheme.textPrimaryColor ?? Theme.defaultTheme.textPrimaryColor
    }
    
    private var themeSecondaryText: Color {
        themeManager?.currentTheme.textSecondaryColor ?? Theme.defaultTheme.textSecondaryColor
    }
    
    private var iconGradient: LinearGradient {
        guard let theme = themeManager?.currentTheme else {
            return LinearGradient(
                colors: [Theme.defaultTheme.primaryColor, Theme.defaultTheme.accentColor],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        
        return LinearGradient(
            colors: [theme.primaryColor, theme.accentColor],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private var iconShadowColor: Color {
        themeManager?.currentTheme.primaryColor.opacity(0.5) ?? Theme.defaultTheme.primaryColor.opacity(0.5)
    }
    
    private var cardShadowColor: Color {
        themeManager?.currentTheme.colorScheme.backgroundPrimary.color.opacity(0.3) ?? Theme.defaultTheme.colorScheme.backgroundPrimary.color.opacity(0.3)
    }
    
    var body: some View {
        ThemedCard(cornerRadius: 18) {
            HStack(spacing: 16) {
                // Icon
                RoundedRectangle(cornerRadius: 14)
                    .fill(iconGradient)
                    .frame(width: 48, height: 48)
                    .overlay(
                        Image(systemName: icon)
                            .font(.system(size: 22, weight: .medium))
                            .foregroundStyle(themePrimaryText)
                    )
                    .shadow(color: iconShadowColor, radius: 10, x: 0, y: 5)
                
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundStyle(themePrimaryText)
                    
                    Text(description)
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundStyle(themeSecondaryText)
                        .lineLimit(2)
                }
                
                Spacer()
            }
        }
        .scaleEffect(isHovered ? 1.02 : 1)
        .shadow(color: cardShadowColor, radius: 20, x: 0, y: 10)
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : 30)
        .scaleEffect(isVisible ? 1 : 0.9)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(delay)) {
                isVisible = true
            }
        }
        .onTapGesture {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isHovered = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isHovered = false
                }
            }
        }
    }
}
