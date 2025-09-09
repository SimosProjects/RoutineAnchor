//
//  MainTabViewModel.swift
//  Routine Anchor
//

import SwiftUI
import SwiftData
import Observation

@Observable
@MainActor
final class MainTabViewModel {
    // MARK: - Observable UI State
    var activeTasks: Int = 0
    var shouldShowSummaryBadge: Bool = false
    var selectedTabProgress: Double = 0.0

    // MARK: - Non-observed internals
    @ObservationIgnored private var isProcessingTabChange = false
    @ObservationIgnored private var modelContext: ModelContext?

    // MARK: - Setup
    func setup(with context: ModelContext) {
        self.modelContext = context
        updateBadges()
    }

    // MARK: - Tab Selection (single entry point)
    /// Call when a tab is selected. Handles animation, side-effects, and broadcasting.
    func didSelectTab(_ tab: MainTabView.Tab) {
        guard !isProcessingTabChange else { return }
        isProcessingTabChange = true

        Task { @MainActor in
            defer { isProcessingTabChange = false }

            // Small progress animation “tick”
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                selectedTabProgress = 1.0
            }
            try? await Task.sleep(nanoseconds: 600_000_000)
            withAnimation(.spring(response: 0.4, dampingFraction: 0.9)) {
                selectedTabProgress = 0.0
            }

            // Per-tab side effects
            switch tab {
            case .today:
                updateBadges()

            case .summary:
                shouldShowSummaryBadge = false
                UserDefaults.standard.set(Date(), forKey: "lastSummaryViewed")

            case .schedule, .settings:
                break
                
            default:
                break
            }

            // Broadcast once updates are applied
            NotificationCenter.default.post(
                name: .tabDidChange,
                object: nil,
                userInfo: ["tab": tab]
            )
        }
    }

    // MARK: - Badges
    private func updateBadges() {
        guard let context = modelContext else { return }
        updateActiveTasks(context: context)
        updateSummaryBadge()
    }

    private func updateActiveTasks(context: ModelContext) {
        // TODO: Replace with real query/logic using context.
        activeTasks = 0
    }

    private func updateSummaryBadge() {
        let lastViewed = UserDefaults.standard.object(forKey: "lastSummaryViewed") as? Date
        if let lastViewed {
            shouldShowSummaryBadge = !Calendar.current.isDateInToday(lastViewed)
        } else {
            shouldShowSummaryBadge = true
        }
    }
}
