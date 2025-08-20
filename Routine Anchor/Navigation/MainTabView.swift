//
//  MainTabView.swift
//  Routine Anchor
//
import SwiftUI
import SwiftData

struct MainTabView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var authManager: AuthenticationManager
    @State private var tabViewModel = MainTabViewModel()
    @State private var selectedTab: Tab = .today
    @State private var tabBarOffset: CGFloat = 0
    @State private var showFloatingAction = false
    @State private var showingAddTimeBlock = false
    @State private var existingTimeBlocks: [TimeBlock] = []
    @State private var showingEmailCapture = false
    
    // Track if we're programmatically changing tabs to prevent loops
    @State private var isInternalTabChange = false
    
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
                
                // Settings Tab
                NavigationStack {
                    SettingsView()
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
                // Force immediate appearance update
                UITabBar.appearance().isTranslucent = true
                UITabBar.appearance().backgroundImage = UIImage()
            }
            .onAppear {
                // Ensure the tab bar background is immediately transparent
                let tabBarAppearance = UITabBarAppearance()
                tabBarAppearance.configureWithTransparentBackground()
                //tabBarAppearance.backgroundColor = UIColor.black.withAlphaComponent(0.95)
                tabBarAppearance.backgroundColor = UIColor.clear
                tabBarAppearance.backgroundEffect = UIBlurEffect(style: .systemMaterialDark)
                
                UITabBar.appearance().standardAppearance = tabBarAppearance
                UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
            }
            .task {
                await setupInitialState()
            }
            // Monitor for external tab change requests
            .task {
                await monitorTabChangeRequests()
            }
            // Monitor for specific navigation notifications
            .task {
                await monitorNavigationNotifications()
            }
            
            floatingActionButton
        }
        .sheet(isPresented: $showingAddTimeBlock) {
            AddTimeBlockView (
                existingTimeBlocks: existingTimeBlocks
            ) { title, startTime, endTime, notes, category in
                // Create and save the time block directly
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
                    
                    // Trigger refresh of TodayView
                    NotificationCenter.default.post(name: .refreshTodayView, object: nil)
                } catch {
                    print("Failed to save time block: \(error)")
                    HapticManager.shared.error()
                }
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingEmailCapture) {
            EmailCaptureView { email in
                authManager.captureEmail(email)
            }
        }
        .onAppear {
            checkForEmailCapture()
        }
        .onChange(of: authManager.shouldShowEmailCapture) { _, shouldShow in
            if shouldShow {
                showingEmailCapture = true
            }
        }
        .onAppear {
            // Load existing time blocks when view appears
            loadExistingTimeBlocks()
        }
        .onChange(of: selectedTab) { _, _ in
            // Reload blocks when tab changes (in case user is switching between days)
            loadExistingTimeBlocks()
        }
    }
    
    // MARK: - Helper Methods for TimeBlock Management
    
    private func loadExistingTimeBlocks() {
        // Get today's date for filtering
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today) ?? today
        
        // Create fetch descriptor for today's time blocks
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
    
    // MARK: - Email Capture
    
    private func checkForEmailCapture() {
        print("Check for Email Capture invoked")
        // Check after a short delay to let the UI settle
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            authManager.checkShouldShowEmailCapture()
        }
    }
    
    // MARK: - Computed Properties
    
    private var tabSelectionBinding: Binding<Tab> {
        Binding(
            get: { selectedTab },
            set: { newValue in
                // Prevent feedback loops - only process user-initiated changes
                guard !isInternalTabChange else { return }
                guard newValue != selectedTab else { return }
                
                // Update the tab
                selectedTab = newValue
                
                // Handle the tab change
                handleTabChange(to: newValue)
            }
        )
    }
    
    // MARK: - Components
    
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
                    .padding(.bottom, 100) // Above tab bar
                }
            }
            .transition(.asymmetric(
                insertion: .scale(scale: 0.8).combined(with: .opacity),
                removal: .scale(scale: 0.6).combined(with: .opacity)
            ))
        }
    }
    
    // MARK: - Setup Methods
    
    @MainActor
    private func setupInitialState() async {
        setupTabBar()
        tabViewModel.setup(with: modelContext)
        
        // Animate floating action button
        withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.5)) {
            showFloatingAction = shouldShowFloatingButton(for: selectedTab)
        }
    }
    
    // MARK: - Tab Change Monitoring
    
    @MainActor
    private func monitorTabChangeRequests() async {
        // Listen for deep link tab changes
        for await notification in NotificationCenter.default.notifications(named: .requestTabChange) {
            if let tab = notification.userInfo?["tab"] as? Tab {
                await changeTab(to: tab, animated: true)
            }
        }
    }
    
    @MainActor
    private func monitorNavigationNotifications() async {
        // Create a task group to monitor multiple notifications
        await withTaskGroup(of: Void.self) { group in
            // Monitor navigate to schedule
            group.addTask {
                for await _ in NotificationCenter.default.notifications(named: .navigateToSchedule) {
                    await self.changeTab(to: .schedule, animated: true)
                }
            }
            
            // Monitor navigate to today
            group.addTask {
                for await _ in NotificationCenter.default.notifications(named: .navigateToToday) {
                    await self.changeTab(to: .today, animated: true)
                }
            }
            
            // Monitor show templates (schedule tab + notification)
            group.addTask {
                for await _ in NotificationCenter.default.notifications(named: .showTemplates) {
                    await self.changeTab(to: .schedule, animated: true)
                    
                    // Wait a moment then post the templates notification
                    try? await Task.sleep(nanoseconds: 300_000_000)
                    NotificationCenter.default.post(name: .showTemplatesInSchedule, object: nil)
                }
            }
        }
    }
    
    // MARK: - Tab Change Handling
    
    @MainActor
    private func changeTab(to tab: Tab, animated: Bool) async {
        guard tab != selectedTab else { return }
        
        // Set flag to prevent feedback loop
        isInternalTabChange = true
        
        if animated {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                selectedTab = tab
            }
        } else {
            selectedTab = tab
        }
        
        // Handle the change
        handleTabChange(to: tab)
        
        // Reset flag after a small delay
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
        isInternalTabChange = false
    }
    
    private func handleTabChange(to newTab: Tab) {
        tabViewModel.didSelectTab(newTab)
        updateFloatingAction(for: newTab)
        broadcastTabChange(newTab)
    }
    
    // MARK: - UI Configuration
    
    private func setupTabBar() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.black.withAlphaComponent(0.95)
        appearance.backgroundEffect = UIBlurEffect(style: .systemMaterialDark)
        
        // Remove separator
        appearance.shadowImage = UIImage()
        appearance.shadowColor = .clear
        
        // Configure item appearance
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
    
    // MARK: - Floating Action Button
    
    private func shouldShowFloatingButton(for tab: Tab) -> Bool {
        switch tab {
        case .today:
            return true  // Only show on Today tab
        case .schedule, .summary, .settings:
            return false
        }
    }
    
    private func updateFloatingAction(for tab: Tab) {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            showFloatingAction = shouldShowFloatingButton(for: tab)
        }
    }
    
    private func floatingActionTapped() {
        HapticManager.shared.mediumImpact()
        
        switch selectedTab {
        case .today:
            // Load latest time blocks before showing the form
            loadExistingTimeBlocks()
            // Present sheet directly instead of posting notification
            showingAddTimeBlock = true
        default:
            break
        }
    }
    
    // MARK: - Broadcasting
    
    private func broadcastTabChange(_ tab: Tab) {
        let userInfo: [String: Any] = ["tab": tab.rawValue]
        NotificationCenter.default.post(name: .tabDidChange, object: nil, userInfo: userInfo)
        
        // Trigger refresh for specific tabs
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
                // Pulsing background
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
                
                // Main button
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
            // Start pulsing animation
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
        case settings = "settings"
        
        var title: String {
            switch self {
            case .today: return "Today"
            case .schedule: return "Schedule"
            case .summary: return "Insights"
            case .settings: return "Settings"
            }
        }
        
        var systemImage: String {
            switch self {
            case .today: return "calendar.circle"
            case .schedule: return "clock"
            case .summary: return "chart.pie"
            case .settings: return "gearshape"
            }
        }
        
        var filledSystemImage: String {
            switch self {
            case .today: return "calendar.circle.fill"
            case .schedule: return "clock.fill"
            case .summary: return "chart.pie.fill"
            case .settings: return "gearshape.fill"
            }
        }
        
        var gradientColors: [Color] {
            switch self {
            case .today: return [Color.anchorBlue, Color.anchorTeal]
            case .schedule: return [Color.anchorPurple, Color.anchorBlue]
            case .summary: return [Color.anchorGreen, Color.anchorTeal]
            case .settings: return [Color.anchorTextSecondary, Color.anchorTextTertiary]
            }
        }
    }
}

// MARK: - Preview
#Preview {
    MainTabView()
        .modelContainer(for: [TimeBlock.self])
        .environment(\.colorScheme, .dark)
}
