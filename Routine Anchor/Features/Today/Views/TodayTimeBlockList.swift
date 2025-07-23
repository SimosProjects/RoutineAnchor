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
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
                .id(timeBlock.id)
            }
        }
        .padding(.horizontal, 24)
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: viewModel.sortedTimeBlocks)
    }
    
    // MARK: - Grouped Time Blocks View
    private var groupedTimeBlocks: some View {
        LazyVStack(spacing: 16) {
            ForEach(BlockStatus.allCases, id: \.self) { status in
                if let blocks = viewModel.timeBlocksByStatus[status], !blocks.isEmpty {
                    GroupedSection(
                        status: status,
                        blocks: blocks,
                        isExpanded: expandedSections.contains(status),
                        currentBlock: viewModel.getCurrentBlock(),
                        onToggle: {
                            toggleSection(status)
                        },
                        onBlockTap: handleTimeBlockTap,
                        onComplete: viewModel.markBlockCompleted,
                        onSkip: viewModel.markBlockSkipped
                    )
                }
            }
        }
        .padding(.horizontal, 24)
        .onAppear {
            // Auto-expand active sections
            if viewModel.getCurrentBlock() != nil {
                expandedSections.insert(.inProgress)
            }
            if viewModel.upcomingBlocksCount > 0 {
                expandedSections.insert(.notStarted)
            }
        }
    }
    
    // MARK: - Empty Message
    private var emptyMessage: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 48, weight: .thin))
                .foregroundStyle(Color.white.opacity(0.3))
            
            Text("No time blocks scheduled")
                .font(.system(size: 18, weight: .medium, design: .rounded))
                .foregroundStyle(Color.white.opacity(0.6))
            
            Text("Add time blocks to structure your day")
                .font(.system(size: 14, weight: .regular))
                .foregroundStyle(Color.white.opacity(0.4))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
        .padding(.horizontal, 24)
    }
    
    // MARK: - Helper Methods
    
    private func handleTimeBlockTap(_ timeBlock: TimeBlock) {
        HapticManager.shared.premiumSelection()
        
        selectedTimeBlock = timeBlock
        
        switch timeBlock.status {
        case .inProgress:
            showingActionSheet = true
        case .notStarted:
            if timeBlock.isCurrentlyActive {
                viewModel.startTimeBlock(timeBlock)
            }
        case .completed, .skipped:
            // Could show details or allow undo
            break
        }
    }
    
    private func toggleSection(_ status: BlockStatus) {
        HapticManager.shared.lightImpact()
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            if expandedSections.contains(status) {
                expandedSections.remove(status)
            } else {
                expandedSections.insert(status)
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var useGroupedView: Bool {
        UserDefaults.standard.bool(forKey: "useGroupedTimeBlocks")
    }
}

// MARK: - Grouped Section Component
struct GroupedSection: View {
    let status: BlockStatus
    let blocks: [TimeBlock]
    let isExpanded: Bool
    let currentBlock: TimeBlock?
    let onToggle: () -> Void
    let onBlockTap: (TimeBlock) -> Void
    let onComplete: (TimeBlock) -> Void
    let onSkip: (TimeBlock) -> Void
    
    @State private var sectionAnimation = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Section header
            Button(action: onToggle) {
                HStack(spacing: 12) {
                    // Status icon
                    ZStack {
                        Circle()
                            .fill(status.color.opacity(0.2))
                            .frame(width: 36, height: 36)
                        
                        Image(systemName: status.iconName)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(status.color)
                    }
                    
                    // Title and count
                    VStack(alignment: .leading, spacing: 2) {
                        Text(status.displayName)
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white)
                        
                        Text("\(blocks.count) \(blocks.count == 1 ? "block" : "blocks")")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Color.white.opacity(0.6))
                    }
                    
                    Spacer()
                    
                    // Progress indicator for in-progress
                    if status == .inProgress, let current = currentBlock {
                        CircularProgressIndicator(
                            progress: current.currentProgress,
                            color: status.color,
                            size: 32
                        )
                    }
                    
                    // Chevron
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.4))
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
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
                            onTap: { onBlockTap(block) },
                            onComplete: { onComplete(block) },
                            onSkip: { onSkip(block) }
                        )
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
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                sectionAnimation = true
            }
        }
    }
}

// MARK: - Compact Time Block Row
struct CompactTimeBlockRow: View {
    let timeBlock: TimeBlock
    let isActive: Bool
    let onTap: () -> Void
    let onComplete: () -> Void
    let onSkip: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Time
                VStack(spacing: 2) {
                    Text(timeBlock.startTime.formatted(date: .omitted, time: .shortened))
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundStyle(isActive ? timeBlock.status.color : Color.white.opacity(0.6))
                    
                    Text(timeBlock.formattedDuration)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.4))
                }
                .frame(width: 50)
                
                // Content
                HStack(spacing: 8) {
                    if let icon = timeBlock.icon {
                        Text(icon)
                            .font(.system(size: 14))
                    }
                    
                    Text(timeBlock.title)
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    
                    Spacer()
                }
                
                // Quick actions for in-progress
                if timeBlock.status == .inProgress {
                    HStack(spacing: 8) {
                        Button(action: {
                            HapticManager.shared.success()
                            onComplete()
                        }) {
                            Image(systemName: "checkmark.circle")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundStyle(Color.premiumGreen)
                        }
                        
                        Button(action: {
                            HapticManager.shared.lightImpact()
                            onSkip()
                        }) {
                            Image(systemName: "xmark.circle")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundStyle(Color.premiumError)
                        }
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(
                        isActive ?
                        timeBlock.status.color.opacity(0.15) :
                        Color.white.opacity(0.05)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(
                        isActive ?
                        timeBlock.status.color.opacity(0.5) :
                        Color.white.opacity(0.1),
                        lineWidth: isActive ? 1.5 : 1
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Circular Progress Indicator
struct CircularProgressIndicator: View {
    let progress: Double
    let color: Color
    let size: CGFloat
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.2), lineWidth: 3)
                .frame(width: size, height: size)
            
            Circle()
                .trim(from: 0, to: CGFloat(progress))
                .stroke(
                    color,
                    style: StrokeStyle(lineWidth: 3, lineCap: .round)
                )
                .frame(width: size, height: size)
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.8, dampingFraction: 0.9), value: progress)
            
            Text("\(Int(progress * 100))%")
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(color)
        }
    }
}
