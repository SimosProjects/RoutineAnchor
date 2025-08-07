//
//  MainTabView.swift
//  Routine Anchor - Premium Version
//  Swift 6 Compatible
//
import SwiftUI
import SwiftData

struct MainTabView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var tabViewModel = MainTabViewModel()
    @State private var selectedTab: Tab = .today
    @State private var tabBarOffset: CGFloat = 0
    @State private var showFloatingAction = false
    @State private var deepLinkObserverTask: Task<Void, Never>?
    
    var body: some View {
        ZStack {
            // Premium background
            AnimatedGradientBackground()
                .ignoresSafeArea()
            
            TabView(selection: $selectedTab) {
                // Today Tab - Premium dashboard
                NavigationStack {
                    PremiumTodayView()
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
                
                // Summary Tab - Premium insights
                NavigationStack {
                    PremiumDailySummaryView()
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
                await setupInitialState()
            }
            .onChange(of: selectedTab) { oldValue, newValue in
                handleEnhancedTabSelection(newValue)
            }
            .onDisappear {
                deepLinkObserverTask?.cancel()
            }
            
            // Floating Action Button
            if selectedTab == .today && showFloatingAction {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        FloatingActionButton {
                            handleFloatingActionTap()
                        }
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
    }
    
    @MainActor
    private func setupInitialState() async {
        setupPremiumTabBar()
        tabViewModel.setup(with: modelContext)
        setupNotificationObservers()
        setupDeepLinkObserver()
        
        // Animate floating action button
        withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.5)) {
            showFloatingAction = shouldShowFloatingButton(for: selectedTab)
        }
    }
    
    private func setupNotificationObservers() {
        NotificationCenter.default.addObserver(
            forName: .navigateToSchedule,
            object: nil,
            queue: .main
        ) { _ in
            Task { @MainActor in
                selectedTab = .schedule
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: .navigateToToday,
            object: nil,
            queue: .main
        ) { _ in
            Task { @MainActor in
                selectedTab = .today
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: .showTemplates,
            object: nil,
            queue: .main
        ) { _ in
            Task { @MainActor in
                selectedTab = .schedule
                try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
                NotificationCenter.default.post(name: .showTemplates, object: nil)
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: .showAddTimeBlockFromTab,
            object: nil,
            queue: .main
        ) { _ in
            // This notification is handled by ScheduleBuilderView
        }
    }
    
    private func setupDeepLinkObserver() {
        // Create a task to observe DeepLinkHandler changes
        deepLinkObserverTask = Task { @MainActor in
            // Poll for changes periodically (since we can't use Combine with @MainActor easily in Swift 6)
            while !Task.isCancelled {
                let newTab = DeepLinkHandler.shared.activeTab
                if newTab != selectedTab {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                        selectedTab = newTab
                    }
                }
                try? await Task.sleep(nanoseconds: 100_000_000) // Check every 0.1 seconds
            }
        }
    }
    
    private func setupPremiumTabBar() {
        // Create premium tab bar appearance
        let appearance = UITabBarAppearance()
        appearance.configureWithTransparentBackground()
        
        // Glass morphism background
        appearance.backgroundColor = UIColor.clear
        appearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterial)
        
        // Remove default shadow
        appearance.shadowColor = UIColor.clear
        
        // Configure item appearance
        let normalColor = UIColor.white.withAlphaComponent(0.6)
        let selectedColor = UIColor(Color.premiumBlue)
        
        appearance.stackedLayoutAppearance.normal.iconColor = normalColor
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: normalColor,
            .font: UIFont.systemFont(ofSize: 10, weight: .medium)
        ]
        
        appearance.stackedLayoutAppearance.selected.iconColor = selectedColor
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: selectedColor,
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
    
    private func handleEnhancedTabSelection(_ tab: Tab) {
        let previousTab = selectedTab
        
        // Haptic feedback
        HapticManager.shared.premiumSelection()
        
        // Update view model
        tabViewModel.didSelectTab(tab)
        
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
            Task {
                try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
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
    let action: () -> Void
    @State private var isPressed = false
    @State private var pulseScale: CGFloat = 1.0
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isPressed = true
            }
            
            Task {
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
                await MainActor.run {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        isPressed = false
                    }
                    action()
                }
            }
        }) {
            ZStack {
                // Pulse effect
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.premiumBlue.opacity(0.3), Color.premiumPurple.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 56, height: 56)
                    .scaleEffect(pulseScale)
                    .opacity(1.0 - (pulseScale - 1.0))
                
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
                    .overlay(
                        Image(systemName: "plus")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundStyle(.white)
                    )
                    .shadow(
                        color: Color.premiumBlue.opacity(0.4),
                        radius: 12,
                        x: 0,
                        y: 6
                    )
                    .scaleEffect(isPressed ? 0.95 : 1.0)
            }
        }
        .onAppear {
            // Start pulsing animation
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                pulseScale = 1.4
            }
        }
    }
}

// MARK: - Tab Enum (Enhanced)
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
            case .today: return [Color.premiumBlue, Color.premiumTeal]
            case .schedule: return [Color.premiumPurple, Color.premiumBlue]
            case .summary: return [Color.premiumGreen, Color.premiumTeal]
            case .settings: return [Color.premiumTextSecondary, Color.premiumTextTertiary]
            }
        }
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let tabDidChange = Notification.Name("tabDidChange")
    static let refreshTodayView = Notification.Name("refreshTodayView")
    static let refreshScheduleView = Notification.Name("refreshScheduleView")
    static let refreshSummaryView = Notification.Name("refreshSummaryView")
    static let showAddTimeBlockFromTab = Notification.Name("showAddTimeBlockFromTab")
    static let timeBlockCreated = Notification.Name("timeBlockCreated")
    static let navigateToToday = Notification.Name("navigateToToday")
}

// MARK: - Preview
#Preview {
    MainTabView()
        .modelContainer(for: [TimeBlock.self])
        .environment(\.colorScheme, .dark)
}
