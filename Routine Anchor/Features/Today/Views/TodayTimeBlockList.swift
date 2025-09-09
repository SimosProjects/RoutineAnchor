//
//  TodayTimeBlocksList.swift
//  Routine Anchor
//
//  Time blocks section for Today. Theme lookups use semantic tokens (no legacy scheme).
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

    private var theme: AppTheme { themeManager?.currentTheme ?? PredefinedThemes.classic }

    var body: some View {
        VStack(spacing: 16) {
            sectionHeader()

            if viewModel.hasScheduledBlocks {
                if useGroupedView { groupedTimeBlocks } else { flatTimeBlocks }
            } else {
                emptyMessage()
            }
        }
    }

    // MARK: - Section Header

    private func sectionHeader() -> some View {
        HStack {
            Text("Today's Schedule")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(theme.primaryTextColor)

            Spacer()

            // Simple toggle menu between Flat vs Grouped
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
                    .foregroundStyle(theme.accentPrimaryColor)
                    .frame(width: 32, height: 32)
                    .background(theme.accentPrimaryColor.opacity(0.15))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(theme.borderColor.opacity(0.8), lineWidth: 1)
                    )
            }

            if viewModel.isLoading {
                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(theme.primaryTextColor)
                    .scaleEffect(0.8)
            }
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Flat Time Blocks

    private var flatTimeBlocks: some View {
        LazyVStack(spacing: 12) {
            ForEach(viewModel.sortedTimeBlocks) { timeBlock in
                // Assumes TimeBlockRowView already exists.
                TimeBlockRowView(
                    timeBlock: timeBlock,
                    showActions: true,
                    onStart: { Task { await viewModel.startTimeBlock(timeBlock) } },
                    onComplete: { Task { await viewModel.markBlockCompleted(timeBlock) } },
                    onSkip: { Task { await viewModel.markBlockSkipped(timeBlock) } }
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

    // MARK: - Grouped Time Blocks

    private var groupedTimeBlocks: some View {
        LazyVStack(spacing: 16) {
            ForEach(BlockStatus.allCases, id: \.self) { status in
                let blocks = blocksForStatus(status)
                if !blocks.isEmpty {
                    // Assumes StatusGroupSection exists and takes these arguments.
                    StatusGroupSection(
                        status: status,
                        blocks: blocks,
                        currentBlock: viewModel.getCurrentBlock(),
                        isExpanded: expandedSections.contains(status),
                        highlightedBlockId: highlightedBlockId,
                        onToggle: {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                if expandedSections.contains(status) { expandedSections.remove(status) }
                                else { expandedSections.insert(status) }
                            }
                        },
                        onBlockTap: handleTimeBlockTap,
                        onComplete: { timeBlock in Task { await viewModel.markBlockCompleted(timeBlock) } },
                        onSkip: { timeBlock in Task { await viewModel.markBlockSkipped(timeBlock) } }
                    )
                    .id(status)
                }
            }
        }
        .padding(.horizontal, 24)
        .onAppear {
            // Auto-expand active section if something is in progress.
            if viewModel.getCurrentBlock() != nil { expandedSections.insert(.inProgress) }
        }
    }

    // MARK: - Empty Message

    private func emptyMessage() -> some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(theme.subtleTextColor.opacity(0.6))

            Text("No blocks scheduled for today")
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(theme.secondaryTextColor.opacity(0.85))

            Button {
                NotificationCenter.default.post(name: .navigateToSchedule, object: nil)
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle")
                        .font(.system(size: 16, weight: .medium))
                    Text("Add Time Blocks")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundStyle(theme.invertedTextColor)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(theme.actionPrimaryGradient)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(theme.borderColor.opacity(0.8), lineWidth: 1)
                )
                .shadow(color: theme.accentPrimaryColor.opacity(0.3), radius: 8, x: 0, y: 4)
            }
        }
        .padding(.vertical, 40)
    }

    // MARK: - Helpers

    private var useGroupedView: Bool {
        UserDefaults.standard.bool(forKey: "useGroupedTimeBlocks")
    }

    private func blocksForStatus(_ status: BlockStatus) -> [TimeBlock] {
        viewModel.timeBlocks
            .filter { $0.status == status }
            .sorted { $0.startTime < $1.startTime }
    }

    private func handleTimeBlockTap(_ timeBlock: TimeBlock) {
        HapticManager.shared.lightImpact()
        selectedTimeBlock = timeBlock
        showingActionSheet = true
    }
}
