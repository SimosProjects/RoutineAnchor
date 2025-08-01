//
//  MainTabView.swift
//  Routine Anchor - Premium Version
//
import SwiftUI
import SwiftData
import Combine

struct MainTabView: View {
    @Environment(\.modelContext) private var modelContext
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
                
                // Summary Tab - Premium insights
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
            .onAppear {
                setupPremiumTabBar()
                tabViewModel.setup(with: modelContext)
                
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
                        // This will trigger the template sheet in ScheduleBuilderView
                        NotificationCenter.default.post(name: .showTemplates, object: nil)
                    }
                }
                
                // Animate floating action button
                withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.5)) {
                    showFloatingAction = shouldShowFloatingButton(for: selectedTab)
                }
            }
            .onChange(of: selectedTab) { oldValue, newValue in
                handleTabSelection(newValue)
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
    
    private func handleTabSelection(_ tab: Tab) {
        // Haptic feedback
        HapticManager.shared.premiumSelection()
        
        // Update view model
        tabViewModel.didSelectTab(tab)
        
        // Show/hide floating action button based on tab
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            showFloatingAction = shouldShowFloatingButton(for: tab)
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
    
    private func handleNewTimeBlock(title: String, startTime: Date, endTime: Date, notes: String?, category: String?) {
        // Create a new time block using the DataManager
        guard let modelContext = try? ModelContext(ModelContainer(for: TimeBlock.self)) else {
            print("Failed to create model context")
            return
        }
        
        let dataManager = DataManager(modelContext: modelContext)
        
        // Create the time block
        let newBlock = TimeBlock(
            title: title,
            startTime: startTime,
            endTime: endTime,
            notes: notes,
            category: category
        )
        
        do {
            // Add the time block using DataManager's addTimeBlock method
            try dataManager.addTimeBlock(newBlock)
            
            // Provide haptic feedback
            HapticManager.shared.premiumSuccess()
            
            // Navigate to today tab to see the new block
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                selectedTab = .today
            }
            
            // Post notification to refresh views
            NotificationCenter.default.post(
                name: .timeBlockCreated,
                object: nil,
                userInfo: ["blockId": newBlock.id]
            )
            
        } catch {
            print("Failed to add time block: \(error)")
            HapticManager.shared.premiumError()
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
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    isPressed = false
                }
                action()
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

extension MainTabView {
    
    // MARK: - Enhanced Tab Selection Handler
    
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
    
    // MARK: - Deep Link Integration
    
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
    
    // MARK: - Enhanced onAppear
    
    private func enhancedOnAppear() {
        setupPremiumTabBar()
        tabViewModel.setup(with: modelContext)
        setupDeepLinkObserver()
        
        // Existing notification observers
        NotificationCenter.default.addObserver(
            forName: .navigateToSchedule,
            object: nil,
            queue: .main
        ) { _ in
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                selectedTab = .schedule
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: .showTemplates,
            object: nil,
            queue: .main
        ) { _ in
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                selectedTab = .schedule
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                NotificationCenter.default.post(name: .showTemplates, object: nil)
            }
        }
        
        // Add new observer for FAB action from Today tab
        NotificationCenter.default.addObserver(
            forName: .showAddTimeBlockFromTab,
            object: nil,
            queue: .main
        ) { _ in
            // This notification is handled by ScheduleBuilderView
        }
        
        // Animate floating action button
        withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.5)) {
            showFloatingAction = shouldShowFloatingButton(for: selectedTab)
        }
    }
}

// MARK: - Preview
#Preview {
    MainTabView()
        .modelContainer(for: []) // Empty model container since we don't need real data
        .environment(\.colorScheme, .dark) // Optional: to match the premium theme
}
