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
            .tint(Color.premiumBlue)
            .onAppear {
                Task { await setupInitialState() }
            }
            .onChange(of: selectedTab) { _, newTab in
                tabViewModel.didSelectTab(newTab)
                updateFloatingAction(for: newTab)
                broadcastTabChange(newTab)
            }
            .onDisappear {
                deepLinkObserverTask?.cancel()
            }
            
            // Premium floating action button - contextual
            floatingActionButton
        }
    }
    
    // MARK: - Components
    
    @ViewBuilder
    private var floatingActionButton: some View {
        if shouldShowFloatingButton(for: selectedTab) {
            VStack {
                Spacer()
                
                HStack {
                    Spacer()
                    
                    PremiumFloatingActionButton(
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
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            }
        }
    }
    
    private func setupPremiumTabBar() {
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
        
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor(Color.premiumBlue)
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor(Color.premiumBlue),
            .font: UIFont.systemFont(ofSize: 11, weight: .semibold)
        ]
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
    
    private func shouldShowFloatingButton(for tab: Tab) -> Bool {
        switch tab {
        case .today, .schedule:
            return true
        case .summary, .settings:
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
            // Show quick add time block sheet
            NotificationCenter.default.post(name: .showAddTimeBlockFromTab, object: nil)
        case .schedule:
            // Show add time block for schedule
            NotificationCenter.default.post(name: .showAddTimeBlockFromTab, object: nil)
        default:
            break
        }
    }
    
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

// MARK: - Premium Floating Action Button Component
struct PremiumFloatingActionButton: View {
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
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    isPressed = false
                }
                action()
            }
        }) {
            ZStack {
                // Pulse effect background
                Circle()
                    .fill(
                        LinearGradient(
                            colors: gradientColors.map { $0.opacity(0.3) },
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 64, height: 64)
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
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.4), Color.white.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(Color.white)
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
