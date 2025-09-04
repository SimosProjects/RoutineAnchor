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
        themeManager?.currentTheme.secondaryTextColor ?? Theme.defaultTheme.secondaryTextColor
    }

    private var themeTertiaryText: Color {
        themeManager?.currentTheme.subtleTextColor ?? Theme.defaultTheme.subtleTextColor
    }
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .medium))
                .foregroundStyle(color)
            
            VStack(spacing: 4) {
                Text(value)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(themeManager?.currentTheme.primaryTextColor ?? Theme.defaultTheme.primaryTextColor)
                
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
                    color: themeManager?.currentTheme.colorScheme.actionSuccess.color ?? Theme.defaultTheme.colorScheme.actionSuccess.color,
                    icon: "checkmark.circle.fill"
                )
                
                StatCard(
                    title: "Time",
                    value: "5h 30m",
                    subtitle: "tracked",
                    color: themeManager?.currentTheme.colorScheme.workflowPrimary.color ?? Theme.defaultTheme.colorScheme.workflowPrimary.color,
                    icon: "clock.fill"
                )
                
                StatCard(
                    title: "Skipped",
                    value: "2",
                    subtitle: "blocks",
                    color: themeManager?.currentTheme.colorScheme.warningColor.color ?? Theme.defaultTheme.colorScheme.warningColor.color,
                    icon: "forward.circle.fill"
                )
            }
            .padding()
        }
    }
}
