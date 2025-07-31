//
//  MainTabView.swift
//  Routine Anchor - Premium Version (iOS 17+ Optimized)
//
import SwiftUI
import SwiftData
import Combine

struct MainTabView: View {
    @Environment(\.modelContext) private var modelContext
    
    // iOS 17+ Pattern: Use @State instead of @StateObject
    @State private var tabViewModel = MainTabViewModel()
    @State private var selectedTab: Tab = .today
    @State private var tabBarOffset: CGFloat = 0
    @State private var showFloatingAction = false
    @State private var cancellables = Set<AnyCancellable>()
    
    var body: some View {
        ZStack {
            // Premium background
            AnimatedGradientBackground()
                .ignoresSafeArea()
            
            TabView(selection: $selectedTab) {
                // Today Tab - Premium dashboard
                NavigationStack {
                    PremiumTodayView(modelContext: modelContext)
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
                
                // Schedule Tab - Premium builder
                NavigationStack {
                    PremiumScheduleBuilderView()
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
                    DailySummaryView()
                        .background(Color.clear)
                }
                .tabItem {
                    TabItemView(
                        icon: "chart.pie",
                        selectedIcon: "chart.pie.fill",
                        title: "Insights",
                        isSelected: selectedTab == .summary
                    )
                }
                .tag(Tab.summary)
                
                // Settings Tab - Premium configuration
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
            .accentColor(.clear) // Remove default tint
            .task {
                await setupTabView()
            }
            .onChange(of: selectedTab) { oldTab, newTab in
                handleTabSelection(newTab, previousTab: oldTab)
            }
            
            // Floating action button
            if showFloatingAction {
                VStack {
                    Spacer()
                    
                    HStack {
                        Spacer()
                        
                        FloatingActionButton(
                            icon: floatingActionIcon,
                            action: handleFloatingActionTap
                        )
                        .transition(.asymmetric(
                            insertion: .scale.combined(with: .opacity),
                            removal: .scale.combined(with: .opacity)
                        ))
                    }
                    .padding(.trailing, 24)
                    .padding(.bottom, 100)
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var floatingActionIcon: String {
        switch selectedTab {
        case .today, .schedule:
            return "plus"
        default:
            return ""
        }
    }
    
    // MARK: - Setup Methods
    
    private func setupTabView() async {
        setupPremiumTabBar()
        await tabViewModel.setup(with: modelContext)
        setupNotificationObservers()
        setupDeepLinkObserver()
        
        // Initial floating action button state
        withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.5)) {
            showFloatingAction = shouldShowFloatingButton(for: selectedTab)
        }
    }
    
    private func setupPremiumTabBar() {
        let appearance = UITabBarAppearance()
        appearance.configureWithTransparentBackground()
        
        // Premium glass morphism effect
        appearance.backgroundColor = UIColor.white.withAlphaComponent(0.05)
        appearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterial)
        
        // Custom tab item appearance
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor.white.withAlphaComponent(0.6),
            .font: UIFont.systemFont(ofSize: 10, weight: .medium)
        ]
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor.white,
            .font: UIFont.systemFont(ofSize: 10, weight: .semibold)
        ]
        
        // Apply appearance
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
        
        // Add subtle shadow
        UITabBar.appearance().layer.shadowColor = UIColor.black.cgColor
        UITabBar.appearance().layer.shadowOffset = CGSize(width: 0, height: -2)
        UITabBar.appearance().layer.shadowRadius = 8
        UITabBar.appearance().layer.shadowOpacity = 0.1
    }
    
    private func setupNotificationObservers() {
        NotificationCenter.default.addObserver(
            forName: .navigateToSchedule,
            object: nil,
            queue: .main
        ) { _ in
            selectedTab = .schedule
        }
        
        NotificationCenter.default.addObserver(
            forName: .showTemplates,
            object: nil,
            queue: .main
        ) { _ in
            selectedTab = .schedule
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                NotificationCenter.default.post(name: .showTemplates, object: nil)
            }
        }
    }
    
    private func setupDeepLinkObserver() {
        // Observe deep link handler's active tab
        DeepLinkHandler.shared.$activeTab
            .receive(on: DispatchQueue.main)
            .removeDuplicates()
            .sink { newTab in
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    selectedTab = newTab
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Tab Selection Handling
    
    private func handleTabSelection(_ tab: Tab, previousTab: Tab) {
        // Haptic feedback
        HapticManager.shared.premiumSelection()
        
        // Update view model
        Task {
            await tabViewModel.didSelectTab(tab)
        }
        
        // Show/hide floating action button based on tab
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            showFloatingAction = shouldShowFloatingButton(for: tab)
        }
        
        // Post notification for tab change to trigger data refresh
        NotificationCenter.default.post(
            name: .tabDidChange,
            object: nil,
            userInfo: [
                "previousTab": previousTab,
                "newTab": tab
            ]
        )
        
        // Tab-specific refresh logic
        switch tab {
        case .today:
            NotificationCenter.default.post(name: .refreshTodayView, object: nil)
        case .schedule:
            NotificationCenter.default.post(name: .refreshScheduleView, object: nil)
        case .summary:
            NotificationCenter.default.post(name: .refreshSummaryView, object: nil)
        case .settings:
            // Settings typically don't need refresh
            break
        }
    }
    
    private func shouldShowFloatingButton(for tab: Tab) -> Bool {
        switch tab {
        case .today, .schedule:
            return true
        case .summary, .settings:
            return false
        }
    }
    
    private func handleFloatingActionTap() {
        HapticManager.shared.premiumImpact()
        
        switch selectedTab {
        case .today:
            // Navigate to schedule tab to add time block
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                selectedTab = .schedule
            }
            // Delay showing the add sheet to allow tab transition
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                NotificationCenter.default.post(name: .showAddTimeBlockFromTab, object: nil)
            }
        case .schedule:
            NotificationCenter.default.post(name: .showAddTimeBlockFromTab, object: nil)
        default:
            break
        }
    }
}

// MARK: - Floating Action Button
struct FloatingActionButton: View {
    let icon: String
    let action: () -> Void
    
    @State private var isPressed = false
    @State private var pulseScale: CGFloat = 1.0
    
    var body: some View {
        Button(action: action) {
            ZStack {
                // Pulse effect
                Circle()
                    .fill(Color.premiumBlue.opacity(0.2))
                    .frame(width: 60, height: 60)
                    .scaleEffect(pulseScale)
                    .opacity(pulseScale == 1.0 ? 0.6 : 0)
                
                // Main button
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.premiumBlue, Color.premiumPurple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 56, height: 56)
                    .shadow(color: Color.premiumBlue.opacity(0.4), radius: 8, x: 0, y: 4)
                
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(Color.white)
                    .rotationEffect(.degrees(isPressed ? 90 : 0))
            }
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
    enum Tab: String, CaseIterable {
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
            case .today: return [Color.premiumBlue, Color.premiumTeal]
            case .schedule: return [Color.premiumPurple, Color.premiumBlue]
            case .summary: return [Color.premiumGreen, Color.premiumTeal]
            case .settings: return [Color.premiumTextSecondary, Color.premiumTextTertiary]
            }
        }
    }
}
