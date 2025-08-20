//
//  ScheduleBlockRowView.swift
//  Routine Anchor
//
//  Created by Christopher Simonson on 8/10/25.
//
import SwiftUI

struct ScheduleBlockRowView: View {
    let timeBlock: TimeBlock
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    @State private var isPressed = false
    @State private var isVisible = false
    
    var body: some View {
        HStack(spacing: 16) {
            // Time and status indicator
            VStack(spacing: 8) {
                // Status indicator
                ZStack {
                    Circle()
                        .fill(statusColor.opacity(0.2))
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: timeBlock.status.iconName)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(statusColor)
                }
                
                // Time range
                VStack(spacing: 2) {
                    Text(timeBlock.shortFormattedTimeRange)
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundStyle(Color.white.opacity(0.8))
                    
                    Text(timeBlock.formattedDuration)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.5))
                }
            }
            
            // Main content
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    if let icon = timeBlock.icon {
                        Text(icon)
                            .font(.system(size: 18))
                    }
                    
                    Text(timeBlock.title)
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                }
                
                if let notes = timeBlock.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundStyle(Color.white.opacity(0.6))
                        .lineLimit(2)
                }
                
                if let category = timeBlock.category {
                    HStack(spacing: 4) {
                        Image(systemName: "folder")
                            .font(.system(size: 10, weight: .medium))
                        
                        Text(category)
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundStyle(Color.white.opacity(0.5))
                }
            }
            
            Spacer()
            
            // Action buttons
            HStack(spacing: 8) {
                Button(action: onEdit) {
                    Image(systemName: "pencil")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Color.anchorBlue)
                        .frame(width: 36, height: 36)
                        .background(Color.anchorBlue.opacity(0.15))
                        .cornerRadius(10)
                }
                
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Color.anchorError)
                        .frame(width: 36, height: 36)
                        .background(Color.anchorError.opacity(0.15))
                        .cornerRadius(10)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.05),
                                    Color.white.opacity(0.02)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    LinearGradient(
                        colors: [
                            statusColor.opacity(0.3),
                            statusColor.opacity(0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        .scaleEffect(isPressed ? 0.98 : 1)
        .opacity(isVisible ? 1 : 0)
        .offset(x: isVisible ? 0 : 50)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.1)) {
                isVisible = true
            }
        }
    }
    
    private var statusColor: Color {
        switch timeBlock.status {
        case .notStarted: return Color.white.opacity(0.6)
        case .inProgress: return Color.anchorBlue
        case .completed: return Color.anchorGreen
        case .skipped: return Color.anchorWarning
        }
    }
}
