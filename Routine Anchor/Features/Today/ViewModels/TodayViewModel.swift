//
//  TodayViewModel.swift
//  Routine Anchor
//
//  View-model for the Today screen. Swift 6 / iOS 17+
//  Uses Observation (@Observable) and MainActor isolation.
//

import SwiftUI
import SwiftData
import Observation

@Observable
@MainActor
final class TodayViewModel {

    // MARK: - Observable State

    var timeBlocks: [TimeBlock] = []
    var isLoading = false
    var errorMessage: String?

    // MARK: - Private

    private let dataManager: DataManager

    // Periodic refresh loop and notification listener (both cancelable tasks).
    nonisolated(unsafe) private var refreshTask: Task<Void, Never>?
    nonisolated(unsafe) private var notificationsTask: Task<Void, Never>?

    // MARK: - Init / Deinit

    init(dataManager: DataManager) {
        self.dataManager = dataManager
        startNotificationListener()
        Task { await loadTodaysBlocks() }
    }

    deinit {
        // Both are safe to cancel here; no cross-actor hops.
        refreshTask?.cancel()
        notificationsTask?.cancel()
    }

    // MARK: - Notifications (async sequence, no removeObserver needed)

    private func startNotificationListener() {
        // Listen to .timeBlocksDidChange and refresh if it concerns today.
        notificationsTask?.cancel()
        notificationsTask = Task { [weak self] in
            guard let self else { return }
            let center = NotificationCenter.default
            for await note in center.notifications(named: .timeBlocksDidChange) {
                if let date = note.userInfo?["date"] as? Date,
                   Calendar.current.isDateInToday(date) {
                    await self.loadTodaysBlocks()
                }
                if Task.isCancelled { break }
            }
        }
    }

    // MARK: - Periodic Refresh

    func startPeriodicUpdates() {
        stopPeriodicUpdates()
        refreshTask = Task { [weak self] in
            guard let self else { return }
            await self.refreshData()                       // initial tick
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(60))
                await self.refreshData()
            }
        }
    }

    func stopPeriodicUpdates() {
        refreshTask?.cancel()
        refreshTask = nil
    }

    // MARK: - Data Loading

    func loadTodaysBlocks() async {
        isLoading = true
        errorMessage = nil

        timeBlocks = dataManager.loadTodaysTimeBlocksSafely()
        dataManager.updateDailyProgressSafely(for: Date())

        isLoading = false
    }

    func refreshData() async {
        isLoading = true
        errorMessage = nil

        timeBlocks = dataManager.loadTodaysTimeBlocksSafely()
        dataManager.updateDailyProgressSafely(for: Date())

        isLoading = false
    }

    // MARK: - Block Actions

    func markBlockCompleted(_ timeBlock: TimeBlock) async {
        isLoading = true; errorMessage = nil
        do {
            try dataManager.markTimeBlockCompleted(timeBlock)
            await loadTodaysBlocks()
            HapticManager.shared.success()
        } catch {
            errorMessage = "Failed to mark block as completed: \(error.localizedDescription)"
            HapticManager.shared.error()
        }
        isLoading = false
    }

    func markBlockSkipped(_ timeBlock: TimeBlock) async {
        isLoading = true; errorMessage = nil
        do {
            try dataManager.markTimeBlockSkipped(timeBlock)
            await loadTodaysBlocks()
            HapticManager.shared.lightImpact()
        } catch {
            errorMessage = "Failed to skip block: \(error.localizedDescription)"
            HapticManager.shared.error()
        }
        isLoading = false
    }

    func startTimeBlock(_ timeBlock: TimeBlock) async {
        do {
            try dataManager.startTimeBlock(timeBlock)
            await loadTodaysBlocks()
            HapticManager.shared.mediumImpact()
        } catch {
            errorMessage = "Failed to start block: \(error.localizedDescription)"
            HapticManager.shared.error()
        }
    }

    // MARK: - Daily Progress (read on demand; don’t retain model)

    private var safeDailyProgress: DailyProgress? {
        dataManager.loadDailyProgressSafely(for: Date())
    }

    var progressRatio: Double { safeDailyProgress?.completionPercentage ?? 0.0 } // 0…1
    var progressPercentage: Double { progressRatio }                             // alias (ratio)
    var progressPercent: Int { Int(round(progressRatio * 100)) }                // 0…100
    var formattedProgressPercentage: String { "\(progressPercent)%" }

    var completionSummary: String { safeDailyProgress?.completionSummary ?? "No tasks scheduled" }
    var timeSummary: String       { safeDailyProgress?.timeSummary ?? "No time planned" }
    var performanceLevel: DailyProgress.PerformanceLevel { safeDailyProgress?.performanceLevel ?? .none }
    var motivationalMessage: String { safeDailyProgress?.motivationalMessage ?? "Ready to start your day?" }

    // MARK: - Derived Collections & Counts

    var sortedTimeBlocks: [TimeBlock] { timeBlocks.sorted() }
    var timeBlocksByStatus: [BlockStatus: [TimeBlock]] { .init(grouping: timeBlocks, by: { $0.status }) }

    var completedBlocksCount: Int { timeBlocks.filter { $0.status == .completed }.count }
    var inProgressBlocksCount: Int { timeBlocks.filter { $0.status == .inProgress }.count }
    var upcomingBlocksCount: Int { timeBlocks.filter { $0.status == .notStarted }.count }
    var remainingBlocksCount: Int { timeBlocks.filter { $0.status == .notStarted || $0.status == .inProgress }.count }

    var completionPercentage: Int { progressPercent }      // legacy alias
    var dayCompletionPercentage: Double { progressRatio }  // legacy alias

    var totalScheduledMinutes: Int { timeBlocks.reduce(0) { $0 + $1.durationMinutes } }
    var totalCompletedMinutes: Int { timeBlocks.filter { $0.status == .completed }.reduce(0) { $0 + $1.durationMinutes } }

    // MARK: - Convenience

    func getCurrentBlock() -> TimeBlock? {
        let now = Date()
        return timeBlocks.first { $0.startTime <= now && $0.endTime > now }
    }

    func getNextUpcomingBlock() -> TimeBlock? {
        let now = Date()
        return timeBlocks.filter { $0.startTime > now }.min(by: { $0.startTime < $1.startTime })
    }

    func getBlocks(withStatus status: BlockStatus) -> [TimeBlock] {
        timeBlocks.filter { $0.status == status }
    }

    func isBlockCurrent(_ block: TimeBlock) -> Bool {
        let now = Date()
        return block.startTime <= now && block.endTime > now
    }

    var shouldShowSummary: Bool {
        let hour = Calendar.current.component(.hour, from: Date())
        return hour >= 20 || isDayComplete
    }

    var hasScheduledBlocks: Bool { !timeBlocks.isEmpty }
    var isDayComplete: Bool { !timeBlocks.isEmpty && timeBlocks.allSatisfy { $0.status == .completed } }

    func timeUntilNextBlock() -> String? {
        guard let next = getNextUpcomingBlock() else { return nil }
        let interval = next.startTime.timeIntervalSince(Date())
        guard interval > 0 else { return nil }
        let h = Int(interval) / 3600
        let m = (Int(interval) % 3600) / 60
        return h > 0 ? "\(h)h \(m)m" : "\(m)m"
    }

    func remainingTimeForCurrentBlock() -> String? {
        guard let current = getCurrentBlock(), let mins = current.remainingMinutes else { return nil }
        let h = mins / 60, m = mins % 60
        return h > 0 ? "\(h)h \(m)m remaining" : "\(m)m remaining"
    }

    // MARK: - Actions

    func resetTodaysProgress() async {
        isLoading = true; errorMessage = nil
        do {
            try dataManager.resetTimeBlocksStatus(for: Date())
            await loadTodaysBlocks()
            HapticManager.shared.success()
        } catch {
            errorMessage = "Failed to reset progress: \(error.localizedDescription)"
            HapticManager.shared.error()
        }
        isLoading = false
    }

    func markDayAsReviewed() async {
        if let progress = dataManager.loadDailyProgressSafely(for: Date()) {
            progress.markSummaryViewed()
            do { try dataManager.updateDailyProgress(for: Date()) } catch { print("Mark reviewed error:", error) }
        }
    }

    func clearError() {
        errorMessage = nil
        dataManager.clearError()
    }

    func retryLastOperation() async {
        clearError()
        await loadTodaysBlocks()
    }

    // MARK: - Pull to refresh

    func pullToRefresh() async {
        await refreshData()
        try? await Task.sleep(for: .milliseconds(400))
    }
}

// MARK: - Friendly Strings

extension TodayViewModel {
    var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        let name = UserDefaults.standard.string(forKey: "userName") ?? ""
        let suffix = name.isEmpty ? "" : ", \(name)"
        switch hour {
        case 5..<12:  return "Good morning\(suffix)"
        case 12..<17: return "Good afternoon\(suffix)"
        case 17..<22: return "Good evening\(suffix)"
        default:      return "Good night\(suffix)"
        }
    }

    var currentDateText: String {
        let f = DateFormatter(); f.dateFormat = "EEEE, MMMM d"
        return f.string(from: Date())
    }

    var dailyQuote: String {
        let quotes = [
            "Small steps lead to big changes",
            "Consistency is the key to success",
            "Today's effort is tomorrow's strength",
            "Progress over perfection",
            "One block at a time",
            "Your routine shapes your future",
            "Focus on what matters most"
        ]
        let day = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
        return quotes[day % quotes.count]
    }

    var isSpecialDay: Bool {
        let cal = Calendar.current
        let c = cal.dateComponents([.month, .day, .weekday], from: Date())
        return (c.month == 1 && c.day == 1) || (c.month == 12 && c.day == 25) || (c.weekday == 6)
    }

    var specialDayIcon: String {
        let cal = Calendar.current
        let c = cal.dateComponents([.month, .day, .weekday], from: Date())
        if c.month == 1, c.day == 1 { return "sparkles" }
        if c.month == 12, c.day == 25 { return "snowflake" }
        if c.weekday == 6 { return "party.popper" }
        return "star"
    }

    func getFocusModeText() -> String? {
        if let current = getCurrentBlock() { return "Focus on: \(current.title)" }
        if let next = getNextUpcomingBlock() { return "Up next: \(next.title)" }
        return isDayComplete ? "All tasks complete! 🎉" : nil
    }

    func toggleTimeBlockStatus(_ timeBlock: TimeBlock) {
        Task {
            switch timeBlock.status {
            case .notStarted, .inProgress: await markBlockCompleted(timeBlock)
            case .completed, .skipped: break
            }
        }
    }

    func startNextBlock() {
        guard let next = getNextUpcomingBlock() else { return }
        Task { await startTimeBlock(next) }
    }
}
