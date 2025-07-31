//
//  TimeBlocksSummaryCard.swift
//  Routine Anchor
//
//  Time blocks summary card component for Daily Summary
//
import SwiftUI

struct TimeBlocksSummaryCard: View {
    let timeBlocks: [TimeBlock]
    @State private var isExpanded = false
    @State private var isVisible = false
    
    private var blockCounts: (completed: Int, inProgress: Int, skipped: Int, upcoming: Int) {
        var counts = (completed: 0, inProgress: 0, skipped: 0, upcoming: 0)
        
        for block in timeBlocks {
            switch block.status {
            case .completed: counts.completed += 1
            case .inProgress: counts.inProgress += 1
            case .skipped: counts.skipped += 1
            case .notStarted: counts.upcoming += 1
            }
        }
        
        return counts
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Time Blocks")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    
                    Text("\(timeBlocks.count) blocks scheduled")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.7))
                }
                
                Spacer()
                
                // Expand/Collapse button
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        isExpanded.toggle()
                    }
                }) {
                    Image(systemName: isExpanded ? "chevron.up.circle.fill" : "chevron.down.circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(Color.white.opacity(0.3))
                        .background(
                            Circle()
                                .fill(.ultraThinMaterial)
                        )
                }
            }
            
            // Status summary
            HStack(spacing: 12) {
                StatCard(
                    title: "Done",
                    value: "\(blockCounts.completed)",
                    subtitle: "blocks",
                    color: Color.premiumGreen,
                    icon: "checkmark.circle.fill"
                )
                
                if blockCounts.inProgress > 0 {
                    StatCard(
                        title: "Active",
                        value: "\(blockCounts.inProgress)",
                        subtitle: "now",
                        color: Color.premiumBlue,
                        icon: "play.circle.fill"
                    )
                }
                
                if blockCounts.skipped > 0 {
                    StatCard(
                        title: "Skipped",
                        value: "\(blockCounts.skipped)",
                        subtitle: "blocks",
                        color: Color.premiumWarning,
                        icon: "forward.circle.fill"
                    )
                }
            }
            
            // Expanded details
            if isExpanded {
                VStack(spacing: 8) {
                    ForEach(timeBlocks.sorted()) { block in
                        TaskBreakdownRow(timeBlock: block)
                    }
                }
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.8).combined(with: .opacity),
                    removal: .scale(scale: 0.8).combined(with: .opacity)
                ))
            }
        }
        .padding(20)
        .glassMorphism(cornerRadius: 20)
        .scaleEffect(isVisible ? 1 : 0.9)
        .opacity(isVisible ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
                isVisible = true
            }
        }
    }
}

// MARK: - Preview
#Preview("Time Blocks Summary") {
    ZStack {
        AnimatedGradientBackground()
            .ignoresSafeArea()
        
        TimeBlocksSummaryCard(
            timeBlocks: [
                {
                    let block = TimeBlock(
                        title: "Morning Routine",
                        startTime: Date(),
                        endTime: Date().addingTimeInterval(3600)
                    )
                    block.status = .completed
                    return block
                }(),
                {
                    let block = TimeBlock(
                        title: "Work Block",
                        startTime: Date().addingTimeInterval(3600),
                        endTime: Date().addingTimeInterval(7200)
                    )
                    block.status = .inProgress
                    return block
                }()
            ]
        )
        .padding()
    }
}
