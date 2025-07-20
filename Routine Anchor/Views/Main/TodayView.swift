//
//  TodayView.swift
//  Routine Anchor
//
//  Created by Christopher Simonson on 7/19/25.
//
import SwiftUI
import SwiftData

struct TodayView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: TodayViewModel?
    
    // MARK: - State
    @State private var showingSettings = false
    @State private var showingSummary = false
    @State private var selectedTimeBlock: TimeBlock?
    @State private var showingActionSheet = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Color.backgroundPrimary
                    .ignoresSafeArea()
                
                if viewModel?.hasScheduledBlocks == true {
                    mainContent
                } else {
                    emptyStateView
                }
            }
            .navigationTitle("Today")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                            .foregroundColor(Color.primaryBlue)
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    if viewModel?.shouldShowSummary == true {
                        Button {
                            showingSummary = true
                        } label: {
                            Image(systemName: "chart.pie")
                                .foregroundColor(Color.primaryBlue)
                        }
                    }
                }
            }
            .refreshable {
                await viewModel?.pullToRefresh()
            }
            .onAppear {
                setupViewModel()
                viewModel?.startAutoRefresh()
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
            .sheet(isPresented: $showingSummary) {
                DailySummaryView()
                    .onDisappear {
                        viewModel?.markDayAsReviewed()
                    }
            }
            .confirmationDialog(
                "Choose Action",
                isPresented: $showingActionSheet,
                titleVisibility: .visible,
                presenting: selectedTimeBlock
            ) { timeBlock in
                actionSheetButtons(for: timeBlock)
            }
        }
        .alert("Error", isPresented: .constant(viewModel?.errorMessage != nil)) {
            Button("OK") {
                viewModel?.clearError()
            }
            Button("Retry") {
                viewModel?.retryLastOperation()
            }
        } message: {
            Text(viewModel?.errorMessage ?? "")
        }
    }
    
    // MARK: - Main Content
    private var mainContent: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                // Progress Section
                if let viewModel = viewModel {
                    progressSection(viewModel)
                    
                    // Focus Section
                    if let focusText = viewModel.getFocusModeText() {
                        focusSection(focusText, viewModel: viewModel)
                    }
                    
                    // Time Blocks List
                    timeBlocksList(viewModel)
                    
                    // Motivational Section
                    motivationalSection(viewModel)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
        }
    }
    
    // MARK: - Progress Section
    private func progressSection(_ viewModel: TodayViewModel) -> some View {
        VStack(spacing: 12) {
            HStack {
                Text("Today's Progress")
                    .font(TypographyConstants.Headers.sectionHeader)
                    .foregroundColor(Color.textPrimary)
                
                Spacer()
                
                Text(viewModel.formattedProgressPercentage)
                    .font(TypographyConstants.UI.progress)
                    .foregroundColor(Color.primaryBlue)
                    .fontWeight(.semibold)
            }
            
            // Progress Bar
            ProgressView(value: viewModel.progressPercentage)
                .progressViewStyle(CustomProgressViewStyle())
            
            // Progress Details
            HStack {
                Text(viewModel.completionSummary)
                    .font(TypographyConstants.Body.secondary)
                    .foregroundColor(Color.textSecondary)
                
                Spacer()
                
                Text(viewModel.timeSummary)
                    .font(TypographyConstants.Body.secondary)
                    .foregroundColor(Color.textSecondary)
            }
        }
        .padding(20)
        .background(Color.cardBackground)
        .cornerRadius(16)
        .shadow(color: ColorConstants.UI.cardShadow, radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Focus Section
    private func focusSection(_ text: String, viewModel: TodayViewModel) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "target")
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(Color.primaryBlue)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Focus Mode")
                    .font(TypographyConstants.UI.caption)
                    .foregroundColor(Color.textSecondary)
                    .textCase(.uppercase)
                    .tracking(0.5)
                
                Text(text)
                    .font(TypographyConstants.Body.emphasized)
                    .foregroundColor(Color.textPrimary)
            }
            
            Spacer()
            
            if let currentBlock = viewModel.getCurrentBlock(),
               let remainingTime = viewModel.remainingTimeForCurrentBlock() {
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Time Left")
                        .font(TypographyConstants.UI.caption)
                        .foregroundColor(Color.textSecondary)
                    
                    Text(remainingTime)
                        .font(TypographyConstants.UI.timeBlock)
                        .foregroundColor(Color.warningOrange)
                        .fontWeight(.medium)
                }
            } else if let nextTime = viewModel.timeUntilNextBlock() {
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Starts In")
                        .font(TypographyConstants.UI.caption)
                        .foregroundColor(Color.textSecondary)
                    
                    Text(nextTime)
                        .font(TypographyConstants.UI.timeBlock)
                        .foregroundColor(Color.primaryBlue)
                        .fontWeight(.medium)
                }
            }
        }
        .padding(16)
        .background(Color.appBackgroundSecondary)
        .cornerRadius(12)
    }
    
    // MARK: - Time Blocks List
    private func timeBlocksList(_ viewModel: TodayViewModel) -> some View {
        VStack(spacing: 0) {
            HStack {
                Text("Schedule")
                    .font(TypographyConstants.Headers.sectionHeader)
                    .foregroundColor(Color.textPrimary)
                
                Spacer()
                
                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
            .padding(.bottom, 12)
            
            LazyVStack(spacing: 8) {
                ForEach(viewModel.sortedTimeBlocks) { timeBlock in
                    TimeBlockRowView(
                        timeBlock: timeBlock,
                        onTap: {
                            handleTimeBlockTap(timeBlock)
                        }
                    )
                }
            }
        }
    }
    
    // MARK: - Motivational Section
    private func motivationalSection(_ viewModel: TodayViewModel) -> some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: viewModel.performanceLevel.emoji)
                    .font(.system(size: 24))
                
                Text(viewModel.motivationalMessage)
                    .font(TypographyConstants.Body.secondary)
                    .foregroundColor(Color.textSecondary)
                    .multilineTextAlignment(.center)
                
                Spacer()
            }
            
            if viewModel.isDayComplete {
                PrimaryButton("View Summary") {
                    showingSummary = true
                }
                .buttonSize(.medium)
            }
        }
        .padding(20)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    viewModel.performanceLevel.color.opacity(0.1),
                    Color.clear
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(viewModel.performanceLevel.color.opacity(0.3), lineWidth: 1)
        )
    }
    
    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 60, weight: .thin))
                .foregroundColor(Color.textSecondary)
                .opacity(0.6)
            
            VStack(spacing: 12) {
                Text("No Schedule Today")
                    .font(TypographyConstants.Headers.screenTitle)
                    .foregroundColor(Color.textPrimary)
                
                Text("Create your first routine to get started with time-blocked productivity.")
                    .font(TypographyConstants.Body.description)
                    .foregroundColor(Color.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .padding(.horizontal, 40)
            }
            
            Spacer()
            
            VStack(spacing: 12) {
                NavigationLink(destination: ScheduleBuilderView()) {
                    HStack {
                        Text("Create Schedule")
                            .font(TypographyConstants.UI.button)
                            .fontWeight(.semibold)
                        
                        Image(systemName: "arrow.right")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(ColorConstants.Palette.onPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(ColorConstants.Palette.primary)
                    .cornerRadius(12)
                }
                
                Button("Import Template") {
                    // TODO: Implement template import
                }
                .font(TypographyConstants.UI.button)
                .foregroundColor(Color.primaryBlue)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
    }
    
    // MARK: - Helper Methods
    
    private func setupViewModel() {
        let dataManager = DataManager(modelContext: modelContext)
        viewModel = TodayViewModel(dataManager: dataManager)
    }
    
    private func handleTimeBlockTap(_ timeBlock: TimeBlock) {
        guard let viewModel = viewModel else { return }
        
        switch timeBlock.status {
        case .inProgress:
            selectedTimeBlock = timeBlock
            showingActionSheet = true
        case .notStarted:
            if timeBlock.isCurrentlyActive {
                viewModel.startTimeBlock(timeBlock)
            }
        case .completed, .skipped:
            // Could show details or allow undo in future
            break
        }
    }
    
    @ViewBuilder
    private func actionSheetButtons(for timeBlock: TimeBlock) -> some View {
        Button("Mark as Completed") {
            viewModel?.markBlockCompleted(timeBlock)
        }
        
        Button("Mark as Skipped") {
            viewModel?.markBlockSkipped(timeBlock)
        }
        
        Button("Cancel", role: .cancel) {}
    }
}

// MARK: - Custom Progress View Style
struct CustomProgressViewStyle: ProgressViewStyle {
    func makeBody(configuration: Configuration) -> some View {
        ZStack(alignment: .leading) {
            // Track
            RoundedRectangle(cornerRadius: 4)
                .fill(ColorConstants.UI.progressTrack)
                .frame(height: 8)
            
            // Progress
            RoundedRectangle(cornerRadius: 4)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.primaryBlue,
                            Color.primaryBlue.opacity(0.8)
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(
                    width: (configuration.fractionCompleted ?? 0) * UIScreen.main.bounds.width * 0.85,
                    height: 8
                )
                .animation(.easeInOut(duration: 0.5), value: configuration.fractionCompleted)
        }
    }
}

// MARK: - Previews
#Preview("Today View with Data") {
    TodayView()
        .modelContainer(for: [TimeBlock.self, DailyProgress.self], inMemory: true)
}

#Preview("Today View Empty") {
    TodayView()
        .modelContainer(for: [TimeBlock.self, DailyProgress.self], inMemory: true)
}
