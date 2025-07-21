import SwiftUI
import SwiftData

@Observable
class TodayViewModel {
    // MARK: - Published Properties
    var timeBlocks: [TimeBlock] = []
    var dailyProgress: DailyProgress?
    var isLoading = false
    var errorMessage: String?

    // MARK: - Private Properties
    private let dataManager: DataManager

    // MARK: - Initialization
    init(dataManager: DataManager) {
        self.dataManager = dataManager
        loadTodaysBlocks()
    }

    // MARK: - Data Loading
    func loadTodaysBlocks() {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                timeBlocks = try await dataManager.loadTodaysTimeBlocks()
                dailyProgress = try await dataManager.loadOrCreateDailyProgress(for: Date())
                try await dataManager.updateDailyProgress(for: Date())
                dailyProgress = try await dataManager.loadDailyProgress(for: Date())
            } catch {
                errorMessage = "Failed to load today's data: \(error.localizedDescription)"
                print("Error loading today's blocks: \(error)")
            }
            isLoading = false
        }
    }

    func refreshData() {
        Task {
            do {
                try await dataManager.updateTimeBlocksBasedOnCurrentTime()
                await MainActor.run { loadTodaysBlocks() }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to refresh data: \(error.localizedDescription)"
                }
            }
        }
    }

    func markBlockCompleted(_ timeBlock: TimeBlock) {
        Task {
            await MainActor.run { isLoading = true; errorMessage = nil }
            do {
                try await dataManager.markTimeBlockCompleted(timeBlock)
                await MainActor.run { loadTodaysBlocks() }
                HapticManager.shared.success()
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to mark block as completed: \(error.localizedDescription)"
                }
                HapticManager.shared.error()
            }
            await MainActor.run { isLoading = false }
        }
    }

    func markBlockSkipped(_ timeBlock: TimeBlock) {
        Task {
            await MainActor.run { isLoading = true; errorMessage = nil }
            do {
                try await dataManager.markTimeBlockSkipped(timeBlock)
                await MainActor.run { loadTodaysBlocks() }
                HapticManager.shared.success()
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to mark block as skipped: \(error.localizedDescription)"
                }
                HapticManager.shared.error()
            }
            await MainActor.run { isLoading = false }
        }
    }

    func startTimeBlock(_ timeBlock: TimeBlock) {
        Task {
            await MainActor.run { isLoading = true; errorMessage = nil }
            do {
                try await dataManager.startTimeBlock(timeBlock)
                await MainActor.run { loadTodaysBlocks() }
                HapticManager.shared.mediumImpact()
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to start time block: \(error.localizedDescription)"
                }
                HapticManager.shared.error()
            }
            await MainActor.run { isLoading = false }
        }
    }

    func getCurrentBlock() async -> TimeBlock? {
        do {
            return try await dataManager.getCurrentActiveTimeBlock()
        } catch {
            print("Error getting current block: \(error)")
            return nil
        }
    }

    func getNextUpcomingBlock() async -> TimeBlock? {
        do {
            return try await dataManager.getNextUpcomingTimeBlock()
        } catch {
            print("Error getting next block: \(error)")
            return nil
        }
    }

    var progressPercentage: Double {
        return dailyProgress?.completionPercentage ?? 0.0
    }

    var formattedProgressPercentage: String {
        return dailyProgress?.formattedCompletionPercentage ?? "0%"
    }

    var completionSummary: String {
        return dailyProgress?.completionSummary ?? "No tasks scheduled"
    }

    var timeSummary: String {
        return dailyProgress?.timeSummary ?? "No time planned"
    }

    var isDayComplete: Bool {
        return dailyProgress?.isDayComplete ?? false
    }

    var performanceLevel: DailyProgress.PerformanceLevel {
        return dailyProgress?.performanceLevel ?? .none
    }

    var motivationalMessage: String {
        return dailyProgress?.motivationalMessage ?? "Ready to start your day?"
    }

    var hasScheduledBlocks: Bool {
        return !timeBlocks.isEmpty
    }

    var sortedTimeBlocks: [TimeBlock] {
        return timeBlocks.sorted()
    }

    var timeBlocksByStatus: [BlockStatus: [TimeBlock]] {
        return Dictionary(grouping: timeBlocks) { $0.status }
    }

    var completedBlocksCount: Int {
        return timeBlocks.filter { $0.status == .completed }.count
    }

    var inProgressBlocksCount: Int {
        return timeBlocks.filter { $0.status == .inProgress }.count
    }

    var upcomingBlocksCount: Int {
        return timeBlocks.filter { $0.status == .notStarted }.count
    }

    var skippedBlocksCount: Int {
        return timeBlocks.filter { $0.status == .skipped }.count
    }

    var shouldShowSummary: Bool {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: Date())
        return hour >= 20 || isDayComplete
    }

    func resetTodaysProgress() {
        Task {
            await MainActor.run { isLoading = true; errorMessage = nil }
            do {
                try await dataManager.resetTimeBlocks(for: Date())
                await MainActor.run { loadTodaysBlocks() }
                HapticManager.shared.success()
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to reset progress: \(error.localizedDescription)"
                }
                HapticManager.shared.error()
            }
            await MainActor.run { isLoading = false }
        }
    }

    func markDayAsReviewed() {
        Task {
            do {
                dailyProgress?.markSummaryViewed()
                try await dataManager.updateDailyProgress(for: Date())
            } catch {
                print("Error marking day as reviewed: \(error)")
            }
        }
    }

    @MainActor
    func clearError() {
        errorMessage = nil
        dataManager.clearError()
    }

    @MainActor
    func retryLastOperation() {
        clearError()
        loadTodaysBlocks()
    }

    func startAutoRefresh() {
        Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { _ in
            self.refreshData()
        }
    }

    func pullToRefresh() async {
        await MainActor.run {
            self.refreshData()
        }
        try? await Task.sleep(nanoseconds: 500_000_000)
    }

    func toggleTimeBlockStatus(_ timeBlock: TimeBlock) {
        switch timeBlock.status {
        case .notStarted, .inProgress:
            markBlockCompleted(timeBlock)
        case .completed, .skipped:
            break
        }
    }

    func startNextBlock() {
        Task {
            if let nextBlock = await getNextUpcomingBlock() {
                startTimeBlock(nextBlock)
            }
        }
    }

    func getFocusModeText() async -> String? {
        if let currentBlock = await getCurrentBlock() {
            return "Focus on: \(currentBlock.title)"
        } else if let nextBlock = await getNextUpcomingBlock() {
            return "Up next: \(nextBlock.title)"
        } else if isDayComplete {
            return "All tasks complete! 🎉"
        } else {
            return nil
        }
    }

    func timeUntilNextBlock() async -> String? {
        guard let nextBlock = await getNextUpcomingBlock() else { return nil }
        let interval = nextBlock.startTime.timeIntervalSince(Date())
        guard interval > 0 else { return nil }

        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60

        return hours > 0 ? "\(hours)h \(minutes)m" : "\(minutes)m"
    }

    func remainingTimeForCurrentBlock() async -> String? {
        guard let currentBlock = await getCurrentBlock() else { return nil }

        let remainingMinutes = currentBlock.minutesRemaining
        let hours = remainingMinutes / 60
        let minutes = remainingMinutes % 60

        return hours > 0 ? "\(hours)h \(minutes)m remaining" : "\(minutes)m remaining"
    }
}
