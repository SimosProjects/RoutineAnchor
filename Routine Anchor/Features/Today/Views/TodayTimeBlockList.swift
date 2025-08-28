//
//  TodayTimeBlocksList.swift
//  Routine Anchor
//
//  Time blocks list section for Today view
//
import SwiftUI

struct TodayTimeBlocksList: View {
    let viewModel: TodayViewModel
    @Environment(\.themeManager) private var themeManager
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
                .foregroundStyle(themeManager?.currentTheme.textPrimaryColor ?? Theme.defaultTheme.textPrimaryColor)
            
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
                    .foregroundStyle(Color.anchorBlue)
                    .frame(width: 32, height: 32)
                    .background(Color.anchorBlue.opacity(0.15))
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
                TimeBlockRowView(
                    timeBlock: timeBlock,
                    showActions: true,
                    onStart: {
                        Task {
                            await viewModel.startTimeBlock(timeBlock)
                        }
                    },
                    onComplete: {
                        Task {
                            await viewModel.markBlockCompleted(timeBlock)
                        }
                    },
                    onSkip: {
                        Task {
                            await viewModel.markBlockSkipped(timeBlock)
                        }
                    }
                )
                .id(timeBlock.id)
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
                        onComplete: { timeBlock in
                            Task {
                                await viewModel.markBlockCompleted(timeBlock)
                            }
                        },
                        onSkip: { timeBlock in
                            Task {
                                await viewModel.markBlockSkipped(timeBlock)
                            }
                        }
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
                .foregroundStyle(Color(themeManager?.currentTheme.textTertiaryColor ?? Theme.defaultTheme.textTertiaryColor).opacity(0.6))
            
            Text("No blocks scheduled for today")
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(Color(themeManager?.currentTheme.textSecondaryColor ?? Theme.defaultTheme.textSecondaryColor).opacity(0.85))
            
            Button(action: {
                NotificationCenter.default.post(name: .navigateToSchedule, object: nil)
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle")
                        .font(.system(size: 16, weight: .medium))
                    
                    Text("Add Time Blocks")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundStyle(themeManager?.currentTheme.textPrimaryColor ?? Theme.defaultTheme.textPrimaryColor)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(
                        colors: [Color.anchorBlue, Color.anchorPurple],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
                .shadow(color: Color.anchorBlue.opacity(0.3), radius: 8, x: 0, y: 4)
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
