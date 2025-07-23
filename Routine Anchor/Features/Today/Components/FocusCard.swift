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
    
    @State private var pulseScale: CGFloat = 1.0
    @State private var progressAnimation: CGFloat = 0
    
    var body: some View {
        HStack(spacing: 16) {
            // Focus icon with pulse
            ZStack {
                Circle()
                    .fill(Color.premiumBlue.opacity(0.2))
                    .frame(width: 50, height: 50)
                    .scaleEffect(pulseScale)
                
                Image(systemName: "target")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(Color.premiumBlue)
            }
            
            // Focus content
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Focus Mode")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.white.opacity(0.6))
                        .textCase(.uppercase)
                        .tracking(1)
                    
                    Spacer()
                    
                    // Time indicator
                    if let currentBlock = currentBlock,
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
                    .foregroundStyle(.white)
                    .lineLimit(2)
                
                // Progress bar for current block
                if let currentBlock = currentBlock, currentBlock.isCurrentlyActive {
                    ProgressBar(
                        progress: currentBlock.currentProgress,
                        color: Color.premiumBlue,
                        animated: true
                    )
                }
            }
        }
        .padding(20)
        .glassMorphism(cornerRadius: 16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.premiumBlue.opacity(0.4),
                            Color.premiumBlue.opacity(0.1)
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
    let timeText: String
    let isActive: Bool
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(isActive ? Color.premiumGreen : Color.premiumBlue)
                .frame(width: 6, height: 6)
            
            Text(timeText)
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundStyle(isActive ? Color.premiumGreen : Color.premiumBlue)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill((isActive ? Color.premiumGreen : Color.premiumBlue).opacity(0.15))
        )
    }
}
