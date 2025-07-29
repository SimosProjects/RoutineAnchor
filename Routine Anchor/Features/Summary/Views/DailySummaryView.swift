//
//  PremiumDailySummaryView.swift
//  Routine Anchor - Premium Version (iOS 17+ Optimized)
//
import SwiftUI
import SwiftData

struct PremiumDailySummaryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    // iOS 17+ Pattern: Direct initialization with @State
    @State private var viewModel: DailySummaryViewModel
    @State private var particleSystem = ParticleSystem()
    
    // MARK: - State
    @State private var selectedDate = Date()
    @State private var showingDatePicker = false
    @State private var showingShareSheet = false
    @State private var isVisible = false
    @State private var animationPhase = 0
    @State private var selectedRating = 0
    @State private var dayNotes = ""
    
    // MARK: - Initialization
    init() {
        // Initialize with placeholder - will be configured in .task
        let placeholderDataManager = DataManager(modelContext: ModelContext(ModelContainer.shared))
        _viewModel = State(initialValue: DailySummaryViewModel(dataManager: placeholderDataManager))
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
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Header
                    headerSection
                    
                    // Content based on state
                    if viewModel.isLoading {
                        loadingState
                    } else if viewModel.dailyProgress != nil {
                        mainContent
                    } else {
                        emptyState
                    }
                }
                .padding(.vertical, 20)
            }
        }
        .navigationBarHidden(true)
        .task {
            await configureViewModel()
            startAnimations()
        }
        .sheet(isPresented: $showingDatePicker) {
            datePickerSheet
        }
        .sheet(isPresented: $showingShareSheet) {
            if let progress = viewModel.dailyProgress {
                ShareSheet(activityItems: [generateShareText(for: progress)])
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Back button and title
            HStack {
                Button(action: { dismiss() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Back")
                            .font(.system(size: 16, weight: .medium))
                    }
                    .foregroundStyle(Color.premiumTextSecondary)
                }
                
                Spacer()
                
                // Date selector
                Button(action: { showingDatePicker = true }) {
                    HStack(spacing: 8) {
                        Text(selectedDate.formatted(.dateTime.weekday(.wide).month(.abbreviated).day()))
                            .font(.system(size: 16, weight: .semibold))
                        Image(systemName: "calendar")
                            .font(.system(size: 14))
                    }
                    .foregroundStyle(Color.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.15))
                    )
                }
            }
            .padding(.horizontal, 24)
            
            // Title
            Text("Daily Summary")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.white, Color.white.opacity(0.8)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .opacity(isVisible ? 1 : 0)
                .offset(y: isVisible ? 0 : 20)
        }
    }
    
    // MARK: - Main Content
    private var mainContent: some View {
        VStack(spacing: 24) {
            // Progress Overview Card
            if let progress = viewModel.dailyProgress {
                ProgressOverviewCard(progress: progress)
                    .padding(.horizontal, 24)
                    .opacity(isVisible ? 1 : 0)
                    .scaleEffect(isVisible ? 1 : 0.9)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1), value: isVisible)
            }
            
            // Time Blocks Summary
            if !viewModel.todaysTimeBlocks.isEmpty {
                TimeBlocksSummaryCard(timeBlocks: viewModel.todaysTimeBlocks)
                    .padding(.horizontal, 24)
                    .opacity(isVisible ? 1 : 0)
                    .scaleEffect(isVisible ? 1 : 0.9)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2), value: isVisible)
            }
            
            // Insights
            if let insights = viewModel.generateInsights() {
                InsightsCard(insights: insights)
                    .padding(.horizontal, 24)
                    .opacity(isVisible ? 1 : 0)
                    .scaleEffect(isVisible ? 1 : 0.9)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.3), value: isVisible)
            }
            
            // Day Rating
            DayRatingCard(selectedRating: $selectedRating, dayNotes: $dayNotes)
                .padding(.horizontal, 24)
                .opacity(isVisible ? 1 : 0)
                .scaleEffect(isVisible ? 1 : 0.9)
                .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.4), value: isVisible)
                .onChange(of: selectedRating) { _, newValue in
                    saveDayRatingAndNotes()
                }
                .onChange(of: dayNotes) { _, _ in
                    saveDayRatingAndNotes()
                }
            
            // Action buttons
            actionButtons
                .padding(.horizontal, 24)
                .opacity(isVisible ? 1 : 0)
                .offset(y: isVisible ? 0 : 20)
                .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.5), value: isVisible)
        }
    }
    
    // MARK: - Action Buttons
    private var actionButtons: some View {
        VStack(spacing: 16) {
            PremiumPrimaryButton(
                title: "Share Summary",
                icon: "square.and.arrow.up"
            ) {
                showingShareSheet = true
            }
            
            PremiumSecondaryButton(
                title: "Plan Tomorrow",
                icon: "arrow.right.circle",
                style: .ghost
            ) {
                planTomorrow()
            }
        }
        .padding(.bottom, 40)
    }
    
    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 60))
                .foregroundStyle(Color.white.opacity(0.3))
            
            Text("No data for this day")
                .font(.system(size: 24, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.white.opacity(0.8))
            
            Text("Create some time blocks to track your progress")
                .font(.system(size: 16))
                .foregroundStyle(Color.white.opacity(0.5))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Spacer()
        }
    }
    
    // MARK: - Loading State
    private var loadingState: some View {
        VStack(spacing: 20) {
            Spacer()
            
            // Elegant loading animation
            ZStack {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(Color.premiumBlue.opacity(0.3))
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
            
            Text("Loading your summary...")
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundStyle(Color.white.opacity(0.7))
            
            Spacer()
        }
    }
    
    // MARK: - Date Picker Sheet
    private var datePickerSheet: some View {
        NavigationView {
            DatePicker(
                "Select Date",
                selection: $selectedDate,
                in: ...Date(),
                displayedComponents: .date
            )
            .datePickerStyle(.graphical)
            .padding()
            .navigationTitle("Select Date")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        showingDatePicker = false
                        Task {
                            await viewModel.loadData(for: selectedDate)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func configureViewModel() async {
        // Create proper DataManager with current context
        let dataManager = DataManager(modelContext: modelContext)
        
        // Reinitialize ViewModel with proper dependencies
        viewModel = DailySummaryViewModel(dataManager: dataManager, date: selectedDate)
        
        // Setup refresh observer
        viewModel.setupRefreshObserver()
    }
    
    private func startAnimations() {
        particleSystem.startEmitting()
        
        withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
            animationPhase = 1
        }
        
        withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.1)) {
            isVisible = true
        }
    }
    
    private func saveDayRatingAndNotes() {
        if selectedRating > 0 || !dayNotes.isEmpty {
            viewModel.saveDayRatingAndNotes(rating: selectedRating, notes: dayNotes)
            HapticManager.shared.lightImpact()
        }
    }
    
    private func planTomorrow() {
        HapticManager.shared.premiumImpact()
        // Navigate to schedule builder for tomorrow
        dismiss()
    }
    
    private func generateShareText(for progress: DailyProgress) -> String {
        var text = "📊 Daily Summary for \(selectedDate.formatted(.dateTime.weekday(.wide).month(.abbreviated).day()))\n\n"
        
        text += "✅ Completed: \(progress.completedBlocks) blocks\n"
        text += "⏰ Total Focus Time: \(formatTime(progress.totalFocusMinutes))\n"
        text += "📈 Completion Rate: \(Int(progress.completionRate * 100))%\n"
        
        if selectedRating > 0 {
            text += "\n⭐ Day Rating: \(selectedRating)/5\n"
        }
        
        if !dayNotes.isEmpty {
            text += "\n📝 Notes: \(dayNotes)\n"
        }
        
        text += "\n#RoutineAnchor #DailyProgress #Productivity"
        
        return text
    }
    
    private func formatTime(_ minutes: Int) -> String {
        let hours = minutes / 60
        let mins = minutes % 60
        
        if hours > 0 && mins > 0 {
            return "\(hours)h \(mins)m"
        } else if hours > 0 {
            return "\(hours)h"
        } else {
            return "\(mins)m"
        }
    }
}
