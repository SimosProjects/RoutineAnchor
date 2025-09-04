//
//  StatusGroupSection.swift
//  Routine Anchor
//
//  Created by Christopher Simonson on 8/9/25.
//
import SwiftUI

struct StatusGroupSection: View {
    let status: BlockStatus
    let blocks: [TimeBlock]
    let currentBlock: TimeBlock?
    let isExpanded: Bool
    let highlightedBlockId: UUID?
    let onToggle: () -> Void
    let onBlockTap: (TimeBlock) -> Void
    let onComplete: (TimeBlock) -> Void
    let onSkip: (TimeBlock) -> Void
    
    @Environment(\.themeManager) private var themeManager
    @State private var sectionAnimation = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Section header
            Button(action: onToggle) {
                HStack {
                    // Status icon and title
                    HStack(spacing: 12) {
                        Image(systemName: status.iconName)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(statusColor(for: status, themeManager: themeManager))
                            .frame(width: 24, height: 24)
                            .background(statusColor(for: status, themeManager: themeManager).opacity(0.15))
                            .cornerRadius(6)
                        
                        Text(status.displayName)
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundStyle(themeManager?.currentTheme.primaryTextColor ?? Theme.defaultTheme.primaryTextColor)
                        
                        Text("\(blocks.count) \(blocks.count == 1 ? "block" : "blocks")")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle((themeManager?.currentTheme.secondaryTextColor ?? Theme.defaultTheme.secondaryTextColor).opacity(0.85))
                    }
                    
                    Spacer()
                    
                    // Expand icon
                    Image(systemName: "chevron.down")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle((themeManager?.currentTheme.secondaryTextColor ?? Theme.defaultTheme.secondaryTextColor).opacity(0.85))
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
                .padding(16)
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
            
            // Expanded content
            if isExpanded {
                VStack(spacing: 8) {
                    ForEach(blocks) { block in
                        CompactTimeBlockRow(
                            timeBlock: block,
                            isActive: block.id == currentBlock?.id,
                            isHighlighted: highlightedBlockId == block.id,
                            onTap: { onBlockTap(block) },
                            onComplete: { onComplete(block) },
                            onSkip: { onSkip(block) }
                        )
                        .id(block.id)
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .move(edge: .top)),
                            removal: .opacity.combined(with: .move(edge: .top))
                        ))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [
                                    (themeManager?.currentTheme.colorScheme.uiElementPrimary.color ?? Theme.defaultTheme.colorScheme.uiElementPrimary.color).opacity(0.8),
                                    (themeManager?.currentTheme.colorScheme.uiElementSecondary.color ?? Theme.defaultTheme.colorScheme.uiElementSecondary.color).opacity(0.04)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    LinearGradient(
                        colors: [
                            statusColor(for: status, themeManager: themeManager).opacity(0.3),
                            statusColor(for: status, themeManager: themeManager).opacity(0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: statusColor(for: status, themeManager: themeManager).opacity(0.2), radius: 8, x: 0, y: 4)
        .scaleEffect(sectionAnimation ? 1 : 0.95)
        .opacity(sectionAnimation ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
                sectionAnimation = true
            }
        }
    }
}
