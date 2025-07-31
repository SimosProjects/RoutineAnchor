//
//  SummaryProgressCard.swift
//  Routine Anchor
//
//  Progress overview card specifically for Daily Summary
//
import SwiftUI

struct SummaryProgressCard: View {
    let progress: DailyProgress
    let timeBlocks: [TimeBlock]
    
    @State private var animateProgress = false
    @State private var isVisible = false
    
    // Computed properties
    private var progressPercentage: Double {
        return progress.completionPercentage
    }
    
    private var formattedProgressPercentage: String {
        return "\(Int(progressPercentage * 100))%"
    }
    
    private var completionSummary: String {
        return "\(progress.completedBlocks) of \(progress.totalBlocks) blocks"
    }
    
    private var timeSummary: String {
        let hours = progress.completedMinutes / 60
        let minutes = progress.completedMinutes % 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m completed"
        } else {
            return "\(minutes)m completed"
        }
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Progress Overview")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    
                    Text(progress.date.formatted(.dateTime.weekday(.wide).month(.abbreviated).day()))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.7))
                }
                
                Spacer()
                
                // Performance badge
                PerformanceBadge(level: progress.performanceLevel)
            }
            
            // Main progress display
            HStack(spacing: 24) {
                // Circular progress
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.1), lineWidth: 6)
                        .frame(width: 80, height: 80)
                    
                    Circle()
                        .trim(from: 0, to: animateProgress ? CGFloat(progressPercentage) : 0)
                        .stroke(
                            LinearGradient(
                                colors: gradientColors(for: progress.performanceLevel),
                                startPoint: .topTrailing,
                                endPoint: .bottomLeading
                            ),
                            style: StrokeStyle(lineWidth: 6, lineCap: .round)
                        )
                        .frame(width: 80, height: 80)
                        .rotationEffect(.degrees(-90))
                    
                    VStack(spacing: 2) {
                        Text(formattedProgressPercentage)
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        
                        Text("complete")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(Color.white.opacity(0.6))
                    }
                }
                
                // Statistics
                VStack(alignment: .leading, spacing: 12) {
                    StatRow(
                        icon: "checkmark.circle.fill",
                        label: "Completed",
                        value: "\(progress.completedBlocks)",
                        color: .premiumGreen
                    )
                    
                    StatRow(
                        icon: "clock.fill",
                        label: "Time tracked",
                        value: formatDuration(progress.completedMinutes),
                        color: .premiumBlue
                    )
                    
                    if progress.skippedBlocks > 0 {
                        StatRow(
                            icon: "forward.circle.fill",
                            label: "Skipped",
                            value: "\(progress.skippedBlocks)",
                            color: .premiumWarning
                        )
                    }
                }
                
                Spacer()
            }
            
            // Motivational message
            if !progress.motivationalMessage.isEmpty {
                Text(progress.motivationalMessage)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.top, 8)
            }
        }
        .padding(24)
        .glassMorphism(cornerRadius: 20)
        .scaleEffect(isVisible ? 1 : 0.9)
        .opacity(isVisible ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                isVisible = true
            }
            
            withAnimation(.spring(response: 1.2, dampingFraction: 0.8).delay(0.3)) {
                animateProgress = true
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func gradientColors(for level: PerformanceLevel) -> [Color] {
        switch level {
        case .excellent:
            return [Color.premiumGreen, Color.premiumTeal]
        case .good:
            return [Color.premiumBlue, Color.premiumGreen]
        case .fair:
            return [Color.premiumWarning, Color.premiumYellow]
        case .poor:
            return [Color.premiumError, Color.premiumWarning]
        case .none:
            return [Color.white.opacity(0.3), Color.white.opacity(0.2)]
        }
    }
    
    private func formatDuration(_ minutes: Int) -> String {
        let hours = minutes / 60
        let mins = minutes % 60
        
        if hours > 0 {
            return "\(hours)h \(mins)m"
        } else {
            return "\(mins)m"
        }
    }
}

// MARK: - Supporting Views

struct PerformanceBadge: View {
    let level: PerformanceLevel
    
    var body: some View {
        HStack(spacing: 6) {
            Text(level.emoji)
                .font(.system(size: 16))
            
            Text(level.displayName)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(level.color)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(level.color.opacity(0.15))
        )
        .overlay(
            Capsule()
                .stroke(level.color.opacity(0.3), lineWidth: 1)
        )
    }
}

struct StatRow: View {
    let icon: String
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(color)
                .frame(width: 20)
            
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color.white.opacity(0.6))
            
            Spacer()
            
            Text(value)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)
        }
    }
}

// MARK: - Preview
#Preview("Summary Progress Card") {
    ZStack {
        AnimatedGradientBackground()
            .ignoresSafeArea()
        
        SummaryProgressCard(
            progress: {
                let progress = DailyProgress(date: Date())
                progress.totalBlocks = 10
                progress.completedBlocks = 7
                progress.skippedBlocks = 1
                progress.completedMinutes = 240
                progress.totalPlannedMinutes = 300
                return progress
            }(),
            timeBlocks: []
        )
        .padding()
    }
}
