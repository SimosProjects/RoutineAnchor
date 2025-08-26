//
//  CompactTimeBlockRow.swift
//  Routine Anchor
//
//  Created by Christopher Simonson on 8/9/25.
//
import SwiftUI

struct CompactTimeBlockRow: View {
    @Environment(\.themeManager) private var themeManager
    let timeBlock: TimeBlock
    let isActive: Bool
    let isHighlighted: Bool
    let onTap: () -> Void
    let onComplete: () -> Void
    let onSkip: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Time
                Text(timeBlock.startTime, style: .time)
                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                    .foregroundStyle(isActive ? Color.anchorBlue : themeManager?.currentTheme.textSecondaryColor ?? Theme.defaultTheme.textSecondaryColor)
                    .frame(width: 60, alignment: .leading)
                
                // Icon and title
                HStack(spacing: 8) {
                    if let icon = timeBlock.icon {
                        Text(icon)
                            .font(.system(size: 16))
                    }
                    
                    Text(timeBlock.title)
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundStyle(themeManager?.currentTheme.textPrimaryColor ?? Theme.defaultTheme.textPrimaryColor)
                        .lineLimit(1)
                }
                
                Spacer()
                
                // Status indicator
                Image(systemName: statusIcon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(statusColor)
                    .frame(width: 20, height: 20)
                    .background(statusColor.opacity(0.15))
                    .cornerRadius(4)
                
                // Quick actions
                if timeBlock.status == .notStarted || timeBlock.status == .inProgress {
                    HStack(spacing: 8) {
                        Button(action: onComplete) {
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(Color.anchorGreen)
                                .frame(width: 28, height: 28)
                                .background(Color.anchorGreen.opacity(0.15))
                                .cornerRadius(6)
                        }
                        
                        Button(action: onSkip) {
                            Image(systemName: "forward.fill")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(Color.anchorWarning)
                                .frame(width: 28, height: 28)
                                .background(Color.anchorWarning.opacity(0.15))
                                .cornerRadius(6)
                        }
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isActive ? Color.anchorBlue.opacity(0.1) : Color.white.opacity(0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(
                        isHighlighted ? Color.anchorBlue : Color.clear,
                        lineWidth: isHighlighted ? 2 : 0
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isHighlighted ? 1.02 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHighlighted)
    }
    
    private var statusIcon: String {
        switch timeBlock.status {
        case .notStarted: return "clock"
        case .inProgress: return "play.fill"
        case .completed: return "checkmark"
        case .skipped: return "forward.fill"
        }
    }
    
    private var statusColor: Color {
        switch timeBlock.status {
        case .notStarted: return .white.opacity(0.6)
        case .inProgress: return .anchorBlue
        case .completed: return .anchorGreen
        case .skipped: return .anchorWarning
        }
    }
}
