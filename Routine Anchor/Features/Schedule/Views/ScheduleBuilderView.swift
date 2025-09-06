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
    
    // Convenience
    private var theme: Theme { themeManager?.currentTheme ?? Theme.defaultTheme }
    
    var body: some View {
        ZStack {
            ThemedAnimatedBackground()
                .ignoresSafeArea()
                .overlay(
                    // Subtle vignette from theme
                    RadialGradient(
                        colors: [
                            theme.colorScheme.todayHeroVignette.color,
                            .clear
                        ],
                        center: .top,
                        startRadius: 0,
                        endRadius: 520
                    )
                    .opacity(theme.colorScheme.todayHeroVignetteOpacity)
                    .blendMode(.softLight)
                    .ignoresSafeArea()
                )
            
            // Static mesh + particles tinted from theme
            StaticMeshBackground()
                .opacity(0.35)
                .allowsHitTesting(false)
            StaticParticles()
                .allowsHitTesting(false)
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    headerSection
                    
                    if let viewModel {
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
            .refreshable { viewModel?.loadTimeBlocks() }
        }
        .toolbar(.hidden, for: .navigationBar)
        .onAppear { setupViewModel() }
        .onReceive(NotificationCenter.default.publisher(for: .showAddTimeBlockFromTab)) { _ in
            showingAddBlock = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .refreshScheduleView)) { _ in
            viewModel?.loadTimeBlocks()
        }
        .onReceive(NotificationCenter.default.publisher(for: .showAddTimeBlock)) { _ in
            showingAddBlock = true
        }
        .confirmationDialog("Reset Today's Progress",
                            isPresented: $showingResetConfirmation,
                            titleVisibility: .visible) {
            Button("Reset Progress", role: .destructive) { viewModel?.resetTodaysProgress() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will reset all time blocks back to 'Not Started' for today. This action cannot be undone.")
        }
        .confirmationDialog("Delete Time Block",
                            isPresented: $showingDeleteConfirmation,
                            titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                if let block = blockToDelete {
                    viewModel?.deleteTimeBlock(block)
                    blockToDelete = nil
                }
            }
            Button("Cancel", role: .cancel) { blockToDelete = nil }
        } message: {
            Text("Are you sure you want to delete this time block?")
        }
        .sheet(isPresented: $showingAddBlock) {
            AddTimeBlockView(existingTimeBlocks: viewModel!.timeBlocks) { title, startTime, endTime, notes, category in
                viewModel?.addTimeBlock(title: title,
                                        startTime: startTime,
                                        endTime: endTime,
                                        notes: notes,
                                        category: category)
            }
            .environment(\.themeManager, themeManager)
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingEditBlock) {
            if let block = selectedBlock {
                EditTimeBlockView(timeBlock: block, existingTimeBlocks: viewModel!.timeBlocks) { updated in
                    viewModel?.updateTimeBlock(updated)
                }
                .environment(\.themeManager, themeManager)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
            }
        }
        .actionSheet(isPresented: $showingQuickAdd) { quickAddActionSheet }
    }
    
    // MARK: - Header
    private var headerSection: some View {
        let hasBlocks = viewModel?.hasTimeBlocks ?? false
        
        return VStack(spacing: 20) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Schedule Builder")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [theme.colorScheme.workflowPrimary.color,
                                         theme.colorScheme.organizationAccent.color],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    
                    Text("Design your perfect routine")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(theme.secondaryTextColor)
                }
                Spacer()
                
                // Only show when there is something to reset
                if hasBlocks {
                    Button {
                        HapticManager.shared.lightImpact()
                        showingResetConfirmation = true
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.system(size: 12, weight: .medium))
                            Text("Reset All")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundStyle(theme.colorScheme.errorColor.color)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            Capsule(style: .continuous)
                                .fill(theme.colorScheme.errorColor.color.opacity(0.12))
                        )
                        .overlay(
                            Capsule(style: .continuous)
                                .stroke(theme.colorScheme.border.color.opacity(0.6), lineWidth: 1)
                        )
                    }
                    .transition(.move(edge: .trailing).combined(with: .opacity))
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 60)
            .animation(.spring(response: 0.35, dampingFraction: 0.85), value: hasBlocks)
        }
    }

    
    // MARK: - Main Content
    private func mainContent(viewModel: ScheduleBuilderViewModel) -> some View {
        VStack(spacing: 24) {
            timeBlocksSection(viewModel: viewModel)
            actionButtonsSection(viewModel: viewModel)
                .padding(.bottom, 100)
        }
        .padding(.top, 32)
    }
    
    // MARK: - Time Blocks
    private func timeBlocksSection(viewModel: ScheduleBuilderViewModel) -> some View {
        VStack(spacing: 16) {
            HStack {
                Text("Your Schedule")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(theme.primaryTextColor)
                Spacer()
            }
            .padding(.horizontal, 24)
            
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
    
    // MARK: - Actions
    private func actionButtonsSection(viewModel: ScheduleBuilderViewModel) -> some View {
        VStack(spacing: 16) {
            // Use cyan→purple accent gradient to match Today
            DesignedButton(
                title: "Add Time Block",
                style: .secondary, // <— was .gradient (green); now accent (cyan→purple)
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
            
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                theme.colorScheme.workflowPrimary.color.opacity(0.4),
                                theme.colorScheme.organizationAccent.color.opacity(0.2),
                                .clear
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
                            colors: [theme.colorScheme.workflowPrimary.color,
                                     theme.colorScheme.organizationAccent.color],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .frame(height: 200)
            
            VStack(spacing: 16) {
                Text("Build Your Perfect Day")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [theme.colorScheme.workflowPrimary.color,
                                     theme.colorScheme.organizationAccent.color],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .multilineTextAlignment(.center)
                
                Text("Create time blocks to structure your day and build consistent, productive habits.")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(theme.secondaryTextColor)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 40)
            
            Spacer()
            
            VStack(spacing: 16) {
                DesignedButton(
                    title: "Add Your First Block",
                    style: .secondary,
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
    
    // MARK: - Loading
    private var loadingState: some View {
        VStack(spacing: 20) {
            Spacer()
            
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: theme.colorScheme.workflowPrimary.color))
                .scaleEffect(1.5)
            
            Text("Setting up your schedule...")
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundStyle(theme.secondaryTextColor)
            
            Spacer()
        }
    }
    
    // MARK: - Quick Add Sheet
    private var quickAddActionSheet: ActionSheet {
        ActionSheet(
            title: Text("Quick Add Templates"),
            message: Text("Choose a common time block to add"),
            buttons: [
                .default(Text("🌅 Morning Routine (7:00-8:00 AM)")) { viewModel?.addMorningRoutine() },
                .default(Text("💼 Work Session (9:00 AM-12:00 PM)")) { viewModel?.addWorkBlock() },
                .default(Text("🍽️ Lunch Break (12:00-1:00 PM)")) { viewModel?.addBreak() },
                .default(Text("✨ Custom Time Block")) { showingAddBlock = true },
                .cancel()
            ]
        )
    }
    
    // MARK: - Helpers
    private func setupViewModel() {
        guard viewModel == nil else {
            viewModel?.loadTimeBlocks()
            return
        }
        let dataManager = DataManager(modelContext: modelContext)
        viewModel = ScheduleBuilderViewModel(dataManager: dataManager)
    }
}

// MARK: - Simple Time Block Row
struct SimpleTimeBlockRow: View {
    let timeBlock: TimeBlock
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    @Environment(\.themeManager) private var themeManager
    @State private var isPressed = false
    
    private var theme: Theme { themeManager?.currentTheme ?? Theme.defaultTheme }
    
    private var accentColors: [Color] {
        switch timeBlock.status {
        case .notStarted: return [theme.colorScheme.organizationAccent.color, theme.colorScheme.workflowPrimary.color]
        case .inProgress: return [theme.colorScheme.workflowPrimary.color, theme.colorScheme.creativeSecondary.color]
        case .completed:  return [theme.colorScheme.actionSuccess.color, theme.colorScheme.creativeSecondary.color]
        case .skipped:    return [theme.colorScheme.errorColor.color, theme.colorScheme.warningColor.color]
        }
    }
    
    private var statusIcon: String {
        switch timeBlock.status {
        case .notStarted: "clock"
        case .inProgress: "play.fill"
        case .completed:  "checkmark"
        case .skipped:    "forward.fill"
        }
    }
    
    private var statusColor: Color {
        switch timeBlock.status {
        case .notStarted: return theme.secondaryTextColor.opacity(0.85)
        case .inProgress: return theme.colorScheme.workflowPrimary.color
        case .completed:  return theme.colorScheme.actionSuccess.color
        case .skipped:    return theme.colorScheme.warningColor.color
        }
    }
    
    var body: some View {
        HStack(spacing: 0) {
            // Left accent bar
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(LinearGradient(colors: accentColors, startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 5)
            
            HStack(spacing: 16) {
                // Time badge
                VStack(spacing: 2) {
                    Text(timeBlock.startTime.formatted(date: .omitted, time: .shortened))
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(theme.primaryTextColor)
                    
                    Text(timeBlock.formattedDuration)
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundStyle(theme.secondaryTextColor.opacity(0.85))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(theme.colorScheme.surface3.color)
                )
                
                // Title & notes
                VStack(alignment: .leading, spacing: 4) {
                    Text(timeBlock.title)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(theme.primaryTextColor)
                    
                    if let notes = timeBlock.notes, !notes.isEmpty {
                        Text(notes)
                            .font(.system(size: 12))
                            .foregroundStyle(theme.secondaryTextColor.opacity(0.85))
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                // Status
                Image(systemName: statusIcon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(statusColor)
                    .frame(width: 24, height: 24)
                    .background(statusColor.opacity(0.15))
                    .cornerRadius(6)
                
                // Actions
                HStack(spacing: 8) {
                    Button(action: onEdit) {
                        Image(systemName: "pencil")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(theme.colorScheme.workflowPrimary.color)
                            .frame(width: 32, height: 32)
                            .background(theme.colorScheme.workflowPrimary.color.opacity(0.15))
                            .cornerRadius(8)
                    }
                    
                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(theme.colorScheme.errorColor.color)
                            .frame(width: 32, height: 32)
                            .background(theme.colorScheme.errorColor.color.opacity(0.15))
                            .cornerRadius(8)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(theme.colorScheme.surface2.color.opacity(0.9))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(theme.colorScheme.divider.color, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.25), radius: isPressed ? 8 : 14, x: 0, y: isPressed ? 4 : 8)
        .scaleEffect(isPressed ? 0.97 : 1.0)
        .onTapGesture {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { isPressed = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { isPressed = false }
            }
        }
    }
}

// MARK: - Static Background Components

struct StaticMeshBackground: View {
    @Environment(\.themeManager) private var themeManager
    private var theme: Theme { themeManager?.currentTheme ?? Theme.defaultTheme }
    
    var body: some View {
        Canvas { context, size in
            let grid = 30
            let dot: CGFloat = 2
            
            for x in stride(from: 0, to: Int(size.width), by: grid) {
                for y in stride(from: 0, to: Int(size.height), by: grid) {
                    context.fill(
                        Path(ellipseIn: CGRect(x: CGFloat(x) - dot/2, y: CGFloat(y) - dot/2, width: dot, height: dot)),
                        with: .color(theme.colorScheme.divider.color.opacity(0.35))
                    )
                }
            }
        }
    }
}

struct StaticParticles: View {
    @Environment(\.themeManager) private var themeManager
    private var theme: Theme { themeManager?.currentTheme ?? Theme.defaultTheme }
    
    var body: some View {
        GeometryReader { geometry in
            ForEach(0..<10, id: \.self) { index in
                Circle()
                    .fill(theme.colorScheme.workflowPrimary.color.opacity(0.12))
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
