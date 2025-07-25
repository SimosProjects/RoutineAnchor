//
//  TodayTimeBlocksList.swift
//  Routine Anchor
//
//  Time blocks list section for Today view
//
import SwiftUI

struct TodayTimeBlocksList: View {
    let viewModel: TodayViewModel
    @Binding var selectedTimeBlock: TimeBlock?
    @Binding var showingActionSheet: Bool
    @Binding var highlightedBlockId: UUID?
    let scrollProxy: ScrollViewProxy?
    
    // MARK: - State
    @State private var expandedSections: Set<BlockStatus> = []
    @State private var listAnimation = false
    
    var body: some View {
        VStack(spacing: 16) {
            // Section header
            sectionHeader
            
            // Time blocks content
            if viewModel.hasScheduledBlocks {
                if useGroupedView {
                    groupedTimeBlocks
                } else {
                    flatTimeBlocks
                }
            } else {
                emptyMessage
            }
        }
    }
    
    // MARK: - Section Header
    private var sectionHeader: some View {
        HStack {
            Text("Today's Schedule")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            
            Spacer()
            
            // View toggle
            Menu {
                Button {
                    HapticManager.shared.lightImpact()
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        UserDefaults.standard.set(false, forKey: "useGroupedTimeBlocks")
                    }
                } label: {
                    Label("List View", systemImage: "list.bullet")
                }
                
                Button {
                    HapticManager.shared.lightImpact()
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        UserDefaults.standard.set(true, forKey: "useGroupedTimeBlocks")
                    }
                } label: {
                    Label("Grouped View", systemImage: "square.grid.2x2")
                }
            } label: {
                Image(systemName: useGroupedView ? "square.grid.2x2" : "list.bullet")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Color.premiumBlue)
                    .frame(width: 32, height: 32)
                    .background(Color.premiumBlue.opacity(0.15))
                    .cornerRadius(8)
            }
            
            if viewModel.isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(0.8)
            }
        }
        .padding(.horizontal, 24)
    }
    
    // MARK: - Flat Time Blocks View
    private var flatTimeBlocks: some View {
        LazyVStack(spacing: 12) {
            ForEach(viewModel.sortedTimeBlocks) { timeBlock in
                PremiumTimeBlockRowView(
                    timeBlock: timeBlock,
                    isHighlighted: highlightedBlockId == timeBlock.id,
                    onTap: {
                        handleTimeBlockTap(timeBlock)
                    },
                    onComplete: {
                        viewModel.markBlockCompleted(timeBlock)
                    },
                    onSkip: {
                        viewModel.markBlockSkipped(timeBlock)
                    }
                )
                .id(timeBlock.id) // Important for ScrollViewReader
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
            }
        }
        .padding(.horizontal, 24)
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: viewModel.sortedTimeBlocks)
    }
    
    // MARK: - Grouped Time Blocks View
    private var groupedTimeBlocks: some View {
        LazyVStack(spacing: 16) {
            ForEach(BlockStatus.allCases, id: \.self) { status in
                let blocks = blocksForStatus(status)
                if !blocks.isEmpty {
                    StatusGroupSection(
                        status: status,
                        blocks: blocks,
                        currentBlock: viewModel.getCurrentBlock(),
                        isExpanded: expandedSections.contains(status),
                        highlightedBlockId: highlightedBlockId,
                        onToggle: {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                if expandedSections.contains(status) {
                                    expandedSections.remove(status)
                                } else {
                                    expandedSections.insert(status)
                                }
                            }
                        },
                        onBlockTap: handleTimeBlockTap,
                        onComplete: viewModel.markBlockCompleted,
                        onSkip: viewModel.markBlockSkipped
                    )
                    .id(status)
                }
            }
        }
        .padding(.horizontal, 24)
        .onAppear {
            // Auto-expand active section
            if viewModel.getCurrentBlock() != nil {
                expandedSections.insert(.inProgress)
            }
        }
    }
    
    // MARK: - Empty Message
    private var emptyMessage: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(Color.white.opacity(0.3))
            
            Text("No blocks scheduled for today")
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(Color.white.opacity(0.6))
            
            Button(action: {
                NotificationCenter.default.post(name: .navigateToSchedule, object: nil)
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle")
                        .font(.system(size: 16, weight: .medium))
                    
                    Text("Add Time Blocks")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(
                        colors: [Color.premiumBlue, Color.premiumPurple],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
                .shadow(color: Color.premiumBlue.opacity(0.3), radius: 8, x: 0, y: 4)
            }
        }
        .padding(.vertical, 40)
    }
    
    // MARK: - Helper Methods
    
    private var useGroupedView: Bool {
        UserDefaults.standard.bool(forKey: "useGroupedTimeBlocks")
    }
    
    private func blocksForStatus(_ status: BlockStatus) -> [TimeBlock] {
        viewModel.timeBlocks.filter { $0.status == status }
            .sorted { $0.startTime < $1.startTime }
    }
    
    private func handleTimeBlockTap(_ timeBlock: TimeBlock) {
        HapticManager.shared.lightImpact()
        selectedTimeBlock = timeBlock
        showingActionSheet = true
    }
}

// MARK: - Status Group Section

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
    
    @State private var sectionAnimation = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            Button(action: onToggle) {
                HStack(spacing: 16) {
                    // Status icon
                    Image(systemName: status.iconName)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(status.color)
                        .frame(width: 24, height: 24)
                    
                    // Title and count
                    VStack(alignment: .leading, spacing: 2) {
                        Text(status.displayName)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(.white)
                        
                        Text("\(blocks.count) \(blocks.count == 1 ? "block" : "blocks")")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Color.white.opacity(0.6))
                    }
                    
                    Spacer()
                    
                    // Expand icon
                    Image(systemName: "chevron.down")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.6))
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
                        .id(block.id) // Important for ScrollViewReader
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
                                    Color.white.opacity(0.08),
                                    Color.white.opacity(0.04)
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
                            status.color.opacity(0.3),
                            status.color.opacity(0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: status.color.opacity(0.2), radius: 8, x: 0, y: 4)
        .scaleEffect(sectionAnimation ? 1 : 0.95)
        .opacity(sectionAnimation ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
                sectionAnimation = true
            }
        }
    }
}

// MARK: - Compact Time Block Row

struct CompactTimeBlockRow: View {
    let timeBlock: TimeBlock
    let isActive: Bool
    let isHighlighted: Bool
    let onTap: () -> Void
    let onComplete: () -> Void
    let onSkip: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Time
                Text(timeBlock.startTime, style: .time)
                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                    .foregroundStyle(isActive ? Color.premiumBlue : Color.white.opacity(0.6))
                    .frame(width: 60, alignment: .leading)
                
                // Title and category
                VStack(alignment: .leading, spacing: 4) {
                    Text(timeBlock.title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    
                    if let category = timeBlock.category {
                        Text(category)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Color.white.opacity(0.6))
                    }
                }
                
                Spacer()
                
                // Quick actions
                if timeBlock.status == .notStarted || timeBlock.status == .inProgress {
                    HStack(spacing: 4) {
                        Button(action: {
                            HapticManager.shared.success()
                            onComplete()
                        }) {
                            Image(systemName: "checkmark")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(Color.premiumGreen)
                                .frame(width: 32, height: 32)
                                .background(Color.premiumGreen.opacity(0.15))
                                .cornerRadius(8)
                        }
                        
                        Button(action: {
                            HapticManager.shared.lightImpact()
                            onSkip()
                        }) {
                            Image(systemName: "forward")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(Color.premiumWarning)
                                .frame(width: 32, height: 32)
                                .background(Color.premiumWarning.opacity(0.15))
                                .cornerRadius(8)
                        }
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isActive ? Color.premiumBlue.opacity(0.1) : Color.white.opacity(0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isHighlighted ? Color.premiumBlue : (isActive ? Color.premiumBlue.opacity(0.3) : Color.clear),
                        lineWidth: isHighlighted ? 2 : 1
                    )
            )
            .scaleEffect(isHighlighted ? 1.02 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHighlighted)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
