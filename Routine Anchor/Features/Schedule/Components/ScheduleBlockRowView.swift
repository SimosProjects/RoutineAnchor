//
//  ScheduleBlockRowView.swift
//  Routine Anchor
//
//  Created by Christopher Simonson on 8/10/25.
//
import SwiftUI

struct ScheduleBlockRowView: View {
    let timeBlock: TimeBlock
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    @Environment(\.themeManager) private var themeManager
    @State private var isPressed = false
    @State private var isVisible = false
    
    // Theme color helpers
    private var themePrimaryText: Color {
        themeManager?.currentTheme.textPrimaryColor ?? Theme.defaultTheme.textPrimaryColor
    }
    
    private var themeSecondaryText: Color {
        themeManager?.currentTheme.textSecondaryColor ?? Theme.defaultTheme.textSecondaryColor
    }
    
    private var themeTertiaryText: Color {
        themeManager?.currentTheme.textTertiaryColor ?? Theme.defaultTheme.textTertiaryColor
    }
    
    private var cardShadowColor: Color {
        themeManager?.currentTheme.colorScheme.backgroundPrimary.color.opacity(0.1) ?? Theme.defaultTheme.colorScheme.backgroundPrimary.color.opacity(0.1)
    }
    
    var body: some View {
        ThemedCard(cornerRadius: 20) {
            HStack(spacing: 16) {
                // Time and status indicator
                VStack(spacing: 8) {
                    // Status indicator
                    ZStack {
                        Circle()
                            .fill(statusColor.opacity(0.2))
                            .frame(width: 32, height: 32)
                        
                        Image(systemName: timeBlock.status.iconName)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(statusColor)
                    }
                    
                    // Time range
                    VStack(spacing: 2) {
                        Text(timeBlock.shortFormattedTimeRange)
                            .font(.system(size: 11, weight: .semibold, design: .monospaced))
                            .foregroundStyle(themeSecondaryText)
                        
                        Text(timeBlock.formattedDuration)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(themeTertiaryText)
                    }
                }
                
                // Main content
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        if let icon = timeBlock.icon {
                            Text(icon)
                                .font(.system(size: 18))
                        }
                        
                        Text(timeBlock.title)
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundStyle(themePrimaryText)
                            .lineLimit(1)
                    }
                    
                    if let notes = timeBlock.notes, !notes.isEmpty {
                        Text(notes)
                            .font(.system(size: 14, weight: .regular))
                            .foregroundStyle(themeSecondaryText)
                            .lineLimit(2)
                    }
                    
                    if let category = timeBlock.category {
                        HStack(spacing: 4) {
                            Image(systemName: "folder")
                                .font(.system(size: 10, weight: .medium))
                            
                            Text(category)
                                .font(.system(size: 12, weight: .medium))
                        }
                        .foregroundStyle(themeTertiaryText)
                    }
                }
                
                Spacer()
                
                // Action buttons
                HStack(spacing: 8) {
                    Button(action: onEdit) {
                        Image(systemName: "pencil")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(editButtonColor)
                            .frame(width: 36, height: 36)
                            .background(editButtonColor.opacity(0.15))
                            .cornerRadius(10)
                    }
                    
                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(deleteButtonColor)
                            .frame(width: 36, height: 36)
                            .background(deleteButtonColor.opacity(0.15))
                            .cornerRadius(10)
                    }
                }
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    LinearGradient(
                        colors: [
                            statusColor.opacity(0.3),
                            statusColor.opacity(0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: cardShadowColor, radius: 10, x: 0, y: 5)
        .scaleEffect(isPressed ? 0.98 : 1)
        .opacity(isVisible ? 1 : 0)
        .offset(x: isVisible ? 0 : 50)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.1)) {
                isVisible = true
            }
        }
    }
    
    private var statusColor: Color {
        guard let theme = themeManager?.currentTheme else {
            switch timeBlock.status {
            case .notStarted: return Theme.defaultTheme.textSecondaryColor
            case .inProgress: return Theme.defaultTheme.colorScheme.blue.color
            case .completed: return Theme.defaultTheme.colorScheme.success.color
            case .skipped: return Theme.defaultTheme.colorScheme.warning.color
            }
        }
        
        switch timeBlock.status {
        case .notStarted: return theme.textSecondaryColor
        case .inProgress: return theme.colorScheme.blue.color
        case .completed: return theme.colorScheme.success.color
        case .skipped: return theme.colorScheme.warning.color
        }
    }
    
    private var editButtonColor: Color {
        themeManager?.currentTheme.colorScheme.blue.color ?? Theme.defaultTheme.colorScheme.blue.color
    }
    
    private var deleteButtonColor: Color {
        themeManager?.currentTheme.colorScheme.error.color ?? Theme.defaultTheme.colorScheme.error.color
    }
}
