//
//  TimeBlockRowView.swift
//  Routine Anchor
//
import SwiftUI

struct TimeBlockRowView: View {
    let timeBlock: TimeBlock
    let isHighlighted: Bool
    let onTap: (() -> Void)?
    let onComplete: (() -> Void)?
    let onSkip: (() -> Void)?
    
    @State private var isPressed = false
    @State private var progressAnimation: CGFloat = 0
    @State private var glowIntensity: Double = 0.3
    @State private var showActions = false
    
    var body: some View {
        Button(action: handleTap) {
            mainContent
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                showActions.toggle()
                HapticManager.shared.lightImpact()
            }
        }
        .onAppear {
            if timeBlock.isCurrentlyActive {
                withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                    glowIntensity = 0.6
                }
            }
        }
    }
    
    // MARK: - Main Content View
    private var mainContent: some View {
        VStack(spacing: 0) {
            // Main content row
            mainRow
            
            // Quick actions (for notStarted/in-progress blocks)
            if showActions && (timeBlock.status == .notStarted || timeBlock.status == .inProgress) {
                quickActionsView
                    .transition(.asymmetric(
                        insertion: .move(edge: .bottom).combined(with: .opacity),
                        removal: .move(edge: .bottom).combined(with: .opacity)
                    ))
            }
        }
        .background(backgroundView)
        .overlay(overlayBorder)
        .shadow(
            color: shadowColor,
            radius: isPressed ? 4 : 8,
            x: 0,
            y: isPressed ? 2 : 4
        )
        .scaleEffect(isHighlighted ? 1.02 : (isPressed ? 0.98 : 1))
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHighlighted)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
    }
    
    // MARK: - Main Row Content
    private var mainRow: some View {
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
                headerRow
                
                // Category and notes
                detailsRow
                
                // Progress bar for active blocks
                if timeBlock.status == .inProgress {
                    ProgressBar(
                        progress: timeBlock.currentProgress,
                        color: .premiumBlue,
                        animated: true
                    )
                    .frame(height: 4)
                    .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: progressAnimation)
                    .onAppear {
                        progressAnimation = 1
                    }
                }
            }
        }
        .padding(20)
    }
    
    // MARK: - Header Row
    private var headerRow: some View {
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
                    .multilineTextAlignment(.leading)
            }
            
            Spacer()
            
            // Time display
            TimeDisplayView(
                startTime: timeBlock.startTime,
                endTime: timeBlock.endTime,
                status: timeBlock.status
            )
        }
    }
    
    // MARK: - Details Row
    private var detailsRow: some View {
        HStack(spacing: 16) {
            if let category = timeBlock.category {
                CategoryBadge(
                    category: category,
                    color: categoryColor(for: category)
                )
            }
            
            if let notes = timeBlock.notes, !notes.isEmpty {
                Text(notes)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.6))
                    .lineLimit(1)
            }
        }
    }
    
    // MARK: - Background View
    private var backgroundView: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(.ultraThinMaterial)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: backgroundGradient,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
    }
    
    // MARK: - Overlay Border
    private var overlayBorder: some View {
        RoundedRectangle(cornerRadius: 16)
            .stroke(
                isHighlighted ? Color.premiumBlue : borderColor,
                lineWidth: isHighlighted ? 2 : 1
            )
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHighlighted)
    }
    
    // MARK: - Actions
    private func handleTap() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            isPressed = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isPressed = false
            }
            onTap?()
        }
    }
    
    // MARK: - Computed Properties
    
    private var statusColor: Color {
        switch timeBlock.status {
        case .notStarted: return .white
        case .inProgress: return .premiumBlue
        case .completed: return .premiumGreen
        case .skipped: return .premiumWarning
        }
    }
    
    private var backgroundGradient: [Color] {
        if timeBlock.isCurrentlyActive {
            return [
                Color.premiumBlue.opacity(0.15),
                Color.premiumBlue.opacity(0.08)
            ]
        } else {
            return [
                Color.white.opacity(0.08),
                Color.white.opacity(0.04)
            ]
        }
    }
    
    private var borderColor: Color {
        if timeBlock.isCurrentlyActive {
            return Color.premiumBlue.opacity(glowIntensity)
        } else {
            switch timeBlock.status {
            case .completed:
                return Color.premiumGreen.opacity(0.3)
            case .skipped:
                return Color.premiumWarning.opacity(0.3)
            default:
                return Color.white.opacity(0.2)
            }
        }
    }
    
    private var shadowColor: Color {
        if timeBlock.isCurrentlyActive {
            return Color.premiumBlue.opacity(0.3)
        } else {
            switch timeBlock.status {
            case .completed:
                return Color.premiumGreen.opacity(0.2)
            case .skipped:
                return Color.premiumWarning.opacity(0.2)
            default:
                return Color.black.opacity(0.1)
            }
        }
    }
    
    private func categoryColor(for category: String) -> Color {
        switch category.lowercased() {
        case "work": return .premiumBlue
        case "personal": return .premiumPurple
        case "health": return .premiumGreen
        case "learning": return .premiumTeal
        default: return .premiumTextSecondary
        }
    }
    
    // MARK: - Quick Actions View
    
    private var quickActionsView: some View {
        HStack(spacing: 12) {
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    showActions = false
                }
                HapticManager.shared.success()
                onComplete?()
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .medium))
                    Text("Complete")
                        .font(.system(size: 14, weight: .medium))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(
                        colors: [Color.premiumGreen, Color.premiumGreen.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
            }
            
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    showActions = false
                }
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

// MARK: - Supporting Views

struct StatusIndicatorView: View {
    let status: BlockStatus
    let isActive: Bool
    let progress: Double
    
    @State private var pulseAnimation = false
    
    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .fill(backgroundColor)
                .frame(width: 44, height: 44)
            
            // Progress ring for active blocks
            if isActive {
                Circle()
                    .trim(from: 0, to: CGFloat(progress))
                    .stroke(
                        Color.premiumBlue,
                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .frame(width: 40, height: 40)
                    .animation(.linear(duration: 0.5), value: progress)
            }
            
            // Status icon
            Image(systemName: iconName)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(iconColor)
                .scaleEffect(pulseAnimation ? 1.1 : 1.0)
        }
        .onAppear {
            if isActive {
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    pulseAnimation = true
                }
            }
        }
    }
    
    private var backgroundColor: Color {
        if isActive {
            return Color.premiumBlue.opacity(0.15)
        }
        
        switch status {
        case .notStarted: return Color.white.opacity(0.1)
        case .inProgress: return Color.premiumBlue.opacity(0.15)
        case .completed: return Color.premiumGreen.opacity(0.15)
        case .skipped: return Color.premiumWarning.opacity(0.15)
        }
    }
    
    private var iconName: String {
        switch status {
        case .notStarted: return "clock"
        case .inProgress: return "play.fill"
        case .completed: return "checkmark"
        case .skipped: return "forward.fill"
        }
    }
    
    private var iconColor: Color {
        switch status {
        case .notStarted: return .white.opacity(0.6)
        case .inProgress: return .premiumBlue
        case .completed: return .premiumGreen
        case .skipped: return .premiumWarning
        }
    }
}

struct TimeDisplayView: View {
    let startTime: Date
    let endTime: Date
    let status: BlockStatus
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 4) {
            Text("\(startTime, style: .time) - \(endTime, style: .time)")
                .font(.system(size: 14, weight: .medium, design: .monospaced))
                .foregroundStyle(Color.white.opacity(0.8))
            
            Text(durationText)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color.white.opacity(0.6))
        }
    }
    
    private var durationText: String {
        let duration = endTime.timeIntervalSince(startTime)
        let hours = Int(duration) / 3600
        let minutes = Int(duration) % 3600 / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

struct CategoryBadge: View {
    let category: String
    let color: Color
    
    var body: some View {
        Text(category)
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(color.opacity(0.15))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(color.opacity(0.3), lineWidth: 1)
            )
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        AnimatedGradientBackground()
            .ignoresSafeArea()
        
        VStack(spacing: 16) {
            TimeBlockRowView(
                timeBlock: TimeBlock(
                    title: "Morning Workout",
                    startTime: Date(),
                    endTime: Date().addingTimeInterval(3600),
                    notes: "Focus on cardio today",
                    icon: "💪",
                    category: "Health"
                ),
                isHighlighted: false,
                onTap: {},
                onComplete: {},
                onSkip: {}
            )
            
            TimeBlockRowView(
                timeBlock: {
                    let block = TimeBlock(
                        title: "Team Meeting",
                        startTime: Date(),
                        endTime: Date().addingTimeInterval(1800),
                        notes: nil,
                        icon: "👥",
                        category: "Work"
                    )
                    block.status = .inProgress
                    return block
                }(),
                isHighlighted: true,
                onTap: {},
                onComplete: {},
                onSkip: {}
            )
        }
        .padding()
    }
}
