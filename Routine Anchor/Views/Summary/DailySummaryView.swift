//
//  DailySummaryView.swift
//  Routine Anchor
//
//  Created by Christopher Simonson on 7/19/25.
//
import SwiftUI
import SwiftData

struct DailySummaryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: DailySummaryViewModel?
    
    // MARK: - State
    @State private var selectedRating: Int = 0
    @State private var dayNotes = ""
    @State private var showingShareSheet = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 24) {
                    if let viewModel = viewModel,
                       let progress = viewModel.dailyProgress {
                        
                        // Header Section
                        headerSection(progress)
                        
                        // Progress Circle
                        progressSection(progress)
                        
                        // Statistics Cards
                        statisticsSection(progress)
                        
                        // Task Breakdown
                        taskBreakdownSection(viewModel)
                        
                        // Performance Insights
                        insightsSection(progress)
                        
                        // Day Rating
                        ratingSection(progress)
                        
                        // Notes Section
                        notesSection(progress)
                        
                        // Actions
                        actionsSection(viewModel)
                        
                    } else {
                        // Loading or No Data
                        emptyStateView
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
            }
            .navigationTitle("Daily Summary")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(Color.primaryBlue)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingShareSheet = true
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(Color.primaryBlue)
                    }
                }
            }
            .onAppear {
                setupViewModel()
            }
            .onDisappear {
                saveDayRatingAndNotes()
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            if let viewModel = viewModel {
                ShareSummaryView(viewModel: viewModel)
            }
        }
    }
    
    // MARK: - Header Section
    private func headerSection(_ progress: DailyProgress) -> some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(progress.formattedDate)
                        .font(TypographyConstants.Headers.screenTitle)
                        .foregroundColor(Color.textPrimary)
                    
                    Text(progress.dayOfWeek)
                        .font(TypographyConstants.Body.secondary)
                        .foregroundColor(Color.textSecondary)
                }
                
                Spacer()
                
                Text(progress.performanceLevel.emoji)
                    .font(.system(size: 40))
            }
            
            Text(progress.motivationalMessage)
                .font(TypographyConstants.Body.description)
                .foregroundColor(Color.textSecondary)
                .multilineTextAlignment(.center)
                .lineLimit(3)
        }
        .padding(20)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    progress.performanceLevel.color.opacity(0.1),
                    Color.clear
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(progress.performanceLevel.color.opacity(0.3), lineWidth: 1)
        )
    }
    
    // MARK: - Progress Section
    private func progressSection(_ progress: DailyProgress) -> some View {
        VStack(spacing: 16) {
            // Main Progress Circle
            ZStack {
                Circle()
                    .stroke(ColorConstants.UI.progressTrack, lineWidth: 12)
                    .frame(width: 160, height: 160)
                
                Circle()
                    .trim(from: 0.0, to: progress.completionPercentage)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                progress.performanceLevel.color,
                                progress.performanceLevel.color.opacity(0.7)
                            ]),
                            startPoint: .topTrailing,
                            endPoint: .bottomLeading
                        ),
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .frame(width: 160, height: 160)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 1.0), value: progress.completionPercentage)
                
                VStack(spacing: 4) {
                    Text(progress.formattedCompletionPercentage)
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(progress.performanceLevel.color)
                    
                    Text("Completed")
                        .font(TypographyConstants.UI.caption)
                        .foregroundColor(Color.textSecondary)
                }
            }
            
            // Summary Text
            VStack(spacing: 4) {
                Text(progress.completionSummary)
                    .font(TypographyConstants.Headers.cardTitle)
                    .foregroundColor(Color.textPrimary)
                
                if progress.totalPlannedMinutes > 0 {
                    Text(progress.timeSummary)
                        .font(TypographyConstants.Body.secondary)
                        .foregroundColor(Color.textSecondary)
                }
            }
        }
        .padding(24)
        .background(Color.cardBackground)
        .cornerRadius(20)
        .shadow(color: ColorConstants.UI.cardShadow, radius: 8, x: 0, y: 4)
    }
    
    // MARK: - Statistics Section
    private func statisticsSection(_ progress: DailyProgress) -> some View {
        HStack(spacing: 12) {
            StatCard(
                title: "Completed",
                value: "\(progress.completedBlocks)",
                subtitle: "blocks",
                color: Color.successGreen,
                icon: "checkmark.circle.fill"
            )
            
            StatCard(
                title: "Skipped",
                value: "\(progress.skippedBlocks)",
                subtitle: "blocks",
                color: Color.errorRed,
                icon: "xmark.circle.fill"
            )
            
            StatCard(
                title: "Time",
                value: "\(progress.completedMinutes / 60)h",
                subtitle: "\(progress.completedMinutes % 60)m",
                color: Color.primaryBlue,
                icon: "clock.fill"
            )
        }
    }
    
    // MARK: - Task Breakdown Section
    private func taskBreakdownSection(_ viewModel: DailySummaryViewModel) -> some View {
        VStack(spacing: 16) {
            HStack {
                Text("Task Breakdown")
                    .font(TypographyConstants.Headers.sectionHeader)
                    .foregroundColor(Color.textPrimary)
                
                Spacer()
            }
            
            LazyVStack(spacing: 8) {
                ForEach(viewModel.todaysTimeBlocks) { timeBlock in
                    TaskBreakdownRow(timeBlock: timeBlock)
                }
            }
        }
        .padding(20)
        .background(Color.cardBackground)
        .cornerRadius(16)
        .shadow(color: ColorConstants.UI.cardShadow, radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Insights Section
    private func insightsSection(_ progress: DailyProgress) -> some View {
        VStack(spacing: 16) {
            HStack {
                Text("Insights & Tips")
                    .font(TypographyConstants.Headers.sectionHeader)
                    .foregroundColor(Color.textPrimary)
                
                Spacer()
            }
            
            VStack(spacing: 12) {
                ForEach(Array(progress.suggestions.enumerated()), id: \.offset) { index, suggestion in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "lightbulb")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color.warningOrange)
                            .frame(width: 20, height: 20)
                        
                        Text(suggestion)
                            .font(TypographyConstants.Body.secondary)
                            .foregroundColor(Color.textSecondary)
                            .multilineTextAlignment(.leading)
                        
                        Spacer()
                    }
                    
                    if index < progress.suggestions.count - 1 {
                        Divider()
                    }
                }
            }
        }
        .padding(20)
        .background(Color.cardBackground)
        .cornerRadius(16)
        .shadow(color: ColorConstants.UI.cardShadow, radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Rating Section
    private func ratingSection(_ progress: DailyProgress) -> some View {
        VStack(spacing: 16) {
            HStack {
                Text("Rate Your Day")
                    .font(TypographyConstants.Headers.sectionHeader)
                    .foregroundColor(Color.textPrimary)
                
                Spacer()
            }
            
            HStack(spacing: 8) {
                ForEach(1...5, id: \.self) { rating in
                    Button {
                        selectedRating = rating
                        HapticManager.shared.lightImpact()
                    } label: {
                        Image(systemName: selectedRating >= rating ? "star.fill" : "star")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(selectedRating >= rating ? Color.warningOrange : Color.textSecondary)
                    }
                }
                
                Spacer()
                
                if selectedRating > 0 {
                    Text(ratingDescription)
                        .font(TypographyConstants.Body.secondary)
                        .foregroundColor(Color.textSecondary)
                }
            }
        }
        .padding(20)
        .background(Color.cardBackground)
        .cornerRadius(16)
        .shadow(color: ColorConstants.UI.cardShadow, radius: 4, x: 0, y: 2)
        .onAppear {
            selectedRating = progress.dayRating ?? 0
        }
    }
    
    // MARK: - Notes Section
    private func notesSection(_ progress: DailyProgress) -> some View {
        VStack(spacing: 16) {
            HStack {
                Text("Day Notes")
                    .font(TypographyConstants.Headers.sectionHeader)
                    .foregroundColor(Color.textPrimary)
                
                Spacer()
            }
            
            TextField("How did your day go? Any insights or reflections?", text: $dayNotes, axis: .vertical)
                .font(TypographyConstants.Body.secondary)
                .lineLimit(3...6)
                .textFieldStyle(.roundedBorder)
                .onAppear {
                    dayNotes = progress.dayNotes ?? ""
                }
        }
        .padding(20)
        .background(Color.cardBackground)
        .cornerRadius(16)
        .shadow(color: ColorConstants.UI.cardShadow, radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Actions Section
    private func actionsSection(_ viewModel: DailySummaryViewModel) -> some View {
        VStack(spacing: 12) {
            if let progress = viewModel.dailyProgress, !progress.isDayComplete {
                SecondaryButton("Back to Today") {
                    dismiss()
                }
                .buttonStyle(.filled)
            }
            
            PrimaryButton("Plan Tomorrow") {
                // Navigate to schedule builder for tomorrow
                planTomorrow()
            }
            .buttonSize(.medium)
            
            if let progress = viewModel.dailyProgress, progress.isDayComplete {
                Text("🎉 Congratulations on completing your day!")
                    .font(TypographyConstants.Body.secondary)
                    .foregroundColor(Color.successGreen)
                    .multilineTextAlignment(.center)
                    .padding(.top, 8)
            }
        }
        .padding(.bottom, 20)
    }
    
    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "chart.pie")
                .font(.system(size: 60, weight: .thin))
                .foregroundColor(Color.textSecondary)
                .opacity(0.6)
            
            VStack(spacing: 12) {
                Text("No Data Yet")
                    .font(TypographyConstants.Headers.screenTitle)
                    .foregroundColor(Color.textPrimary)
                
                Text("Complete some time blocks to see your daily summary.")
                    .font(TypographyConstants.Body.description)
                    .foregroundColor(Color.textSecondary)
                    .multilineTextAlignment(.center)
            }
            
            PrimaryButton("Start Your Day") {
                dismiss()
            }
            .buttonSize(.medium)
        }
        .padding(40)
    }
    
    // MARK: - Computed Properties
    
    private var ratingDescription: String {
        switch selectedRating {
        case 1: return "Poor"
        case 2: return "Fair"
        case 3: return "Good"
        case 4: return "Great"
        case 5: return "Excellent"
        default: return ""
        }
    }
    
    // MARK: - Helper Methods
    
    private func setupViewModel() {
        let dataManager = DataManager(modelContext: modelContext)
        viewModel = DailySummaryViewModel(dataManager: dataManager)
    }
    
    private func saveDayRatingAndNotes() {
        guard let progress = viewModel?.dailyProgress else { return }
        
        if selectedRating > 0 {
            progress.setDayRating(selectedRating)
        }
        
        if !dayNotes.isEmpty {
            progress.setDayNotes(dayNotes)
        }
        
        viewModel?.saveDayRatingAndNotes(rating: selectedRating, notes: dayNotes)
    }
    
    private func planTomorrow() {
        // TODO: Navigate to schedule builder for tomorrow's date
        dismiss()
    }
}

// MARK: - Stat Card Component
struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(color)
            
            VStack(spacing: 2) {
                Text(title)
                    .font(TypographyConstants.UI.caption)
                    .foregroundColor(Color.textPrimary)
                    .fontWeight(.medium)
                
                Text(subtitle)
                    .font(TypographyConstants.UI.caption)
                    .foregroundColor(Color.textSecondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(Color.cardBackground)
        .cornerRadius(12)
        .shadow(color: ColorConstants.UI.cardShadow, radius: 2, x: 0, y: 1)
    }
}

// MARK: - Task Breakdown Row
struct TaskBreakdownRow: View {
    let timeBlock: TimeBlock
    
    var body: some View {
        HStack(spacing: 12) {
            timeBlock.status.statusIndicator
                .frame(width: 20, height: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(timeBlock.title)
                    .font(TypographyConstants.Body.emphasized)
                    .foregroundColor(Color.textPrimary)
                    .lineLimit(1)
                
                Text(timeBlock.shortFormattedTimeRange)
                    .font(TypographyConstants.UI.caption)
                    .foregroundColor(Color.textSecondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(timeBlock.formattedDuration)
                    .font(TypographyConstants.UI.caption)
                    .foregroundColor(Color.textSecondary)
                
                Text(timeBlock.status.shortDisplayName)
                    .font(TypographyConstants.UI.caption)
                    .foregroundColor(timeBlock.status.color)
                    .fontWeight(.medium)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Share Summary View
struct ShareSummaryView: View {
    let viewModel: DailySummaryViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Share Your Progress")
                    .font(TypographyConstants.Headers.screenTitle)
                    .foregroundColor(Color.textPrimary)
                    .padding(.top, 20)
                
                Text("Share your daily routine progress with friends or save it for your records.")
                    .font(TypographyConstants.Body.description)
                    .foregroundColor(Color.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                
                // Preview of shareable content
                ScrollView {
                    Text(viewModel.generateShareableText())
                        .font(TypographyConstants.Body.secondary)
                        .foregroundColor(Color.textSecondary)
                        .padding(16)
                        .background(Color.appBackgroundSecondary)
                        .cornerRadius(12)
                }
                .frame(maxHeight: 200)
                .padding(.horizontal, 20)
                
                Spacer()
                
                VStack(spacing: 12) {
                    PrimaryButton("Share Progress") {
                        shareProgress()
                    }
                    
                    SecondaryButton("Copy to Clipboard") {
                        copyToClipboard()
                    }
                    .buttonStyle(.outlined)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
            .navigationTitle("Share")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(Color.primaryBlue)
                }
            }
        }
    }
    
    private func shareProgress() {
        let text = viewModel.generateShareableText()
        let activityVC = UIActivityViewController(
            activityItems: [text],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(activityVC, animated: true)
        }
        
        dismiss()
    }
    
    private func copyToClipboard() {
        let text = viewModel.generateShareableText()
        UIPasteboard.general.string = text
        
        HapticManager.shared.success()
        dismiss()
    }
}

// MARK: - Previews
#Preview("Daily Summary with Data") {
    DailySummaryView()
        .modelContainer(for: [TimeBlock.self, DailyProgress.self], inMemory: true)
}

#Preview("Stat Card") {
    StatCard(
        title: "Completed",
        value: "8",
        subtitle: "blocks",
        color: Color.successGreen,
        icon: "checkmark.circle.fill"
    )
    .padding()
}

#Preview("Task Breakdown Row") {
    let sampleBlock = TimeBlock(
        title: "Morning Routine",
        startTime: Date(),
        endTime: Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
    )
    
    return TaskBreakdownRow(timeBlock: sampleBlock)
        .padding()
}
