//
//  AnalyticsService.swift
//  Routine Anchor
//
//  Service for tracking app usage, generating insights, and analytics
//
import Foundation
import SwiftData

class AnalyticsService {
    // MARK: - Singleton
    static let shared = AnalyticsService()
    private init() {}
    
    // MARK: - Analytics Methods
    
    /// Generate weekly analytics report
    func generateWeeklyReport(timeBlocks: [TimeBlock], dailyProgress: [DailyProgress]) -> WeeklyReport {
        let calendar = Calendar.current
        let now = Date()
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: now)!
        
        // Filter data for the past week
        let weekBlocks = timeBlocks.filter { $0.startTime >= weekAgo }
        let weekProgress = dailyProgress.filter { $0.date >= weekAgo }
        
        // Calculate basic metrics
        let totalBlocks = weekBlocks.count
        let completedBlocks = weekBlocks.filter { $0.status == .completed }.count
        let skippedBlocks = weekBlocks.filter { $0.status == .skipped }.count
        let completionRate = totalBlocks > 0 ? Double(completedBlocks) / Double(totalBlocks) : 0
        
        // Calculate time metrics
        let totalScheduledTime = weekBlocks.reduce(0) { total, block in
            total + Double(block.durationMinutes * 60) // Convert to seconds
        }
        let totalCompletedTime = weekBlocks
            .filter { $0.status == .completed }
            .reduce(0) { total, block in
                total + Double(block.durationMinutes * 60)
            }
        
        // Daily breakdown
        let dailyStats = getDailyBreakdown(blocks: weekBlocks, progress: weekProgress)
        
        // Category performance
        let categoryPerformance = getCategoryPerformance(blocks: weekBlocks)
        
        // Time of day analysis
        let timeOfDayStats = getTimeOfDayAnalysis(blocks: weekBlocks)
        
        // Streak calculation
        let currentStreak = calculateCurrentStreak(progress: dailyProgress)
        let longestStreak = calculateLongestStreak(progress: dailyProgress)
        
        // Trends
        let trends = calculateTrends(blocks: timeBlocks, progress: dailyProgress)
        
        return WeeklyReport(
            dateRange: weekAgo...now,
            totalBlocks: totalBlocks,
            completedBlocks: completedBlocks,
            skippedBlocks: skippedBlocks,
            completionRate: completionRate,
            totalScheduledTime: totalScheduledTime,
            totalCompletedTime: totalCompletedTime,
            dailyStats: dailyStats,
            categoryPerformance: categoryPerformance,
            timeOfDayStats: timeOfDayStats,
            currentStreak: currentStreak,
            longestStreak: longestStreak,
            trends: trends
        )
    }
    
    /// Generate monthly analytics
    func generateMonthlyReport(timeBlocks: [TimeBlock], dailyProgress: [DailyProgress]) -> MonthlyReport {
        let calendar = Calendar.current
        let now = Date()
        let monthAgo = calendar.date(byAdding: .month, value: -1, to: now)!
        
        // Filter data for the past month
        let monthBlocks = timeBlocks.filter { $0.startTime >= monthAgo }
        let monthProgress = dailyProgress.filter { $0.date >= monthAgo }
        
        // Get weekly breakdowns
        var weeklyBreakdowns: [WeeklyBreakdown] = []
        var currentWeekStart = monthAgo
        
        while currentWeekStart < now {
            let weekEnd = calendar.date(byAdding: .day, value: 6, to: currentWeekStart)!
            let weekBlocks = monthBlocks.filter {
                $0.startTime >= currentWeekStart && $0.startTime <= weekEnd
            }
            
            let completed = weekBlocks.filter { $0.status == .completed }.count
            let total = weekBlocks.count
            let rate = total > 0 ? Double(completed) / Double(total) : 0
            
            weeklyBreakdowns.append(WeeklyBreakdown(
                weekNumber: calendar.component(.weekOfYear, from: currentWeekStart),
                completionRate: rate,
                totalBlocks: total
            ))
            
            currentWeekStart = calendar.date(byAdding: .day, value: 7, to: currentWeekStart)!
        }
        
        // Calculate improvements
        let improvements = calculateImprovements(blocks: monthBlocks, progress: monthProgress)
        
        // Most productive days
        let productiveDays = findMostProductiveDays(blocks: monthBlocks)
        
        return MonthlyReport(
            month: calendar.component(.month, from: now),
            year: calendar.component(.year, from: now),
            weeklyBreakdowns: weeklyBreakdowns,
            improvements: improvements,
            mostProductiveDays: productiveDays,
            totalTimeScheduled: monthBlocks.reduce(0) { $0 + Double($1.durationMinutes * 60) },
            totalTimeCompleted: monthBlocks.filter { $0.status == .completed }.reduce(0) { $0 + Double($1.durationMinutes * 60) }
        )
    }
    
    // MARK: - Daily Analysis
    
    private func getDailyBreakdown(blocks: [TimeBlock], progress: [DailyProgress]) -> [DailyStats] {
        let calendar = Calendar.current
        var dailyStatsDict: [Date: DailyStats] = [:]
        
        // Group blocks by day
        let groupedBlocks = Dictionary(grouping: blocks) { block in
            calendar.startOfDay(for: block.startTime)
        }
        
        for (date, dayBlocks) in groupedBlocks {
            let completed = dayBlocks.filter { $0.status == .completed }.count
            let total = dayBlocks.count
            let completionRate = total > 0 ? Double(completed) / Double(total) : 0
            
            // Find matching progress entry
            let progressEntry = progress.first { calendar.isDate($0.date, inSameDayAs: date) }
            
            dailyStatsDict[date] = DailyStats(
                date: date,
                completedBlocks: completed,
                totalBlocks: total,
                completionRate: completionRate,
                dayNotes: progressEntry?.dayNotes
            )
        }
        
        return dailyStatsDict.values.sorted { $0.date < $1.date }
    }
    
    // MARK: - Category Analysis
    
    private func getCategoryPerformance(blocks: [TimeBlock]) -> [CategoryPerformance] {
        let grouped = Dictionary(grouping: blocks) { $0.category ?? "Uncategorized" }
        
        return grouped.map { category, categoryBlocks in
            let completed = categoryBlocks.filter { $0.status == .completed }.count
            let total = categoryBlocks.count
            let completionRate = total > 0 ? Double(completed) / Double(total) : 0
            let totalTime = categoryBlocks.reduce(0) { $0 + Double($1.durationMinutes * 60) }
            
            return CategoryPerformance(
                category: category,
                completionRate: completionRate,
                totalBlocks: total,
                totalTime: totalTime
            )
        }.sorted { $0.completionRate > $1.completionRate }
    }
    
    // MARK: - Time of Day Analysis
    
    private func getTimeOfDayAnalysis(blocks: [TimeBlock]) -> TimeOfDayStats {
        let calendar = Calendar.current
        var hourlyCompletion: [Int: (completed: Int, total: Int)] = [:]
        
        for block in blocks {
            let hour = calendar.component(.hour, from: block.startTime)
            let current = hourlyCompletion[hour] ?? (0, 0)
            
            if block.status == .completed {
                hourlyCompletion[hour] = (current.completed + 1, current.total + 1)
            } else {
                hourlyCompletion[hour] = (current.completed, current.total + 1)
            }
        }
        
        // Find most productive hours
        let productiveHours = hourlyCompletion
            .filter { $0.value.total >= 3 } // At least 3 blocks to be significant
            .map { (hour: $0.key, rate: Double($0.value.completed) / Double($0.value.total)) }
            .sorted { $0.rate > $1.rate }
            .prefix(3)
            .map { $0.hour }
        
        return TimeOfDayStats(
            hourlyBreakdown: hourlyCompletion,
            mostProductiveHours: Array(productiveHours)
        )
    }
    
    // MARK: - Streak Calculations
    
    private func calculateCurrentStreak(progress: [DailyProgress]) -> Int {
        let sorted = progress.sorted { $0.date > $1.date }
        var streak = 0
        let calendar = Calendar.current
        var expectedDate = Date()
        
        for entry in sorted {
            let dayDifference = calendar.dateComponents([.day], from: entry.date, to: expectedDate).day ?? 0
            
            if dayDifference <= 1 && entry.completionPercentage > 0 {
                streak += 1
                expectedDate = calendar.date(byAdding: .day, value: -1, to: entry.date)!
            } else {
                break
            }
        }
        
        return streak
    }
    
    private func calculateLongestStreak(progress: [DailyProgress]) -> Int {
        let sorted = progress.sorted { $0.date < $1.date }
        var longestStreak = 0
        var currentStreak = 0
        var lastDate: Date?
        let calendar = Calendar.current
        
        for entry in sorted {
            if let last = lastDate {
                let dayDifference = calendar.dateComponents([.day], from: last, to: entry.date).day ?? 0
                
                if dayDifference == 1 && entry.completionPercentage > 0 {
                    currentStreak += 1
                } else if entry.completionPercentage > 0 {
                    currentStreak = 1
                } else {
                    currentStreak = 0
                }
            } else if entry.completionPercentage > 0 {
                currentStreak = 1
            }
            
            longestStreak = max(longestStreak, currentStreak)
            lastDate = entry.date
        }
        
        return longestStreak
    }
    
    // MARK: - Trend Analysis
    
    private func calculateTrends(blocks: [TimeBlock], progress: [DailyProgress]) -> TrendAnalysis {
        let calendar = Calendar.current
        let now = Date()
        
        // Compare this week to last week
        let thisWeekStart = calendar.dateInterval(of: .weekOfYear, for: now)!.start
        let lastWeekStart = calendar.date(byAdding: .weekOfYear, value: -1, to: thisWeekStart)!
        
        let thisWeekBlocks = blocks.filter {
            $0.startTime >= thisWeekStart && $0.startTime < now
        }
        let lastWeekBlocks = blocks.filter {
            $0.startTime >= lastWeekStart && $0.startTime < thisWeekStart
        }
        
        let thisWeekRate = calculateCompletionRate(for: thisWeekBlocks)
        let lastWeekRate = calculateCompletionRate(for: lastWeekBlocks)
        
        let trend: TrendDirection
        if thisWeekRate > lastWeekRate + 0.05 {
            trend = .improving
        } else if thisWeekRate < lastWeekRate - 0.05 {
            trend = .declining
        } else {
            trend = .stable
        }
        
        return TrendAnalysis(
            direction: trend,
            percentageChange: thisWeekRate - lastWeekRate,
            message: generateTrendMessage(trend: trend, change: thisWeekRate - lastWeekRate)
        )
    }
    
    private func calculateCompletionRate(for blocks: [TimeBlock]) -> Double {
        guard !blocks.isEmpty else { return 0 }
        let completed = blocks.filter { $0.status == .completed }.count
        return Double(completed) / Double(blocks.count)
    }
    
    private func generateTrendMessage(trend: TrendDirection, change: Double) -> String {
        let percentage = Int(abs(change) * 100)
        
        switch trend {
        case .improving:
            return "Your completion rate improved by \(percentage)% this week! 🎉"
        case .declining:
            return "Your completion rate decreased by \(percentage)% this week. Let's get back on track! 💪"
        case .stable:
            return "Your completion rate remained stable this week. Consistency is key! 👍"
        }
    }
    
    // MARK: - Improvement Suggestions
    
    private func calculateImprovements(blocks: [TimeBlock], progress: [DailyProgress]) -> [ImprovementSuggestion] {
        var suggestions: [ImprovementSuggestion] = []
        
        // Check for overambitious scheduling
        let avgBlocksPerDay = Double(blocks.count) / Double(Set(blocks.map { Calendar.current.startOfDay(for: $0.startTime) }).count)
        if avgBlocksPerDay > 10 {
            suggestions.append(ImprovementSuggestion(
                title: "Reduce Daily Blocks",
                description: "You're scheduling \(Int(avgBlocksPerDay)) blocks per day. Consider reducing to 6-8 for better focus.",
                impact: .high
            ))
        }
        
        // Check for long blocks
        let longBlocks = blocks.filter { $0.durationMinutes > 120 } // More than 2 hours
        if !longBlocks.isEmpty {
            suggestions.append(ImprovementSuggestion(
                title: "Break Down Long Tasks",
                description: "You have \(longBlocks.count) blocks over 2 hours. Try breaking them into smaller chunks.",
                impact: .medium
            ))
        }
        
        // Check for low completion categories
        let categoryPerf = getCategoryPerformance(blocks: blocks)
        if let worstCategory = categoryPerf.last, worstCategory.completionRate < 0.5 {
            suggestions.append(ImprovementSuggestion(
                title: "Focus on \(worstCategory.category)",
                description: "Your completion rate for \(worstCategory.category) is only \(Int(worstCategory.completionRate * 100))%. Consider scheduling these tasks at your peak productivity times.",
                impact: .high
            ))
        }
        
        return suggestions
    }
    
    // MARK: - Productive Days Analysis
    
    private func findMostProductiveDays(blocks: [TimeBlock]) -> [ProductiveDay] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: blocks) { block in
            calendar.startOfDay(for: block.startTime)
        }
        
        return grouped.compactMap { date, dayBlocks in
            let completed = dayBlocks.filter { $0.status == .completed }.count
            let total = dayBlocks.count
            guard total >= 3 else { return nil } // Need at least 3 blocks to be significant
            
            let rate = Double(completed) / Double(total)
            guard rate >= 0.8 else { return nil } // At least 80% completion
            
            return ProductiveDay(
                date: date,
                completionRate: rate,
                totalBlocks: total
            )
        }
        .sorted { $0.completionRate > $1.completionRate }
        .prefix(5)
        .map { $0 }
    }
}

// MARK: - Report Models

struct WeeklyReport {
    let dateRange: ClosedRange<Date>
    let totalBlocks: Int
    let completedBlocks: Int
    let skippedBlocks: Int
    let completionRate: Double
    let totalScheduledTime: TimeInterval
    let totalCompletedTime: TimeInterval
    let dailyStats: [DailyStats]
    let categoryPerformance: [CategoryPerformance]
    let timeOfDayStats: TimeOfDayStats
    let currentStreak: Int
    let longestStreak: Int
    let trends: TrendAnalysis
}

struct MonthlyReport {
    let month: Int
    let year: Int
    let weeklyBreakdowns: [WeeklyBreakdown]
    let improvements: [ImprovementSuggestion]
    let mostProductiveDays: [ProductiveDay]
    let totalTimeScheduled: TimeInterval
    let totalTimeCompleted: TimeInterval
}

struct DailyStats {
    let date: Date
    let completedBlocks: Int
    let totalBlocks: Int
    let completionRate: Double
    let dayNotes: String?
}

struct CategoryPerformance {
    let category: String
    let completionRate: Double
    let totalBlocks: Int
    let totalTime: TimeInterval
}

struct TimeOfDayStats {
    let hourlyBreakdown: [Int: (completed: Int, total: Int)]
    let mostProductiveHours: [Int]
}

struct TrendAnalysis {
    let direction: TrendDirection
    let percentageChange: Double
    let message: String
}

enum TrendDirection {
    case improving
    case declining
    case stable
}

struct WeeklyBreakdown {
    let weekNumber: Int
    let completionRate: Double
    let totalBlocks: Int
}

struct ImprovementSuggestion {
    let title: String
    let description: String
    let impact: ImpactLevel
    
    enum ImpactLevel {
        case high
        case medium
        case low
    }
}

struct ProductiveDay {
    let date: Date
    let completionRate: Double
    let totalBlocks: Int
}
