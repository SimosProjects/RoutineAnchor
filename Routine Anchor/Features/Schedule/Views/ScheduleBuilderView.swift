//
//  ScheduleBuilderView.swift
//  Routine Anchor - Premium Version
//
import SwiftUI
import SwiftData

struct ScheduleBuilderView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: ScheduleBuilderViewModel?
    @State private var animationTask: Task<Void, Never>?
    
    // MARK: - State
    @State private var showingAddBlock = false
    @State private var showingEditBlock = false
    @State private var selectedBlock: TimeBlock?
    @State private var showingDeleteConfirmation = false
    @State private var blockToDelete: TimeBlock?
    @State private var showingQuickAdd = false
    @State private var animationPhase = 0
    
    var body: some View {
        ZStack {
            // Premium animated background
            AnimatedGradientBackground()
                .ignoresSafeArea()
            
            AnimatedMeshBackground()
                .opacity(0.3)
                .allowsHitTesting(false)
            
            ParticleEffectView()
                .allowsHitTesting(false)
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Header section
                    headerSection
                    
                    // Content based on state
                    if let viewModel = viewModel {
                        if viewModel.hasTimeBlocks {
                            mainContent(viewModel: viewModel)
                        } else {
                            emptyStateView
                        }
                    } else {
                        loadingState
                    }
                }
            }
            .refreshable {
                viewModel?.loadTimeBlocks()
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            setupViewModel()
            animationTask = Task { @MainActor in
                while !Task.isCancelled {
                    withAnimation(.easeInOut(duration: 2)) {
                        animationPhase = 1
                    }
                    try? await Task.sleep(nanoseconds: 2_000_000_000)
                }
            }
        }
        .onDisappear {
            animationTask?.cancel()
            animationTask = nil
            animationPhase = 0
        }
        .onReceive(NotificationCenter.default.publisher(for: .showAddTimeBlockFromTab)) { _ in
            showingAddBlock = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .refreshScheduleView)) { _ in
            viewModel?.loadTimeBlocks()
        }
        .sheet(isPresented: $showingAddBlock) {
            PremiumAddTimeBlockView { title, startTime, endTime, notes, category in
                viewModel?.addTimeBlock(
                    title: title,
                    startTime: startTime,
                    endTime: endTime,
                    notes: notes,
                    category: category
                )
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingEditBlock) {
            if let block = selectedBlock {
                EditTimeBlockView(timeBlock: block) { updatedBlock in
                    viewModel?.updateTimeBlock(updatedBlock)
                }
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .showAddTimeBlock)) { _ in
            showingAddBlock = true
        }
        .onDisappear {
            // Clean up notifications if needed
            NotificationCenter.default.removeObserver(self)
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
        .onReceive(NotificationCenter.default.publisher(for: .showAddTimeBlock)) { _ in
            showingAddBlock = true
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 20) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Schedule Builder")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.premiumPurple, Color.premiumBlue],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    
                    Text("Design your perfect routine")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.7))
                }
                
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.top, 60)
        }
    }
    
    // MARK: - Main Content
    private func mainContent(viewModel: ScheduleBuilderViewModel) -> some View {
        VStack(spacing: 24) {
            // Time blocks section
            timeBlocksSection(viewModel: viewModel)
            
            // Action buttons
            actionButtonsSection(viewModel: viewModel)
                .padding(.bottom, 100) // Space for tab bar
        }
        .padding(.top, 32)
    }
    
    // MARK: - Time Blocks Section
    private func timeBlocksSection(viewModel: ScheduleBuilderViewModel) -> some View {
        VStack(spacing: 16) {
            // Section header
            HStack {
                Text("Your Schedule")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                
                Spacer()
                
                Button("Reset All") {
                    HapticManager.shared.premiumImpact()
                    viewModel.resetRoutineStatus()
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.premiumError)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.premiumError.opacity(0.15))
                .cornerRadius(8)
            }
            .padding(.horizontal, 24)
            
            // Time blocks list
            LazyVStack(spacing: 12) {
                ForEach(viewModel.sortedTimeBlocks) { timeBlock in
                    TimeBlockRowView(
                        timeBlock: timeBlock,
                        showActions: true,
                        onEdit: {
                            selectedBlock = timeBlock
                            showingEditBlock = true
                        },
                        onDelete: {
                            blockToDelete = timeBlock
                            showingDeleteConfirmation = true
                        }
                    )
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
                }
            }
            .padding(.horizontal, 24)
        }
    }
    
    // MARK: - Action Buttons Section
    private func actionButtonsSection(viewModel: ScheduleBuilderViewModel) -> some View {
        VStack(spacing: 16) {
            PremiumButton(
                title: "Add Time Block",
                style: .gradient,
                action: {
                    HapticManager.shared.premiumImpact()
                    showingAddBlock = true
                }
            )
            
            HStack(spacing: 12) {
                SecondaryActionButton(
                    title: "Copy to Tomorrow",
                    icon: "calendar.badge.plus",
                    action: {
                        HapticManager.shared.lightImpact()
                        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
                        viewModel.copyRoutineToDate(tomorrow)
                    }
                )
                
                SecondaryActionButton(
                    title: "Templates",
                    icon: "sparkles",
                    action: {
                        HapticManager.shared.lightImpact()
                        showingQuickAdd = true
                    }
                )
            }
        }
        .padding(.horizontal, 24)
    }
    
    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Illustration
            ZStack {
                // Floating particles
                FloatingParticlesView()
                    .opacity(0.6)
                
                // Main illustration
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        Color.premiumBlue.opacity(0.4),
                                        Color.premiumPurple.opacity(0.2),
                                        Color.clear
                                    ],
                                    center: .center,
                                    startRadius: 50,
                                    endRadius: 150
                                )
                            )
                            .frame(width: 200, height: 200)
                            .blur(radius: 30)
                        
                        Image(systemName: "plus.circle")
                            .font(.system(size: 80, weight: .thin))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color.premiumBlue, Color.premiumPurple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                }
            }
            .frame(height: 200)
            
            // Content
            VStack(spacing: 16) {
                Text("Build Your Perfect Day")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.premiumBlue, Color.premiumPurple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .multilineTextAlignment(.center)
                
                Text("Create time blocks to structure your day and build consistent, productive habits.")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 40)
            
            Spacer()
            
            // Action buttons
            VStack(spacing: 16) {
                PremiumButton(
                    title: "Add Your First Block",
                    style: .gradient,
                    action: {
                        HapticManager.shared.premiumImpact()
                        showingAddBlock = true
                    }
                )
                
                SecondaryActionButton(
                    title: "Use a Template",
                    icon: "sparkles",
                    action: {
                        HapticManager.shared.lightImpact()
                        showingQuickAdd = true
                    }
                )
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 40)
        }
    }
    
    // MARK: - Loading State
    private var loadingState: some View {
        VStack(spacing: 20) {
            Spacer()
            
            // Loading animation
            ZStack {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(Color.premiumPurple.opacity(0.3))
                        .frame(width: 12, height: 12)
                        .scaleEffect(animationPhase == 0 ? 0.8 : 1.2)
                        .animation(
                            .easeInOut(duration: 0.8)
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.2),
                            value: animationPhase
                        )
                        .offset(x: CGFloat(index - 1) * 20)
                }
            }
            
            Text("Setting up your schedule...")
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundStyle(Color.white.opacity(0.7))
            
            Spacer()
        }
    }
    
    // MARK: - Quick Add Action Sheet
    private var quickAddActionSheet: ActionSheet {
        ActionSheet(
            title: Text("Quick Add Templates"),
            message: Text("Choose a common time block to add"),
            buttons: [
                .default(Text("🌅 Morning Routine (7:00-8:00 AM)")) {
                    viewModel?.addMorningRoutine()
                },
                .default(Text("💼 Work Session (9:00 AM-12:00 PM)")) {
                    viewModel?.addWorkBlock()
                },
                .default(Text("🍽️ Lunch Break (12:00-1:00 PM)")) {
                    viewModel?.addBreak()
                },
                .default(Text("✨ Custom Time Block")) {
                    showingAddBlock = true
                },
                .cancel()
            ]
        )
    }
    
    // MARK: - Helper Methods
    
    private func setupViewModel() {
        guard viewModel == nil else {
            viewModel?.loadTimeBlocks()
            return
        }
        let dataManager = DataManager(modelContext: modelContext)
        viewModel = ScheduleBuilderViewModel(dataManager: dataManager)
    }
    
    private func saveAndDismiss() {
        viewModel?.saveRoutine()
        HapticManager.shared.premiumSuccess()
        dismiss()
    }
}

// MARK: - Preview
#Preview {
    ScheduleBuilderView()
        .modelContainer(for: [TimeBlock.self], inMemory: true)
}
