//
//  ProgressOverviewCard.swift
//  Routine Anchor
//
//  Created by Christopher Simonson on 7/21/25.
//
import SwiftUI
import UserNotifications

// MARK: - Progress Overview Card
struct ProgressOverviewCard: View {
    let viewModel: TodayViewModel
    @State private var animateProgress = false
    
    var body: some View {
        HStack(spacing: 20) {
            // Circular progress
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.2), lineWidth: 4)
                    .frame(width: 60, height: 60)
                
                Circle()
                    .trim(from: 0, to: animateProgress ? CGFloat(viewModel.progressPercentage) : 0)
                    .stroke(
                        LinearGradient(
                            colors: [Color.anchorGreen, Color.anchorTeal],
                            startPoint: .topTrailing,
                            endPoint: .bottomLeading
                        ),
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .frame(width: 60, height: 60)
                    .rotationEffect(.degrees(-90))
                
                Text(viewModel.formattedProgressPercentage)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }
            
            // Progress details
            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.completionSummary)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                
                Text(viewModel.timeSummary)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.7))
                
                // Performance indicator
                HStack(spacing: 6) {
                    Text(viewModel.performanceLevel.emoji)
                        .font(.system(size: 12))
                    
                    Text(viewModel.performanceLevel.displayName)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(viewModel.performanceLevel.color)
                }
            }
            
            Spacer()
        }
        .padding(20)
        .glassMorphism(cornerRadius: 16)
        .onAppear {
            withAnimation(.spring(response: 1.2, dampingFraction: 0.8).delay(0.3)) {
                animateProgress = true
            }
        }
    }
}
