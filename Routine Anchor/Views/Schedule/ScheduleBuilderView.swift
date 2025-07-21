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
    
    // MARK: - State
    @State private var showingAddBlock = false
    @State private var showingEditBlock = false
    @State private var selectedBlock: TimeBlock?
    @State private var showingDeleteConfirmation = false
    @State private var blockToDelete: TimeBlock?
    @State private var showingQuickAdd = false
    @State private var animationPhase = 0.0
    @State private var showSaveSuccess = false
    @State private var particleSystem = ParticleSystem()
    
    var body: some View {
        NavigationView {
            ZStack {
                // Premium animated background
                AnimatedGradientBackground()
                    .ignoresSafeArea()
                
                AnimatedMeshBackground()
                    .opacity(0.3)
                    .ignoresSafeArea()
                
                if showSaveSuccess {
                    ParticleEffectView(system: particleSystem)
                        .allowsHitTesting(false)
                        .ignoresSafeArea()
                }
                
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
                    Button {
                        dismiss()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "xmark")
                                .font(.system(size: 12, weight: .semibold))
                            Text("Cancel")
                                .font(.system(size: 16, weight: .medium))
                        }
                        .foregroundStyle(Color.premiumTextSecondary)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 16) {
                        // Quick Add Button with Glow
                        Button {
                            showingQuickAdd = true
                            HapticManager.shared.lightImpact()
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(Color.premiumPurple.opacity(0.2))
                                    .frame(width: 36, height: 36)
                                    .blur(radius: animationPhase > 0.5 ? 8 : 4)
                                    .scaleEffect(animationPhase > 0.5 ? 1.2 : 1.0)
                                
                                Image(systemName: "wand.and.stars")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [Color.premiumPurple, Color.premiumBlue],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                            }
                        }
                        .animation(.easeInOut(duration: 2).repeatForever(), value: animationPhase)
                        
                        // Save Button with Gradient
                        Button {
                            saveAndDismiss()
                        } label: {
                            Text("Save")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(
                                    LinearGradient(
                                        colors: [Color.premiumBlue, Color.premiumTeal],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(8)
                        }
                    }
                }
            }
            .onAppear {
                setupViewModel()
                withAnimation(.linear(duration: 4).repeatForever(autoreverses: false)) {
                    animationPhase = 1.0
                }
            }
            .sheet(isPresented: $showingAddBlock) {
                AddTimeBlockView { title, startTime, endTime, notes, category, icon in
                    viewModel?.addTimeBlock(
                        title: title,
                        startTime: startTime,
                        endTime: endTime,
                        notes: notes,
                        category: category,
                        icon: icon
                    )
                }
                .presentationBackground(.ultraThinMaterial)
                .presentationCornerRadius(24)
            }
            .sheet(isPresented: $showingEditBlock) {
                if let block = selectedBlock {
                    EditTimeBlockView(timeBlock: block) { updatedBlock in
                        viewModel?.updateTimeBlock(updatedBlock)
                    }
                    .presentationBackground(.ultraThinMaterial)
                    .presentationCornerRadius(24)
                }
            }
            .confirmationDialog(
                "Delete Time Block",
                isPresented: $showingDeleteConfirmation,
                titleVisibility: .visible,
                presenting: blockToDelete
            ) { block in
                Button("Delete", role: .destructive) {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        viewModel?.deleteTimeBlock(block)
                    }
                    HapticManager.shared.warning()
                }
                Button("Cancel", role: .cancel) {}
            } message: { block in
                Text("Are you sure you want to delete '\(block.title)'?")
            }
        }
        .preferredColorScheme(.dark)
    }
    
    // MARK: - Main Content
    private var mainContent: some View {
        ScrollView {
            VStack(spacing: 24) {
                if let viewModel = viewModel {
                    // Premium Stats Card
                    statsCard(viewModel)
                        .transition(.asymmetric(
                            insertion: .scale.combined(with: .opacity),
                            removal: .scale.combined(with: .opacity)
                        ))
                    
                    // Time Blocks Section with Staggered Animation
                    timeBlocksSection(viewModel)
                        .transition(.asymmetric(
                            insertion: .move(edge: .bottom).combined(with: .opacity),
                            removal: .move(edge: .top).combined(with: .opacity)
                        ))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 24)
        }
    }
    
    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Animated Icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.premiumBlue.opacity(0.2), Color.premiumPurple.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                    .blur(radius: 20)
                    .scaleEffect(animationPhase > 0.5 ? 1.2 : 0.8)
                
                Image(systemName: "calendar.badge.plus")
                    .font(.system(size: 48, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.premiumBlue, Color.premiumPurple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .rotationEffect(.degrees(animationPhase > 0.5 ? 5 : -5))
            }
            
            VStack(spacing: 16) {
                Text("Build Your Perfect Day")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                
                Text("Add time blocks to create your ideal schedule")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Color.premiumTextSecondary)
                    .multilineTextAlignment(.center)
            }
            
            // CTA Button with Glow Effect
            Button {
                showingAddBlock = true
                HapticManager.shared.success()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                    Text("Add Your First Block")
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
                .background(
                    ZStack {
                        // Glow effect
                        RoundedRectangle(cornerRadius: 12)
                            .fill(
                                LinearGradient(
                                    colors: [Color.premiumBlue, Color.premiumPurple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .blur(radius: 20)
                            .opacity(0.6)
                        
                        // Button background
                        RoundedRectangle(cornerRadius: 12)
                            .fill(
                                LinearGradient(
                                    colors: [Color.premiumBlue, Color.premiumPurple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    }
                )
            }
            .scaleEffect(animationPhase > 0.5 ? 1.05 : 0.95)
            
            Spacer()
        }
        .padding(.horizontal, 32)
        .animation(.easeInOut(duration: 2).repeatForever(), value: animationPhase)
    }
    
    // MARK: - Stats Card
    private func statsCard(_ viewModel: ScheduleBuilderViewModel) -> some View {
        VStack(spacing: 20) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Schedule Overview")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    
                    Text("\(viewModel.timeBlocks.count) time blocks")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.premiumTextSecondary)
                }
                
                Spacer()
                
                // Total Duration with Animated Gradient
                VStack(alignment: .trailing, spacing: 4) {
                    Text(viewModel.formattedTotalDuration)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.premiumGreen, Color.premiumTeal],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    
                    Text("Total Time")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color.premiumTextTertiary)
                }
            }
            
            // Progress Indicator
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Track
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 8)
                    
                    // Fill with gradient
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [Color.premiumGreen, Color.premiumTeal],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * min(Double(viewModel.totalMinutes) / 480.0, 1.0), height: 8)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: viewModel.totalMinutes)
                }
            }
            .frame(height: 8)
        }
        .padding(24)
        .glassMorphism()
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.2),
                            Color.white.opacity(0.05)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
    }
    
    // MARK: - Time Blocks Section
    private func timeBlocksSection(_ viewModel: ScheduleBuilderViewModel) -> some View {
        VStack(spacing: 16) {
            // Section Header
            HStack {
                Image(systemName: "clock.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Color.premiumBlue)
                
                Text("Your Schedule")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                
                Spacer()
                
                if viewModel.hasTimeBlocks {
                    Button {
                        viewModel.resetRoutineStatus()
                        HapticManager.shared.warning()
                    } label: {
                        Text("Reset All")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Color.premiumError)
                    }
                }
            }
            
            // Time Blocks List with Staggered Animation
            LazyVStack(spacing: 12) {
                ForEach(Array(viewModel.sortedTimeBlocks.enumerated()), id: \.element.id) { index, timeBlock in
                    PremiumScheduleBlockRow(
                        timeBlock: timeBlock,
                        onEdit: {
                            selectedBlock = timeBlock
                            showingEditBlock = true
                            HapticManager.shared.lightImpact()
                        },
                        onDelete: {
                            blockToDelete = timeBlock
                            showingDeleteConfirmation = true
                            HapticManager.shared.warning()
                        }
                    )
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .scale.combined(with: .opacity)
                    ))
                    .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(Double(index) * 0.05), value: viewModel.timeBlocks.count)
                }
            }
            
            // Add Block Button
            Button {
                showingAddBlock = true
                HapticManager.shared.lightImpact()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle")
                        .font(.system(size: 16, weight: .medium))
                    Text("Add Time Block")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundStyle(Color.premiumBlue)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.premiumBlue.opacity(0.15))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(
                                    style: StrokeStyle(lineWidth: 2, dash: [8, 4])
                                )
                                .foregroundStyle(Color.premiumBlue.opacity(0.3))
                        )
                )
            }
        }
    }
    
    // MARK: - Helper Methods
    private func setupViewModel() {
        let vm = ScheduleBuilderViewModel(modelContext: modelContext)
        vm.loadTimeBlocks()
        self.viewModel = vm
    }
    
    private func saveAndDismiss() {
        guard let viewModel = viewModel else { return }
        
        // Trigger success animation
        showSaveSuccess = true
        particleSystem.emit(at: CGPoint(x: UIScreen.main.bounds.width / 2, y: 100))
        HapticManager.shared.success()
        
        // Save and dismiss after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            viewModel.saveSchedule()
            dismiss()
        }
    }
}

// MARK: - Premium Schedule Block Row
struct PremiumScheduleBlockRow: View {
    let timeBlock: TimeBlock
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    @State private var isPressed = false
    @State private var showActions = false
    
    var body: some View {
        HStack(spacing: 16) {
            // Time Column with Icon
            VStack(alignment: .center, spacing: 8) {
                if let icon = timeBlock.icon {
                    Text(icon)
                        .font(.system(size: 24))
                } else {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.premiumBlue, Color.premiumPurple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                
                VStack(spacing: 2) {
                    Text(timeBlock.shortFormattedTimeRange)
                        .font(.system(size: 12, weight: .semibold, design: .monospaced))
                        .foregroundStyle(.white)
                    
                    Text(timeBlock.formattedDuration)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(Color.premiumTextTertiary)
                }
            }
            .frame(width: 80)
            
            // Content
            VStack(alignment: .leading, spacing: 6) {
                Text(timeBlock.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                
                if let category = timeBlock.category {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(categoryGradient(for: category))
                            .frame(width: 6, height: 6)
                        
                        Text(category)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Color.premiumTextSecondary)
                    }
                }
                
                if let notes = timeBlock.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.system(size: 12))
                        .foregroundStyle(Color.premiumTextTertiary)
                        .lineLimit(2)
                }
            }
            
            Spacer()
            
            // Action Buttons
            HStack(spacing: 12) {
                Button(action: onEdit) {
                    Image(systemName: "pencil.circle.fill")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.premiumBlue, Color.premiumPurple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                
                Button(action: onDelete) {
                    Image(systemName: "trash.circle.fill")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.premiumError, Color.premiumError.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
            }
            .opacity(showActions ? 1 : 0)
            .animation(.spring(response: 0.3), value: showActions)
        }
        .padding(20)
        .glassMorphism(cornerRadius: 16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(showActions ? 0.3 : 0.15),
                            Color.white.opacity(0.05)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .onTapGesture {
            withAnimation(.spring(response: 0.3)) {
                showActions.toggle()
            }
        }
        .onLongPressGesture(
            minimumDuration: 0.1,
            pressing: { pressing in
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = pressing
                }
            },
            perform: {}
        )
    }
    
    private func categoryGradient(for category: String) -> LinearGradient {
        let colors: [Color] = switch category.lowercased() {
        case "work": [Color.premiumBlue, Color.premiumPurple]
        case "personal": [Color.premiumGreen, Color.premiumTeal]
        case "health": [Color.premiumGreen, Color.premiumBlue]
        case "learning": [Color.premiumPurple, Color.premiumBlue]
        case "social": [Color.premiumTeal, Color.premiumBlue]
        default: [Color.premiumTextSecondary, Color.premiumTextTertiary]
        }
        
        return LinearGradient(
            colors: colors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - Previews
#Preview("Schedule Builder") {
    ScheduleBuilderView()
        .modelContainer(for: [TimeBlock.self, DailyProgress.self], inMemory: true)
        .preferredColorScheme(.dark)
}
