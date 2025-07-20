//
//  DailySummaryViewModel.swift
//  Routine Anchor
//
//  Created by Christopher Simonson on 7/19/25.
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
    
    // MARK: - Data Loading
    
    /// Load all data for the specified date
    func loadData(for date: Date) {
        selectedDate = date
        isLoading = true
        errorMessage = nil
        
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
            loadWeeklyStatistics(for: date)
            
        } catch {
            errorMessage = "Failed to load daily summary: \(error.localizedDescription)"
            print("Error loading daily summary: \(error)")
        }
        
        isLoading = false
    }
    
    /// Load weekly statistics for context
    private func loadWeeklyStatistics(for date: Date) {
        do {
            weeklyStats = try dataManager.getWeeklyStatistics(for: date)
        } catch {
            print("Error loading weekly stats: \(error)")
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
        
        do {
            if rating > 0 {
                progress.setDayRating(rating)
            }
            
            if !notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                progress.setDayNotes(notes)
            }
            
            try dataManager.updateDailyProgress(for: selectedDate)
            
            // Mark summary as viewed
            progress.markSummaryViewed()
            
        } catch {
            errorMessage = "Failed to save rating and notes: \(error.localizedDescription)"
        }
    }
    
    /// Update a specific time block status from summary view
    func updateTimeBlockStatus(_ timeBlock: TimeBlock, to status: BlockStatus) {
        do {
            try dataManager.updateTimeBlockStatus(timeBlock, to: status)
            refreshData() // Reload to show updated data
            HapticManager.shared.success()
        } catch {
            errorMessage = "Failed to update time block: \(error.localizedDescription)"
            HapticManager.shared.error()
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
            insights.append("Consider sharing your success strategy with others.")
            
        case .good:
            insights.append("Great job! You're on track to build lasting habits.")
            insights.append("Small tweaks could help you reach excellent performance.")
            
        case .fair:
            insights.append("Good progress! Consistency is key to improvement.")
            insights.append("Try breaking larger blocks into smaller, manageable pieces.")
            
        case .poor:
            insights.append("Every step forward counts. Tomorrow is a new opportunity.")
            insights.append("Consider reducing your time blocks to build confidence.")
            
        case .none:
            insights.append("Ready to start? Create your first time block!")
        }
        
        // Skip rate insights
        if progress.skipRate > 0.3 {
            insights.append("High skip rate detected. Consider shorter time blocks.")
        }
        
        // Time-based insights
        if progress.totalPlannedMinutes > 8 * 60 { // More than 8 hours
            insights.append("Long days can be challenging. Remember to include breaks.")
        }
        
        // Weekly context if available
        if let weeklyStats = weeklyStats {
            if weeklyStats.averageCompletion > progress.completionPercentage {
                insights.append("Today was below your weekly average. You've got this!")
            } else if weeklyStats.averageCompletion < progress.completionPercentage {
                insights.append("Above your weekly average! Great improvement.")
            }
        }
        
        return insights
    }
    
    /// Get improvement suggestions
    func getImprovementSuggestions() -> [String] {
        guard let progress = dailyProgress else { return [] }
        
        var suggestions: [String] = []
        
        // Based on completion rate
        if progress.completionPercentage < 0.5 {
            suggestions.append("Start with 2-3 small time blocks to build momentum")
            suggestions.append("Choose your easiest tasks first to gain confidence")
        } else if progress.completionPercentage < 0.8 {
            suggestions.append("You're doing well! Try adding one more manageable block")
            suggestions.append("Focus on consistency over perfection")
        }
        
        // Based on skip patterns
        if progress.skippedBlocks > progress.completedBlocks {
            suggestions.append("Consider what's causing you to skip blocks")
            suggestions.append("Try scheduling blocks at your most energetic times")
        }
        
        // Time-based suggestions
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: Date())
        
        if hour < 12 && progress.completionPercentage < 0.3 {
            suggestions.append("Morning blocks set the tone - prioritize early wins")
        } else if hour > 18 && progress.completionPercentage > 0.8 {
            suggestions.append("Strong day! Plan tomorrow while momentum is high")
        }
        
        return suggestions.isEmpty ? ["Keep up the great work!"] : suggestions
    }
    
    // MARK: - Sharing & Export
    
    /// Generate shareable text summary
    func generateShareableText() -> String {
        guard let progress = dailyProgress else {
            return "Daily Summary - No data available"
        }
        
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        
        var text = "📊 Daily Summary - \(formatter.string(from: selectedDate))\n\n"
        
        // Main stats
        text += "✅ Completed: \(progress.completedBlocks)/\(progress.totalBlocks) blocks (\(progress.formattedCompletionPercentage))\n"
        
        if progress.totalPlannedMinutes > 0 {
            text += "⏰ Time: \(progress.timeSummary)\n"
        }
        
        text += "📈 Performance: \(progress.performanceLevel.displayName) \(progress.performanceLevel.emoji)\n\n"
        
        // Breakdown by status
        let counts = statusCounts
        if counts.completed > 0 || counts.skipped > 0 {
            text += "📋 Breakdown:\n"
            if counts.completed > 0 { text += "• Completed: \(counts.completed)\n" }
            if counts.skipped > 0 { text += "• Skipped: \(counts.skipped)\n" }
            if counts.inProgress > 0 { text += "• In Progress: \(counts.inProgress)\n" }
            if counts.upcoming > 0 { text += "• Upcoming: \(counts.upcoming)\n" }
            text += "\n"
        }
        
        // Personal reflection
        if progress.dayRating != nil || progress.dayNotes != nil {
            text += "💭 Reflection:\n"
            if let rating = progress.dayRating {
                text += "Rating: \(String(repeating: "⭐", count: rating)) (\(rating)/5)\n"
            }
            if let notes = progress.dayNotes, !notes.isEmpty {
                text += "Notes: \(notes)\n"
            }
            text += "\n"
        }
        
        // Weekly context if available
        if let weeklyStats = weeklyStats {
            text += "📈 Week Overview:\n"
            text += "• Average: \(weeklyStats.formattedAverageCompletion)\n"
            text += "• Total: \(weeklyStats.completionSummary)\n\n"
        }
        
        text += "Built with Routine Anchor 📱"
        
        return text
    }
    
    /// Generate detailed export data
    func generateDetailedExport() -> [String: Any] {
        guard let progress = dailyProgress else {
            return ["error": "No data available"]
        }
        
        var exportData: [String: Any] = [:]
        
        // Basic info
        exportData["date"] = ISO8601DateFormatter().string(from: selectedDate)
        exportData["summary"] = progress.exportData
        
        // Time blocks
        exportData["timeBlocks"] = todaysTimeBlocks.map { block in
            return [
                "id": block.id.uuidString,
                "title": block.title,
                "startTime": ISO8601DateFormatter().string(from: block.startTime),
                "endTime": ISO8601DateFormatter().string(from: block.endTime),
                "duration": block.durationMinutes,
                "status": block.status.rawValue,
                "notes": block.notes ?? "",
                "category": block.category ?? "",
                "icon": block.icon ?? ""
            ]
        }
        
        // Analysis
        exportData["insights"] = getPersonalizedInsights()
        exportData["suggestions"] = getImprovementSuggestions()
        
        // Weekly context
        if let weeklyStats = weeklyStats {
            exportData["weeklyContext"] = [
                "totalDays": weeklyStats.totalDays,
                "completedDays": weeklyStats.completedDays,
                "averageCompletion": weeklyStats.averageCompletion,
                "totalBlocks": weeklyStats.totalBlocks,
                "totalCompleted": weeklyStats.totalCompleted
            ]
        }
        
        exportData["exportedAt"] = ISO8601DateFormatter().string(from: Date())
        
        return exportData
    }
    
    // MARK: - Navigation Helpers
    
    /// Load previous day's data
    func loadPreviousDay() {
        let previousDay = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) ?? selectedDate
        loadData(for: previousDay)
    }
    
    /// Load next day's data
    func loadNextDay() {
        let nextDay = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) ?? selectedDate
        loadData(for: nextDay)
    }
    
    /// Check if we can navigate to next day (don't go beyond today)
    var canNavigateToNextDay: Bool {
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) ?? selectedDate
        return Calendar.current.compare(tomorrow, to: Date(), toGranularity: .day) != .orderedDescending
    }
    
    /// Check if we can navigate to previous day (reasonable limit)
    var canNavigateToPreviousDay: Bool {
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        return Calendar.current.compare(selectedDate, to: thirtyDaysAgo, toGranularity: .day) == .orderedDescending
    }
    
    // MARK: - Error Handling
    
    /// Clear any error messages
    func clearError() {
        errorMessage = nil
        dataManager.clearError()
    }
    
    /// Retry last failed operation
    func retryLastOperation() {
        clearError()
        refreshData()
    }
}
