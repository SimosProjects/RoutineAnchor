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
                SecondaryButton(
                    title: "Quick Add",
                    icon: "plus.circle",
                    style: .outlined
                ) {
                    showingQuickAdd = true
                }
                
                SecondaryButton(
                    title: "Clear All",
                    icon: "trash",
                    style: .ghost
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
                PrimaryButton(title: "Add First Block", icon: "plus.circle.fill") {
                    showingAddBlock = true
                }
                
                SecondaryButton(
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
    
    // MARK: - Premium Schedule Block Row View
    struct PremiumScheduleBlockRowView: View {
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
                            .foregroundStyle(Color.premiumBlue)
                            .frame(width: 36, height: 36)
                            .background(Color.premiumBlue.opacity(0.15))
                            .cornerRadius(10)
                    }
                    
                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(Color.premiumError)
                            .frame(width: 36, height: 36)
                            .background(Color.premiumError.opacity(0.15))
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
            case .inProgress: return Color.premiumBlue
            case .completed: return Color.premiumGreen
            case .skipped: return Color.premiumWarning
            }
        }
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
