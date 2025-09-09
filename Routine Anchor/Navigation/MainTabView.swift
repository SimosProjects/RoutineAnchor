//
//  MainTabView.swift
//  Routine Anchor
//
//  Navigation shell wired to token-based AppTheme.
//

import SwiftUI
import SwiftData

struct MainTabView: View {
    // Env
    @Environment(\.modelContext) private var modelContext
    @Environment(\.premiumManager) private var premiumManager
    @Environment(\.themeManager) private var themeManager
    @EnvironmentObject private var authManager: AuthenticationManager
    @EnvironmentObject private var adManager: AdManager

    // Local state
    @State private var tabViewModel = MainTabViewModel()
    @State private var selectedTab: Tab = .today
    @State private var showFloatingAction = false
    @State private var showingAddTimeBlock = false
    @State private var existingTimeBlocks: [TimeBlock] = []
    @State private var showingEmailCapture = false
    @State private var showingPremiumUpgrade = false
    @State private var isInternalTabChange = false
    @State private var hasHandledEmailCaptureThisSession = false

    // Safe fallbacks
    private var theme: AppTheme { themeManager?.currentTheme ?? PredefinedThemes.classic }
    private var safePremiumManager: PremiumManager { premiumManager ?? PremiumManager() }

    var body: some View {
        ZStack {
            ThemedAnimatedBackground().ignoresSafeArea()

            TabView(selection: tabSelectionBinding) {
                // Today
                NavigationStack {
                    TodayView(modelContext: modelContext)
                        .environment(\.themeManager, themeManager)
                        .background(Color.clear)
                }
                .tabItem { TabItemView(icon: "calendar.circle", selectedIcon: "calendar.circle.fill", title: "Today", isSelected: selectedTab == .today) }
                .tag(Tab.today)

                // Schedule
                NavigationStack {
                    ScheduleBuilderView()
                        .environment(\.themeManager, themeManager)
                        .background(Color.clear)
                }
                .tabItem { TabItemView(icon: "clock", selectedIcon: "clock.fill", title: "Schedule", isSelected: selectedTab == .schedule) }
                .tag(Tab.schedule)

                // Insights (Daily Summary)
                NavigationStack {
                    DailySummaryView(modelContext: modelContext)
                        .environment(\.premiumManager, safePremiumManager)
                        .environment(\.themeManager, themeManager)
                        .background(Color.clear)
                }
                .tabItem {
                    TabItemView(icon: "chart.pie", selectedIcon: "chart.pie.fill", title: "Insights", isSelected: selectedTab == .summary)
                        .badge(tabViewModel.shouldShowSummaryBadge ? "" : nil)
                }
                .tag(Tab.summary)

                // Analytics (gated)
                NavigationStack {
                    analyticsTab
                        .environment(\.premiumManager, safePremiumManager)
                        .environment(\.themeManager, themeManager)
                        .background(Color.clear)
                }
                .tabItem { TabItemView(icon: "chart.bar", selectedIcon: "chart.bar.fill", title: "Analytics", isSelected: selectedTab == .analytics) }
                .tag(Tab.analytics)

                // Settings
                NavigationStack {
                    SettingsView()
                        .environmentObject(authManager)
                        .environment(\.themeManager, themeManager)
                        .background(Color.clear)
                }
                .tabItem { TabItemView(icon: "gearshape", selectedIcon: "gearshape.fill", title: "Settings", isSelected: selectedTab == .settings) }
                .tag(Tab.settings)
            }
            .tint(theme.accentPrimaryColor)
            .background(Color.clear)
            .task { await setupInitialState() }
            .task { await monitorTabChangeRequests() }
            .task { await monitorNavigationNotifications() }
            .onAppear {
                if !hasHandledEmailCaptureThisSession {
                    hasHandledEmailCaptureThisSession = true
                    checkForEmailCapture()
                }
                loadExistingTimeBlocks()
                applyTabBarAppearance()
            }
            .onChange(of: theme.name) { _, _ in
                // theme changed → update tab bar inks/typography
                applyTabBarAppearance()
            }

            // Floating action button
            floatingActionButton
        }
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: showingPremiumUpgrade)

        // Sheets
        .sheet(isPresented: $showingAddTimeBlock) {
            AddTimeBlockView(existingTimeBlocks: existingTimeBlocks) { title, startTime, endTime, notes, category in
                createTimeBlock(title: title, startTime: startTime, endTime: endTime, notes: notes ?? "", category: category ?? "")
            }
            .environment(\.themeManager, themeManager)
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingEmailCapture) {
            EmailCaptureView { email in authManager.captureEmail(email) }
                .environment(\.themeManager, themeManager)
                .onDisappear {
                    if !authManager.isEmailCaptured { authManager.dismissEmailCapture() }
                }
        }
        .sheet(isPresented: $showingPremiumUpgrade) {
            PremiumUpgradeView()
                .environment(\.themeManager, themeManager)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .onReceive(authManager.$shouldShowEmailCapture) { shouldShow in
            if shouldShow && !showingEmailCapture && !authManager.isEmailCaptured {
                showingEmailCapture = true
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ForceShowEmailCapture"))) { _ in
            showingEmailCapture = true
        }
        .onChange(of: selectedTab) { oldTab, newTab in
            handleTabChangeWithAds(from: oldTab, to: newTab)
        }
    }

    // MARK: - Analytics Tab (gated)
    @ViewBuilder
    private var analyticsTab: some View {
        if safePremiumManager.userIsPremium {
            PremiumAnalyticsView(premiumManager: safePremiumManager)
        } else {
            BasicAnalyticsView {
                showingPremiumUpgrade = true
            }
        }
    }

    // MARK: - FAB
    @ViewBuilder
    private var floatingActionButton: some View {
        if selectedTab == .today {
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    FloatingActionButton(
                        tab: selectedTab,
                        tabGradientColors: [theme.accentPrimaryColor, theme.accentSecondaryColor],
                        action: floatingActionTapped
                    )
                    .scaleEffect(showFloatingAction ? 1.0 : 0.01)
                    .opacity(showFloatingAction ? 1.0 : 0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.7), value: showFloatingAction)
                    .padding(.trailing, 24)
                    .padding(.bottom, 100)
                }
            }
            .transition(.asymmetric(insertion: .scale(scale: 0.8).combined(with: .opacity),
                                    removal: .scale(scale: 0.6).combined(with: .opacity)))
        }
    }
    
    // MARK: - Actions
    private func floatingActionTapped() {
        HapticManager.shared.impact()
        // Route to the “quick add time block” flow that Today listens for.
        NotificationCenter.default.post(name: .showAddTimeBlockFromTab, object: nil)
    }

    // MARK: - Setup / Appearance

    @MainActor
    private func setupInitialState() async {
        tabViewModel.setup(with: modelContext)
        withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.5)) {
            showFloatingAction = (selectedTab == .today)
        }
    }

    /// Re-colors UITabBar using semantic tokens.
    private func applyTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        // Secondary background is a good “chrome” color
        appearance.backgroundColor = UIColor(theme.color.bg.secondary).withAlphaComponent(0.95)
        appearance.backgroundEffect = UIBlurEffect(style: theme.isLight ? .systemMaterialLight : .systemMaterialDark)
        appearance.shadowImage = UIImage()
        appearance.shadowColor = .clear

        let normalColor = UIColor(theme.secondaryTextColor.opacity(0.6))
        let selectedColor = UIColor(theme.accentPrimaryColor)

        appearance.stackedLayoutAppearance.normal.iconColor = normalColor
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: normalColor,
            .font: UIFont.systemFont(ofSize: 11, weight: .medium)
        ]
        appearance.stackedLayoutAppearance.selected.iconColor = selectedColor
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: selectedColor,
            .font: UIFont.systemFont(ofSize: 11, weight: .semibold)
        ]

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }

    // MARK: - Selection / Ads

    private var tabSelectionBinding: Binding<Tab> {
        Binding(
            get: { selectedTab },
            set: { newValue in
                guard !isInternalTabChange, newValue != selectedTab else { return }
                selectedTab = newValue
                handleTabChange(to: newValue)
            }
        )
    }

    private func handleTabChange(to newTab: MainTabView.Tab) {
        tabViewModel.didSelectTab(newTab)
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            showFloatingAction = (newTab == .today)
        }
    }

    private func handleTabChangeWithAds(from _: Tab, to _: Tab) {
        guard !adManager.isShowingAd, safePremiumManager.shouldShowAds, adManager.isAdLoaded else { return }
        let count = UserDefaults.standard.integer(forKey: "tabSwitchCount") + 1
        UserDefaults.standard.set(count, forKey: "tabSwitchCount")
        if count % 5 == 0 { adManager.showInterstitialIfAllowed(premiumManager: safePremiumManager) }
        loadExistingTimeBlocks()
    }

    // MARK: - Data helpers

    private func createTimeBlock(title: String, startTime: Date, endTime: Date, notes: String, category: String) {
        let newBlock = TimeBlock(title: title, startTime: startTime, endTime: endTime, notes: notes, category: category)
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
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let tomorrow = cal.date(byAdding: .day, value: 1, to: today) ?? today

        let descriptor = FetchDescriptor<TimeBlock>(
            predicate: #Predicate<TimeBlock> { tb in tb.startTime >= today && tb.startTime < tomorrow },
            sortBy: [SortDescriptor(\.startTime)]
        )
        do { existingTimeBlocks = try modelContext.fetch(descriptor) }
        catch { existingTimeBlocks = [] }
    }

    private func checkForEmailCapture() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            authManager.checkShouldShowEmailCapture(premiumManager: safePremiumManager)
        }
    }

    // MARK: - Notification-driven tab changes

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
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) { selectedTab = tab }
        } else {
            selectedTab = tab
        }
        handleTabChange(to: tab)
        try? await Task.sleep(nanoseconds: 100_000_000)
        isInternalTabChange = false
    }
}

// MARK: - Basic Analytics (free)
private struct BasicAnalyticsView: View {
    @Environment(\.themeManager) private var themeManager
    @Environment(\.modelContext) private var modelContext

    @State private var dataManager: DataManager?
    @State private var todaysProgress: DailyProgress?
    @State private var weeklyStats: (totalBlocks: Int, completedBlocks: Int, averageCompletion: Double)?

    let onUpgrade: () -> Void
    private var theme: AppTheme { themeManager?.currentTheme ?? PredefinedThemes.classic }

    var body: some View {
        ZStack {
            ThemedAnimatedBackground().ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Text("Your Progress")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundStyle(theme.primaryTextColor)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        Text("A quick snapshot of today and this week.")
                            .font(.system(size: 16))
                            .foregroundStyle(theme.secondaryTextColor)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    // Cards
                    ThemedCard(cornerRadius: 20) {
                        VStack(spacing: 16) {
                            Text("Today's Overview")
                                .font(.system(size: 20, weight: .semibold, design: .rounded))
                                .foregroundStyle(theme.primaryTextColor)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            if let progress = todaysProgress {
                                HStack(spacing: 16) {
                                    StatCard(title: "Completed", value: "\(progress.completedBlocks)", subtitle: "blocks", color: theme.statusSuccessColor, icon: "checkmark.circle.fill")
                                    StatCard(title: "Progress", value: "\(Int(progress.completionPercentage * 100))%", subtitle: "today", color: theme.accentPrimaryColor, icon: "chart.pie.fill")
                                }

                                if let weeklyStats {
                                    HStack(spacing: 16) {
                                        StatCard(title: "This Week", value: "\(weeklyStats.completedBlocks)", subtitle: "completed", color: theme.accentSecondaryColor, icon: "calendar.circle.fill")
                                        StatCard(title: "Average", value: "\(Int(weeklyStats.averageCompletion * 100))%", subtitle: "weekly", color: theme.statusInfoColor, icon: "chart.line.uptrend.xyaxis")
                                    }
                                }
                            } else {
                                VStack(spacing: 12) {
                                    Image(systemName: "chart.bar.fill")
                                        .font(.system(size: 40))
                                        .foregroundStyle(theme.subtleTextColor)
                                    Text("No data yet")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundStyle(theme.secondaryTextColor)
                                    Text("Create and complete time blocks to see your progress!")
                                        .font(.system(size: 14))
                                        .foregroundStyle(theme.subtleTextColor)
                                        .multilineTextAlignment(.center)
                                }
                                .padding(.vertical, 40)
                            }
                        }
                    }

                    // Premium showcase
                    ThemedCard(cornerRadius: 20) {
                        VStack(spacing: 16) {
                            HStack {
                                Text("Premium Analytics")
                                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                                    .foregroundStyle(theme.primaryTextColor)
                                Spacer()
                                PremiumBadge()
                            }

                            VStack(spacing: 12) {
                                PremiumFeaturePreview(icon: "chart.line.uptrend.xyaxis", title: "Productivity Trends", description: "Track your completion rates over time", color: theme.accentPrimaryColor)
                                PremiumFeaturePreview(icon: "brain.head.profile", title: "Peak Performance Times", description: "Discover when you're most productive", color: theme.statusSuccessColor)
                                PremiumFeaturePreview(icon: "lightbulb.fill", title: "AI-Powered Insights", description: "Get personalized recommendations", color: theme.statusWarningColor)
                                PremiumFeaturePreview(icon: "target", title: "Category Performance", description: "Analyze completion by activity type", color: theme.accentSecondaryColor)
                            }
                        }
                    }

                    PremiumMiniPrompt(title: "Unlock advanced analytics", subtitle: "Trends, AI insights, and more", onUpgrade: onUpgrade)
                }
                .padding(.horizontal)
                .padding(.bottom, 100)
            }
        }
        .navigationTitle("Analytics")
        .navigationBarTitleDisplayMode(.large)
        .task { await loadBasicAnalytics() }
        .onAppear { applyTransparentNavBarAppearance() }
        .onChange(of: theme.name) { _, _ in applyTransparentNavBarAppearance() }
    }

    private func applyTransparentNavBarAppearance() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundEffect = nil
        appearance.backgroundColor = .clear
        appearance.titleTextAttributes      = [.foregroundColor: UIColor(theme.primaryTextColor.opacity(0.9))]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor(theme.primaryTextColor.opacity(0.9))]
        UINavigationBar.appearance().standardAppearance   = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance    = appearance
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

        let total = timeBlocks.count
        let completed = timeBlocks.filter { $0.status == .completed }.count
        let avg = total > 0 ? Double(completed) / Double(total) : 0
        weeklyStats = (totalBlocks: total, completedBlocks: completed, averageCompletion: avg)
    }
}

// MARK: - Premium Feature Preview (uses tokens only)
private struct PremiumFeaturePreview: View {
    let icon: String
    let title: String
    let description: String
    let color: Color

    @Environment(\.themeManager) private var themeManager
    private var theme: AppTheme { themeManager?.currentTheme ?? PredefinedThemes.classic }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(color)
                .frame(width: 32, height: 32)
                .background(Circle().fill(color.opacity(0.15)))

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(theme.subtleTextColor)
                Text(description)
                    .font(.system(size: 12))
                    .foregroundStyle(theme.subtleTextColor.opacity(0.8))
                    .lineLimit(2)
            }

            Spacer()
            Image(systemName: "lock.fill")
                .font(.system(size: 12))
                .foregroundStyle(theme.statusWarningColor)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Floating Action Button (uses tokens only)
private struct FloatingActionButton: View {
    let tab: MainTabView.Tab
    let tabGradientColors: [Color] // kept for API parity; we don’t rely on it
    let action: () -> Void

    @Environment(\.themeManager) private var themeManager
    @State private var isPressed = false
    @State private var pulseScale: CGFloat = 1.0

    private var theme: AppTheme { themeManager?.currentTheme ?? PredefinedThemes.classic }

    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { isPressed = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { isPressed = false }
            action()
        }) {
            ZStack {
                Circle()
                    .fill(RadialGradient(colors: [theme.accentPrimaryColor.opacity(0.30), .clear],
                                         center: .center, startRadius: 20, endRadius: 40))
                    .frame(width: 80, height: 80)
                    .scaleEffect(pulseScale)
                    .opacity(0.5)

                Circle()
                    .fill(theme.actionPrimaryGradient)
                    .frame(width: 56, height: 56)

                Image(systemName: "plus")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundStyle(theme.invertedTextColor)
                    .rotationEffect(.degrees(isPressed ? 90 : 0))
            }
            .shadow(color: theme.accentPrimaryColor.opacity(0.4), radius: 12, x: 0, y: 6)
            .shadow(color: theme.color.bg.primary.opacity(0.2), radius: 8, x: 0, y: 4)
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
        case today, schedule, summary, analytics, settings

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
            case .analytics: return "chart.bar.fill"
            case .settings: return "gearshape.fill"
            }
        }
    }
}

#Preview {
    MainTabView()
        .modelContainer(for: [TimeBlock.self, DailyProgress.self, RoutineTemplate.self], inMemory: true)
        .environment(\.premiumManager, PremiumManager())
        .environmentObject(AuthenticationManager())
        .environmentObject(AdManager())
        .environment(\.colorScheme, .dark)
}
