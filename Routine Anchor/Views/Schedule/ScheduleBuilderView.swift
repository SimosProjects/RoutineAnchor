//
//  ScheduleBuilderView.swift
//  Routine Anchor
//
//  Created by Christopher Simonson on 7/19/25.
//
import SwiftUI
import SwiftData

struct ScheduleBuilderView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: ScheduleBuilderViewModel?
    
    // MARK: - State
    @State private var showingAddBlock = false
    @State private var showingEditBlock = false
    @State private var selectedBlock: TimeBlock?
    @State private var showingDeleteConfirmation = false
    @State private var blockToDelete: TimeBlock?
    @State private var showingQuickAdd = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.backgroundPrimary
                    .ignoresSafeArea()
                
                if viewModel?.hasTimeBlocks == true {
                    mainContent
                } else {
                    emptyStateView
                }
            }
            .navigationTitle("Schedule Builder")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(Color.textSecondary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 16) {
                        Button {
                            showingQuickAdd = true
                        } label: {
                            Image(systemName: "wand.and.stars")
                                .foregroundColor(Color.primaryBlue)
                        }
                        
                        Button("Save") {
                            saveAndDismiss()
                        }
                        .foregroundColor(Color.primaryBlue)
                        .fontWeight(.semibold)
                    }
                }
            }
            .onAppear {
                setupViewModel()
            }
            .sheet(isPresented: $showingAddBlock) {
                AddTimeBlockView { title, startTime, endTime, notes, category in
                    viewModel?.addTimeBlock(
                        title: title,
                        startTime: startTime,
                        endTime: endTime,
                        notes: notes,
                        category: category
                    )
                }
            }
            .sheet(isPresented: $showingEditBlock) {
                if let block = selectedBlock {
                    EditTimeBlockView(timeBlock: block) { updatedBlock in
                        viewModel?.updateTimeBlock(updatedBlock)
                    }
                }
            }
            .confirmationDialog(
                "Delete Time Block",
                isPresented: $showingDeleteConfirmation,
                titleVisibility: .visible,
                presenting: blockToDelete
            ) { block in
                Button("Delete", role: .destructive) {
                    viewModel?.deleteTimeBlock(block)
                }
                Button("Cancel", role: .cancel) {}
            } message: { block in
                Text("Are you sure you want to delete '\(block.title)'?")
            }
            .actionSheet(isPresented: $showingQuickAdd) {
                quickAddActionSheet
            }
        }
        .alert("Error", isPresented: .constant(viewModel?.errorMessage != nil)) {
            Button("OK") {
                viewModel?.clearError()
            }
        } message: {
            Text(viewModel?.errorMessage ?? "")
        }
    }
    
    // MARK: - Main Content
    private var mainContent: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                // Summary Section
                if let viewModel = viewModel {
                    summarySection(viewModel)
                    
                    // Time Blocks List
                    timeBlocksSection(viewModel)
                }
                
                // Add Block Button
                addBlockButton
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
        }
    }
    
    // MARK: - Summary Section
    private func summarySection(_ viewModel: ScheduleBuilderViewModel) -> some View {
        VStack(spacing: 12) {
            HStack {
                Text("Schedule Overview")
                    .font(TypographyConstants.Headers.sectionHeader)
                    .foregroundColor(Color.textPrimary)
                
                Spacer()
                
                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
            
            HStack(spacing: 20) {
                // Block Count
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(viewModel.timeBlocks.count)")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(Color.primaryBlue)
                    
                    Text("Time Blocks")
                        .font(TypographyConstants.UI.caption)
                        .foregroundColor(Color.textSecondary)
                }
                
                Spacer()
                
                // Total Duration
                VStack(alignment: .trailing, spacing: 4) {
                    Text(viewModel.formattedTotalDuration)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(Color.successGreen)
                    
                    Text("Total Time")
                        .font(TypographyConstants.UI.caption)
                        .foregroundColor(Color.textSecondary)
                }
            }
        }
        .padding(20)
        .background(Color.cardBackground)
        .cornerRadius(16)
        .shadow(color: ColorConstants.UI.cardShadow, radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Time Blocks Section
    private func timeBlocksSection(_ viewModel: ScheduleBuilderViewModel) -> some View {
        VStack(spacing: 12) {
            HStack {
                Text("Your Schedule")
                    .font(TypographyConstants.Headers.sectionHeader)
                    .foregroundColor(Color.textPrimary)
                
                Spacer()
                
                Button("Reset All") {
                    viewModel.resetRoutineStatus()
                }
                .font(TypographyConstants.UI.caption)
                .foregroundColor(Color.errorRed)
            }
            
            LazyVStack(spacing: 8) {
                ForEach(viewModel.sortedTimeBlocks) { timeBlock in
                    ScheduleBlockRowView(
                        timeBlock: timeBlock,
                        onEdit: {
                            selectedBlock = timeBlock
                            showingEditBlock = true
                        },
                        onDelete: {
                            blockToDelete = timeBlock
                            showingDeleteConfirmation = true
                        }
                    )
                }
            }
        }
    }
    
    // MARK: - Add Block Button
    private var addBlockButton: some View {
        Button {
            showingAddBlock = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 20, weight: .medium))
                
                Text("Add Time Block")
                    .font(TypographyConstants.UI.button)
                    .fontWeight(.medium)
            }
            .foregroundColor(Color.primaryBlue)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.primaryBlue.opacity(0.1))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.primaryBlue.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [5]))
            )
        }
    }
    
    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "clock.badge.plus")
                .font(.system(size: 60, weight: .thin))
                .foregroundColor(Color.textSecondary)
                .opacity(0.6)
            
            VStack(spacing: 12) {
                Text("Build Your Routine")
                    .font(TypographyConstants.Headers.screenTitle)
                    .foregroundColor(Color.textPrimary)
                
                Text("Create time blocks to structure your day and build consistent habits.")
                    .font(TypographyConstants.Body.description)
                    .foregroundColor(Color.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .padding(.horizontal, 40)
            }
            
            Spacer()
            
            VStack(spacing: 12) {
                PrimaryButton("Add Your First Block") {
                    showingAddBlock = true
                }
                
                SecondaryButton("Use Quick Templates") {
                    showingQuickAdd = true
                }
                .buttonStyle(.outlined)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
    }
    
    // MARK: - Quick Add Action Sheet
    private var quickAddActionSheet: ActionSheet {
        ActionSheet(
            title: Text("Quick Add Templates"),
            message: Text("Choose a common time block to add"),
            buttons: [
                .default(Text("Morning Routine (7:00-8:00 AM)")) {
                    viewModel?.addMorningRoutine()
                },
                .default(Text("Work Session (9:00 AM-12:00 PM)")) {
                    viewModel?.addWorkBlock()
                },
                .default(Text("Lunch Break (12:00-1:00 PM)")) {
                    viewModel?.addBreak()
                },
                .default(Text("Custom Time Block")) {
                    showingAddBlock = true
                },
                .cancel()
            ]
        )
    }
    
    // MARK: - Helper Methods
    
    private func setupViewModel() {
        let dataManager = DataManager(modelContext: modelContext)
        viewModel = ScheduleBuilderViewModel(dataManager: dataManager)
    }
    
    private func saveAndDismiss() {
        viewModel?.saveRoutine()
        
        // Add haptic feedback
        HapticManager.shared.success()
        
        // Dismiss with animation
        dismiss()
    }
}

// MARK: - Schedule Block Row View
struct ScheduleBlockRowView: View {
    let timeBlock: TimeBlock
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    @State private var showingContextMenu = false
    
    var body: some View {
        HStack(spacing: 16) {
            // Time and Icon
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    if let icon = timeBlock.icon {
                        Text(icon)
                            .font(.system(size: 16))
                    } else {
                        Image(systemName: "clock")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Color.primaryBlue)
                    }
                    
                    Text(timeBlock.shortFormattedTimeRange)
                        .font(TypographyConstants.UI.timeBlock)
                        .foregroundColor(Color.textSecondary)
                        .fontWeight(.medium)
                }
                
                Text(timeBlock.formattedDuration)
                    .font(TypographyConstants.UI.caption)
                    .foregroundColor(Color.textSecondary)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(timeBlock.title)
                    .font(TypographyConstants.Headers.cardTitle)
                    .foregroundColor(Color.textPrimary)
                    .lineLimit(1)
                
                if let category = timeBlock.category {
                    Text(category)
                        .font(TypographyConstants.UI.caption)
                        .foregroundColor(Color.primaryBlue)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.primaryBlue.opacity(0.1))
                        .cornerRadius(4)
                }
                
                if let notes = timeBlock.notes, !notes.isEmpty {
                    Text(notes)
                        .font(TypographyConstants.UI.caption)
                        .foregroundColor(Color.textSecondary)
                        .lineLimit(2)
                }
            }
            
            Spacer()
            
            // Actions
            HStack(spacing: 8) {
                Button {
                    onEdit()
                } label: {
                    Image(systemName: "pencil.circle")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(Color.primaryBlue)
                }
                
                Button {
                    onDelete()
                } label: {
                    Image(systemName: "trash.circle")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(Color.errorRed)
                }
            }
        }
        .padding(16)
        .background(Color.cardBackground)
        .cornerRadius(12)
        .shadow(color: ColorConstants.UI.cardShadow, radius: 2, x: 0, y: 1)
        .contextMenu {
            contextMenuButtons
        }
    }
    
    @ViewBuilder
    private var contextMenuButtons: some View {
        Button {
            onEdit()
        } label: {
            Label("Edit", systemImage: "pencil")
        }
        
        Button(role: .destructive) {
            onDelete()
        } label: {
            Label("Delete", systemImage: "trash")
        }
    }
}

// MARK: - Previews
#Preview("Schedule Builder with Data") {
    ScheduleBuilderView()
        .modelContainer(for: [TimeBlock.self, DailyProgress.self], inMemory: true)
}

#Preview("Schedule Builder Empty") {
    ScheduleBuilderView()
        .modelContainer(for: [TimeBlock.self, DailyProgress.self], inMemory: true)
}
