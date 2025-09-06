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
        let theme  = (themeManager?.currentTheme ?? Theme.defaultTheme)
        let scheme = theme.colorScheme
        
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Time
                Text(timeBlock.startTime, style: .time)
                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                    .foregroundStyle(isActive ? scheme.workflowPrimary.color : theme.secondaryTextColor)
                    .frame(width: 60, alignment: .leading)
                
                // Icon and title
                HStack(spacing: 8) {
                    if let icon = timeBlock.icon {
                        Text(icon)
                            .font(.system(size: 16))
                    }
                    
                    Text(timeBlock.title)
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundStyle(theme.primaryTextColor)
                        .lineLimit(1)
                }
                
                Spacer()
                
                // Status indicator
                Image(systemName: statusIcon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(statusColor(scheme))
                    .frame(width: 20, height: 20)
                    .background(statusColor(scheme).opacity(scheme.ringOuterAlpha)) // standardized ring alpha
                    .cornerRadius(4)
                
                // Quick actions
                if timeBlock.status == .notStarted || timeBlock.status == .inProgress {
                    HStack(spacing: 8) {
                        Button(action: onComplete) {
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(scheme.actionSuccess.color)
                                .frame(width: 28, height: 28)
                                .background(scheme.actionSuccess.color.opacity(0.15))
                                .cornerRadius(6)
                        }
                        
                        Button(action: onSkip) {
                            Image(systemName: "forward.fill")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(scheme.warningColor.color)
                                .frame(width: 28, height: 28)
                                .background(scheme.warningColor.color.opacity(0.15))
                                .cornerRadius(6)
                        }
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(
                        (isActive
                         ? scheme.surface2.color.opacity(0.50)  // active row elevation
                         : scheme.surface2.color.opacity(0.25)) // inactive row elevation
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(
                        isHighlighted
                        ? scheme.focusRing.color   // unified focus ring
                        : scheme.border.color.opacity(0.8),
                        lineWidth: isHighlighted ? 2 : 1
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
        case .completed:  return "checkmark"
        case .skipped:    return "forward.fill"
        }
    }
    
    private func statusColor(_ scheme: ThemeColorScheme) -> Color {
        switch timeBlock.status {
        case .notStarted:
            return (themeManager?.currentTheme.secondaryTextColor ?? Theme.defaultTheme.secondaryTextColor)
        case .inProgress:
            return scheme.workflowPrimary.color
        case .completed:
            return scheme.actionSuccess.color
        case .skipped:
            return scheme.warningColor.color
        }
    }
}
