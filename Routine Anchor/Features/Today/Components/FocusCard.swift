//
//  FocusCard.swift
//  Routine Anchor
//
//  Created by Christopher Simonson on 7/21/25.
//
import SwiftUI
import UserNotifications

// MARK: - Focus Card
struct FocusCard: View {
    let text: String
    let currentBlock: TimeBlock?
    let viewModel: TodayViewModel
    
    @Environment(\.themeManager) private var themeManager
    @State private var pulseScale: CGFloat = 1.0
    @State private var progressAnimation: CGFloat = 0
    
    var body: some View {
        // Pull once to avoid repeating optionals and to match new tokens
        let scheme = (themeManager?.currentTheme.colorScheme ?? Theme.defaultTheme.colorScheme)
        let primaryText = (themeManager?.currentTheme.primaryTextColor ?? Theme.defaultTheme.primaryTextColor)
        let secondaryText = (themeManager?.currentTheme.secondaryTextColor ?? Theme.defaultTheme.secondaryTextColor)
        
        return HStack(spacing: 16) {
            // Focus icon with pulse
            ZStack {
                Circle()
                    .fill(scheme.workflowPrimary.color.opacity(scheme.ringOuterAlpha))
                    .frame(width: 50, height: 50)
                    .scaleEffect(pulseScale)
                
                Image(systemName: "target")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(scheme.workflowPrimary.color)
            }
            
            // Focus content
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Focus Mode")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(secondaryText.opacity(0.85))
                        .textCase(.uppercase)
                        .tracking(1)
                    
                    Spacer()
                    
                    // Time indicator
                    if currentBlock != nil,
                       let remainingTime = viewModel.remainingTimeForCurrentBlock() {
                        TimeIndicator(
                            timeText: remainingTime,
                            isActive: true
                        )
                    } else if let nextTime = viewModel.timeUntilNextBlock() {
                        TimeIndicator(
                            timeText: "in \(nextTime)",
                            isActive: false
                        )
                    }
                }
                
                Text(text)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(primaryText)
                    .lineLimit(2)
                
                // Progress bar for current block
                if let currentBlock = currentBlock, currentBlock.isCurrentlyActive {
                    ProgressBar(
                        progress: currentBlock.currentProgress,
                        color: scheme.workflowPrimary.color,
                        animated: true
                    )
                }
            }
        }
        .padding(20)
        .themedGlassMorphism(cornerRadius: 16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    LinearGradient(
                        colors: [
                            scheme.workflowPrimary.color.opacity(0.4),
                            scheme.workflowPrimary.color.opacity(0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .onAppear {
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                pulseScale = 1.1
            }
        }
    }
}

// MARK: - Time Indicator
struct TimeIndicator: View {
    @Environment(\.themeManager) private var themeManager
    let timeText: String
    let isActive: Bool
    
    var body: some View {
        let scheme = (themeManager?.currentTheme.colorScheme ?? Theme.defaultTheme.colorScheme)
        let activeColor = scheme.actionSuccess.color
        let idleColor = scheme.workflowPrimary.color
        
        return HStack(spacing: 4) {
            Circle()
                .fill(isActive ? activeColor : idleColor)
                .frame(width: 6, height: 6)
            
            Text(timeText)
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundStyle(isActive ? activeColor : idleColor)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill((isActive ? activeColor : idleColor).opacity(0.15))
        )
    }
}
