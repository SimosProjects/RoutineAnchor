//
//  TimeBlockRowView.swift
//  Routine Anchor - Premium Version
//
import SwiftUI

struct PremiumTimeBlockRowView: View {
    let timeBlock: TimeBlock
    let onTap: (() -> Void)?
    let onComplete: (() -> Void)?
    let onSkip: (() -> Void)?
    
    @State private var isPressed = false
    @State private var progressAnimation: CGFloat = 0
    @State private var glowIntensity: Double = 0.3
    @State private var showActions = false
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isPressed = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isPressed = false
                }
                onTap?()
            }
        }) {
            VStack(spacing: 0) {
                // Main content
                HStack(spacing: 16) {
                    // Status indicator with animation
                    StatusIndicatorView(
                        status: timeBlock.status,
                        isActive: timeBlock.isCurrentlyActive,
                        progress: timeBlock.currentProgress
                    )
                    
                    // Content area
                    VStack(alignment: .leading, spacing: 8) {
                        // Header row
                        HStack(alignment: .top, spacing: 8) {
                            // Icon and title
                            HStack(spacing: 8) {
                                if let icon = timeBlock.icon {
                                    Text(icon)
                                        .font(.system(size: 16))
                                } else {
                                    Image(systemName: "clock")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundStyle(statusColor.opacity(0.8))
                                }
                                
                                Text(timeBlock.title)
                                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                                    .foregroundStyle(.white)
                                    .lineLimit(2)
                            }
                            
                            Spacer()
                            
                            // Time and duration
                            VStack(alignment: .trailing, spacing: 2) {
                                Text(formatTimeRange())
                                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                                    .foregroundStyle(Color.white.opacity(0.7))
                                
                                Text(timeBlock.formattedDuration)
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundStyle(statusColor)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(
                                        Capsule()
                                            .fill(statusColor.opacity(0.15))
                                    )
                            }
                        }
                        
                        // Category and notes
                        if timeBlock.category != nil || timeBlock.notes != nil {
                            HStack {
                                if let category = timeBlock.category {
                                    CategoryBadge(category: category)
                                }
                                
                                if let notes = timeBlock.notes, !notes.isEmpty {
                                    Text(notes)
                                        .font(.system(size: 13, weight: .regular))
                                        .foregroundStyle(Color.white.opacity(0.6))
                                        .lineLimit(1)
                                }
                                
                                Spacer()
                            }
                        }
                        
                        // Progress bar for active blocks
                        if timeBlock.isCurrentlyActive {
                            ProgressIndicatorView(
                                progress: timeBlock.currentProgress,
                                color: statusColor
                            )
                            .animation(.easeInOut(duration: 0.5), value: timeBlock.currentProgress)
                        }
                    }
                }
                .padding(20)
                
                // Action buttons for active blocks
                if timeBlock.status == .inProgress && showActions {
                    ActionButtonsView(
                        onComplete: onComplete,
                        onSkip: onSkip
                    )
                    .transition(.asymmetric(
                        insertion: .move(edge: .bottom).combined(with: .opacity),
                        removal: .move(edge: .bottom).combined(with: .opacity)
                    ))
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .background(
            // Glass morphism background
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(backgroundOpacity),
                                    Color.white.opacity(backgroundOpacity * 0.5)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
        )
        .overlay(
            // Border with status color
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    LinearGradient(
                        colors: [
                            statusColor.opacity(borderOpacity),
                            statusColor.opacity(borderOpacity * 0.3)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: borderWidth
                )
        )
        .shadow(
            color: shadowColor,
            radius: shadowRadius,
            x: 0,
            y: shadowY
        )
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
        .onAppear {
            setupAnimations()
        }
        .onChange(of: timeBlock.status) { _, newStatus in
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                showActions = (newStatus == .inProgress)
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var statusColor: Color {
        switch timeBlock.status {
        case .completed: return Color.premiumGreen
        case .inProgress: return Color.premiumBlue
        case .notStarted: return Color.white.opacity(0.4)
        case .skipped: return Color.premiumError
        }
    }
    
    private var backgroundOpacity: Double {
        switch timeBlock.status {
        case .completed: return 0.12
        case .inProgress: return 0.15
        case .notStarted: return 0.06
        case .skipped: return 0.08
        }
    }
    
    private var borderOpacity: Double {
        switch timeBlock.status {
        case .completed: return 0.6
        case .inProgress: return 0.8
        case .notStarted: return 0.2
        case .skipped: return 0.4
        }
    }
    
    private var borderWidth: CGFloat {
        switch timeBlock.status {
        case .inProgress: return 2
        default: return 1
        }
    }
    
    private var shadowColor: Color {
        switch timeBlock.status {
        case .completed: return Color.premiumGreen.opacity(0.3)
        case .inProgress: return Color.premiumBlue.opacity(0.4)
        case .notStarted: return Color.black.opacity(0.1)
        case .skipped: return Color.premiumError.opacity(0.2)
        }
    }
    
    private var shadowRadius: CGFloat {
        timeBlock.status == .inProgress ? 15 : 8
    }
    
    private var shadowY: CGFloat {
        timeBlock.status == .inProgress ? 8 : 4
    }
    
    // MARK: - Helper Methods
    
    private func formatTimeRange() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return "\(formatter.string(from: timeBlock.startTime)) - \(formatter.string(from: timeBlock.endTime))"
    }
    
    private func setupAnimations() {
        if timeBlock.status == .inProgress {
            showActions = true
            
            // Gentle glow animation for active blocks
            withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                glowIntensity = 0.8
            }
        }
    }
}

// MARK: - Status Indicator View
struct StatusIndicatorView: View {
    let status: BlockStatus
    let isActive: Bool
    let progress: Double
    
    @State private var pulseScale: CGFloat = 1.0
    @State private var rotation: Double = 0
    
    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .fill(statusColor.opacity(0.2))
                .frame(width: 44, height: 44)
            
            // Progress ring for active blocks
            if status == .inProgress {
                Circle()
                    .trim(from: 0, to: CGFloat(progress))
                    .stroke(
                        statusColor,
                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                    )
                    .frame(width: 44, height: 44)
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.8, dampingFraction: 0.9), value: progress)
            }
            
            // Status icon
            Group {
                switch status {
                case .notStarted:
                    Circle()
                        .stroke(statusColor, lineWidth: 2)
                        .frame(width: 16, height: 16)
                        .opacity(0.6)
                        
                case .inProgress:
                    Image(systemName: "play.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(statusColor)
                        .scaleEffect(pulseScale)
                        
                case .completed:
                    Image(systemName: "checkmark")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                        .background(
                            Circle()
                                .fill(statusColor)
                                .frame(width: 20, height: 20)
                        )
                        
                case .skipped:
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(statusColor)
                        .rotationEffect(.degrees(rotation))
                }
            }
        }
        .onAppear {
            if status == .inProgress {
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    pulseScale = 1.2
                }
            } else if status == .skipped {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                    rotation = 180
                }
            }
        }
    }
    
    private var statusColor: Color {
        switch status {
        case .completed: return Color.premiumGreen
        case .inProgress: return Color.premiumBlue
        case .notStarted: return Color.white.opacity(0.5)
        case .skipped: return Color.premiumError
        }
    }
}

// MARK: - Category Badge
struct CategoryBadge: View {
    let category: String
    
    var body: some View {
        Text(category)
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(categoryColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(
                Capsule()
                    .fill(categoryColor.opacity(0.15))
                    .overlay(
                        Capsule()
                            .stroke(categoryColor.opacity(0.3), lineWidth: 0.5)
                    )
            )
    }
    
    private var categoryColor: Color {
        switch category.lowercased() {
        case "work": return Color.premiumBlue
        case "personal": return Color.premiumPurple
        case "health": return Color.premiumGreen
        case "learning": return Color.premiumTeal
        default: return Color.white.opacity(0.6)
        }
    }
}

// MARK: - Progress Indicator
struct ProgressIndicatorView: View {
    let progress: Double
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            HStack {
                Text("Progress")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.6))
                
                Spacer()
                
                Text("\(Int(progress * 100))%")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(color)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Track
                    Capsule()
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 4)
                    
                    // Progress
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [color, color.opacity(0.7)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * CGFloat(progress), height: 4)
                        .animation(.spring(response: 0.8, dampingFraction: 0.9), value: progress)
                }
            }
            .frame(height: 4)
        }
    }
}

// MARK: - Action Buttons
struct ActionButtonsView: View {
    let onComplete: (() -> Void)?
    let onSkip: (() -> Void)?
    
    var body: some View {
        HStack(spacing: 12) {
            // Complete button
            Button(action: {
                HapticManager.shared.premiumSuccess()
                onComplete?()
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Complete")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(
                        colors: [Color.premiumGreen, Color.premiumTeal],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
            }
            
            // Skip button
            Button(action: {
                HapticManager.shared.lightImpact()
                onSkip?()
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "forward")
                        .font(.system(size: 14, weight: .medium))
                    Text("Skip")
                        .font(.system(size: 14, weight: .medium))
                }
                .foregroundStyle(Color.white.opacity(0.7))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    Color.white.opacity(0.1)
                )
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
    }
}
