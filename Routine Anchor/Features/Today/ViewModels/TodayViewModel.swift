//
//  TodayViewModel.swift
//  Routine Anchor
//
//  Created by Christopher Simonson on 7/19/25.
//  Swift 6 Compatible Version
//
import SwiftUI
import SwiftData
import Observation

@Observable
@MainActor
final class TodayViewModel {
    // MARK: - Observable Properties
    var timeBlocks: [TimeBlock] = []
    var dailyProgress: DailyProgress?
    var isLoading = false
    var errorMessage: String?
    
    // MARK: - Private Properties
    private let dataManager: DataManager
    
    // MARK: - Nonisolated Properties
    nonisolated(unsafe) private var updateTimer: Timer?
    nonisolated(unsafe) private var notificationObserver: NSObjectProtocol?
    
    // MARK: - Initialization
    init(dataManager: DataManager) {
        self.dataManager = dataManager
        setupNotificationObserver()
        
        // Load today's blocks asynchronously
        Task { await loadTodaysBlocks() }
    }
    
    private func setupNotificationObserver() {
        notificationObserver = NotificationCenter.default.addObserver(
            forName: .timeBlocksDidChange,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self = self else { return }
            
            // Check if the change affects today's blocks
            if let date = notification.userInfo?["date"] as? Date,
               Calendar.current.isDateInToday(date) {
                Task { @MainActor [weak self] in
                    await self?.loadTodaysBlocks()
                }
            }
        }
    }
    
    deinit {
        if let timer = updateTimer {
            timer.invalidate()
        }
        
        if let observer = notificationObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    // MARK: - Timer Management

    func startPeriodicUpdates() {
        stopPeriodicUpdates()
        
        updateTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.refreshData()
            }
        }
    }
    
    func stopPeriodicUpdates() {
        updateTimer?.invalidate()
        updateTimer = nil
    }
    
    // MARK: - Data Loading
    
    /// Load today's time blocks and calculate progress
    func loadTodaysBlocks() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Since DataManager should be @MainActor, we can call it directly
            // without Task.detached
            let blocks = try dataManager.loadTodaysTimeBlocks()
            try dataManager.updateDailyProgress(for: Date())
            let updatedProgress = try dataManager.loadDailyProgress(for: Date())
            
            // Update properties directly (we're already on MainActor)
            self.timeBlocks = blocks
            self.dailyProgress = updatedProgress
            self.isLoading = false
            
        } catch {
            self.errorMessage = "Failed to load today's blocks: \(error.localizedDescription)"
            self.isLoading = false
            print("Error loading today's blocks: \(error)")
        }
    }
    
    /// Refresh data and update time-based statuses
    func refreshData() async {
        do {
            try dataManager.updateTimeBlocksBasedOnCurrentTime()
            await loadTodaysBlocks()
        } catch {
            self.errorMessage = "Failed to refresh data: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Time Block Actions
    
    /// Mark a time block as completed
    func markBlockCompleted(_ timeBlock: TimeBlock) async {
        isLoading = true
        errorMessage = nil
        
        do {
            try dataManager.markTimeBlockCompleted(timeBlock)
            await loadTodaysBlocks()
            HapticManager.shared.success()
        } catch {
            self.errorMessage = "Failed to mark block as completed: \(error.localizedDescription)"
            HapticManager.shared.error()
        }
        
        isLoading = false
    }
    
    /// Mark a time block as skipped
    func markBlockSkipped(_ timeBlock: TimeBlock) async {
        isLoading = true
        errorMessage = nil
        
        do {
            try dataManager.markTimeBlockSkipped(timeBlock)
            await loadTodaysBlocks()
            HapticManager.shared.lightImpact()
        } catch {
            self.errorMessage = "Failed to skip block: \(error.localizedDescription)"
            HapticManager.shared.error()
        }
        
        isLoading = false
    }
    
    /// Start a time block (transition to in-progress)
    func startTimeBlock(_ timeBlock: TimeBlock) async {
        do {
            try dataManager.startTimeBlock(timeBlock)
            await loadTodaysBlocks()
            HapticManager.shared.mediumImpact()
        } catch {
            self.errorMessage = "Failed to start block: \(error.localizedDescription)"
            HapticManager.shared.error()
        }
    }
    
    // MARK: - Computed Properties
    
    var progressPercentage: Double {
        return dailyProgress?.completionPercentage ?? 0.0
    }
    
    /// Formatted progress percentage string
    var formattedProgressPercentage: String {
        return dailyProgress?.formattedCompletionPercentage ?? "0%"
    }
    
    /// Completion summary string (e.g., "4 of 6 completed")
    var completionSummary: String {
        return dailyProgress?.completionSummary ?? "No tasks scheduled"
    }
    
    /// Time summary string (e.g., "2h 30m of 4h planned")
    var timeSummary: String {
        return dailyProgress?.timeSummary ?? "No time planned"
    }
    
    /// Performance level for the day
    var performanceLevel: DailyProgress.PerformanceLevel {
        return dailyProgress?.performanceLevel ?? .none
    }
    
    /// Motivational message based on progress
    var motivationalMessage: String {
        return dailyProgress?.motivationalMessage ?? "Ready to start your day?"
    }
    
    /// Sorted time blocks by start time
    var sortedTimeBlocks: [TimeBlock] {
        return timeBlocks.sorted()
    }
    
    /// Time blocks grouped by status
    var timeBlocksByStatus: [BlockStatus: [TimeBlock]] {
        return Dictionary(grouping: timeBlocks) { $0.status }
    }
    
    /// Count of blocks by status
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
    
    /// Check if there are any scheduled blocks for today
    var hasScheduledBlocks: Bool {
        !timeBlocks.isEmpty
    }
    
    /// Check if all blocks are complete for today
    var isDayComplete: Bool {
        guard !timeBlocks.isEmpty else { return false }
        return timeBlocks.allSatisfy { $0.status == .completed }
    }
    
    /// Get completion percentage for today (duplicate name fixed)
    var dayCompletionPercentage: Double {
        guard !timeBlocks.isEmpty else { return 0 }
        let completedCount = timeBlocks.filter { $0.status == .completed }.count
        return Double(completedCount) / Double(timeBlocks.count)
    }
    
    /// Get total scheduled time for today
    var totalScheduledMinutes: Int {
        timeBlocks.reduce(0) { $0 + $1.durationMinutes }
    }

    /// Get total completed time for today
    var totalCompletedMinutes: Int {
        timeBlocks
            .filter { $0.status == .completed }
            .reduce(0) { $0 + $1.durationMinutes }
    }
    
    // MARK: - Helper Methods
    
    /// Get the currently active time block
    func getCurrentBlock() -> TimeBlock? {
        let now = Date()
        return timeBlocks.first { block in
            block.startTime <= now && block.endTime > now
        }
    }
    
    /// Get the next upcoming time block
    func getNextUpcomingBlock() -> TimeBlock? {
        let now = Date()
        return timeBlocks
            .filter { $0.startTime > now }
            .sorted { $0.startTime < $1.startTime }
            .first
    }
    
    /// Get time blocks by status
    func getBlocks(withStatus status: BlockStatus) -> [TimeBlock] {
        timeBlocks.filter { $0.status == status }
    }
    
    /// Check if a specific time block is current
    func isBlockCurrent(_ block: TimeBlock) -> Bool {
        let now = Date()
        return block.startTime <= now && block.endTime > now
    }
    
    /// Whether it's the right time to show summary (end of day)
    var shouldShowSummary: Bool {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: Date())
        
        // Show summary after 8 PM or if all blocks are complete
        return hour >= 20 || isDayComplete
    }
    
    /// Get time until next block
    func timeUntilNextBlock() -> String? {
        guard let nextBlock = getNextUpcomingBlock() else { return nil }
        
        let interval = nextBlock.startTime.timeIntervalSince(Date())
        guard interval > 0 else { return nil }
        
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    /// Get remaining time for current block
    func remainingTimeForCurrentBlock() -> String? {
        guard let currentBlock = getCurrentBlock(),
              let remainingMinutes = currentBlock.remainingMinutes else {
            return nil
        }
        
        let hours = remainingMinutes / 60
        let minutes = remainingMinutes % 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m remaining"
        } else {
            return "\(minutes)m remaining"
        }
    }
    
    // MARK: - Actions
    
    /// Reset today's progress (useful for testing or corrections)
    func resetTodaysProgress() async {
        isLoading = true
        errorMessage = nil
        
        do {
            try dataManager.resetTimeBlocksStatus(for: Date())
            await loadTodaysBlocks()
            HapticManager.shared.success()
        } catch {
            self.errorMessage = "Failed to reset progress: \(error.localizedDescription)"
            HapticManager.shared.error()
        }
        
        isLoading = false
    }
    
    /// Mark day as reviewed (for summary tracking)
    func markDayAsReviewed() async {
        do {
            dailyProgress?.markSummaryViewed()
            try dataManager.updateDailyProgress(for: Date())
        } catch {
            print("Error marking day as reviewed: \(error)")
        }
    }
    
    // MARK: - Error Handling
    
    /// Clear any error messages
    func clearError() {
        self.errorMessage = nil
        self.dataManager.clearError()
    }
    
    /// Retry the last failed operation
    func retryLastOperation() async {
        clearError()
        await loadTodaysBlocks()
    }
}

// MARK: - Auto-refresh Logic
extension TodayViewModel {
    /// Manual refresh with pull-to-refresh gesture
    func pullToRefresh() async {
        await refreshData()
        
        // Add small delay for better UX
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
    }
}

// MARK: - Convenience Methods
extension TodayViewModel {
    /// Quick action methods for common operations
    
    /// Toggle time block status (complete/skip based on current state)
    func toggleTimeBlockStatus(_ timeBlock: TimeBlock) {
        Task {
            switch timeBlock.status {
            case .notStarted, .inProgress:
                await markBlockCompleted(timeBlock)
            case .completed, .skipped:
                // Could allow undo in future
                break
            }
        }
    }
    
    /// Start the next available time block
    func startNextBlock() {
        guard let nextBlock = getNextUpcomingBlock() else { return }
        Task {
            await startTimeBlock(nextBlock)
        }
    }
    
    /// Get focus mode suggestions based on current block
    func getFocusModeText() -> String? {
        if let currentBlock = getCurrentBlock() {
            return "Focus on: \(currentBlock.title)"
        } else if let nextBlock = getNextUpcomingBlock() {
            return "Up next: \(nextBlock.title)"
        } else if isDayComplete {
            return "All tasks complete! 🎉"
        } else {
            return nil
        }
    }
    
    var isSpecialDay: Bool {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.month, .day], from: Date())
        
        // Special occasions
        if components.month == 1 && components.day == 1 { return true } // New Year
        if components.month == 12 && components.day == 25 { return true } // Christmas
        
        // Check if it's Friday (weekend start)
        let weekday = calendar.component(.weekday, from: Date())
        if weekday == 6 { return true } // Friday
        
        return false
    }
    
    /// Get icon for special days
    var specialDayIcon: String {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.month, .day], from: Date())
        
        if components.month == 1 && components.day == 1 { return "sparkles" }
        if components.month == 12 && components.day == 25 { return "snowflake" }
        
        let weekday = calendar.component(.weekday, from: Date())
        if weekday == 6 { return "party.popper" }
        
        return "star"
    }
    
    /// Get personalized greeting based on time of day
    var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        let name = UserDefaults.standard.string(forKey: "userName") ?? ""
        let personalizedGreeting = name.isEmpty ? "" : ", \(name)"
        
        switch hour {
        case 5..<12: return "Good morning\(personalizedGreeting)"
        case 12..<17: return "Good afternoon\(personalizedGreeting)"
        case 17..<22: return "Good evening\(personalizedGreeting)"
        default: return "Good night\(personalizedGreeting)"
        }
    }
    
    /// Get formatted current date
    var currentDateText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: Date())
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
        
        // Use date as seed for consistent daily quote
        let calendar = Calendar.current
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: Date()) ?? 1
        let index = dayOfYear % quotes.count
        
        return quotes[index]
    }
}
