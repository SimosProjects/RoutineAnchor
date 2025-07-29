//
//  PremiumScheduleBuilderView.swift
//  Routine Anchor - Premium Version (iOS 17+ Optimized)
//
import SwiftUI
import SwiftData

struct PremiumScheduleBuilderView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    // iOS 17+ Pattern: Direct initialization with @State
    @State private var viewModel: ScheduleBuilderViewModel
    @State private var particleSystem = ParticleSystem()
    
    // MARK: - State
    @State private var showingAddBlock = false
    @State private var showingEditBlock = false
    @State private var selectedBlock: TimeBlock?
    @State private var showingDeleteConfirmation = false
    @State private var blockToDelete: TimeBlock?
    @State private var showingQuickAdd = false
    @State private var animationPhase = 0
    @State private var headerOffset: CGFloat = 0
    @State private var scrollProgress: CGFloat = 0
    
    // MARK: - Initialization
    init() {
        // Initialize with placeholder - will be configured in .task
        let placeholderDataManager = DataManager(modelContext: ModelContext(ModelContainer.shared))
        _viewModel = State(initialValue: ScheduleBuilderViewModel(dataManager: placeholderDataManager))
    }
    
    var body: some View {
        ZStack {
            // Premium animated background
            AnimatedGradientBackground()
                .ignoresSafeArea()
            
            AnimatedMeshBackground()
                .opacity(0.3)
                .allowsHitTesting(false)
            
            ParticleEffectView(system: particleSystem)
                .allowsHitTesting(false)
            
            GeometryReader { geometry in
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 0) {
                        // Header section
                        headerSection
                        
                        // Content based on state
                        if viewModel.hasTimeBlocks {
                            mainContent(viewModel: viewModel)
                        } else {
                            emptyStateView
                        }
                    }
                }
                .coordinateSpace(name: "scroll")
                .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                    updateScrollProgress(value, geometry: geometry)
                }
            }
        }
        .navigationBarHidden(true)
        .task {
            await configureViewModel()
            startAnimations()
        }
        .onReceive(NotificationCenter.default.publisher(for: .showAddTimeBlockFromTab)) { _ in
            showingAddBlock = true
        }
        .sheet(isPresented: $showingAddBlock) {
            PremiumAddTimeBlockView { title, startTime, endTime, notes, category in
                viewModel.addTimeBlock(
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
                PremiumEditTimeBlockView(timeBlock: block) { updatedBlock in
                    viewModel.updateTimeBlock(updatedBlock)
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
                viewModel.deleteTimeBlock(block)
            }
            Button("Cancel", role: .cancel) {}
        } message: { block in
            Text("Are you sure you want to delete '\(block.title)'?")
        }
        .actionSheet(isPresented: $showingQuickAdd) {
            quickAddActionSheet
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Title with parallax effect
            Text("Schedule Builder")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.white, Color.white.opacity(0.8)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .offset(y: headerOffset * 0.3)
            
            // Subtitle
            Text("Design your perfect day")
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundStyle(Color.white.opacity(0.6))
                .offset(y: headerOffset * 0.5)
            
            // Stats bar
            if viewModel.hasTimeBlocks {
                ScheduleStatsBar(viewModel: viewModel)
                    .padding(.horizontal, 24)
                    .offset(y: headerOffset * 0.7)
                    .opacity(1 - scrollProgress)
            }
        }
        .padding(.vertical, 20)
    }
    
    // MARK: - Main Content
    private func mainContent(viewModel: ScheduleBuilderViewModel) -> some View {
        VStack(spacing: 20) {
            // Quick actions
            HStack(spacing: 12) {
                PremiumSecondaryButton(
                    title: "Quick Add",
                    icon: "plus.circle",
                    style: .outlined
                ) {
                    showingQuickAdd = true
                }
                
                PremiumSecondaryButton(
                    title: "Clear All",
                    icon: "trash",
                    style: .destructive
                ) {
                    viewModel.clearAllBlocks()
                }
            }
            .padding(.horizontal, 24)
            .opacity(Double(viewModel.timeBlocks.count))
            
            // Time blocks list
            VStack(spacing: 12) {
                ForEach(viewModel.timeBlocks) { block in
                    PremiumScheduleBlockRowView(
                        timeBlock: block,
                        onEdit: {
                            selectedBlock = block
                            showingEditBlock = true
                        },
                        onDelete: {
                            blockToDelete = block
                            showingDeleteConfirmation = true
                        }
                    )
                    .padding(.horizontal, 24)
                }
            }
            
            Spacer(minLength: 100) // Space for FAB and tab bar
        }
        .padding(.top, 12)
    }
    
    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Animation
            ZStack {
                ForEach(0..<3) { index in
                    Circle()
                        .stroke(Color.premiumBlue.opacity(0.3), lineWidth: 2)
                        .frame(width: 80 + CGFloat(index * 40), height: 80 + CGFloat(index * 40))
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
            
            Text("No schedule yet")
                .font(.system(size: 24, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.white)
            
            Text("Start building your perfect routine")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Color.white.opacity(0.6))
            
            // Action buttons
            VStack(spacing: 16) {
                PremiumPrimaryButton(title: "Add First Block", icon: "plus.circle.fill") {
                    showingAddBlock = true
                }
                
                PremiumSecondaryButton(
                    title: "Use Template",
                    icon: "doc.text",
                    style: .ghost
                ) {
                    showingQuickAdd = true
                }
            }
            .padding(.horizontal, 40)
            
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
                    viewModel.addMorningRoutine()
                },
                .default(Text("💼 Work Session (9:00 AM-12:00 PM)")) {
                    viewModel.addWorkBlock()
                },
                .default(Text("🍽️ Lunch Break (12:00-1:00 PM)")) {
                    viewModel.addBreak()
                },
                .default(Text("✨ Custom Time Block")) {
                    showingAddBlock = true
                },
                .cancel()
            ]
        )
    }
    
    // MARK: - Helper Methods
    
    private func configureViewModel() async {
        // Create proper DataManager with current context
        let dataManager = DataManager(modelContext: modelContext)
        
        // Reinitialize ViewModel with proper dependencies
        viewModel = ScheduleBuilderViewModel(dataManager: dataManager)
        
        // Setup refresh observer
        viewModel.setupRefreshObserver()
    }
    
    private func startAnimations() {
        particleSystem.startEmitting()
        
        withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
            animationPhase = 1
        }
    }
    
    private func updateScrollProgress(_ offset: CGFloat, geometry: GeometryProxy) {
        let progress = min(max(-offset / 100, 0), 1)
        
        withAnimation(.easeOut(duration: 0.1)) {
            scrollProgress = progress
            headerOffset = offset
        }
    }
    
    private func saveAndDismiss() {
        viewModel.saveRoutine()
        HapticManager.shared.premiumSuccess()
        dismiss()
    }
}
