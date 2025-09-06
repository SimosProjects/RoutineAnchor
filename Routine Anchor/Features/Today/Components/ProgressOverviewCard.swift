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
    @Environment(\.themeManager) private var themeManager
    @State private var animateProgress = false
    
    var body: some View {
        // Pull theme + scheme once
        let theme  = (themeManager?.currentTheme ?? Theme.defaultTheme)
        let scheme = theme.colorScheme
        
        return ThemedCard(cornerRadius: 16, useMaterial: false, useTint: true) {
            HStack(spacing: 20) {
                // Circular progress
                ZStack {
                    // Track
                    Circle()
                        .stroke(scheme.progressTrack.color, lineWidth: 4)
                        .frame(width: 60, height: 60)
                    
                    // Fill
                    Circle()
                        .trim(from: 0, to: animateProgress ? CGFloat(viewModel.progressPercentage) : 0)
                        .stroke(
                            LinearGradient(
                                colors: [scheme.progressFillStart.color, scheme.progressFillEnd.color],
                                startPoint: .topTrailing,
                                endPoint: .bottomLeading
                            ),
                            style: StrokeStyle(lineWidth: 4, lineCap: .round)
                        )
                        .frame(width: 60, height: 60)
                        .rotationEffect(.degrees(-90))
                    
                    // Label
                    Text(viewModel.formattedProgressPercentage)
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(theme.primaryTextColor)
                }
                
                // Progress details
                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.completionSummary)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(theme.primaryTextColor)
                    
                    Text(viewModel.timeSummary)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(theme.secondaryTextColor)
                    
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
        }
        .onAppear {
            withAnimation(.spring(response: 1.2, dampingFraction: 0.8).delay(0.3)) {
                animateProgress = true
            }
        }
    }
}
