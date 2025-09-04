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
        HStack(spacing: 16) {
            // Focus icon with pulse
            ZStack {
                Circle()
                    .fill((themeManager?.currentTheme.colorScheme.workflowPrimary.color ?? Theme.defaultTheme.colorScheme.workflowPrimary.color).opacity(0.2))
                    .frame(width: 50, height: 50)
                    .scaleEffect(pulseScale)
                
                Image(systemName: "target")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(themeManager?.currentTheme.colorScheme.workflowPrimary.color ?? Theme.defaultTheme.colorScheme.workflowPrimary.color)
            }
            
            // Focus content
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Focus Mode")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle((themeManager?.currentTheme.secondaryTextColor ?? Theme.defaultTheme.secondaryTextColor).opacity(0.85))
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
                    .foregroundStyle(themeManager?.currentTheme.primaryTextColor ?? Theme.defaultTheme.primaryTextColor)
                    .lineLimit(2)
                
                // Progress bar for current block
                if let currentBlock = currentBlock, currentBlock.isCurrentlyActive {
                    ProgressBar(
                        progress: currentBlock.currentProgress,
                        color: themeManager?.currentTheme.colorScheme.workflowPrimary.color ?? Theme.defaultTheme.colorScheme.workflowPrimary.color,
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
                            (themeManager?.currentTheme.colorScheme.workflowPrimary.color ?? Theme.defaultTheme.colorScheme.workflowPrimary.color).opacity(0.4),
                            (themeManager?.currentTheme.colorScheme.workflowPrimary.color ?? Theme.defaultTheme.colorScheme.workflowPrimary.color).opacity(0.1)
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
        HStack(spacing: 4) {
            Circle()
                .fill(isActive ?
                    (themeManager?.currentTheme.colorScheme.actionSuccess.color ?? Theme.defaultTheme.colorScheme.actionSuccess.color) :
                    (themeManager?.currentTheme.colorScheme.workflowPrimary.color ?? Theme.defaultTheme.colorScheme.workflowPrimary.color))
                .frame(width: 6, height: 6)
            
            Text(timeText)
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundStyle(isActive ?
                    (themeManager?.currentTheme.colorScheme.actionSuccess.color ?? Theme.defaultTheme.colorScheme.actionSuccess.color) :
                    (themeManager?.currentTheme.colorScheme.workflowPrimary.color ?? Theme.defaultTheme.colorScheme.workflowPrimary.color))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill((isActive ?
                    (themeManager?.currentTheme.colorScheme.actionSuccess.color ?? Theme.defaultTheme.colorScheme.actionSuccess.color) :
                    (themeManager?.currentTheme.colorScheme.workflowPrimary.color ?? Theme.defaultTheme.colorScheme.workflowPrimary.color)).opacity(0.15))
        )
    }
}
