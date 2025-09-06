//
//  AnalyticsComponents.swift
//  Routine Anchor
//
//  Components for PremiumAnalyticsView
//
import SwiftUI

// MARK: - Analytics Card
struct AnalyticsCard: View {
    @Environment(\.themeManager) private var themeManager
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    let icon: String
    let trend: TrendDisplayDirection
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(color)
                
                Spacer()
                
                Image(systemName: trend.iconName)
                    .font(.system(size: 12))
                    .foregroundStyle(trend.color(theme: themeManager?.currentTheme))
            }
            
            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(themeManager?.currentTheme.primaryTextColor ?? Theme.defaultTheme.primaryTextColor)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle((themeManager?.currentTheme.primaryTextColor ?? Theme.defaultTheme.primaryTextColor).opacity(0.8))
                
                Text(subtitle)
                    .font(.system(size: 10))
                    .foregroundStyle(themeManager?.currentTheme.secondaryTextColor ??
                                     Theme.defaultTheme.secondaryTextColor)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(themeManager?.currentTheme.colorScheme.uiElementPrimary.color
                      ?? Theme.defaultTheme.colorScheme.uiElementPrimary.color)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(color.opacity(0.35), lineWidth: 1)
                )
        )
    }
}

// MARK: - Category Performance Row
struct CategoryPerformanceRow: View {
    @Environment(\.themeManager) private var themeManager
    let category: String
    let completionRate: Double
    let totalTime: String
    let color: Color
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(category)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(themeManager?.currentTheme.primaryTextColor ?? Theme.defaultTheme.primaryTextColor)
                
                Text(totalTime)
                    .font(.system(size: 12))
                    .foregroundStyle(themeManager?.currentTheme.secondaryTextColor ??
                                     Theme.defaultTheme.secondaryTextColor)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(Int(completionRate * 100))%")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(themeManager?.currentTheme.primaryTextColor ?? Theme.defaultTheme.primaryTextColor)
                
                ProgressView(value: completionRate)
                    .progressViewStyle(LinearProgressViewStyle(tint: color))
                    .frame(width: 80)
                    .scaleEffect(y: 1.5)
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Time Slot Row
struct TimeSlotRow: View {
    @Environment(\.themeManager) private var themeManager
    let timeSlot: String
    let performance: Double
    let label: String
    let color: Color
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(timeSlot)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(themeManager?.currentTheme.primaryTextColor ?? Theme.defaultTheme.primaryTextColor)
                
                Text(label)
                    .font(.system(size: 12))
                    .foregroundStyle(color)
            }
            
            Spacer()
            
            HStack(spacing: 8) {
                Text("\(Int(performance * 100))%")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(themeManager?.currentTheme.primaryTextColor ?? Theme.defaultTheme.primaryTextColor)
                
                Circle()
                    .fill(color)
                    .frame(width: 8, height: 8)
            }
        }
        .padding(.vertical, 6)
    }
}
