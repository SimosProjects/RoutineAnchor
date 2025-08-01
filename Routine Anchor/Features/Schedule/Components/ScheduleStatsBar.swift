//
//  ScheduleStatsBar.swift
//  Routine Anchor
//
//  Stats bar showing schedule overview information
//

import SwiftUI

struct ScheduleStatsBar: View {
    let viewModel: ScheduleBuilderViewModel
    
    @State private var isVisible = false
    
    var body: some View {
        HStack(spacing: 16) {
            // Total blocks
            StatItem(
                icon: "square.stack.3d.up",
                value: "\(viewModel.timeBlocks.count)",
                label: "Blocks",
                color: .premiumBlue
            )
            
            Spacer()
            
            // Total duration
            StatItem(
                icon: "clock",
                value: viewModel.formattedTotalDuration,
                label: "Total Time",
                color: .premiumPurple
            )
            
            Spacer()
            
            // Categories
            StatItem(
                icon: "tag",
                value: "\(uniqueCategories)",
                label: "Categories",
                color: .premiumTeal
            )
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
        .scaleEffect(isVisible ? 1 : 0.9)
        .opacity(isVisible ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                isVisible = true
            }
        }
    }
    
    private var uniqueCategories: Int {
        let categories = viewModel.timeBlocks.compactMap { $0.category }
        return Set(categories).count
    }
}

// MARK: - Stat Item Component
private struct StatItem: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(color)
                
                Text(value)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }
            
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color.white.opacity(0.6))
        }
    }
}
