//
//  StatCard.swift
//  Routine Anchor
//
//  Statistic card component for displaying metrics
//
import SwiftUI

struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    let icon: String
    
    @Environment(\.themeManager) private var themeManager
    @State private var isVisible = false
    
    private var themeSecondaryText: Color {
        themeManager?.currentTheme.textSecondaryColor ?? Theme.defaultTheme.textSecondaryColor
    }

    private var themeTertiaryText: Color {
        themeManager?.currentTheme.textTertiaryColor ?? Theme.defaultTheme.textTertiaryColor
    }
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .medium))
                .foregroundStyle(color)
            
            VStack(spacing: 4) {
                Text(value)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(themeManager?.currentTheme.textPrimaryColor ?? Theme.defaultTheme.textPrimaryColor)
                
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(themeSecondaryText)
                    .textCase(.uppercase)
                    .tracking(0.5)
                
                Text(subtitle)
                    .font(.system(size: 11, weight: .regular))
                    .foregroundStyle(themeTertiaryText)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(color.opacity(0.1))
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(color.opacity(0.3), lineWidth: 1)
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
    
    var body: some View {
        ZStack {
            ThemedAnimatedBackground()
                .ignoresSafeArea()
            
            HStack(spacing: 12) {
                StatCard(
                    title: "Completed",
                    value: "8",
                    subtitle: "blocks",
                    color: themeManager?.currentTheme.colorScheme.green.color ?? Theme.defaultTheme.colorScheme.green.color,
                    icon: "checkmark.circle.fill"
                )
                
                StatCard(
                    title: "Time",
                    value: "5h 30m",
                    subtitle: "tracked",
                    color: themeManager?.currentTheme.colorScheme.blue.color ?? Theme.defaultTheme.colorScheme.blue.color,
                    icon: "clock.fill"
                )
                
                StatCard(
                    title: "Skipped",
                    value: "2",
                    subtitle: "blocks",
                    color: themeManager?.currentTheme.colorScheme.warning.color ?? Theme.defaultTheme.colorScheme.warning.color,
                    icon: "forward.circle.fill"
                )
            }
            .padding()
        }
    }
}
