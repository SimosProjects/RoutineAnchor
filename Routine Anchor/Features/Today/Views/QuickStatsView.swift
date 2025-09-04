//
//  QuickStatsView.swift
//  Routine Anchor
//
//  Created by Christopher Simonson on 8/15/25.
//
import SwiftUI

struct QuickStatsView: View {
    let viewModel: TodayViewModel
    @Environment(\.themeManager) private var themeManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 24) {
                // Header - FIXED with safe area handling
                HStack {
                    Text("Quick Stats")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [themeManager?.currentTheme.colorScheme.workflowPrimary.color ?? Theme.defaultTheme.colorScheme.workflowPrimary.color, themeManager?.currentTheme.colorScheme.organizationAccent.color ?? Theme.defaultTheme.colorScheme.organizationAccent.color],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    
                    Spacer()
                    
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(Color(themeManager?.currentTheme.subtleTextColor ?? Theme.defaultTheme.subtleTextColor).opacity(0.6))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, max(geometry.safeAreaInsets.top + 8, 20)) // FIXED: Respect safe area
                
                // Stats Grid
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    StatCard(
                        title: "Total Blocks",
                        value: "\(viewModel.timeBlocks.count)",
                        subtitle: "blocks",
                        color: themeManager?.currentTheme.colorScheme.workflowPrimary.color ?? Theme.defaultTheme.colorScheme.workflowPrimary.color,
                        icon: "square.stack"
                    )
                    
                    StatCard(
                        title: "Completed",
                        value: "\(viewModel.completedBlocksCount)",
                        subtitle: "blocks",
                        color: themeManager?.currentTheme.colorScheme.actionSuccess.color ?? Theme.defaultTheme.colorScheme.actionSuccess.color,
                        icon: "checkmark.circle"
                    )
                    
                    StatCard(
                        title: "Progress",
                        value: "\(viewModel.progressPercentage)%",
                        subtitle: "blocks",
                        color: themeManager?.currentTheme.colorScheme.organizationAccent.color ?? Theme.defaultTheme.colorScheme.organizationAccent.color,
                        icon: "chart.pie"
                    )
                    
                    StatCard(
                        title: "Remaining",
                        value: "\(viewModel.upcomingBlocksCount)",
                        subtitle: "blocks",
                        color: themeManager?.currentTheme.colorScheme.creativeSecondary.color ?? Theme.defaultTheme.colorScheme.creativeSecondary.color,
                        icon: "clock"
                    )
                }
                .padding(.horizontal, 24)
                
                // Current Focus
                if let currentBlock = viewModel.getCurrentBlock() {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Currently Working On")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Color(themeManager?.currentTheme.secondaryTextColor ?? Theme.defaultTheme.secondaryTextColor).opacity(0.85))
                        
                        Text(currentBlock.title)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(themeManager?.currentTheme.primaryTextColor ?? Theme.defaultTheme.primaryTextColor)
                        
                        if let remaining = viewModel.remainingTimeForCurrentBlock() {
                            Text(remaining)
                                .font(.system(size: 14))
                                .foregroundStyle(themeManager?.currentTheme.colorScheme.actionSuccess.color ?? Theme.defaultTheme.colorScheme.actionSuccess.color)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .background(Color(themeManager?.currentTheme.colorScheme.uiElementPrimary.color ?? Theme.defaultTheme.colorScheme.uiElementPrimary.color).opacity(0.5))
                    .cornerRadius(12)
                    .padding(.horizontal, 24)
                }
                
                Spacer(minLength: geometry.safeAreaInsets.bottom + 16)
            }
        }
        .background(ThemedAnimatedBackground())
        .ignoresSafeArea(.container, edges: .bottom)
    }
}
