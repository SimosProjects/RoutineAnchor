//
//  TimeBlockRowView.swift
//  Routine Anchor
//
//  Created by Christopher Simonson on 8/10/25.
//
import SwiftUI

struct TimeBlockRowView: View {
    let timeBlock: TimeBlock
    let showActions: Bool
    let onStart: (() -> Void)?
    let onComplete: (() -> Void)?
    let onSkip: (() -> Void)?
    let onEdit: (() -> Void)?
    let onDelete: (() -> Void)?
    
    @State private var isPressed = false
    @State private var isHovered = false
    @State private var shimmerPhase: CGFloat = 0
    
    init(
        timeBlock: TimeBlock,
        showActions: Bool = true,
        onStart: (() -> Void)? = nil,
        onComplete: (() -> Void)? = nil,
        onSkip: (() -> Void)? = nil,
        onEdit: (() -> Void)? = nil,
        onDelete: (() -> Void)? = nil
    ) {
        self.timeBlock = timeBlock
        self.showActions = showActions
        self.onStart = onStart
        self.onComplete = onComplete
        self.onSkip = onSkip
        self.onEdit = onEdit
        self.onDelete = onDelete
    }
    
    var body: some View {
        HStack(spacing: 0) {
            // Left accent bar with animated gradient
            accentBar
            
            HStack(spacing: 16) {
                // Time badge with glass effect
                timeBadge
                
                // Main content with enhanced typography
                mainContent
                
                Spacer(minLength: 8)
                
                // Action buttons with premium feel
                if showActions {
                    actionButtons
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        .background(backgroundLayer)
        .overlay(overlayEffects)
        .shadow(color: shadowColor, radius: 12, x: 0, y: 6)
        .scaleEffect(isPressed ? 0.97 : 1.0)
        .rotation3DEffect(
            .degrees(isHovered ? 1 : 0),
            axis: (x: -1, y: 0, z: 0)
        )
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
        .animation(.easeInOut(duration: 0.2), value: isHovered)
        .onAppear {
            withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
                shimmerPhase = 1
            }
        }
    }
    
    // MARK: - Accent Bar
    private var accentBar: some View {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
            .fill(
                LinearGradient(
                    colors: accentColors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: 5)
            .overlay(
                // Animated shimmer effect
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0),
                                Color.white.opacity(0.3),
                                Color.white.opacity(0)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .offset(y: shimmerPhase * 100 - 50)
                    .opacity(timeBlock.status == .inProgress ? 1 : 0)
            )
    }
    
    // MARK: - Time Badge
    private var timeBadge: some View {
        VStack(spacing: 6) {
            // Enhanced status indicator with pulse animation
            ZStack {
                // Outer ring
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [statusColor, statusColor.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
                    .frame(width: 42, height: 42)
                
                // Inner filled circle with glass effect
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                statusColor.opacity(0.3),
                                statusColor.opacity(0.1)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 36, height: 36)
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
                    )
                
                // Icon with shadow
                Image(systemName: timeBlock.status.iconName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(statusColor)
                    .shadow(color: statusColor.opacity(0.3), radius: 2, x: 0, y: 1)
                
                // Pulse animation for in-progress
                if timeBlock.status == .inProgress {
                    Circle()
                        .stroke(statusColor, lineWidth: 2)
                        .frame(width: 36, height: 36)
                        .scaleEffect(isPressed ? 1.2 : 1.4)
                        .opacity(isPressed ? 0.8 : 0)
                        .animation(
                            .easeOut(duration: 1.5).repeatForever(autoreverses: false),
                            value: isPressed
                        )
                }
            }
            
            // Time display with better typography
            VStack(spacing: 2) {
                Text(timeBlock.startTime.formatted(date: .omitted, time: .shortened))
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.white, Color.white.opacity(0.9)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                
                Text(timeBlock.formattedDuration)
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.6))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.1))
                    )
            }
        }
    }
    
    // MARK: - Main Content
    private var mainContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Title row with icon
            HStack(spacing: 10) {
                if let icon = timeBlock.icon {
                    Text(icon)
                        .font(.system(size: 24))
                        .scaleEffect(isHovered ? 1.1 : 1.0)
                        .animation(.spring(response: 0.3), value: isHovered)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(timeBlock.title)
                        .font(.system(size: 19, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.white, Color.white.opacity(0.95)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .lineLimit(1)
                    
                    // Category pill if exists
                    if let category = timeBlock.category {
                        HStack(spacing: 4) {
                            Image(systemName: "folder.fill")
                                .font(.system(size: 9, weight: .semibold))
                            
                            Text(category.uppercased())
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .tracking(0.5)
                        }
                        .foregroundStyle(categoryColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(
                            Capsule()
                                .fill(categoryColor.opacity(0.2))
                                .overlay(
                                    Capsule()
                                        .stroke(categoryColor.opacity(0.3), lineWidth: 0.5)
                                )
                        )
                    }
                }
            }
            
            // Notes with glass card effect
            if let notes = timeBlock.notes, !notes.isEmpty {
                Text(notes)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.white.opacity(0.75))
                    .lineLimit(2)
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color.white.opacity(0.05))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .stroke(
                                        LinearGradient(
                                            colors: [
                                                Color.white.opacity(0.1),
                                                Color.white.opacity(0.05)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 0.5
                                    )
                            )
                    )
            }
            
            // Progress indicator for in-progress items
            if timeBlock.status == .inProgress {
                progressBar
            }
        }
    }
    
    // MARK: - Progress Bar
    private var progressBar: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background track
                Capsule()
                    .fill(Color.white.opacity(0.1))
                    .frame(height: 4)
                
                // Progress fill
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [Color.premiumBlue, Color.premiumBlue.opacity(0.6)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geometry.size.width * progressPercentage, height: 4)
                    .animation(.linear(duration: 1), value: progressPercentage)
            }
        }
        .frame(height: 4)
    }
    
    private var progressPercentage: CGFloat {
        guard timeBlock.status == .inProgress else { return 0 }
        let now = Date()
        let total = timeBlock.endTime.timeIntervalSince(timeBlock.startTime)
        let elapsed = now.timeIntervalSince(timeBlock.startTime)
        return min(max(elapsed / total, 0), 1)
    }
    
    // MARK: - Action Buttons
    @ViewBuilder
    private var actionButtons: some View {
        HStack(spacing: 10) {
            if onStart != nil || onComplete != nil || onSkip != nil {
                todayViewActions
            } else if onEdit != nil || onDelete != nil {
                scheduleViewActions
            }
        }
    }
    
    @ViewBuilder
    private var todayViewActions: some View {
        switch timeBlock.status {
        case .notStarted:
            if let onStart = onStart {
                TimeBlockActionButton(
                    icon: "play.fill",
                    color: .premiumGreen,
                    action: onStart,
                    isLarge: true
                )
            }
        case .inProgress:
            HStack(spacing: 8) {
                if let onComplete = onComplete {
                    TimeBlockActionButton(
                        icon: "checkmark.circle.fill",
                        color: .premiumGreen,
                        action: onComplete,
                        isLarge: true
                    )
                }
                if let onSkip = onSkip {
                    TimeBlockActionButton(
                        icon: "forward.fill",
                        color: .premiumWarning,
                        action: onSkip
                    )
                }
            }
        case .completed, .skipped:
            Image(systemName: timeBlock.status == .completed ? "checkmark.seal.fill" : "forward.circle.fill")
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(
                    LinearGradient(
                        colors: timeBlock.status == .completed
                            ? [Color.premiumGreen, Color.premiumGreen.opacity(0.7)]
                            : [Color.premiumWarning, Color.premiumWarning.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
    }
    
    @ViewBuilder
    private var scheduleViewActions: some View {
        if let onEdit = onEdit {
            TimeBlockActionButton(
                icon: "pencil.circle",
                color: .premiumBlue,
                action: onEdit
            )
        }
        
        if let onDelete = onDelete {
            TimeBlockActionButton(
                icon: "trash.circle",
                color: .premiumError,
                action: onDelete
            )
        }
    }
    
    // MARK: - Background & Effects
    private var backgroundLayer: some View {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        Color(red: 0x1a / 255.0, green: 0x1a / 255.0, blue: 0x2e / 255.0),
                        Color(red: 0x16 / 255.0, green: 0x21 / 255.0, blue: 0x3e / 255.0)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.08),
                                Color.white.opacity(0.02)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            )
    }
    
    private var overlayEffects: some View {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
            .stroke(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.15),
                        Color.white.opacity(0.05)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 1
            )
    }
    
    // MARK: - Helper Properties
    private var statusColor: Color {
        switch timeBlock.status {
        case .notStarted: return Color.white.opacity(0.7)
        case .inProgress: return Color.premiumBlue
        case .completed: return Color.premiumGreen
        case .skipped: return Color.premiumWarning
        }
    }
    
    private var accentColors: [Color] {
        switch timeBlock.status {
        case .notStarted:
            return [
                Color(red: 102/255, green: 126/255, blue: 234/255), // #667eea
                Color(red: 118/255, green: 75/255,  blue: 162/255)  // #764ba2
            ]
        case .inProgress:
            return [Color.premiumBlue, Color.premiumBlue.opacity(0.6)]
        case .completed:
            return [Color.premiumGreen, Color.premiumGreen.opacity(0.6)]
        case .skipped:
            return [Color.premiumWarning, Color.premiumWarning.opacity(0.6)]
        }
    }
    
    private var categoryColor: Color {
        switch timeBlock.category?.lowercased() {
        case "work": return Color.premiumBlue
        case "personal": return Color.premiumPurple
        case "health": return Color.premiumGreen
        case "learning": return Color.premiumTeal
        default: return Color.white.opacity(0.6)
        }
    }
    
    private var shadowColor: Color {
        statusColor.opacity(0.2)
    }
}

// MARK: - Action Button Component
struct TimeBlockActionButton: View {
    let icon: String
    let color: Color
    let action: () -> Void
    var isLarge: Bool = false
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            HapticManager.shared.lightImpact()
            action()
        }) {
            ZStack {
                // Gradient background
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                color.opacity(0.3),
                                color.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                // Glass overlay
                Circle()
                    .fill(Color.white.opacity(0.05))
                    .blur(radius: 1)
                
                // Border
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [color, color.opacity(0.5)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
                
                // Icon
                Image(systemName: icon)
                    .font(.system(size: isLarge ? 20 : 16, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [color, color.opacity(0.8)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: color.opacity(0.3), radius: 2, x: 0, y: 1)
            }
            .frame(width: isLarge ? 44 : 36, height: isLarge ? 44 : 36)
            .scaleEffect(isPressed ? 0.9 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: .infinity, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}
