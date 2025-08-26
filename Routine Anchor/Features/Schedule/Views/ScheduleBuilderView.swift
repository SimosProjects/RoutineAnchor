//
//  ScheduleBuilderView.swift
//  Routine Anchor
//
import SwiftUI
import SwiftData

struct ScheduleBuilderView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.themeManager) private var themeManager
    @State private var viewModel: ScheduleBuilderViewModel?
    
    // MARK: - State
    @State private var showingAddBlock = false
    @State private var showingEditBlock = false
    @State private var selectedBlock: TimeBlock?
    @State private var showingDeleteConfirmation = false
    @State private var blockToDelete: TimeBlock?
    @State private var showingQuickAdd = false
    @State private var showingResetConfirmation = false
    
    var body: some View {
        ZStack {
            ThemedAnimatedBackground()
                .ignoresSafeArea()
            .ignoresSafeArea()
            .overlay(
                RadialGradient(
                    colors: [
                        Color(red: 0.2, green: 0.3, blue: 0.8).opacity(0.3),
                        Color.clear
                    ],
                    center: .top,
                    startRadius: 100,
                    endRadius: 400
                )
                .ignoresSafeArea()
            )
            
            // Static mesh background
            StaticMeshBackground()
                .opacity(0.3)
                .allowsHitTesting(false)
            
            // Static particles
            StaticParticles()
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
        }
        .onReceive(NotificationCenter.default.publisher(for: .showAddTimeBlockFromTab)) { _ in
            showingAddBlock = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .refreshScheduleView)) { _ in
            viewModel?.loadTimeBlocks()
        }
        .onReceive(NotificationCenter.default.publisher(for: .showAddTimeBlock)) { _ in
            showingAddBlock = true
        }
        .confirmationDialog(
            "Reset Today's Progress",
            isPresented: $showingResetConfirmation,
            titleVisibility: .visible
        ) {
            Button("Reset Progress", role: .destructive) {
                viewModel?.resetTodaysProgress()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will reset all time blocks back to 'Not Started' for today. This action cannot be undone.")
        }
        .confirmationDialog(
            "Delete Time Block",
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                if let block = blockToDelete {
                    viewModel?.deleteTimeBlock(block)
                    blockToDelete = nil
                }
            }
            Button("Cancel", role: .cancel) {
                blockToDelete = nil
            }
        } message: {
            Text("Are you sure you want to delete this time block?")
        }
        .sheet(isPresented: $showingAddBlock) {
            AddTimeBlockView(
                existingTimeBlocks: viewModel!.timeBlocks
            ) { title, startTime, endTime, notes, category in
                viewModel?.addTimeBlock(
                    title: title,
                    startTime: startTime,
                    endTime: endTime,
                    notes: notes,
                    category: category
                )
            }
            .environment(\.themeManager, themeManager)
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingEditBlock) {
            if let block = selectedBlock {
                EditTimeBlockView(timeBlock: block, existingTimeBlocks: viewModel!.timeBlocks) { updatedBlock in
                    viewModel?.updateTimeBlock(updatedBlock)
                }
                .environment(\.themeManager, themeManager)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
            }
        }
        .actionSheet(isPresented: $showingQuickAdd) {
            quickAddActionSheet
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
                                colors: [Color.anchorPurple, Color.anchorBlue],
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
                
                Button(action: {
                    HapticManager.shared.lightImpact()
                    showingResetConfirmation = true
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 12, weight: .medium))
                        Text("Reset All")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundStyle(Color.anchorError)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.anchorError.opacity(0.15))
                    .cornerRadius(8)
                }
            }
            .padding(.horizontal, 24)
            
            // Time blocks list - Using custom non-animated rows
            VStack(spacing: 12) {
                ForEach(viewModel.sortedTimeBlocks) { timeBlock in
                    SimpleTimeBlockRow(
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
            .padding(.horizontal, 24)
        }
    }
    
    // MARK: - Action Buttons Section
    private func actionButtonsSection(viewModel: ScheduleBuilderViewModel) -> some View {
        VStack(spacing: 16) {
            DesignedButton(
                title: "Add Time Block",
                style: .gradient,
                action: {
                    HapticManager.shared.impact()
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
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.anchorBlue.opacity(0.4),
                                Color.anchorPurple.opacity(0.2),
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
                            colors: [Color.anchorBlue, Color.anchorPurple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .frame(height: 200)
            
            // Content
            VStack(spacing: 16) {
                Text("Build Your Perfect Day")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.anchorBlue, Color.anchorPurple],
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
                DesignedButton(
                    title: "Add Your First Block",
                    style: .gradient,
                    action: {
                        HapticManager.shared.impact()
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
            
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: Color.anchorBlue))
                .scaleEffect(1.5)
            
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
        HapticManager.shared.anchorSuccess()
        dismiss()
    }
}

// MARK: - Simple Time Block Row (No Animations)
struct SimpleTimeBlockRow: View {
    let timeBlock: TimeBlock
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    @State private var isPressed = false
    
    private var accentColors: [Color] {
        switch timeBlock.status {
        case .notStarted:
            return [Color.anchorPurple, Color.anchorBlue]
        case .inProgress:
            return [Color.anchorBlue, Color.anchorTeal]
        case .completed:
            return [Color.anchorGreen, Color.anchorTeal]
        case .skipped:
            return [Color.anchorError, Color.anchorWarning]
        }
    }
    
    private var statusIcon: String {
        switch timeBlock.status {
        case .notStarted: return "clock"
        case .inProgress: return "play.fill"
        case .completed: return "checkmark"
        case .skipped: return "forward.fill"
        }
    }
    
    private var statusColor: Color {
        switch timeBlock.status {
        case .notStarted: return .white.opacity(0.6)
        case .inProgress: return .anchorBlue
        case .completed: return .anchorGreen
        case .skipped: return .anchorWarning
        }
    }
    
    var body: some View {
        HStack(spacing: 0) {
            // Left accent bar
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: accentColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 5)
            
            HStack(spacing: 16) {
                // Time badge
                VStack(spacing: 2) {
                    Text(timeBlock.startTime.formatted(date: .omitted, time: .shortened))
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    
                    Text(timeBlock.formattedDuration)
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundStyle(Color.white.opacity(0.6))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.1))
                )
                
                // Title and notes
                VStack(alignment: .leading, spacing: 4) {
                    Text(timeBlock.title)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                    
                    if let notes = timeBlock.notes, !notes.isEmpty {
                        Text(notes)
                            .font(.system(size: 12, weight: .regular))
                            .foregroundStyle(Color.white.opacity(0.6))
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                // Status Indicator
                Image(systemName: statusIcon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(statusColor)
                    .frame(width: 24, height: 24)
                    .background(statusColor.opacity(0.15))
                    .cornerRadius(6)
                
                // Action buttons
                HStack(spacing: 8) {
                    Button(action: onEdit) {
                        Image(systemName: "pencil")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Color.anchorBlue)
                            .frame(width: 32, height: 32)
                            .background(Color.anchorBlue.opacity(0.15))
                            .cornerRadius(8)
                    }
                    
                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Color.anchorError)
                            .frame(width: 32, height: 32)
                            .background(Color.anchorError.opacity(0.15))
                            .cornerRadius(8)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
        .scaleEffect(isPressed ? 0.97 : 1.0)
        .onTapGesture {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isPressed = false
                }
            }
        }
    }
}

// MARK: - Static Background Components

struct StaticMeshBackground: View {
    var body: some View {
        Canvas { context, size in
            let gridSize = 30
            let dotSize: CGFloat = 2
            
            for x in stride(from: 0, to: Int(size.width), by: gridSize) {
                for y in stride(from: 0, to: Int(size.height), by: gridSize) {
                    let xPos = CGFloat(x)
                    let yPos = CGFloat(y)
                    
                    context.fill(
                        Path(ellipseIn: CGRect(x: xPos - dotSize/2, y: yPos - dotSize/2, width: dotSize, height: dotSize)),
                        with: .color(.white.opacity(0.05))
                    )
                }
            }
        }
    }
}

struct StaticParticles: View {
    var body: some View {
        GeometryReader { geometry in
            ForEach(0..<10, id: \.self) { index in
                Circle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 4, height: 4)
                    .position(
                        x: CGFloat(20 + index * 40).truncatingRemainder(dividingBy: geometry.size.width),
                        y: CGFloat(30 + index * 60).truncatingRemainder(dividingBy: geometry.size.height)
                    )
                    .blur(radius: 1)
            }
        }
    }
}

// MARK: - Preview
#Preview {
    ScheduleBuilderView()
        .modelContainer(for: [TimeBlock.self], inMemory: true)
}
