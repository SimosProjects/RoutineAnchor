//
//  DailySummaryViewModel.swift
//  Routine Anchor
//
import SwiftUI
import SwiftData
import Foundation

@Observable
@MainActor
class DailySummaryViewModel {
    // MARK: - Published Properties
    var todaysTimeBlocks: [TimeBlock] = []
    var weeklyStats: WeeklyStats?
    var isLoading = false
    var errorMessage: String?
    var selectedDate = Date()
    
    // MARK: - Private Properties
    private let dataManager: DataManager
    private var loadTask: Task<Void, Never>?
    
    // FIXED: Safe access to daily progress with crash protection
    var safeDailyProgress: DailyProgress? {
        do {
            // Use safe model access to prevent crashes
            return dataManager.safeModelAccess({
                return dataManager.loadDailyProgressSafely(for: selectedDate)
            }, fallback: nil)
        } catch {
            print("⚠️ Model context issue in safeDailyProgress: \(error)")
            return nil
        }
    }
    
    // MARK: - Initialization
    init(dataManager: DataManager, loadImmediately: Bool = true) {
        self.dataManager = dataManager
        if loadImmediately {
            Task { await loadData(for: selectedDate) }
        }
    }
    
    init(dataManager: DataManager, date: Date) {
        self.dataManager = dataManager
        self.selectedDate = date
        Task { await loadData(for: date) }
    }
    
    func cancelLoadTask() {
        let taskToCancel = loadTask
        loadTask = nil
        taskToCancel?.cancel()
    }
    
    // MARK: - Data Loading (FIXED with crash protection)
    
    /// Load all data for the specified date
    func loadData(for date: Date) async {
        selectedDate = date
        isLoading = true
        errorMessage = nil
        
        // Cancel any existing load task
        loadTask?.cancel()
        
        do {
            // FIXED: Wrap all model access in try-catch
            let blocks = dataManager.safeModelAccess({
                return dataManager.loadTimeBlocksSafely(for: date)
            }, fallback: [])
            
            dataManager.safeModelAccess({
                dataManager.updateDailyProgressSafely(for: date)
            }, fallback: ())
            
            // Create weekly stats if we have a method for it
            let stats = await calculateWeeklyStats(for: date)
            
            // Update properties directly
            self.todaysTimeBlocks = blocks
            self.weeklyStats = stats
            self.isLoading = false
            
        } catch {
            print("⚠️ Error loading data: \(error)")
            self.isLoading = false
            self.errorMessage = "Failed to load data. Please try again."
        }
    }
    
    private func calculateWeeklyStats(for date: Date) async -> WeeklyStats? {
        return dataManager.safeModelAccess({
            let calendar = Calendar.current
            guard let weekStart = calendar.dateInterval(of: .weekOfYear, for: date)?.start else {
                return nil
            }

            var totalDays = 0
            var completedDays = 0
            var totalCompletion: Double = 0
            var totalBlocks = 0
            var totalCompleted = 0

            for dayOffset in 0..<7 {
                guard let day = calendar.date(byAdding: .day, value: dayOffset, to: weekStart),
                      day <= Date() else { continue }

                if let progress = dataManager.loadDailyProgressSafely(for: day) {
                    // Wrap each property access in safe access
                    let completion = dataManager.safeModelAccess({ progress.completionPercentage }, fallback: 0.0)
                    let blocks = dataManager.safeModelAccess({ progress.totalBlocks }, fallback: 0)
                    let completed = dataManager.safeModelAccess({ progress.completedBlocks }, fallback: 0)
                    
                    totalDays += 1
                    totalCompletion += completion
                    totalBlocks += blocks
                    totalCompleted += completed

                    if completion >= 0.7 {
                        completedDays += 1
                    }
                }
            }

            guard totalDays > 0 else { return nil }

            return WeeklyStats(
                totalDays: totalDays,
                completedDays: completedDays,
                averageCompletion: totalCompletion / Double(totalDays),
                totalBlocks: totalBlocks,
                totalCompleted: totalCompleted
            )
        }, fallback: nil)
    }
    
    /// Refresh current data
    func refreshData() async {
        await loadData(for: selectedDate)
    }
    
    // MARK: - Data Updates (FIXED with crash protection)
    
    /// Save day rating and notes
    @MainActor
    func saveDayRatingAndNotes(rating: Int, notes: String) async {
        do {
            guard let progress = safeDailyProgress else { return }
            
            // FIXED: Wrap all model property access in safe calls
            dataManager.safeModelAccess({
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
            }, fallback: ())
            
            dataManager.safeModelAccess({
                dataManager.updateDailyProgressSafely(for: selectedDate)
            }, fallback: ())
            
            // Trigger success haptic
            HapticManager.shared.lightImpact()
            
        }
    }
    
    /// Update a specific time block status from summary view
    func updateTimeBlockStatus(_ timeBlock: TimeBlock, to status: BlockStatus) async {
        do {
            dataManager.safeModelAccess({
                dataManager.updateTimeBlockStatusSafely(timeBlock, to: status)
            }, fallback: ())
            
            // Refresh data to show updated statistics
            await refreshData()
            
            HapticManager.shared.success()
        }
    }
    
    // MARK: - Computed Properties (FIXED with crash protection)
    
    /// Whether we have any data to show
    var hasData: Bool {
        let timeBlocksExist = !todaysTimeBlocks.isEmpty
        let progressExists = dataManager.safeModelAccess({
            safeDailyProgress?.totalBlocks ?? 0 > 0
        }, fallback: false)
        return timeBlocksExist || progressExists
    }
    
    /// Completion percentage for the day
    var completionPercentage: Double {
        return dataManager.safeModelAccess({
            safeDailyProgress?.completionPercentage ?? 0.0
        }, fallback: 0.0)
    }
    
    /// Performance message for the day
    var performanceMessage: String {
        return dataManager.safeModelAccess({
            safeDailyProgress?.motivationalMessage ?? "Keep going! Every step counts."
        }, fallback: "Keep going! Every step counts.")
    }
    
    /// Whether the day is complete
    var isDayComplete: Bool {
        return dataManager.safeModelAccess({
            safeDailyProgress?.isDayComplete ?? false
        }, fallback: false)
    }
    
    /// Performance level for the day
    var performanceLevel: DailyProgress.PerformanceLevel {
        return dataManager.safeModelAccess({
            safeDailyProgress?.performanceLevel ?? .none
        }, fallback: .none)
    }
    
    /// Time blocks grouped by status for better organization
    var timeBlocksByStatus: [BlockStatus: [TimeBlock]] {
        return Dictionary(grouping: todaysTimeBlocks) { timeBlock in
            dataManager.safeModelAccess({ timeBlock.status }, fallback: .notStarted)
        }
    }
    
    /// Sorted time blocks by start time
    var sortedTimeBlocks: [TimeBlock] {
        return todaysTimeBlocks.sorted { block1, block2 in
            let time1 = dataManager.safeModelAccess({ block1.startTime }, fallback: Date())
            let time2 = dataManager.safeModelAccess({ block2.startTime }, fallback: Date())
            return time1 < time2
        }
    }
    
    /// Count of blocks by each status
    var statusCounts: (completed: Int, skipped: Int, inProgress: Int, upcoming: Int) {
        let completed = todaysTimeBlocks.filter { block in
            dataManager.safeModelAccess({ block.status == .completed }, fallback: false)
        }.count
        
        let skipped = todaysTimeBlocks.filter { block in
            dataManager.safeModelAccess({ block.status == .skipped }, fallback: false)
        }.count
        
        let inProgress = todaysTimeBlocks.filter { block in
            dataManager.safeModelAccess({ block.status == .inProgress }, fallback: false)
        }.count
        
        let upcoming = todaysTimeBlocks.filter { block in
            dataManager.safeModelAccess({ block.status == .notStarted }, fallback: false)
        }.count
        
        return (completed, skipped, inProgress, upcoming)
    }
    
    // MARK: - Analysis & Insights (FIXED with crash protection)
    
    /// Get personalized insights based on performance
    func getPersonalizedInsights() -> [String] {
        guard let progress = safeDailyProgress else {
            return ["Create time blocks to start tracking your progress!"]
        }
        
        var insights: [String] = []
        
        // FIXED: Wrap all progress property access in safe calls
        let performanceLevel = dataManager.safeModelAccess({ progress.performanceLevel }, fallback: .none)
        let completedBlocks = dataManager.safeModelAccess({ progress.completedBlocks }, fallback: 0)
        let skipRate = dataManager.safeModelAccess({ progress.skipRate }, fallback: 0.0)
        let totalPlannedMinutes = dataManager.safeModelAccess({ progress.totalPlannedMinutes }, fallback: 0)
        let completionPercentage = dataManager.safeModelAccess({ progress.completionPercentage }, fallback: 0.0)
        
        // Performance-based insights
        switch performanceLevel {
        case .excellent:
            insights.append("Outstanding work! You're building incredible momentum.")
            if completedBlocks >= 5 {
                insights.append("Managing \(completedBlocks) blocks shows exceptional time management.")
            }
            
        case .good:
            insights.append("Great job! You're on track to build lasting habits.")
            let suggestions = dataManager.safeModelAccess({ progress.suggestions }, fallback: [])
            if let suggestion = suggestions.first {
                insights.append(suggestion)
            }
            
        case .fair:
            insights.append("Good progress! Consistency is key to improvement.")
            let suggestions = dataManager.safeModelAccess({ progress.suggestions }, fallback: [])
            insights.append(contentsOf: suggestions.prefix(2))
            
        case .poor:
            insights.append("Every step forward counts. Tomorrow is a new opportunity.")
            if skipRate > 0.5 {
                insights.append("High skip rate detected. Consider shorter, more manageable blocks.")
            }
            
        case .none:
            insights.append("Ready to start? Create your first time block!")
        }
        
        // Time-based insights
        if totalPlannedMinutes > 8 * 60 {
            insights.append("Remember to include breaks in long schedules for sustainability.")
        }
        
        // Weekly context insights
        if let weeklyStats = weeklyStats {
            let todayVsAverage = completionPercentage - weeklyStats.averageCompletion
            
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
        let completedCategories = Set(todaysTimeBlocks.compactMap { block in
            let isCompleted = dataManager.safeModelAccess({ block.status == .completed }, fallback: false)
            return isCompleted ? dataManager.safeModelAccess({ block.category }, fallback: nil) : nil
        })
        
        if completedCategories.count >= 3 {
            insights.append("Great balance across \(completedCategories.count) different life areas today.")
        }
        
        return insights
    }
    
    /// Get improvement suggestions
    func getImprovementSuggestions() -> [String] {
        guard let progress = safeDailyProgress else { return [] }
        
        var suggestions: [String] = []
        
        // FIXED: Wrap all property access in safe calls
        let completionPercentage = dataManager.safeModelAccess({ progress.completionPercentage }, fallback: 0.0)
        let totalBlocks = dataManager.safeModelAccess({ progress.totalBlocks }, fallback: 0)
        
        // Completion rate suggestions
        if completionPercentage < 0.5 && totalBlocks > 5 {
            suggestions.append("Consider reducing to 3-4 essential blocks to build momentum.")
        }
        
        // Skip pattern analysis
        let skippedBlocks = todaysTimeBlocks.filter { block in
            dataManager.safeModelAccess({ block.status == .skipped }, fallback: false)
        }
        
        if !skippedBlocks.isEmpty {
            let categories = Set(skippedBlocks.compactMap { block in
                dataManager.safeModelAccess({ block.category }, fallback: nil)
            })
            if categories.count == 1, let category = categories.first {
                suggestions.append("Notice a pattern? \(category) blocks are frequently skipped.")
            }
        }
        
        // Time of day patterns
        let morningBlocks = todaysTimeBlocks.filter { block in
            let startTime = dataManager.safeModelAccess({ block.startTime }, fallback: Date())
            return Calendar.current.component(.hour, from: startTime) < 12
        }
        
        let morningCompletion = morningBlocks.filter { block in
            dataManager.safeModelAccess({ block.status == .completed }, fallback: false)
        }.count
        
        if morningBlocks.count > 0 && Double(morningCompletion) / Double(morningBlocks.count) < 0.5 {
            suggestions.append("Morning blocks have lower completion. Are you a night owl?")
        }
        
        // Duration insights
        let longBlocks = todaysTimeBlocks.filter { block in
            dataManager.safeModelAccess({ block.durationMinutes > 90 }, fallback: false)
        }
        
        let longBlocksSkipped = longBlocks.filter { block in
            dataManager.safeModelAccess({ block.status == .skipped }, fallback: false)
        }.count
        
        if longBlocks.count > 0 && Double(longBlocksSkipped) / Double(longBlocks.count) > 0.5 {
            suggestions.append("Long blocks (90+ min) are often skipped. Try breaking them down.")
        }
        
        return suggestions.isEmpty ? ["Keep experimenting to find your optimal routine!"] : suggestions
    }
    
    // MARK: - Sharing & Export (FIXED with crash protection)
    
    /// Generate shareable text summary
    func generateShareableText() -> String {
        guard let progress = safeDailyProgress else {
            return "Daily Summary - No data available"
        }
        
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        
        // Wrap property access safely
        let performanceLevel = dataManager.safeModelAccess({
            progress.performanceLevel
        }, fallback: DailyProgress.PerformanceLevel.none)
        
        let completionPercentage = dataManager.safeModelAccess({
            progress.formattedCompletionPercentage
        }, fallback: "0%")
        
        let completionSummary = dataManager.safeModelAccess({
            progress.completionSummary
        }, fallback: "No data")
        
        var text = """
        📊 Daily Summary - \(formatter.string(from: selectedDate))
        
        ✨ Performance: \(performanceLevel.displayName) \(performanceLevel.emoji)
        📈 Completion: \(completionPercentage) (\(completionSummary))
        """
        
        // Safe access to planned minutes
        let plannedMinutes = dataManager.safeModelAccess({
            progress.totalPlannedMinutes
        }, fallback: 0)
        
        if plannedMinutes > 0 {
            let timeSummary = dataManager.safeModelAccess({
                progress.timeSummary
            }, fallback: "No time data")
            text += "\n⏰ Time: \(timeSummary)"
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
        
        // Safe access to rating and notes
        let rating = dataManager.safeModelAccess({
            progress.dayRating
        }, fallback: nil)
        
        let notes = dataManager.safeModelAccess({
            progress.dayNotes
        }, fallback: nil)
        
        // Add rating and reflection
        if let rating = rating {
            text += "\n\n💭 Personal Rating: \(String(repeating: "⭐", count: rating))"
        }
        
        if let notes = notes, !notes.isEmpty {
            text += "\n📝 Reflection: \(notes)"
        }
        
        // Add motivational close
        let motivationalMessage = dataManager.safeModelAccess({
            progress.motivationalMessage
        }, fallback: "Keep going!")
        
        text += "\n\n\(motivationalMessage)"
        text += "\n\n—\nBuilt with Routine Anchor 🎯"
        
        return text
    }
    
    /// Generate detailed export data
    func generateDetailedExport() -> [String: Any] {
        guard let progress = safeDailyProgress else {
            return ["error": "No data available"]
        }
        
        // Create weekly context with explicit type annotation
        let weeklyContext: [String: Any]
        if let weeklyStats = weeklyStats {
            weeklyContext = [
                "averageCompletion": weeklyStats.averageCompletion,
                "totalDays": weeklyStats.totalDays,
                "completedDays": weeklyStats.completedDays
            ]
        } else {
            weeklyContext = [
                "averageCompletion": 0.0,
                "totalDays": 0,
                "completedDays": 0
            ]
        }
        
        // FIXED: Wrap all progress property access in safe calls
        let summaryData = dataManager.safeModelAccess({
            return [
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
            ]
        }, fallback: [
            "date": ISO8601DateFormatter().string(from: selectedDate),
            "completionPercentage": 0.0,
            "performanceLevel": "none",
            "totalBlocks": 0,
            "completedBlocks": 0,
            "skippedBlocks": 0,
            "totalMinutes": 0,
            "completedMinutes": 0,
            "dayRating": NSNull(),
            "dayNotes": NSNull()
        ])
        
        return [
            "summary": summaryData,
            "timeBlocks": todaysTimeBlocks.compactMap { block in
                // Wrap property access in safe access to prevent crashes
                return dataManager.safeModelAccess({
                    return [
                        "id": block.id.uuidString,
                        "title": block.title,
                        "startTime": ISO8601DateFormatter().string(from: block.startTime),
                        "endTime": ISO8601DateFormatter().string(from: block.endTime),
                        "duration": block.durationMinutes,
                        "status": block.status.rawValue,
                        "category": block.category ?? "",
                        "icon": block.icon ?? ""
                    ]
                }, fallback: nil)
            }.compactMap { $0 },
            "insights": getPersonalizedInsights(),
            "suggestions": getImprovementSuggestions(),
            "weeklyContext": weeklyContext,
            "exportedAt": ISO8601DateFormatter().string(from: Date())
        ]
    }
    
    // MARK: - Navigation Helpers
    
    /// Load previous day's data
    func loadPreviousDay() async {
        guard let previousDay = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) else { return }
        await loadData(for: previousDay)
    }
    
    /// Load next day's data
    func loadNextDay() async {
        guard let nextDay = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) else { return }
        await loadData(for: nextDay)
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
        Task {
            clearError()
            await refreshData()
        }
    }
}
