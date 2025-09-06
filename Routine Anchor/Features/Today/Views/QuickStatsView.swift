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
        let theme  = (themeManager?.currentTheme ?? Theme.defaultTheme)
        let scheme = theme.colorScheme
        
        return GeometryReader { geometry in
            VStack(spacing: 24) {
                HStack {
                    Text("Quick Stats")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [scheme.workflowPrimary.color, scheme.organizationAccent.color],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    
                    Spacer()
                    
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(theme.subtleTextColor.opacity(0.6))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, max(geometry.safeAreaInsets.top + 8, 20))
                
                // Stats Grid
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    StatCard(
                        title: "Total Blocks",
                        value: "\(viewModel.timeBlocks.count)",
                        subtitle: "blocks",
                        color: scheme.workflowPrimary.color,
                        icon: "square.stack"
                    )
                    
                    StatCard(
                        title: "Completed",
                        value: "\(viewModel.completedBlocksCount)",
                        subtitle: "blocks",
                        color: scheme.actionSuccess.color,
                        icon: "checkmark.circle"
                    )
                    
                    StatCard(
                        title: "Progress",
                        value: "\(viewModel.progressPercentage)%",
                        subtitle: "blocks",
                        color: scheme.organizationAccent.color,
                        icon: "chart.pie"
                    )
                    
                    StatCard(
                        title: "Remaining",
                        value: "\(viewModel.upcomingBlocksCount)",
                        subtitle: "blocks",
                        color: scheme.creativeSecondary.color,
                        icon: "clock"
                    )
                }
                .padding(.horizontal, 24)
                
                // Current Focus
                if let currentBlock = viewModel.getCurrentBlock() {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Currently Working On")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(theme.secondaryTextColor.opacity(0.85))
                        
                        Text(currentBlock.title)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(theme.primaryTextColor)
                        
                        if let remaining = viewModel.remainingTimeForCurrentBlock() {
                            Text(remaining)
                                .font(.system(size: 14, weight: .medium, design: .monospaced))
                                .foregroundStyle(scheme.actionSuccess.color)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(scheme.surface2.color.opacity(0.55))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(scheme.border.color.opacity(0.8), lineWidth: 1)
                    )
                    .padding(.horizontal, 24)
                }
                
                Spacer(minLength: geometry.safeAreaInsets.bottom + 16)
            }
            .background(
                ZStack {
                    LinearGradient(
                        colors: [scheme.todayHeroTop.color, scheme.todayHeroBottom.color],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    RadialGradient(
                        colors: [
                            scheme.todayHeroVignette.color.opacity(scheme.todayHeroVignetteOpacity),
                            .clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 520
                    )
                }
                .ignoresSafeArea()
            )
        }
        .ignoresSafeArea(.container, edges: .bottom)
    }
}
