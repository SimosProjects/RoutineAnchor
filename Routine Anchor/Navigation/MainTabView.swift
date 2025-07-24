//
//  MainTabView.swift
//  Routine Anchor - Premium Version
//
import SwiftUI
import SwiftData

struct MainTabView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var tabViewModel = MainTabViewModel()
    @State private var selectedTab: Tab = .today
    @State private var tabBarOffset: CGFloat = 0
    @State private var showFloatingAction = false
    
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
            .onAppear {
                setupPremiumTabBar()
                tabViewModel.setup(with: modelContext)
                
                // Animate floating action button
                withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.5)) {
                    showFloatingAction = shouldShowFloatingButton(for: selectedTab)
                }
            }
            .onChange(of: selectedTab) { oldValue, newValue in
                handleTabSelection(newValue)
            }
            
            // Floating Action Button (appears on Today and Schedule tabs)
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
        /*.sheet(isPresented: $showingAddTimeBlock) {
            PremiumAddTimeBlockView { title, startTime, endTime, notes, category in
                // Handle the new time block creation
                handleNewTimeBlock(title: title, startTime: startTime, endTime: endTime, notes: notes, category: category)
            }
        }*/
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
        // This will be handled by the Schedule view model
        // The sheet dismissal will trigger the Schedule view to reload
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

extension Notification.Name {
    static let showAddTimeBlockFromTab = Notification.Name("showAddTimeBlockFromTab")
}

// MARK: - Preview
#Preview {
    MainTabView()
        .modelContainer(for: []) // Empty model container since we don't need real data
        .environment(\.colorScheme, .dark) // Optional: to match the premium theme
}
