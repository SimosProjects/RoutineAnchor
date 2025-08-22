//
//  MainTabView.swift
//  Routine Anchor
//
//  Consolidated tab view with premium, ads, and email integration
//
import SwiftUI
import SwiftData

struct MainTabView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.premiumManager) private var premiumManager
    @EnvironmentObject private var authManager: AuthenticationManager
    @EnvironmentObject private var adManager: AdManager
    @State private var tabViewModel = MainTabViewModel()
    @State private var selectedTab: Tab = .today
    @State private var tabBarOffset: CGFloat = 0
    @State private var showFloatingAction = false
    @State private var showingAddTimeBlock = false
    @State private var existingTimeBlocks: [TimeBlock] = []
    @State private var showingEmailCapture = false
    @State private var showingPremiumUpgrade = false
    
    // Track if we're programmatically changing tabs to prevent loops
    @State private var isInternalTabChange = false
    
    // Track if we've already handled email capture on this app launch
    @State private var hasHandledEmailCaptureThisSession = false
    
    // Use fallback if premiumManager is nil
    private var safePremiumManager: PremiumManager {
        premiumManager ?? PremiumManager()
    }
    
    var body: some View {
        ZStack {
            AnimatedGradientBackground()
                .ignoresSafeArea()
            
            TabView(selection: tabSelectionBinding) {
                // Today Tab
                NavigationStack {
                    TodayView(modelContext: modelContext)
                        .background(Color.clear)
                }
                .tabItem {
                    TabItemView(
                        icon: "calendar.circle",
                        selectedIcon: "calendar.circle.fill",
                        title: "Today",
                        isSelected: selectedTab == .today
                    )
                }
                .tag(Tab.today)
                
                // Schedule Tab
                NavigationStack {
                    ScheduleBuilderView()
                        .background(Color.clear)
                }
                .tabItem {
                    TabItemView(
                        icon: "clock",
                        selectedIcon: "clock.fill",
                        title: "Schedule",
                        isSelected: selectedTab == .schedule
                    )
                }
                .tag(Tab.schedule)
                
                // Summary Tab
                NavigationStack {
                    DailySummaryView(modelContext: modelContext)
                        .environment(safePremiumManager)
                        .background(Color.clear)
                }
                .tabItem {
                    TabItemView(
                        icon: "chart.pie",
                        selectedIcon: "chart.pie.fill",
                        title: "Insights",
                        isSelected: selectedTab == .summary
                    )
                    .badge(tabViewModel.shouldShowSummaryBadge ? "" : nil)
                }
                .tag(Tab.summary)
                
                // Analytics Tab (Premium gated)
                NavigationStack {
                    analyticsTab
                        .environment(safePremiumManager)
                        .background(Color.clear)
                }
                .tabItem {
                    TabItemView(
                        icon: "chart.bar",
                        selectedIcon: "chart.bar.fill",
                        title: "Analytics",
                        isSelected: selectedTab == .analytics
                    )
                }
                .tag(Tab.analytics)
                
                // Settings Tab
                NavigationStack {
                    SettingsView()
                        .environmentObject(authManager)
                        .background(Color.clear)
                }
                .tabItem {
                    TabItemView(
                        icon: "gearshape",
                        selectedIcon: "gearshape.fill",
                        title: "Settings",
                        isSelected: selectedTab == .settings
                    )
                }
                .tag(Tab.settings)
            }
            .tint(Color.anchorBlue)
            .background(Color.clear)
            .onAppear {
                setupTabBarAppearance()
            }
            .task {
                await setupInitialState()
            }
            .task {
                await monitorTabChangeRequests()
            }
            .task {
                await monitorNavigationNotifications()
            }
            
            // Floating action button
            floatingActionButton
            
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
        .sheet(isPresented: $showingAddTimeBlock) {
            AddTimeBlockView(
                existingTimeBlocks: existingTimeBlocks
            ) { title, startTime, endTime, notes, category in
                createTimeBlock(title: title, startTime: startTime, endTime: endTime, notes: notes ?? "", category: category ?? "")
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }

        .sheet(isPresented: $showingEmailCapture) {
            EmailCaptureView { email in
                authManager.captureEmail(email)
            }
            .onDisappear {
                // Ensure dismissal is properly tracked when sheet is dismissed
                if !authManager.isEmailCaptured {
                    authManager.dismissEmailCapture()
                }
            }
        }
        .onAppear {
            // Only check for email capture once per session and after a delay
            if !hasHandledEmailCaptureThisSession {
                hasHandledEmailCaptureThisSession = true
                checkForEmailCapture()
            }
            loadExistingTimeBlocks()
        }
        .onReceive(authManager.$shouldShowEmailCapture) { shouldShow in
            // Only show if not already handled and conditions are met
            if shouldShow && !showingEmailCapture && !authManager.isEmailCaptured {
                showingEmailCapture = true
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ForceShowEmailCapture"))) { _ in
            showingEmailCapture = true
        }
        .onChange(of: selectedTab) { oldTab, newTab in
            // Handle tab changes with proper ad integration
            handleTabChangeWithAds(from: oldTab, to: newTab)
        }
    }
    
    // MARK: - Analytics Tab with Premium Gating
    @ViewBuilder
    private var analyticsTab: some View {
        if safePremiumManager.canAccessAdvancedAnalytics {
            PremiumAnalyticsView(premiumManager: safePremiumManager)
        } else {
            BasicAnalyticsView {
                showingPremiumUpgrade = true
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func handleTabChangeWithAds(from oldTab: Tab, to newTab: Tab) {
        // Ensure we don't show ads during ad presentation
        guard !adManager.isShowingAd else {
            print("⚠️ Ad currently showing, deferring tab change handling")
            return
        }
        
        // Check if we should show an interstitial ad
        if shouldShowInterstitialAd() {
            adManager.showInterstitialIfAllowed(premiumManager: safePremiumManager)
        }
        
        // Continue with normal tab change handling
        loadExistingTimeBlocks()
    }
    
    private func createTimeBlock(title: String, startTime: Date, endTime: Date, notes: String, category: String) {
        let newBlock = TimeBlock(
            title: title,
            startTime: startTime,
            endTime: endTime,
            notes: notes,
            category: category
        )
        
        modelContext.insert(newBlock)
        
        do {
            try modelContext.save()
            HapticManager.shared.success()
            NotificationCenter.default.post(name: .refreshTodayView, object: nil)
        } catch {
            print("Failed to save time block: \(error)")
            HapticManager.shared.error()
        }
    }
    
    private func loadExistingTimeBlocks() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today) ?? today
        
        let descriptor = FetchDescriptor<TimeBlock>(
            predicate: #Predicate<TimeBlock> { timeBlock in
                timeBlock.startTime >= today && timeBlock.startTime < tomorrow
            },
            sortBy: [SortDescriptor(\.startTime)]
        )
        
        do {
            existingTimeBlocks = try modelContext.fetch(descriptor)
        } catch {
            print("Failed to fetch existing time blocks: \(error)")
            existingTimeBlocks = []
        }
    }
    
    private func shouldShowInterstitialAd() -> Bool {
        // Don't show ads if user has premium
        guard safePremiumManager.shouldShowAds else {
            return false
        }
        
        // Don't show if ad is currently being shown or not loaded
        guard !adManager.isShowingAd && adManager.isAdLoaded else {
            return false
        }
        
        // Track tab switches and show ad every 5th switch
        let tabSwitchCount = UserDefaults.standard.integer(forKey: "tabSwitchCount") + 1
        UserDefaults.standard.set(tabSwitchCount, forKey: "tabSwitchCount")
        
        let shouldShow = tabSwitchCount % 5 == 0
        
        if shouldShow {
            print("📊 Tab switch #\(tabSwitchCount) - showing interstitial ad")
        }
        
        return shouldShow
    }
    
    // MARK: - Email Capture
    
    private func checkForEmailCapture() {
        // Add a delay and pass premium manager for proper checking
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            authManager.checkShouldShowEmailCapture(premiumManager: safePremiumManager)
        }
    }
    
    // MARK: - Computed Properties
    
    private var tabSelectionBinding: Binding<Tab> {
        Binding(
            get: { selectedTab },
            set: { newValue in
                guard !isInternalTabChange else { return }
                guard newValue != selectedTab else { return }
                
                selectedTab = newValue
                handleTabChange(to: newValue)
            }
        )
    }
    
    // MARK: - Floating Action Button
    
    @ViewBuilder
    private var floatingActionButton: some View {
        if shouldShowFloatingButton(for: selectedTab) {
            VStack {
                Spacer()
                
                HStack {
                    Spacer()
                    
                    FloatingActionButton(
                        tab: selectedTab,
                        action: floatingActionTapped
                    )
                    .scaleEffect(showFloatingAction ? 1.0 : 0.01)
                    .opacity(showFloatingAction ? 1.0 : 0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.7), value: showFloatingAction)
                    .padding(.trailing, 24)
                    .padding(.bottom, 100)
                }
            }
            .transition(.asymmetric(
                insertion: .scale(scale: 0.8).combined(with: .opacity),
                removal: .scale(scale: 0.6).combined(with: .opacity)
            ))
        }
    }
    
    private func shouldShowFloatingButton(for tab: Tab) -> Bool {
        if tab == .today {
            return true
        }
        else {
            return false
        }
    }
    
    private func floatingActionTapped() {
        HapticManager.shared.mediumImpact()
        
        switch selectedTab {
        case .today:
            loadExistingTimeBlocks()
            showingAddTimeBlock = true
        default:
            break
        }
    }
    
    // MARK: - Setup Methods
    
    @MainActor
    private func setupInitialState() async {
        setupTabBar()
        tabViewModel.setup(with: modelContext)
        
        withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.5)) {
            showFloatingAction = shouldShowFloatingButton(for: selectedTab)
        }
    }
    
    private func setupTabBarAppearance() {
        UITabBar.appearance().isTranslucent = true
        UITabBar.appearance().backgroundImage = UIImage()
        
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithTransparentBackground()
        tabBarAppearance.backgroundColor = UIColor.clear
        tabBarAppearance.backgroundEffect = UIBlurEffect(style: .systemMaterialDark)
        
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
    }
    
    private func setupTabBar() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.black.withAlphaComponent(0.95)
        appearance.backgroundEffect = UIBlurEffect(style: .systemMaterialDark)
        
        appearance.shadowImage = UIImage()
        appearance.shadowColor = .clear
        
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor.white.withAlphaComponent(0.5)
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor.white.withAlphaComponent(0.5),
            .font: UIFont.systemFont(ofSize: 11, weight: .medium)
        ]
        
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor(Color.anchorBlue)
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor(Color.anchorBlue),
            .font: UIFont.systemFont(ofSize: 11, weight: .semibold)
        ]
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
    
    // MARK: - Tab Change Monitoring
    
    @MainActor
    private func monitorTabChangeRequests() async {
        for await notification in NotificationCenter.default.notifications(named: .requestTabChange) {
            if let tab = notification.userInfo?["tab"] as? Tab {
                await changeTab(to: tab, animated: true)
            }
        }
    }
    
    @MainActor
    private func monitorNavigationNotifications() async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                for await _ in NotificationCenter.default.notifications(named: .navigateToSchedule) {
                    await self.changeTab(to: .schedule, animated: true)
                }
            }
            
            group.addTask {
                for await _ in NotificationCenter.default.notifications(named: .navigateToToday) {
                    await self.changeTab(to: .today, animated: true)
                }
            }
            
            group.addTask {
                for await _ in NotificationCenter.default.notifications(named: .showTemplates) {
                    await self.changeTab(to: .schedule, animated: true)
                    try? await Task.sleep(nanoseconds: 300_000_000)
                    NotificationCenter.default.post(name: .showTemplatesInSchedule, object: nil)
                }
            }
        }
    }
    
    @MainActor
    private func changeTab(to tab: Tab, animated: Bool) async {
        guard tab != selectedTab else { return }
        
        isInternalTabChange = true
        
        if animated {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                selectedTab = tab
            }
        } else {
            selectedTab = tab
        }
        
        handleTabChange(to: tab)
        
        try? await Task.sleep(nanoseconds: 100_000_000)
        isInternalTabChange = false
    }
    
    private func handleTabChange(to newTab: Tab) {
        tabViewModel.didSelectTab(newTab)
        updateFloatingAction(for: newTab)
        broadcastTabChange(newTab)
    }
    
    private func updateFloatingAction(for tab: Tab) {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            showFloatingAction = shouldShowFloatingButton(for: tab)
        }
    }
    
    private func broadcastTabChange(_ tab: Tab) {
        let userInfo: [String: Any] = ["tab": tab.rawValue]
        NotificationCenter.default.post(name: .tabDidChange, object: nil, userInfo: userInfo)
        
        switch tab {
        case .today:
            NotificationCenter.default.post(name: .refreshTodayView, object: nil)
        case .schedule:
            NotificationCenter.default.post(name: .refreshScheduleView, object: nil)
        case .summary:
            NotificationCenter.default.post(name: .refreshSummaryView, object: nil)
        default:
            break
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
                    headerSection
                    basicStatsSection
                    premiumFeaturesShowcase
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
    
    private var upgradePromptSection: some View {
        AnalyticsGate(onUpgrade: onUpgrade)
    }
    
    @MainActor
    private func loadBasicAnalytics() async {
        guard dataManager == nil else { return }
        
        dataManager = DataManager(modelContext: modelContext)
        
        let today = Calendar.current.startOfDay(for: Date())
        let progressArray = dataManager!.loadDailyProgressRangeSafely(from: today, to: today)
        todaysProgress = progressArray.first
        
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let timeBlocks = dataManager!.loadAllTimeBlocksSafely().filter { $0.startTime >= weekAgo }
        
        let totalWeeklyBlocks = timeBlocks.count
        let completedWeeklyBlocks = timeBlocks.filter { $0.status == .completed }.count
        let averageCompletion = totalWeeklyBlocks > 0 ? Double(completedWeeklyBlocks) / Double(totalWeeklyBlocks) : 0
        
        weeklyStats = (
            totalBlocks: totalWeeklyBlocks,
            completedBlocks: completedWeeklyBlocks,
            averageCompletion: averageCompletion
        )
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

// MARK: - Floating Action Button Component
struct FloatingActionButton: View {
    let tab: MainTabView.Tab
    let action: () -> Void
    
    @State private var isPressed = false
    @State private var pulseScale: CGFloat = 1.0
    
    private var icon: String {
        switch tab {
        case .today, .schedule:
            return "plus"
        default:
            return "plus"
        }
    }
    
    private var gradientColors: [Color] {
        tab.gradientColors
    }
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isPressed = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isPressed = false
            }
            
            action()
        }) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [gradientColors[0].opacity(0.3), Color.clear],
                            center: .center,
                            startRadius: 20,
                            endRadius: 40
                        )
                    )
                    .frame(width: 80, height: 80)
                    .scaleEffect(pulseScale)
                    .opacity(0.5)
                
                Circle()
                    .fill(
                        LinearGradient(
                            colors: gradientColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 56, height: 56)
                
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.white)
                    .rotationEffect(.degrees(isPressed ? 90 : 0))
            }
            .shadow(color: gradientColors[0].opacity(0.4), radius: 12, x: 0, y: 6)
            .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
            .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                pulseScale = 1.4
            }
        }
    }
}

// MARK: - Tab Enum
extension MainTabView {
    enum Tab: String, CaseIterable, Equatable {
        case today = "today"
        case schedule = "schedule"
        case summary = "summary"
        case analytics = "analytics"
        case settings = "settings"
        
        var title: String {
            switch self {
            case .today: return "Today"
            case .schedule: return "Schedule"
            case .summary: return "Insights"
            case .analytics: return "Analytics"
            case .settings: return "Settings"
            }
        }
        
        var systemImage: String {
            switch self {
            case .today: return "calendar.circle"
            case .schedule: return "clock"
            case .summary: return "chart.pie"
            case .analytics: return "chart.bar"
            case .settings: return "gearshape"
            }
        }
        
        var filledSystemImage: String {
            switch self {
            case .today: return "calendar.circle.fill"
            case .schedule: return "clock.fill"
            case .summary: return "chart.pie.fill"
            case .analytics: return "chart.bar.fill"  // ADDED: Missing analytics case
            case .settings: return "gearshape.fill"
            }
        }
        
        var gradientColors: [Color] {
            switch self {
            case .today: return [Color.anchorBlue, Color.anchorTeal]
            case .schedule: return [Color.anchorPurple, Color.anchorBlue]
            case .summary: return [Color.anchorGreen, Color.anchorTeal]
            case .analytics: return [Color.anchorWarning, Color.anchorPurple]  // ADDED: Missing analytics case
            case .settings: return [Color.anchorTextSecondary, Color.anchorTextTertiary]
            }
        }
    }
}

// MARK: - Preview
#Preview {
    MainTabView()
        .modelContainer(for: [TimeBlock.self, DailyProgress.self, RoutineTemplate.self], inMemory: true)
        .environment(\.premiumManager, PremiumManager())
        .environmentObject(AuthenticationManager())
        .environmentObject(AdManager())
        .environment(\.colorScheme, .dark)
}
