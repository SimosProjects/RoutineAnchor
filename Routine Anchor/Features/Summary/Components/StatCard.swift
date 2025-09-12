//
//  StatCard.swift
//  Routine Anchor
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

    private var theme: Theme { themeManager?.currentTheme ?? Theme.defaultTheme }
    private var scheme: ThemeColorScheme { theme.colorScheme }

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .medium))
                .foregroundStyle(color)

            VStack(spacing: 4) {
                Text(value)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(theme.primaryTextColor)

                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(theme.secondaryTextColor)
                    .textCase(.uppercase)
                    .tracking(0.5)

                Text(subtitle)
                    .font(.system(size: 11, weight: .regular))
                    .foregroundStyle(theme.subtleTextColor)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(scheme.secondaryBackground.color.opacity(0.9))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(color.opacity(0.08))
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(scheme.border.color.opacity(0.85), lineWidth: 1)
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
                    color: themeManager?.currentTheme.colorScheme.success.color ?? Theme.defaultTheme.colorScheme.success.color,
                    icon: "checkmark.circle.fill"
                )
                
                StatCard(
                    title: "Time",
                    value: "5h 30m",
                    subtitle: "tracked",
                    color: themeManager?.currentTheme.colorScheme.normal.color ?? Theme.defaultTheme.colorScheme.normal.color,
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
