//
//  DailySummaryView.swift
//  Routine Anchor
//
//  Daily summary view showing completed tasks and statistics
//
import SwiftUI
import SwiftData

struct DailySummaryView: View {
    // MARK: - Properties
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var viewModel: DailySummaryViewModel
    @State private var selectedDate: Date
    @State private var showingDatePicker = false
    @State private var showingShareSheet = false
    @State private var isVisible = false
    @State private var animationPhase = 0
    @State private var particleSystem = ParticleSystem()
    
    // Rating & Notes
    @State private var selectedRating: Int = 0
    @State private var dayNotes: String = ""
    
    // MARK: - Initialization
    init(date: Date = Date()) {
        self._selectedDate = State(initialValue: date)
        self._viewModel = State(initialValue: DailySummaryViewModel(
            dataManager: DataManager(modelContext: ModelContext(try! ModelContainer(for: TimeBlock.self, DailyProgress.self))),
            date: date
        ))
    }
    
    // MARK: - Body
    var body: some View {
        ZStack {
            // Background
            AnimatedGradientBackground()
                .ignoresSafeArea()
            
            AnimatedMeshBackground()
                .opacity(0.3)
                .ignoresSafeArea()
            
            ParticleEffectView(system: particleSystem)
                .ignoresSafeArea()
                .allowsHitTesting(false)
            
            // Content
            ScrollView {
                VStack(spacing: 32) {
                    // Header
                    headerSection
                    
                    // Main content
                    if viewModel.isLoading {
                        loadingView
                    } else if viewModel.hasData {
                        mainContent
                    } else {
                        emptyStateView
                    }
                }
                .padding(.bottom, 100)
            }
            .refreshable {
                await viewModel.refreshData()
            }
        }
        .navigationBarHidden(true)
        .task {
            await configureViewModel()
            await viewModel.loadData(for: selectedDate)
            
            // Load existing rating and notes
            if let progress = viewModel.dailyProgress {
                selectedRating = progress.dayRating ?? 0
                dayNotes = progress.dayNotes ?? ""
            }
            
            startAnimations()
        }
        .sheet(isPresented: $showingDatePicker) {
            datePickerSheet
        }
        .sheet(isPresented: $showingShareSheet) {
            ShareSummaryView(viewModel: viewModel)
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") {
                viewModel.clearError()
            }
        } message: {
            if let error = viewModel.errorMessage {
                Text(error)
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Navigation bar
            HStack {
                Button(action: { dismiss() }) {
                    HStack(spacing: 8) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .medium))
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
                SummaryProgressCard(progress: progress, timeBlocks: viewModel.todaysTimeBlocks)
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
            if let insights = viewModel.generateInsights(), !insights.isEmpty {
                InsightsCard(insights: insights)
                    .padding(.horizontal, 24)
                    .opacity(isVisible ? 1 : 0)
                    .scaleEffect(isVisible ? 1 : 0.9)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.3), value: isVisible)
            }
            
            // Day Rating
            Rating(selectedRating: $selectedRating, dayNotes: $dayNotes)
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
        VStack(spacing: 12) {
            // Share button
            PrimaryButton(
                title: "Share Summary",
                icon: "square.and.arrow.up",
                action: { showingShareSheet = true }
            )
            
            // Navigation buttons
            HStack(spacing: 12) {
                SecondaryButton(
                    title: "Previous",
                    icon: "chevron.left",
                    style: .outlined,
                    action: { viewModel.loadPreviousDay() }
                )
                .enabled(viewModel.canNavigateToPreviousDay)
                
                SecondaryButton(
                    title: "Next",
                    icon: "chevron.right",
                    style: .outlined,
                    action: { viewModel.loadNextDay() }
                )
                .enabled(viewModel.canNavigateToNextDay)
            }
        }
    }
    
    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "calendar.day.timeline.left")
                .font(.system(size: 64, weight: .light))
                .foregroundStyle(Color.white.opacity(0.3))
                .scaleEffect(animationPhase == 0 ? 1.0 : 1.1)
                .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: animationPhase)
            
            VStack(spacing: 12) {
                Text("No Activity")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                
                Text("No time blocks were scheduled for this day")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
            
            // Navigate to schedule
            if Calendar.current.isDateInToday(selectedDate) {
                PrimaryButton(
                    title: "Create Schedule",
                    icon: "plus.circle.fill",
                    action: {
                        dismiss()
                        // Navigate to schedule tab - handled by parent
                    }
                )
                .padding(.horizontal, 60)
                .padding(.top, 12)
            }
        }
        .padding(.horizontal, 40)
        .padding(.top, 80)
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : 20)
    }
    
    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: 32) {
            // Animated loading dots
            HStack(spacing: 12) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(Color.white.opacity(0.3))
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
}

// MARK: - Insights Card
struct InsightsCard: View {
    let insights: [String]
    @State private var isVisible = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(Color.premiumWarning)
                
                Text("Insights")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 12) {
                ForEach(insights, id: \.self) { insight in
                    HStack(alignment: .top, spacing: 12) {
                        Circle()
                            .fill(Color.premiumWarning.opacity(0.3))
                            .frame(width: 6, height: 6)
                            .offset(y: 6)
                        
                        Text(insight)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Color.white.opacity(0.8))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .padding(20)
        .glassMorphism(cornerRadius: 20)
        .scaleEffect(isVisible ? 1 : 0.9)
        .opacity(isVisible ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
                isVisible = true
            }
        }
    }
}

// MARK: - Preview
#Preview("Daily Summary") {
    NavigationStack {
        DailySummaryView(date: Date())
    }
    .modelContainer(for: [TimeBlock.self, DailyProgress.self])
}
