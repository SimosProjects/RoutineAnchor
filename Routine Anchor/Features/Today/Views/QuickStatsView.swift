//
//  QuickStatsView.swift
//  Routine Anchor
//
//  Created by Christopher Simonson on 8/15/25.
//
import SwiftUI

struct QuickStatsView: View {
    let viewModel: TodayViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
            HStack {
                Text("Quick Stats")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.anchorBlue, Color.anchorPurple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                
                Spacer()
                
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(Color.white.opacity(0.3))
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            
            // Stats Grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                StatCard(
                    title: "Total Blocks",
                    value: "\(viewModel.timeBlocks.count)",
                    subtitle: "blocks",
                    color: .anchorBlue,
                    icon: "square.stack"
                )
                
                StatCard(
                    title: "Completed",
                    value: "\(viewModel.completedBlocksCount)",
                    subtitle: "blocks",
                    color: .anchorGreen,
                    icon: "checkmark.circle"
                )
                
                StatCard(
                    title: "Progress",
                    value: "\(viewModel.progressPercentage)%",
                    subtitle: "blocks",
                    color: .anchorPurple,
                    icon: "chart.pie"
                )
                
                StatCard(
                    title: "Remaining",
                    value: "\(viewModel.upcomingBlocksCount)",
                    subtitle: "blocks",
                    color: .anchorTeal,
                    icon: "clock"
                )
            }
            .padding(.horizontal, 24)
            
            // Current Focus
            if let currentBlock = viewModel.getCurrentBlock() {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Currently Working On")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.6))
                    
                    Text(currentBlock.title)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                    
                    if let remaining = viewModel.remainingTimeForCurrentBlock() {
                        Text(remaining)
                            .font(.system(size: 14))
                            .foregroundStyle(Color.anchorGreen)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(Color.white.opacity(0.05))
                .cornerRadius(12)
                .padding(.horizontal, 24)
            }
            
            Spacer()
        }
        .background(AnimatedGradientBackground())
    }
}
