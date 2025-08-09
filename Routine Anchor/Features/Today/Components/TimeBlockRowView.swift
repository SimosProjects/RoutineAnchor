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
    
    var body: some View {
        HStack(spacing: 12) {
            // Status indicator
            Circle()
                .fill(timeBlock.status.color.opacity(0.2))
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: timeBlock.status.iconName)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(timeBlock.status.color)
                )
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    if let icon = timeBlock.icon {
                        Text(icon)
                            .font(.system(size: 18))
                    }
                    
                    Text(timeBlock.title)
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                    
                    Spacer()
                    
                    // Time
                    Text("\(timeBlock.startTime, style: .time)")
                        .font(.system(size: 14, weight: .medium, design: .monospaced))
                        .foregroundStyle(Color.white.opacity(0.7))
                }
                
                if let notes = timeBlock.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.system(size: 14))
                        .foregroundStyle(Color.white.opacity(0.6))
                        .lineLimit(1)
                }
                
                if let category = timeBlock.category {
                    Text(category)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(categoryColor(for: category))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(categoryColor(for: category).opacity(0.15))
                        .cornerRadius(4)
                }
            }
            
            // Action buttons - always visible for incomplete blocks
            if timeBlock.status == .notStarted || timeBlock.status == .inProgress {
                HStack(spacing: 8) {
                    Button(action: {
                        HapticManager.shared.success()
                        onComplete?()
                    }) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 28, weight: .medium))
                            .foregroundStyle(Color.premiumGreen)
                    }
                    
                    Button(action: {
                        HapticManager.shared.lightImpact()
                        onSkip?()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28, weight: .medium))
                            .foregroundStyle(Color.premiumWarning.opacity(0.8))
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    timeBlock.isCurrentlyActive
                    ? Color.premiumBlue.opacity(0.1)
                    : Color.white.opacity(0.05)
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    isHighlighted ? Color.premiumBlue : borderColor,
                    lineWidth: isHighlighted ? 2 : 1
                )
        )
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .contentShape(Rectangle())
        .onTapGesture {
            if let onTap = onTap {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isPressed = true
                }
                
                HapticManager.shared.lightImpact()
                onTap()
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        isPressed = false
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private var borderColor: Color {
        if timeBlock.isCurrentlyActive {
            return Color.premiumBlue.opacity(0.5)
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
    
    private func categoryColor(for category: String) -> Color {
        switch category.lowercased() {
        case "work": return .premiumBlue
        case "personal": return .premiumPurple
        case "health": return .premiumGreen
        case "learning": return .premiumTeal
        default: return .premiumTextSecondary
        }
    }
}

// Keep these helper views if they're used elsewhere
struct StatusIndicatorView: View {
    let status: BlockStatus
    let isActive: Bool
    let progress: Double
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.2), lineWidth: 2)
                .frame(width: 40, height: 40)
            
            if status == .inProgress && isActive {
                Circle()
                    .trim(from: 0, to: CGFloat(progress))
                    .stroke(Color.premiumBlue, lineWidth: 2)
                    .frame(width: 40, height: 40)
                    .rotationEffect(.degrees(-90))
            }
            
            Image(systemName: status.iconName)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(status.color)
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
