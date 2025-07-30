//
//  MainTabViewModel.swift
//  Routine Anchor (iOS 17+ Optimized)
//
//  Created by Christopher Simonson on 7/23/25.
//
import SwiftUI
import SwiftData

@Observable
@MainActor
class MainTabViewModel {
    // MARK: - Published Properties (now automatically observable)
    var activeTasks: Int = 0
    var shouldShowSummaryBadge: Bool = false
    var selectedTabProgress: Double = 0.0
    
    // MARK: - Private Properties
    private var modelContext: ModelContext?
    
    // MARK: - Setup
    func setup(with context: ModelContext) async {
        self.modelContext = context
        await updateBadges()
    }
    
    // MARK: - Public Methods
    func didSelectTab(_ tab: MainTabView.Tab) async {
        // Animate tab selection progress
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            selectedTabProgress = 1.0
        }
        
        // Reset progress after animation
        try? await Task.sleep(nanoseconds: 600_000_000)
        
        withAnimation(.spring(response: 0.4, dampingFraction: 0.9)) {
            selectedTabProgress = 0.0
        }
        
        // Handle tab-specific logic
        switch tab {
        case .today:
            await updateBadges()
        case .summary:
            shouldShowSummaryBadge = false
            UserDefaults.standard.set(Date(), forKey: "lastSummaryViewed")
        default:
            break
        }
    }
    
    // MARK: - Private Methods
    private func updateBadges() async {
        guard let context = modelContext else { return }
        
        await updateActiveTasks(context: context)
        updateSummaryBadge()
    }
    
    private func updateActiveTasks(context: ModelContext) async {
        do {
            // Create a descriptor to fetch today's time blocks
            let calendar = Calendar.current
            let startOfDay = calendar.startOfDay(for: Date())
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
            
            let descriptor = FetchDescriptor<TimeBlock>(
                predicate: #Predicate { timeBlock in
                    timeBlock.startTime >= startOfDay &&
                    timeBlock.startTime < endOfDay
                }
            )
            
            let todayBlocks = try context.fetch(descriptor)
            // Filter in memory for status
            let inProgressBlocks = todayBlocks.filter { $0.status == .inProgress }
            activeTasks = inProgressBlocks.count
        } catch {
            print("Error fetching active tasks: \(error)")
            activeTasks = 0
        }
    }
    
    private func updateSummaryBadge() {
        let lastViewed = UserDefaults.standard.object(forKey: "lastSummaryViewed") as? Date
        let calendar = Calendar.current
        
        if let lastViewed = lastViewed {
            // Show badge if last viewed was not today
            shouldShowSummaryBadge = !calendar.isDateInToday(lastViewed)
        } else {
            // Never viewed, show badge
            shouldShowSummaryBadge = true
        }
    }
    
    // MARK: - Badge Management
    func markSummaryAsViewed() {
        shouldShowSummaryBadge = false
        UserDefaults.standard.set(Date(), forKey: "lastSummaryViewed")
    }
    
    func refreshBadges() async {
        await updateBadges()
    }
}
