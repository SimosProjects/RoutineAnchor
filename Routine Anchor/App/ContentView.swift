//
//  ContentView.swift
//  Routine Anchor
//
//  Created by Christopher Simonson on 7/19/25.
//  Updated with premium integration
//
import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.premiumManager) private var premiumManager
    @EnvironmentObject private var authManager: AuthenticationManager
    @State private var showOnboarding = true
    
    var body: some View {
        Group {
            if showOnboarding {
                OnboardingFlow(showOnboarding: $showOnboarding)
            } else {
                MainTabViewPremium()
                    .environment(DataManager(modelContext: modelContext))
                    .environmentObject(authManager)
            }
        }
        .onAppear {
            checkFirstLaunch()
        }
    }
    
    private func checkFirstLaunch() {
        // Handle UI test state if needed
        #if DEBUG
        handleUITestState()
        #endif
        
        // Check if onboarding has been completed
        let hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
        showOnboarding = !hasCompletedOnboarding
        
        #if DEBUG
        // Log the state for debugging
        print("📱 ContentView - Onboarding completed: \(hasCompletedOnboarding), showing: \(showOnboarding)")
        #endif
    }
    
    #if DEBUG
    /// Handle UI test specific state checks
    private func handleUITestState() {
        // Check if we're in UI test mode
        let isUITesting = ProcessInfo.processInfo.arguments.contains("--uitesting") ||
                         ProcessInfo.processInfo.environment["UITEST_MODE"] == "1"
        
        guard isUITesting else { return }
        
        // Check if we should force onboarding to show
        let shouldResetOnboarding = ProcessInfo.processInfo.arguments.contains("--reset-onboarding") ||
                                   ProcessInfo.processInfo.environment["RESET_ONBOARDING"] == "1"
        
        if shouldResetOnboarding {
            // Double-check that the reset happened
            let hasCompleted = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
            if hasCompleted {
                // Force reset if it didn't happen in App init
                UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")
                UserDefaults.standard.synchronize()
                print("⚠️ UI Test: Force resetting onboarding in ContentView")
            } else {
                print("✅ UI Test: Onboarding already reset")
            }
        }
        
        // Log current state for debugging
        print("🧪 UI Test Mode Active")
        print("   - Reset Onboarding: \(shouldResetOnboarding)")
        print("   - Current hasCompletedOnboarding: \(UserDefaults.standard.bool(forKey: "hasCompletedOnboarding"))")
    }
    #endif
}

// MARK: - Premium-Enabled Main Tab View
struct MainTabViewPremium: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.premiumManager) private var premiumManager
    @EnvironmentObject private var authManager: AuthenticationManager
    @State private var showingEmailCapture = false
    @State private var selectedTab = 0
    @State private var showingPremiumUpgrade = false
    @State private var manualShowSheet = false
    
    // Use fallback if premiumManager is nil
    private var safePremiumManager: PremiumManager {
        premiumManager ?? PremiumManager()
    }
    
    var body: some View {
        ZStack {
            AnimatedGradientBackground()
                .ignoresSafeArea()
            
            TabView(selection: $selectedTab) {
                // Today Tab
                TodayView(modelContext: modelContext)
                    .tabItem {
                        Image(systemName: selectedTab == 0 ? "house.fill" : "house")
                        Text("Today")
                    }
                    .tag(0)
                
                // Schedule Tab
                ScheduleBuilderView()
                    .tabItem {
                        Image(systemName: selectedTab == 1 ? "calendar.circle.fill" : "calendar.circle")
                        Text("Schedule")
                    }
                    .tag(1)
                
                // Analytics Tab (with premium gating)
                analyticsTab
                    .tabItem {
                        Image(systemName: selectedTab == 2 ? "chart.line.uptrend.xyaxis" : "chart.line.uptrend.xyaxis")
                        Text("Analytics")
                    }
                    .tag(2)
                
                // Settings Tab
                SettingsView()
                    .environmentObject(authManager)
                    .tabItem {
                        Image(systemName: selectedTab == 3 ? "gearshape.fill" : "gearshape")
                        Text("Settings")
                    }
                    .tag(3)
            }
            .accentColor(.white)
            .preferredColorScheme(.dark)
            
            // Premium upgrade overlay
            if showingPremiumUpgrade {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        showingPremiumUpgrade = false
                    }
                
                PremiumUpgradeView(premiumManager: safePremiumManager)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: showingPremiumUpgrade)
        .sheet(isPresented: $showingEmailCapture) {
            EmailCaptureView { email in
                authManager.captureEmail(email)
            }
        }
        .onAppear {
            checkForEmailCapture()
        }
        .onReceive(authManager.$shouldShowEmailCapture) { shouldShow in
            if shouldShow {
                showingEmailCapture = true
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ForceShowEmailCapture"))) { _ in
            showingEmailCapture = true
        }
    }
    
    // MARK: - Email Capture
    private func checkForEmailCapture() {
        // Check after a short delay to let the UI settle
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            authManager.checkShouldShowEmailCapture()
        }
    }
    
    // MARK: - Analytics Tab with Premium Gating
    @ViewBuilder
    private var analyticsTab: some View {
        if safePremiumManager.canAccessAdvancedAnalytics {
            PremiumAnalyticsView(premiumManager: safePremiumManager)
        } else {
            // Basic analytics for free users with upgrade prompts
            BasicAnalyticsView {
                showingPremiumUpgrade = true
            }
        }
    }
}

// MARK: - Basic Analytics View (Free Users)
struct BasicAnalyticsView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var dataManager: DataManager?
    @State private var todaysProgress: DailyProgress?
    @State private var weeklyStats: (totalBlocks: Int, completedBlocks: Int, averageCompletion: Double)?
    
    let onUpgrade: () -> Void
    
    var body: some View {
        ZStack {
            AnimatedGradientBackground()
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection
                    
                    // Basic stats that free users can see
                    basicStatsSection
                    
                    // Premium feature showcase
                    premiumFeaturesShowcase
                    
                    // Upgrade prompt
                    upgradePromptSection
                }
                .padding(.horizontal)
                .padding(.bottom, 100)
            }
        }
        .navigationTitle("Analytics")
        .navigationBarTitleDisplayMode(.large)
        .task {
            await loadBasicAnalytics()
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Your Progress")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                
                Spacer()
                
                Button("Upgrade") {
                    onUpgrade()
                    HapticManager.shared.anchorSelection()
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.anchorBlue)
                .cornerRadius(8)
            }
            
            Text("Unlock advanced insights and detailed analytics with Premium")
                .font(.system(size: 16))
                .foregroundStyle(.white.opacity(0.7))
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    // MARK: - Basic Stats Section
    private var basicStatsSection: some View {
        VStack(spacing: 16) {
            Text("Today's Overview")
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            if let progress = todaysProgress {
                HStack(spacing: 16) {
                    StatCard(
                        title: "Completed",
                        value: "\(progress.completedBlocks)",
                        subtitle: "blocks",
                        color: Color.anchorGreen,
                        icon: "checkmark.circle.fill"
                    )
                    
                    StatCard(
                        title: "Progress",
                        value: "\(Int(progress.completionPercentage * 100))%",
                        subtitle: "today",
                        color: Color.anchorBlue,
                        icon: "chart.pie.fill"
                    )
                }
                
                if let weeklyStats = weeklyStats {
                    HStack(spacing: 16) {
                        StatCard(
                            title: "This Week",
                            value: "\(weeklyStats.completedBlocks)",
                            subtitle: "completed",
                            color: Color.anchorPurple,
                            icon: "calendar.circle.fill"
                        )
                        
                        StatCard(
                            title: "Average",
                            value: "\(Int(weeklyStats.averageCompletion * 100))%",
                            subtitle: "weekly",
                            color: Color.anchorTeal,
                            icon: "chart.line.uptrend.xyaxis"
                        )
                    }
                }
            } else {
                // No data state
                VStack(spacing: 12) {
                    Image(systemName: "chart.bar.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(.white.opacity(0.3))
                    
                    Text("No data yet")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.white.opacity(0.7))
                    
                    Text("Create and complete time blocks to see your progress!")
                        .font(.system(size: 14))
                        .foregroundStyle(.white.opacity(0.5))
                        .multilineTextAlignment(.center)
                }
                .padding(.vertical, 40)
            }
        }
        .padding(20)
        .glassMorphism(cornerRadius: 20)
    }
    
    // MARK: - Premium Features Showcase
    private var premiumFeaturesShowcase: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Premium Analytics")
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                
                Spacer()
                
                PremiumBadge()
            }
            
            VStack(spacing: 12) {
                PremiumFeaturePreview(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Productivity Trends",
                    description: "Track your completion rates over time",
                    color: Color.anchorBlue
                )
                
                PremiumFeaturePreview(
                    icon: "brain.head.profile",
                    title: "Peak Performance Times",
                    description: "Discover when you're most productive",
                    color: Color.anchorGreen
                )
                
                PremiumFeaturePreview(
                    icon: "lightbulb.fill",
                    title: "AI-Powered Insights",
                    description: "Get personalized recommendations",
                    color: Color.anchorWarning
                )
                
                PremiumFeaturePreview(
                    icon: "target",
                    title: "Category Performance",
                    description: "Analyze completion by activity type",
                    color: Color.anchorPurple
                )
            }
        }
        .padding(20)
        .glassMorphism(cornerRadius: 20)
    }
    
    // MARK: - Upgrade Prompt Section
    private var upgradePromptSection: some View {
        AnalyticsGate(onUpgrade: onUpgrade)
    }
    
    // MARK: - Data Loading
    @MainActor
    private func loadBasicAnalytics() async {
        guard dataManager == nil else { return }
        
        dataManager = DataManager(modelContext: modelContext)
        
        do {
            // Load today's progress
            let today = Calendar.current.startOfDay(for: Date())
            let progressArray = try dataManager!.loadDailyProgress(from: today, to: today)
            todaysProgress = progressArray.first
            
            // Load this week's basic stats
            let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
            let timeBlocks = try dataManager!.loadAllTimeBlocks().filter { $0.startTime >= weekAgo }
            
            let totalWeeklyBlocks = timeBlocks.count
            let completedWeeklyBlocks = timeBlocks.filter { $0.status == .completed }.count
            let averageCompletion = totalWeeklyBlocks > 0 ? Double(completedWeeklyBlocks) / Double(totalWeeklyBlocks) : 0
            
            weeklyStats = (
                totalBlocks: totalWeeklyBlocks,
                completedBlocks: completedWeeklyBlocks,
                averageCompletion: averageCompletion
            )
            
        } catch {
            print("Failed to load basic analytics: \(error)")
        }
    }
}

// MARK: - Premium Feature Preview
struct PremiumFeaturePreview: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(color)
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(color.opacity(0.15))
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.5))
                
                Text(description)
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.4))
                    .lineLimit(2)
            }
            
            Spacer()
            
            Image(systemName: "lock.fill")
                .font(.system(size: 12))
                .foregroundStyle(Color.anchorWarning)
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [TimeBlock.self, DailyProgress.self, RoutineTemplate.self], inMemory: true)
        .environment(PremiumManager())
}
