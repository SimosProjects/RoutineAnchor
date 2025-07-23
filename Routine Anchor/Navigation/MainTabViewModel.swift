//
//  MainTabViewModel.swift
//  Routine Anchor
//
//  Created by Christopher Simonson on 7/23/25.
//
import SwiftUI
import SwiftData

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
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            selectedTabProgress = 1.0
        }

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

