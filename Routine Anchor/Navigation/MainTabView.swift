//
//  MainTabView.swift
//  Routine Anchor
//
import SwiftUI
import SwiftData
import EventKit

struct MainTabView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.premiumManager) private var premiumManager
    @Environment(\.themeManager) private var themeManager
    @EnvironmentObject private var authManager: AuthenticationManager
    @EnvironmentObject private var adManager: AdManager

    @State private var tabViewModel = MainTabViewModel()
    @State private var calendarVM = CalendarAccessViewModel()
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
    private var safePremiumManager: PremiumManager { premiumManager ?? PremiumManager() }

    // Theme helpers
    private var theme: Theme { themeManager?.currentTheme ?? Theme.defaultTheme }
    private var scheme: ThemeColorScheme { theme.colorScheme }

    private var themePrimaryText: Color { theme.primaryTextColor }
    private var themeAccent: Color { theme.buttonAccentColor }
    private var themeBackground: Color { scheme.primaryBackground.color }

    // Helper gradient per tab
    private func gradientColors(for tab: Tab) -> [Color] {
        switch tab {
        case .today:    return [scheme.normal.color, scheme.secondaryUIElement.color]
        case .schedule: return [scheme.primaryAccent.color, scheme.normal.color]
        case .summary:  return [scheme.success.color, scheme.secondaryUIElement.color]
        case .analytics:return [scheme.warning.color, scheme.primaryAccent.color]
        case .settings: return [theme.secondaryTextColor, theme.subtleTextColor]
        }
    }

    var body: some View {
        ZStack {
            ThemedAnimatedBackground()
                .ignoresSafeArea()

            TabView(selection: tabSelectionBinding) {
                // Today
                NavigationStack {
                    TodayView(modelContext: modelContext)
                        .environment(\.themeManager, themeManager)
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

                // Schedule
                NavigationStack {
                    ScheduleBuilderView()
                        .environment(\.themeManager, themeManager)
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

                // Insights (Daily Summary)
                NavigationStack {
                    DailySummaryView(modelContext: modelContext)
                        .environment(\.premiumManager, safePremiumManager)
                        .environment(\.themeManager, themeManager)
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

                // Analytics (gated)
                NavigationStack {
                    analyticsTab
                        .environment(\.premiumManager, safePremiumManager)
                        .environment(\.themeManager, themeManager)
                        .background(Color.clear)
                }
                .themedNavBar(theme)
                .tabItem {
                    TabItemView(
                        icon: "chart.bar",
                        selectedIcon: "chart.bar.fill",
                        title: "Analytics",
                        isSelected: selectedTab == .analytics
                    )
                }
                .tag(Tab.analytics)

                // Settings
                NavigationStack {
                    SettingsView()
                        .environmentObject(authManager)
                        .environment(\.themeManager, themeManager)
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
            .tint(themeAccent)
            .background(Color.clear)
            .onAppear {
                setupTabBarAppearance()
                setupTabBar()
            }
            .onChange(of: theme.id) { oldValue, newValue in
                guard oldValue != newValue else { return }
                setupTabBarAppearance()
                setupTabBar()
            }
            .environmentObject(calendarVM)
            .task {
              calendarVM.attachModelContext(modelContext)   // keep it wired once
              await calendarVM.reconcileLinkedBlocksIfNeeded() // one-off sweep on first launch
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
              Task { await calendarVM.reconcileLinkedBlocksIfNeeded() }
            }
            .task { await setupInitialState() }
            .task { await monitorTabChangeRequests() }
            .task { await monitorNavigationNotifications() }

            // Floating action button
            floatingActionButton
        }
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: showingPremiumUpgrade)

        // Sheets
        .sheet(isPresented: $showingAddTimeBlock) {
            AddTimeBlockView(
                existingTimeBlocks: existingTimeBlocks
            ) { title, startTime, endTime, notes, category, icon, linkToCal, calId in
                createTimeBlock(title: title, startTime: startTime, endTime: endTime, notes: notes ?? "", category: category ?? "", icon: icon ?? "", linkToCalendar: linkToCal, selectedCalendarId: calId)
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

        // Email capture trigger + initial data load
        .onAppear {
            if !hasHandledEmailCaptureThisSession {
                hasHandledEmailCaptureThisSession = true
                checkForEmailCapture()
            }
            loadExistingTimeBlocks()
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
        if safePremiumManager.canAccessAdvancedAnalytics {
            PremiumAnalyticsView(premiumManager: safePremiumManager)
        } else {
            BasicAnalyticsView {
                showingPremiumUpgrade = true
            }
        }
    }

    // MARK: - Helpers

    private func handleTabChangeWithAds(from oldTab: Tab, to newTab: Tab) {
        guard !adManager.isShowingAd else { return }
        if shouldShowInterstitialAd() {
            adManager.showInterstitialIfAllowed(premiumManager: safePremiumManager)
        }
        loadExistingTimeBlocks()
    }

    private func createTimeBlock(
        title: String,
        startTime: Date,
        endTime: Date,
        notes: String,
        category: String,
        icon: String,
        linkToCalendar: Bool = false,
        selectedCalendarId: String? = nil
    ) {
        var eventId: String? = nil
        var calId: String? = nil
        var lastModified: Date? = nil

        if linkToCalendar, let targetCalId = selectedCalendarId {
            let store = EKEventStore()
            if hasEventAccess() {
                if let cal = store.calendar(withIdentifier: targetCalId) {
                    do {
                        let ev = EKEvent(eventStore: store)
                        ev.calendar  = cal
                        ev.title     = title
                        ev.notes     = notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : notes
                        ev.startDate = startTime
                        ev.endDate   = endTime

                        try store.save(ev, span: .thisEvent, commit: true)
                        eventId      = ev.eventIdentifier
                        calId        = targetCalId
                        lastModified = ev.lastModifiedDate
                    } catch {
                        print("EventKit create failed: \(error)")
                    }
                } else {
                    print("Calendar not found for id: \(targetCalId)")
                }
            } else {
                print("EventKit not authorized; skipping calendar creation")
            }
        }

        // Normalize inputs
        let normalizedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : notes
        let normalizedIcon  = icon.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : icon

        // Build the TimeBlock
        let newBlock = TimeBlock(
            title: title,
            startTime: startTime,
            endTime: endTime,
            notes: normalizedNotes,
            icon: normalizedIcon,
            category: category,
            colorId: nil,
            calendarEventId: eventId,
            calendarId: calId,
            calendarLastModified: lastModified
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
    
    @inline(__always)
    private func hasEventAccess() -> Bool {
        switch EKEventStore.authorizationStatus(for: .event) {
        case .fullAccess, .writeOnly:
            return true
        case .authorized:
            return true
        default:
            return false
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

    private func shouldShowInterstitialAd() -> Bool {
        guard safePremiumManager.shouldShowAds else { return false }
        guard !adManager.isShowingAd && adManager.isAdLoaded else { return false }
        let count = UserDefaults.standard.integer(forKey: "tabSwitchCount") + 1
        UserDefaults.standard.set(count, forKey: "tabSwitchCount")
        return count % 5 == 0
    }

    private func checkForEmailCapture() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            authManager.checkShouldShowEmailCapture(premiumManager: safePremiumManager)
        }
    }

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

    // Floating Action Button
    @ViewBuilder
    private var floatingActionButton: some View {
        if shouldShowFloatingButton(for: selectedTab) {
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    FloatingActionButton(
                        tab: selectedTab,
                        tabGradientColors: gradientColors(for: selectedTab),
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

    private func shouldShowFloatingButton(for tab: Tab) -> Bool { tab == .today }

    private func floatingActionTapped() {
        HapticManager.shared.mediumImpact()
        if selectedTab == .today {
            loadExistingTimeBlocks()
            showingAddTimeBlock = true
        }
    }

    // Setup
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

        let app = UITabBarAppearance()
        app.configureWithTransparentBackground()
        app.backgroundColor = .clear
        app.backgroundEffect = UIBlurEffect(style: .systemMaterialDark)

        UITabBar.appearance().standardAppearance = app
        UITabBar.appearance().scrollEdgeAppearance = app
    }

    private func setupTabBar() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(themeBackground).withAlphaComponent(0.95)
        appearance.backgroundEffect = UIBlurEffect(style: .systemMaterialDark)

        appearance.shadowImage = UIImage()
        appearance.shadowColor = .clear

        let normalIconColor = themePrimaryText.opacity(0.5)
        let selectedIconColor = themeAccent

        appearance.stackedLayoutAppearance.normal.iconColor = UIColor(normalIconColor)
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor(normalIconColor),
            .font: UIFont.systemFont(ofSize: 11, weight: .medium)
        ]
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor(selectedIconColor)
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor(selectedIconColor),
            .font: UIFont.systemFont(ofSize: 11, weight: .semibold)
        ]

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }

    // Tab change events
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
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            showFloatingAction = shouldShowFloatingButton(for: newTab)
        }
        broadcastTabChange(newTab)
    }

    private func broadcastTabChange(_ tab: Tab) {
        NotificationCenter.default.post(name: .tabDidChange, object: nil, userInfo: ["tab": tab.rawValue])
        switch tab {
        case .today:    NotificationCenter.default.post(name: .refreshTodayView, object: nil)
        case .schedule: NotificationCenter.default.post(name: .refreshScheduleView, object: nil)
        case .summary:  NotificationCenter.default.post(name: .refreshSummaryView, object: nil)
        default: break
        }
    }
}

// MARK: - Basic Analytics View (Free Users)
struct BasicAnalyticsView: View {
    @Environment(\.themeManager) private var themeManager
    @Environment(\.modelContext) private var modelContext

    @State private var dataManager: DataManager?
    @State private var todaysProgress: DailyProgress?
    @State private var weeklyStats: (totalBlocks: Int, completedBlocks: Int, averageCompletion: Double)?

    let onUpgrade: () -> Void

    private var theme: Theme { themeManager?.currentTheme ?? Theme.defaultTheme }
    private var scheme: ThemeColorScheme { theme.colorScheme }
    private var themePrimaryText: Color { theme.primaryTextColor }
    private var themeSecondaryText: Color { theme.secondaryTextColor }
    private var themeTertiaryText: Color { theme.subtleTextColor }

    var body: some View {
        ZStack {
            ThemedAnimatedBackground()
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
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
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    onUpgrade()
                    HapticManager.shared.anchorSelection()
                } label: {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(scheme.warning.color)
                        .padding(8)
                        .background(
                            Circle()
                                .fill(scheme.secondaryBackground.color)
                                .overlay(Circle().stroke(scheme.border.color.opacity(0.85), lineWidth: 1))
                        )
                }
                .accessibilityLabel("Upgrade to Premium")
            }
        }
        .onAppear {
            applyTransparentNavBarAppearance()
        }
        // Re-apply when the theme changes
        .onChange(of: theme.id) { _, _ in
            applyTransparentNavBarAppearance()
        }
        .task { await loadBasicAnalytics() }
    }

    // Make the UINavigationBar fully transparent so it doesn’t go gray when scrolling
    private func applyTransparentNavBarAppearance() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundEffect = nil
        appearance.backgroundColor = .clear
        appearance.titleTextAttributes       = [.foregroundColor: UIColor(themePrimaryText.opacity(0.9))]
        appearance.largeTitleTextAttributes  = [.foregroundColor: UIColor(themePrimaryText.opacity(0.9))]

        UINavigationBar.appearance().standardAppearance   = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance    = appearance
    }

    private var headerSection: some View {
        VStack(spacing: 8) {
            Text("Your Progress")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(themePrimaryText)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text("A quick snapshot of today and this week.")
                .font(.system(size: 16))
                .foregroundStyle(themeSecondaryText)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var basicStatsSection: some View {
        ThemedCard(cornerRadius: 20) {
            VStack(spacing: 16) {
                Text("Today's Overview")
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundStyle(themePrimaryText)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if let progress = todaysProgress {
                    HStack(spacing: 16) {
                        StatCard(
                            title: "Completed",
                            value: "\(progress.completedBlocks)",
                            subtitle: "blocks",
                            color: scheme.success.color,
                            icon: "checkmark.circle.fill"
                        )
                        StatCard(
                            title: "Progress",
                            value: "\(Int(progress.completionPercentage * 100))%",
                            subtitle: "today",
                            color: scheme.normal.color,
                            icon: "chart.pie.fill"
                        )
                    }

                    if let weeklyStats {
                        HStack(spacing: 16) {
                            StatCard(
                                title: "This Week",
                                value: "\(weeklyStats.completedBlocks)",
                                subtitle: "completed",
                                color: scheme.primaryAccent.color,
                                icon: "calendar.circle.fill"
                            )
                            StatCard(
                                title: "Average",
                                value: "\(Int(weeklyStats.averageCompletion * 100))%",
                                subtitle: "weekly",
                                color: scheme.secondaryUIElement.color,
                                icon: "chart.line.uptrend.xyaxis"
                            )
                        }
                    }
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "chart.bar.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(themeTertiaryText)
                        Text("No data yet")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(themeSecondaryText)
                        Text("Create and complete time blocks to see your progress!")
                            .font(.system(size: 14))
                            .foregroundStyle(themeTertiaryText)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.vertical, 40)
                }
            }
        }
    }

    private var premiumFeaturesShowcase: some View {
        ThemedCard(cornerRadius: 20) {
            VStack(spacing: 16) {
                HStack {
                    Text("Premium Analytics")
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .foregroundStyle(themePrimaryText)
                    Spacer()
                    PremiumBadge()
                }

                VStack(spacing: 12) {
                    PremiumFeaturePreview(
                        icon: "chart.line.uptrend.xyaxis",
                        title: "Productivity Trends",
                        description: "Track your completion rates over time",
                        color: scheme.normal.color
                    )
                    PremiumFeaturePreview(
                        icon: "brain.head.profile",
                        title: "Peak Performance Times",
                        description: "Discover when you're most productive",
                        color: scheme.success.color
                    )
                    PremiumFeaturePreview(
                        icon: "lightbulb.fill",
                        title: "AI-Powered Insights",
                        description: "Get personalized recommendations",
                        color: scheme.warning.color
                    )
                    PremiumFeaturePreview(
                        icon: "target",
                        title: "Category Performance",
                        description: "Analyze completion by activity type",
                        color: scheme.primaryAccent.color
                    )
                }
            }
        }
    }

    private var upgradePromptSection: some View {
        PremiumMiniPrompt(
            title: "Unlock advanced analytics",
            subtitle: "Trends, AI insights, and more",
            onUpgrade: onUpgrade
        )
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


// MARK: - Premium Feature Preview
struct PremiumFeaturePreview: View {
    let icon: String
    let title: String
    let description: String
    let color: Color

    @Environment(\.themeManager) private var themeManager
    private var theme: Theme { themeManager?.currentTheme ?? Theme.defaultTheme }

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
                .foregroundStyle(theme.colorScheme.warning.color)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Floating Action Button
struct FloatingActionButton: View {
    let tab: MainTabView.Tab
    let tabGradientColors: [Color]
    let action: () -> Void

    @Environment(\.themeManager) private var themeManager
    @State private var isPressed = false
    @State private var pulseScale: CGFloat = 1.0

    private var icon: String { "plus" }
    private var theme: Theme { themeManager?.currentTheme ?? Theme.defaultTheme }

    private var gradientColors: [Color] {
        [theme.buttonPrimaryColor, theme.buttonAccentColor]
    }
    private var shadowColor: Color { theme.buttonPrimaryColor.opacity(0.4) }
    private var backgroundShadowColor: Color { theme.colorScheme.primaryBackground.color.opacity(0.2) }

    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { isPressed = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { isPressed = false }
            action()
        }) {
            ZStack {
                Circle()
                    .fill(RadialGradient(colors: [gradientColors[0].opacity(0.3), .clear],
                                         center: .center, startRadius: 20, endRadius: 40))
                    .frame(width: 80, height: 80)
                    .scaleEffect(pulseScale)
                    .opacity(0.5)

                Circle()
                    .fill(LinearGradient(colors: gradientColors, startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 56, height: 56)

                Image(systemName: icon)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundStyle(theme.primaryTextColor)
                    .rotationEffect(.degrees(isPressed ? 90 : 0))
            }
            .shadow(color: shadowColor, radius: 12, x: 0, y: 6)
            .shadow(color: backgroundShadowColor, radius: 8, x: 0, y: 4)
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
