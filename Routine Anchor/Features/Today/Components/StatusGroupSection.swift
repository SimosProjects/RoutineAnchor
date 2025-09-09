//
//  StatusGroupSection.swift
//  Routine Anchor
//
//  Expandable group of time blocks by status (e.g., In Progress, Completed).
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

    private var theme: AppTheme { themeManager?.currentTheme ?? PredefinedThemes.classic }

    var body: some View {
        let statusTint = tint(for: status)

        return VStack(spacing: 0) {
            // Section header
            Button(action: onToggle) {
                HStack {
                    HStack(spacing: 12) {
                        Image(systemName: status.iconName)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(statusTint)
                            .frame(width: 24, height: 24)
                            .background(statusTint.opacity(0.15))
                            .cornerRadius(6)

                        Text(status.displayName)
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundStyle(theme.primaryTextColor)

                        Text("\(blocks.count) \(blocks.count == 1 ? "block" : "blocks")")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(theme.secondaryTextColor.opacity(0.85))
                    }

                    Spacer()

                    Image(systemName: "chevron.down")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(theme.secondaryTextColor.opacity(0.85))
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
                .padding(16)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

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
            ZStack {
                RoundedRectangle(cornerRadius: 16).fill(theme.surfaceCardColor)
                RoundedRectangle(cornerRadius: 16).fill(theme.glassMaterialOverlay)
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(theme.borderColor.opacity(0.8), lineWidth: 1)
        )
        .shadow(color: statusTint.opacity(0.18), radius: 8, x: 0, y: 4)
        .scaleEffect(sectionAnimation ? 1 : 0.95)
        .opacity(sectionAnimation ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
                sectionAnimation = true
            }
        }
    }

    private func tint(for status: BlockStatus) -> Color {
        switch status {
        case .notStarted: return theme.secondaryTextColor
        case .inProgress: return theme.accentPrimaryColor
        case .completed:  return theme.statusSuccessColor
        case .skipped:    return theme.statusWarningColor
        }
    }
}
