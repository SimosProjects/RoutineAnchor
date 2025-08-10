//
//  TaskBreakdownRow.swift
//  Routine Anchor
//
//  Task breakdown row component for Daily Summary
//
import SwiftUI

struct TaskBreakdownRow: View {
    let timeBlock: TimeBlock
    
    var body: some View {
        HStack(spacing: 12) {
            // Status indicator
            timeBlock.status.statusIndicator
                .frame(width: 24, height: 24)
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    if let icon = timeBlock.icon {
                        Text(icon)
                            .font(.system(size: 14))
                    }
                    
                    Text(timeBlock.title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                }
                
                Text(timeBlock.shortFormattedTimeRange)
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.6))
            }
            
            Spacer()
            
            // Duration and status
            VStack(alignment: .trailing, spacing: 2) {
                Text(timeBlock.formattedDuration)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.6))
                
                Text(timeBlock.status.shortDisplayName)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(timeBlock.status.color)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(timeBlock.status.color.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Preview
#Preview("Task Breakdown Row") {
    ZStack {
        AnimatedGradientBackground()
            .ignoresSafeArea()
        
        VStack(spacing: 8) {
            // Sample completed task
            TaskBreakdownRow(
                timeBlock: {
                    let today = Date()
                    let startTime = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: today)!
                    let endTime = Calendar.current.date(byAdding: .hour, value: 1, to: startTime)!
                    
                    let block = TimeBlock(
                        title: "Morning Routine",
                        startTime: startTime,
                        endTime: endTime,
                        icon: "☕",
                        category: "Personal"
                    )
                    block.status = .completed
                    return block
                }()
            )
            
            // Sample in progress task
            TaskBreakdownRow(
                timeBlock: {
                    let today = Date()
                    let startTime = Calendar.current.date(bySettingHour: 10, minute: 0, second: 0, of: today)!
                    let endTime = Calendar.current.date(byAdding: .hour, value: 3, to: startTime)!
                    
                    let block = TimeBlock(
                        title: "Project Work",
                        startTime: startTime,
                        endTime: endTime,
                        icon: "💼",
                        category: "Work"
                    )
                    block.status = .inProgress
                    return block
                }()
            )

            // Sample skipped task
            TaskBreakdownRow(
                timeBlock: {
                    let today = Date()
                    let startTime = Calendar.current.date(bySettingHour: 18, minute: 0, second: 0, of: today)!
                    let endTime = Calendar.current.date(byAdding: .hour, value: 1, to: startTime)!
                    
                    let block = TimeBlock(
                        title: "Gym Session",
                        startTime: startTime,
                        endTime: endTime,
                        icon: "🏋️",
                        category: "Health"
                    )
                    block.status = .skipped
                    return block
                }()
            )

        }
        .padding()
    }
}
