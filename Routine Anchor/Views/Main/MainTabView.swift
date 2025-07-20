//
//  MainTabView.swift
//  Routine Anchor
//
//  Created by Christopher Simonson on 7/19/25.
//
import SwiftUI
import SwiftData

struct MainTabView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var tabViewModel = MainTabViewModel()
    @State private var selectedTab: Tab = .today
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Today Tab - Primary screen where users interact with their schedule
            NavigationStack {
                TodayView()
            }
            .tabItem {
                Label {
                    Text("Today")
                } icon: {
                    Image(systemName: selectedTab == .today ? "calendar.circle.fill" : "calendar.circle")
                }
            }
            .tag(Tab.today)
            .badge(tabViewModel.activeTasks)
            
            // Schedule Tab - Create and manage daily routines
            NavigationStack {
                ScheduleBuilderView()
            }
            .tabItem {
                Label {
                    Text("Schedule")
                } icon: {
                    Image(systemName: selectedTab == .schedule ? "clock.fill" : "clock")
                }
            }
            .tag(Tab.schedule)
            
            // Summary Tab - View daily progress and insights
            NavigationStack {
                DailySummaryView()
            }
            .tabItem {
                Label {
                    Text("Summary")
                } icon: {
                    Image(systemName: selectedTab == .summary ? "chart.pie.fill" : "chart.pie")
                }
            }
            .tag(Tab.summary)
            .badge(tabViewModel.shouldShowSummaryBadge ? "•" : nil)
            
            // Settings Tab - App configuration and preferences
            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label {
                    Text("Settings")
                } icon: {
                    Image(systemName: selectedTab == .settings ? "gearshape.fill" : "gearshape")
                }
            }
            .tag(Tab.settings)
        }
        .tint(Color.primaryBlue)
        .onAppear {
            setupTabBarAppearance()
            tabViewModel.setup(with: modelContext)
        }
        .onChange(of: selectedTab) { oldValue, newValue in
            // Handle tab selection analytics or actions
            tabViewModel.didSelectTab(newValue)
            
            // Provide haptic feedback for tab switches
            HapticManager.shared.lightImpact()
        }
    }
    
    private func setupTabBarAppearance() {
        // Configure tab bar appearance for modern iOS
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.systemBackground
        
        // Add subtle shadow
        appearance.shadowColor = UIColor.black.withAlphaComponent(0.1)
        
        // Configure selected state
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor(Color.primaryBlue)
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor(Color.primaryBlue),
            .font: UIFont.systemFont(ofSize: 10, weight: .medium)
        ]
        
        // Configure normal state
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor.systemGray
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor.systemGray,
            .font: UIFont.systemFont(ofSize: 10, weight: .regular)
        ]
        
        // Apply appearance
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
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
            case .summary: return "Summary"
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
        
        var accessibilityIdentifier: String {
            return "tab_\(rawValue)"
        }
    }
}

// MARK: - Tab View Model
@MainActor
class MainTabViewModel: ObservableObject {
    @Published var activeTasks: Int = 0
    @Published var shouldShowSummaryBadge: Bool = false
    
    private var modelContext: ModelContext?
    
    func setup(with context: ModelContext) {
        self.modelContext = context
        updateBadges()
    }
    
    func didSelectTab(_ tab: MainTabView.Tab) {
        // Handle tab selection logic
        switch tab {
        case .today:
            // Refresh today's data when tab is selected
            updateBadges()
        case .summary:
            // Mark summary as viewed
            shouldShowSummaryBadge = false
            UserDefaults.standard.set(Date(), forKey: "lastSummaryViewed")
        default:
            break
        }
    }
    
    private func updateBadges() {
        guard let context = modelContext else { return }
        
        // Update active tasks count for Today tab
        updateActiveTasks(context: context)
        
        // Update summary badge
        updateSummaryBadge()
    }
    
    private func updateActiveTasks(context: ModelContext) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        
        let notStartedStatus = BlockStatus.notStarted.rawValue
        let inProgressStatus = BlockStatus.inProgress.rawValue
        
        let descriptor = FetchDescriptor<TimeBlock>(
            predicate: #Predicate<TimeBlock> { block in
                block.startTime >= today && block.startTime < tomorrow &&
                (block.statusValue == notStartedStatus || block.statusValue == inProgressStatus)
            }
        )
        
        do {
            let blocks = try context.fetch(descriptor)
            activeTasks = blocks.count
        } catch {
            print("Error fetching active tasks: \(error)")
            activeTasks = 0
        }
    }
    
    private func updateSummaryBadge() {
        // Show badge if user hasn't viewed summary today
        let lastViewed = UserDefaults.standard.object(forKey: "lastSummaryViewed") as? Date
        let calendar = Calendar.current
        
        if let lastViewed = lastViewed {
            shouldShowSummaryBadge = !calendar.isDateInToday(lastViewed)
        } else {
            shouldShowSummaryBadge = true
        }
    }
}

// MARK: - Haptic Manager
class HapticManager {
    static let shared = HapticManager()
    
    private init() {}
    
    func lightImpact() {
        let impactGenerator = UIImpactFeedbackGenerator(style: .light)
        impactGenerator.impactOccurred()
    }
    
    func mediumImpact() {
        let impactGenerator = UIImpactFeedbackGenerator(style: .medium)
        impactGenerator.impactOccurred()
    }
    
    func success() {
        let notificationGenerator = UINotificationFeedbackGenerator()
        notificationGenerator.notificationOccurred(.success)
    }
    
    func error() {
        let notificationGenerator = UINotificationFeedbackGenerator()
        notificationGenerator.notificationOccurred(.error)
    }
}

// MARK: - Previews
#Preview("Light Mode") {
    MainTabView()
        .preferredColorScheme(.light)
        .modelContainer(for: [TimeBlock.self, DailyProgress.self], inMemory: true)
}

#Preview("Dark Mode") {
    MainTabView()
        .preferredColorScheme(.dark)
        .modelContainer(for: [TimeBlock.self, DailyProgress.self], inMemory: true)
}

#Preview("With Sample Data") {
    let container = try! ModelContainer(for: TimeBlock.self, DailyProgress.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    
    // Add sample data
    let context = container.mainContext
    let sampleBlock = TimeBlock(title: "Morning Routine", startTime: Date(), endTime: Date().addingTimeInterval(3600))
    context.insert(sampleBlock)
    
    return MainTabView()
        .modelContainer(container)
}
