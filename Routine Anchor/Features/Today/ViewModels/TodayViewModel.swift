//
//  TodayViewModel.swift
//  Routine Anchor
//
//  Created by Christopher Simonson on 7/19/25.
//
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
    private var autoRefreshTimer: Timer?
    
    // MARK: - Initialization
    init(dataManager: DataManager) {
        self.dataManager = dataManager
        loadTodaysBlocks()
    }
    
    // MARK: - Data Loading
    
    /// Load today's time blocks and calculate progress
    func loadTodaysBlocks() {
        isLoading = true
        errorMessage = nil
        
        do {
            // Fetch today's time blocks
            timeBlocks = try dataManager.loadTodaysTimeBlocks()
            
            // Load or create daily progress
            dailyProgress = try dataManager.loadOrCreateDailyProgress(for: Date())
            
            // Update progress based on current time blocks
            try dataManager.updateDailyProgress(for: Date())
            
            // Reload progress after update
            dailyProgress = try dataManager.loadDailyProgress(for: Date())
            
        } catch {
            errorMessage = "Failed to load today's data: \(error.localizedDescription)"
            print("Error loading today's blocks: \(error)")
        }
        
        isLoading = false
    }
    
    /// Refresh data and update time-based statuses
    func refreshData() {
        do {
            // Update time blocks based on current time
            try dataManager.updateTimeBlocksBasedOnCurrentTime()
            
            // Reload everything
            loadTodaysBlocks()
            
        } catch {
            errorMessage = "Failed to refresh data: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Time Block Actions
    
    /// Mark a time block as completed
    func markBlockCompleted(_ timeBlock: TimeBlock) {
        isLoading = true
        errorMessage = nil
        
        do {
            try dataManager.markTimeBlockCompleted(timeBlock)
            loadTodaysBlocks() // Refresh data
            
            // Success feedback
            HapticManager.shared.success()
            
        } catch {
            errorMessage = "Failed to mark block as completed: \(error.localizedDescription)"
            HapticManager.shared.error()
        }
        
        isLoading = false
    }
    
    /// Mark a time block as skipped
    func markBlockSkipped(_ timeBlock: TimeBlock) {
        isLoading = true
        errorMessage = nil
        
        do {
            try dataManager.markTimeBlockSkipped(timeBlock)
            loadTodaysBlocks() // Refresh data
            
            // Success feedback
            HapticManager.shared.success()
            
        } catch {
            errorMessage = "Failed to mark block as skipped: \(error.localizedDescription)"
            HapticManager.shared.error()
        }
        
        isLoading = false
    }
    
    /// Start a time block (mark as in progress)
    func startTimeBlock(_ timeBlock: TimeBlock) {
        isLoading = true
        errorMessage = nil
        
        do {
            try dataManager.startTimeBlock(timeBlock)
            loadTodaysBlocks() // Refresh data
            
            // Success feedback
            HapticManager.shared.mediumImpact()
            
        } catch {
            errorMessage = "Failed to start time block: \(error.localizedDescription)"
            HapticManager.shared.error()
        }
        
        isLoading = false
    }
    
    // MARK: - Computed Properties
    
    /// Get the currently active time block
    func getCurrentBlock() -> TimeBlock? {
        do {
            return try dataManager.getCurrentActiveTimeBlock()
        } catch {
            print("Error getting current block: \(error)")
            return nil
        }
    }
    
    /// Get the next upcoming time block
    func getNextUpcomingBlock() -> TimeBlock? {
        do {
            return try dataManager.getNextUpcomingTimeBlock()
        } catch {
            print("Error getting next block: \(error)")
            return nil
        }
    }
    
    /// Progress percentage (0.0 to 1.0)
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
    
    /// Whether the day is complete
    var isDayComplete: Bool {
        return dailyProgress?.isDayComplete ?? false
    }
    
    /// Performance level for the day
    var performanceLevel: DailyProgress.PerformanceLevel {
        return dailyProgress?.performanceLevel ?? .none
    }
    
    /// Motivational message based on progress
    var motivationalMessage: String {
        return dailyProgress?.motivationalMessage ?? "Ready to start your day?"
    }
    
    /// Whether there are any scheduled blocks today
    var hasScheduledBlocks: Bool {
        return !timeBlocks.isEmpty
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
    
    // MARK: - Time-based Logic
    
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
    func resetTodaysProgress() {
        isLoading = true
        errorMessage = nil
        
        do {
            try dataManager.resetTimeBlocksStatus(for: Date())
            loadTodaysBlocks() // Refresh data
            
            // Success feedback
            HapticManager.shared.success()
            
        } catch {
            errorMessage = "Failed to reset progress: \(error.localizedDescription)"
            HapticManager.shared.error()
        }
        
        isLoading = false
    }
    
    /// Mark day as reviewed (for summary tracking)
    func markDayAsReviewed() {
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
        errorMessage = nil
        dataManager.clearError()
    }
    
    /// Retry the last failed operation
    func retryLastOperation() {
        clearError()
        loadTodaysBlocks()
    }
}

// MARK: - Auto-refresh Logic
extension TodayViewModel {
    /// Set up automatic refresh for time-sensitive updates (FIXED VERSION)
    func startAutoRefresh() {
        // Cancel any existing timer
        stopAutoRefresh()
        
        // Create new timer with weak self reference
        autoRefreshTimer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { [weak self] _ in
            self?.refreshData()
        }
    }
    
    /// Stop automatic refresh
    func stopAutoRefresh() {
        autoRefreshTimer?.invalidate()
        autoRefreshTimer = nil
    }
    
    /// Manual refresh with pull-to-refresh gesture
    func pullToRefresh() async {
        await MainActor.run {
            self.refreshData()
        }
        
        // Add small delay for better UX
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
    }
}

// MARK: - Convenience Methods
extension TodayViewModel {
    /// Quick action methods for common operations
    
    /// Toggle time block status (complete/skip based on current state)
    func toggleTimeBlockStatus(_ timeBlock: TimeBlock) {
        switch timeBlock.status {
        case .notStarted, .inProgress:
            // Show action sheet or default to complete
            markBlockCompleted(timeBlock)
        case .completed:
            // Could allow undo in future
            break
        case .skipped:
            // Could allow undo in future
            break
        }
    }
    
    /// Start the next available time block
    func startNextBlock() {
        guard let nextBlock = getNextUpcomingBlock() else { return }
        startTimeBlock(nextBlock)
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
}
