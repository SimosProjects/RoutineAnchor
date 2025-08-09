//
//  MainTabViewModel.swift
//  Routine Anchor
//
//  Created by Christopher Simonson on 7/23/25.
//  Updated for Swift 6 Compatibility
//
import SwiftUI
import SwiftData
import Observation

@Observable
@MainActor
final class MainTabViewModel {
    // MARK: - Observable Properties
    var activeTasks: Int = 0
    var shouldShowSummaryBadge: Bool = false
    var selectedTabProgress: Double = 0.0
    
    @ObservationIgnored
    private var isProcessingTabChange = false
    
    @ObservationIgnored
    private var modelContext: ModelContext?
    
    // MARK: - Public Methods
    func setup(with context: ModelContext) {
        self.modelContext = context
        updateBadges()
    }
    
    func didSelectTab(_ tab: MainTabView.Tab) {
        // Prevent concurrent tab changes
        guard !isProcessingTabChange else { return }
        isProcessingTabChange = true
        
        Task {
            await processTabSelection(tab)
            isProcessingTabChange = false
        }
    }
    
    private func processTabSelection(_ tab: MainTabView.Tab) async {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            selectedTabProgress = 1.0
        }
        
        try? await Task.sleep(nanoseconds: 600_000_000)
        
        withAnimation(.spring(response: 0.4, dampingFraction: 0.9)) {
            selectedTabProgress = 0.0
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
    
    // MARK: - Private Methods
    private func updateBadges() {
        guard let context = modelContext else { return }
        updateActiveTasks(context: context)
        updateSummaryBadge()
    }
    
    private func updateActiveTasks(context: ModelContext) {
        activeTasks = 0 // Replace with real logic
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
