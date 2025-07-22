//
//  DailySummaryViewModel.swift
//  Routine Anchor - Updated Version
//
import SwiftUI
import SwiftData
import Foundation

@Observable
class DailySummaryViewModel {
    // MARK: - Published Properties
    var dailyProgress: DailyProgress?
    var todaysTimeBlocks: [TimeBlock] = []
    var weeklyStats: WeeklyStats?
    var isLoading = false
    var errorMessage: String?
    var selectedDate = Date()
    
    // MARK: - Private Properties
    private let dataManager: DataManager
    private var loadTask: Task<Void, Never>?
    
    // MARK: - Initialization
    init(dataManager: DataManager) {
        self.dataManager = dataManager
        loadData(for: selectedDate)
    }
    
    init(dataManager: DataManager, date: Date) {
        self.dataManager = dataManager
        self.selectedDate = date
        loadData(for: date)
    }
    
    deinit {
        loadTask?.cancel()
    }
    
    // MARK: - Data Loading
    
    /// Load all data for the specified date
    func loadData(for date: Date) {
        selectedDate = date
        isLoading = true
        errorMessage = nil
        
        // Cancel any existing load task
        loadTask?.cancel()
        
        loadTask = Task { @MainActor in
            do {
                // Load time blocks for the selected date
                todaysTimeBlocks = try dataManager.loadTimeBlocks(for: date)
                
                // Load or create daily progress
                dailyProgress = try dataManager.loadOrCreateDailyProgress(for: date)
                
                // Update progress based on current time blocks
                try dataManager.updateDailyProgress(for: date)
                
                // Reload progress after update
                dailyProgress = try dataManager.loadDailyProgress(for: date)
                
                // Load weekly statistics
                weeklyStats = try dataManager.getWeeklyStatistics(for: date)
                
                isLoading = false
                
            } catch {
                errorMessage = "Failed to load daily summary: \(error.localizedDescription)"
                print("Error loading daily summary: \(error)")
                isLoading = false
            }
        }
    }
    
    /// Refresh current data
    func refreshData() {
        loadData(for: selectedDate)
    }
    
    // MARK: - Data Updates
    
    /// Save day rating and notes
    func saveDayRatingAndNotes(rating: Int, notes: String) {
        guard let progress = dailyProgress else { return }
        
        Task { @MainActor in
            do {
                // Update the progress object
                if rating > 0 {
                    progress.setDayRating(rating)
                }
                
                let trimmedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmedNotes.isEmpty {
                    progress.setDayNotes(trimmedNotes)
                }
                
                // Mark summary as viewed
                progress.markSummaryViewed()
                
                // Save changes through data manager
                try dataManager.updateDailyProgress(for: selectedDate)
                
                // Trigger success haptic
                HapticManager.shared.lightImpact()
                
            } catch {
                errorMessage = "Failed to save rating and notes: \(error.localizedDescription)"
                HapticManager.shared.error()
            }
        }
    }
    
    /// Update a specific time block status from summary view
    func updateTimeBlockStatus(_ timeBlock: TimeBlock, to status: BlockStatus) {
        Task { @MainActor in
            do {
                try dataManager.updateTimeBlockStatus(timeBlock, to: status)
                
                // Refresh data to show updated statistics
                refreshData()
                
                HapticManager.shared.success()
                
            } catch {
                errorMessage = "Failed to update time block: \(error.localizedDescription)"
                HapticManager.shared.error()
            }
        }
    }
    
    // MARK: - Computed Properties
    
    /// Whether we have any data to show
    var hasData: Bool {
        return !todaysTimeBlocks.isEmpty || dailyProgress?.totalBlocks ?? 0 > 0
    }
    
    /// Completion percentage for the day
    var completionPercentage: Double {
        return dailyProgress?.completionPercentage ?? 0.0
    }
    
    /// Performance message for the day
    var performanceMessage: String {
        return dailyProgress?.motivationalMessage ?? "Keep going! Every step counts."
    }
    
    /// Whether the day is complete
    var isDayComplete: Bool {
        return dailyProgress?.isDayComplete ?? false
    }
    
    /// Performance level for the day
    var performanceLevel: DailyProgress.PerformanceLevel {
        return dailyProgress?.performanceLevel ?? .none
    }
    
    /// Time blocks grouped by status for better organization
    var timeBlocksByStatus: [BlockStatus: [TimeBlock]] {
        return Dictionary(grouping: todaysTimeBlocks) { $0.status }
    }
    
    /// Sorted time blocks by start time
    var sortedTimeBlocks: [TimeBlock] {
        return todaysTimeBlocks.sorted()
    }
    
    /// Count of blocks by each status
    var statusCounts: (completed: Int, skipped: Int, inProgress: Int, upcoming: Int) {
        let completed = todaysTimeBlocks.filter { $0.status == .completed }.count
        let skipped = todaysTimeBlocks.filter { $0.status == .skipped }.count
        let inProgress = todaysTimeBlocks.filter { $0.status == .inProgress }.count
        let upcoming = todaysTimeBlocks.filter { $0.status == .notStarted }.count
        
        return (completed, skipped, inProgress, upcoming)
    }
    
    // MARK: - Analysis & Insights
    
    /// Get personalized insights based on performance
    func getPersonalizedInsights() -> [String] {
        guard let progress = dailyProgress else {
            return ["Create time blocks to start tracking your progress!"]
        }
        
        var insights: [String] = []
        
        // Performance-based insights
        switch progress.performanceLevel {
        case .excellent:
            insights.append("Outstanding work! You're building incredible momentum.")
            if progress.completedBlocks >= 5 {
                insights.append("Managing \(progress.completedBlocks) blocks shows exceptional time management.")
            }
            
        case .good:
            insights.append("Great job! You're on track to build lasting habits.")
            if let suggestion = progress.suggestions.first {
                insights.append(suggestion)
            }
            
        case .fair:
            insights.append("Good progress! Consistency is key to improvement.")
            insights.append(contentsOf: progress.suggestions.prefix(2))
            
        case .poor:
            insights.append("Every step forward counts. Tomorrow is a new opportunity.")
            if progress.skipRate > 0.5 {
                insights.append("High skip rate detected. Consider shorter, more manageable blocks.")
            }
            
        case .none:
            insights.append("Ready to start? Create your first time block!")
        }
        
        // Time-based insights
        if progress.totalPlannedMinutes > 8 * 60 {
            insights.append("Remember to include breaks in long schedules for sustainability.")
        }
        
        // Weekly context insights
        if let weeklyStats = weeklyStats {
            let todayVsAverage = progress.completionPercentage - weeklyStats.averageCompletion
            
            if todayVsAverage > 0.2 {
                insights.append("You're \(Int(todayVsAverage * 100))% above your weekly average! 🌟")
            } else if todayVsAverage < -0.2 {
                insights.append("Today was challenging, but you're still making progress.")
            }
            
            if weeklyStats.totalDays >= 7 && weeklyStats.averageCompletion > 0.7 {
                insights.append("A full week of consistent progress - you're building a solid routine!")
            }
        }
        
        // Pattern insights
        let completedCategories = Set(todaysTimeBlocks.filter { $0.status == .completed }.compactMap { $0.category })
        if completedCategories.count >= 3 {
            insights.append("Great balance across \(completedCategories.count) different life areas today.")
        }
        
        return insights
    }
    
    /// Get improvement suggestions
    func getImprovementSuggestions() -> [String] {
        guard let progress = dailyProgress else { return [] }
        
        var suggestions: [String] = []
        
        // Completion rate suggestions
        if progress.completionPercentage < 0.5 && progress.totalBlocks > 5 {
            suggestions.append("Consider reducing to 3-4 essential blocks to build momentum.")
        }
        
        // Skip pattern analysis
        let skippedBlocks = todaysTimeBlocks.filter { $0.status == .skipped }
        if !skippedBlocks.isEmpty {
            let categories = Set(skippedBlocks.compactMap { $0.category })
            if categories.count == 1, let category = categories.first {
                suggestions.append("Notice a pattern? \(category) blocks are frequently skipped.")
            }
        }
        
        // Time of day patterns
        let morningBlocks = todaysTimeBlocks.filter {
            Calendar.current.component(.hour, from: $0.startTime) < 12
        }
        let morningCompletion = morningBlocks.filter { $0.status == .completed }.count
        
        if morningBlocks.count > 0 && Double(morningCompletion) / Double(morningBlocks.count) < 0.5 {
            suggestions.append("Morning blocks have lower completion. Are you a night owl?")
        }
        
        // Duration insights
        let longBlocks = todaysTimeBlocks.filter { $0.durationMinutes > 90 }
        let longBlocksSkipped = longBlocks.filter { $0.status == .skipped }.count
        
        if longBlocks.count > 0 && Double(longBlocksSkipped) / Double(longBlocks.count) > 0.5 {
            suggestions.append("Long blocks (90+ min) are often skipped. Try breaking them down.")
        }
        
        return suggestions.isEmpty ? ["Keep experimenting to find your optimal routine!"] : suggestions
    }
    
    // MARK: - Sharing & Export
    
    /// Generate shareable text summary
    func generateShareableText() -> String {
        guard let progress = dailyProgress else {
            return "Daily Summary - No data available"
        }
        
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        
        var text = """
        📊 Daily Summary - \(formatter.string(from: selectedDate))
        
        ✨ Performance: \(progress.performanceLevel.displayName) \(progress.performanceLevel.emoji)
        📈 Completion: \(progress.formattedCompletionPercentage) (\(progress.completionSummary))
        """
        
        if progress.totalPlannedMinutes > 0 {
            text += "\n⏰ Time: \(progress.timeSummary)"
        }
        
        // Add breakdown if meaningful
        let counts = statusCounts
        if counts.completed > 0 || counts.skipped > 0 {
            text += "\n\n📋 Breakdown:"
            if counts.completed > 0 { text += "\n• Completed: \(counts.completed)" }
            if counts.inProgress > 0 { text += "\n• In Progress: \(counts.inProgress)" }
            if counts.skipped > 0 { text += "\n• Skipped: \(counts.skipped)" }
            if counts.upcoming > 0 { text += "\n• Upcoming: \(counts.upcoming)" }
        }
        
        // Add rating and reflection
        if let rating = progress.dayRating {
            text += "\n\n💭 Personal Rating: \(String(repeating: "⭐", count: rating))"
        }
        
        if let notes = progress.dayNotes, !notes.isEmpty {
            text += "\n📝 Reflection: \(notes)"
        }
        
        // Add motivational close
        text += "\n\n\(progress.motivationalMessage)"
        text += "\n\n—\nBuilt with Routine Anchor 🎯"
        
        return text
    }
    
    /// Generate detailed export data
    func generateDetailedExport() -> [String: Any] {
        guard let progress = dailyProgress else {
            return ["error": "No data available"]
        }
        
        return [
            "summary": [
                "date": ISO8601DateFormatter().string(from: selectedDate),
                "completionPercentage": progress.completionPercentage,
                "performanceLevel": progress.performanceLevel.rawValue,
                "totalBlocks": progress.totalBlocks,
                "completedBlocks": progress.completedBlocks,
                "skippedBlocks": progress.skippedBlocks,
                "totalMinutes": progress.totalPlannedMinutes,
                "completedMinutes": progress.completedMinutes,
                "dayRating": progress.dayRating as Any,
                "dayNotes": progress.dayNotes as Any
            ],
            "timeBlocks": todaysTimeBlocks.map { block in
                [
                    "id": block.id.uuidString,
                    "title": block.title,
                    "startTime": ISO8601DateFormatter().string(from: block.startTime),
                    "endTime": ISO8601DateFormatter().string(from: block.endTime),
                    "duration": block.durationMinutes,
                    "status": block.status.rawValue,
                    "category": block.category ?? "",
                    "icon": block.icon ?? ""
                ]
            },
            "insights": getPersonalizedInsights(),
            "suggestions": getImprovementSuggestions(),
            "weeklyContext": weeklyStats != nil ? [
                "averageCompletion": weeklyStats!.averageCompletion,
                "totalDays": weeklyStats!.totalDays,
                "completedDays": weeklyStats!.completedDays
            ] : nil,
            "exportedAt": ISO8601DateFormatter().string(from: Date())
        ]
    }
    
    // MARK: - Navigation Helpers
    
    /// Load previous day's data
    func loadPreviousDay() {
        guard let previousDay = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) else { return }
        loadData(for: previousDay)
    }
    
    /// Load next day's data
    func loadNextDay() {
        guard let nextDay = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) else { return }
        loadData(for: nextDay)
    }
    
    /// Check if we can navigate to next day
    var canNavigateToNextDay: Bool {
        guard let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) else { return false }
        return Calendar.current.compare(tomorrow, to: Date(), toGranularity: .day) != .orderedDescending
    }
    
    /// Check if we have sufficient history to navigate back
    var canNavigateToPreviousDay: Bool {
        guard let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) else { return false }
        return selectedDate > thirtyDaysAgo
    }
    
    // MARK: - Error Handling
    
    /// Clear any error messages
    func clearError() {
        errorMessage = nil
    }
    
    /// Retry last failed operation
    func retryLastOperation() {
        clearError()
        refreshData()
    }
}
