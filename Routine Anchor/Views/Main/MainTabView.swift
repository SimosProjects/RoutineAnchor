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
                    showFloatingAction = true
                }
            }
            .onChange(of: selectedTab) { oldValue, newValue in
                handleTabSelection(newValue)
            }
            
            // Floating Action Button (appears on Today tab)
            if selectedTab == .today && showFloatingAction {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        FloatingActionButton {
                            // Quick add time block action
                            HapticManager.shared.premiumImpact()
                            // Navigate to add block
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
            showFloatingAction = (tab == .today)
        }
    }
}

// MARK: - Tab Item View
struct TabItemView: View {
    let icon: String
    let selectedIcon: String
    let title: String
    let isSelected: Bool
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: isSelected ? selectedIcon : icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(
                    isSelected ?
                    LinearGradient(
                        colors: [Color.premiumBlue, Color.premiumPurple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ) :
                    LinearGradient(
                        colors: [Color.white.opacity(0.6), Color.white.opacity(0.6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .scaleEffect(isSelected ? 1.1 : 1.0)
                .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isSelected)
            
            Text(title)
                .font(.system(size: 10, weight: isSelected ? .semibold : .medium))
                .foregroundStyle(
                    isSelected ? Color.premiumBlue : Color.white.opacity(0.6)
                )
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

// MARK: - Premium View Placeholders

struct PremiumScheduleBuilderView: View {
    var body: some View {
        Text("Premium Schedule Builder")
            .foregroundStyle(.white)
    }
}

struct PremiumDailySummaryView: View {
    var body: some View {
        Text("Premium Daily Summary")
            .foregroundStyle(.white)
    }
}

// MARK: - Enhanced Tab View Model
@MainActor
class MainTabViewModel: ObservableObject {
    @Published var activeTasks: Int = 0
    @Published var shouldShowSummaryBadge: Bool = false
    @Published var selectedTabProgress: Double = 0.0
    
    private var modelContext: ModelContext?
    
    func setup(with context: ModelContext) {
        self.modelContext = context
        updateBadges()
    }
    
    func didSelectTab(_ tab: MainTabView.Tab) {
        // Enhanced tab selection logic with animations
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            selectedTabProgress = 1.0
        }
        
        // Reset after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.9)) {
                self.selectedTabProgress = 0.0
            }
        }
        
        switch tab {
        case .today:
            updateBadges()
        case .summary:
            shouldShowSummaryBadge = false
            UserDefaults.standard.set(Date(), forKey: "lastSummaryViewed")
        default:
            break
        }
    }
    
    private func updateBadges() {
        guard let context = modelContext else { return }
        updateActiveTasks(context: context)
        updateSummaryBadge()
    }
    
    private func updateActiveTasks(context: ModelContext) {
        // Implementation for counting active tasks
        // This would use your existing data fetching logic
        activeTasks = 0 // Placeholder
    }
    
    private func updateSummaryBadge() {
        let lastViewed = UserDefaults.standard.object(forKey: "lastSummaryViewed") as? Date
        let calendar = Calendar.current
        
        if let lastViewed = lastViewed {
            shouldShowSummaryBadge = !calendar.isDateInToday(lastViewed)
        } else {
            shouldShowSummaryBadge = true
        }
    }
}

// MARK: - Preview
#Preview {
    MainTabView()
        .modelContainer(for: []) // Empty model container since we don't need real data
        .environment(\.colorScheme, .dark) // Optional: to match the premium theme
}
