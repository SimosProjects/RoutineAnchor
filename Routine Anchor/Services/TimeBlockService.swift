//
//  TimeBlockService.swift
//  Routine Anchor
//
//  Service for time block validation, conflict detection, and business logic
//
import Foundation
import SwiftData

@MainActor
class TimeBlockService {
    // MARK: - Singleton
    static let shared = TimeBlockService()
    private init() {}
    
    // MARK: - Validation
    
    /// Validate a time block before saving
    func validate(timeBlock: TimeBlock) throws {
        // Title validation
        if timeBlock.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            throw ValidationError.emptyTitle
        }
        
        if timeBlock.title.count > 100 {
            throw ValidationError.titleTooLong
        }
        
        // Time validation
        if timeBlock.startTime >= timeBlock.endTime {
            throw ValidationError.invalidTimeRange
        }
        
        let duration = timeBlock.endTime.timeIntervalSince(timeBlock.startTime)
        if duration < 60 { // Less than 1 minute
            throw ValidationError.durationTooShort
        }
        
        if duration > 86400 { // More than 24 hours
            throw ValidationError.durationTooLong
        }
        
        // Notes validation
        if let notes = timeBlock.notes, notes.count > 500 {
            throw ValidationError.notesTooLong
        }
        
        // Category validation
        if let category = timeBlock.category, category.count > 50 {
            throw ValidationError.categoryTooLong
        }
    }
    
    /// Check for conflicts with existing time blocks
    func checkConflicts(for timeBlock: TimeBlock, existingBlocks: [TimeBlock], excludingId: UUID? = nil) -> [TimeBlock] {
        let conflictingBlocks = existingBlocks.filter { existingBlock in
            // Skip if it's the same block (for editing)
            if let excludeId = excludingId, existingBlock.id == excludeId {
                return false
            }
            
            // Skip if different days
            if !Calendar.current.isDate(existingBlock.startTime, inSameDayAs: timeBlock.startTime) {
                return false
            }
            
            // Check for time overlap
            return isOverlapping(timeBlock, with: existingBlock)
        }
        
        return conflictingBlocks
    }
    
    /// Check if two time blocks overlap
    private func isOverlapping(_ block1: TimeBlock, with block2: TimeBlock) -> Bool {
        // Check if block1 starts during block2
        if block1.startTime >= block2.startTime && block1.startTime < block2.endTime {
            return true
        }
        
        // Check if block1 ends during block2
        if block1.endTime > block2.startTime && block1.endTime <= block2.endTime {
            return true
        }
        
        // Check if block1 completely contains block2
        if block1.startTime <= block2.startTime && block1.endTime >= block2.endTime {
            return true
        }
        
        return false
    }
    
    // MARK: - Business Logic
    
    /// Get optimal time slot suggestions based on existing blocks
    func suggestTimeSlots(for date: Date, existingBlocks: [TimeBlock], duration: TimeInterval = 3600) -> [TimeSlotSuggestion] {
        var suggestions: [TimeSlotSuggestion] = []
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        
        // Define working hours (can be customized later)
        let workingHours = [
            (start: 6, end: 9, type: "Morning"),
            (start: 9, end: 12, type: "Late Morning"),
            (start: 12, end: 14, type: "Lunch"),
            (start: 14, end: 17, type: "Afternoon"),
            (start: 17, end: 20, type: "Evening"),
            (start: 20, end: 22, type: "Night")
        ]
        
        // Sort existing blocks by start time
        let dayBlocks = existingBlocks
            .filter { calendar.isDate($0.startTime, inSameDayAs: date) }
            .sorted { $0.startTime < $1.startTime }
        
        for timeSlot in workingHours {
            guard let slotStart = calendar.date(bySettingHour: timeSlot.start, minute: 0, second: 0, of: startOfDay),
                  let slotEnd = calendar.date(bySettingHour: timeSlot.end, minute: 0, second: 0, of: startOfDay) else {
                continue
            }
            
            // Find available gaps in this time slot
            var currentTime = slotStart
            
            while currentTime.addingTimeInterval(duration) <= slotEnd {
                let proposedBlock = TimeBlock(
                    title: "",
                    startTime: currentTime,
                    endTime: currentTime.addingTimeInterval(duration)
                )
                
                let conflicts = checkConflicts(for: proposedBlock, existingBlocks: dayBlocks)
                
                if conflicts.isEmpty {
                    suggestions.append(TimeSlotSuggestion(
                        startTime: currentTime,
                        endTime: currentTime.addingTimeInterval(duration),
                        type: timeSlot.type,
                        isOptimal: isOptimalTime(currentTime, type: timeSlot.type)
                    ))
                    
                    // Jump to next hour
                    currentTime = currentTime.addingTimeInterval(3600)
                } else {
                    // Jump past the conflict
                    if let lastConflict = conflicts.sorted(by: { $0.endTime > $1.endTime }).first {
                        currentTime = lastConflict.endTime
                    } else {
                        currentTime = currentTime.addingTimeInterval(900) // 15 minutes
                    }
                }
            }
        }
        
        return suggestions.sorted { $0.startTime < $1.startTime }
    }
    
    /// Determine if a time is optimal based on common productivity patterns
    private func isOptimalTime(_ time: Date, type: String) -> Bool {
        let hour = Calendar.current.component(.hour, from: time)
        
        switch type {
        case "Morning":
            return hour >= 7 && hour <= 8 // Peak morning productivity
        case "Late Morning":
            return hour >= 9 && hour <= 11 // Deep work time
        case "Afternoon":
            return hour >= 14 && hour <= 16 // Post-lunch productivity
        case "Evening":
            return hour >= 18 && hour <= 19 // Wind-down productive time
        default:
            return false
        }
    }
    
    /// Calculate statistics for time blocks
    func calculateStats(for timeBlocks: [TimeBlock], in dateRange: ClosedRange<Date>? = nil) -> TimeBlockStats {
        let filteredBlocks: [TimeBlock]
        
        if let range = dateRange {
            filteredBlocks = timeBlocks.filter { range.contains($0.startTime) }
        } else {
            filteredBlocks = timeBlocks
        }
        
        let totalBlocks = filteredBlocks.count
        let completedBlocks = filteredBlocks.filter { $0.status == .completed }.count
        let skippedBlocks = filteredBlocks.filter { $0.status == .skipped }.count
        let pendingBlocks = filteredBlocks.filter { $0.status == .notStarted || $0.status == .inProgress }.count
        
        let totalDuration = filteredBlocks.reduce(0.0) {
            $0 + $1.endTime.timeIntervalSince($1.startTime)
        }

        let completedDuration = filteredBlocks
            .filter { $0.status == .completed }
            .reduce(0.0) {
                $0 + $1.endTime.timeIntervalSince($1.startTime)
            }
        
        let categoryBreakdown = Dictionary(grouping: filteredBlocks) { $0.category ?? "Uncategorized" }
            .mapValues { blocks in
                CategoryStats(
                    count: blocks.count,
                    completedCount: blocks.filter { $0.status == .completed }.count,
                    totalDuration: blocks.reduce(0) { $0 + $1.endTime.timeIntervalSince($1.startTime) }
                )
            }
        
        let averageBlockDuration = totalBlocks > 0 ? totalDuration / Double(totalBlocks) : 0
        let completionRate = totalBlocks > 0 ? Double(completedBlocks) / Double(totalBlocks) : 0
        
        return TimeBlockStats(
            totalBlocks: totalBlocks,
            completedBlocks: completedBlocks,
            skippedBlocks: skippedBlocks,
            pendingBlocks: pendingBlocks,
            totalDuration: totalDuration,
            completedDuration: completedDuration,
            averageBlockDuration: averageBlockDuration,
            completionRate: completionRate,
            categoryBreakdown: categoryBreakdown
        )
    }
    
    /// Get productivity insights based on time block patterns
    func getProductivityInsights(for timeBlocks: [TimeBlock]) -> [ProductivityInsight] {
        var insights: [ProductivityInsight] = []
        
        let stats = calculateStats(for: timeBlocks)
        
        // Completion rate insight
        if stats.completionRate >= 0.8 {
            insights.append(ProductivityInsight(
                type: .positive,
                title: "Excellent Completion Rate",
                message: "You're completing \(Int(stats.completionRate * 100))% of your time blocks. Keep up the great work!",
                icon: "🌟"
            ))
        } else if stats.completionRate < 0.5 {
            insights.append(ProductivityInsight(
                type: .improvement,
                title: "Room for Improvement",
                message: "You're completing \(Int(stats.completionRate * 100))% of blocks. Try breaking tasks into smaller chunks.",
                icon: "💡"
            ))
        }
        
        // Most productive time of day
        if let mostProductiveHour = findMostProductiveHour(from: timeBlocks) {
            insights.append(ProductivityInsight(
                type: .info,
                title: "Peak Productivity Time",
                message: "You complete most tasks around \(formatHour(mostProductiveHour)). Schedule important work during this time.",
                icon: "⏰"
            ))
        }
        
        // Category insights
        if let mostSuccessfulCategory = findMostSuccessfulCategory(from: stats.categoryBreakdown) {
            insights.append(ProductivityInsight(
                type: .positive,
                title: "Strong in \(mostSuccessfulCategory)",
                message: "You have the highest completion rate in \(mostSuccessfulCategory) tasks. Build on this strength!",
                icon: "💪"
            ))
        }
        
        return insights
    }
    
    private func findMostProductiveHour(from blocks: [TimeBlock]) -> Int? {
        let completedBlocks = blocks.filter { $0.status == .completed }
        guard !completedBlocks.isEmpty else { return nil }
        
        let hourCounts = Dictionary(grouping: completedBlocks) { block in
            Calendar.current.component(.hour, from: block.startTime)
        }.mapValues { $0.count }
        
        return hourCounts.max(by: { $0.value < $1.value })?.key
    }
    
    private func findMostSuccessfulCategory(from categoryStats: [String: CategoryStats]) -> String? {
        let categoriesWithCompletion = categoryStats.compactMap { (category, stats) -> (String, Double)? in
            guard stats.count > 0 else { return nil }
            let completionRate = Double(stats.completedCount) / Double(stats.count)
            return (category, completionRate)
        }
        
        return categoriesWithCompletion.max(by: { $0.1 < $1.1 })?.0
    }
    
    private func formatHour(_ hour: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h a"
        let date = Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: Date())!
        return formatter.string(from: date)
    }
}

// MARK: - Supporting Types

struct TimeSlotSuggestion {
    let startTime: Date
    let endTime: Date
    let type: String
    let isOptimal: Bool
}

struct TimeBlockStats {
    let totalBlocks: Int
    let completedBlocks: Int
    let skippedBlocks: Int
    let pendingBlocks: Int
    let totalDuration: TimeInterval
    let completedDuration: TimeInterval
    let averageBlockDuration: TimeInterval
    let completionRate: Double
    let categoryBreakdown: [String: CategoryStats]
}

struct CategoryStats {
    let count: Int
    let completedCount: Int
    let totalDuration: TimeInterval
}

struct ProductivityInsight {
    enum InsightType {
        case positive
        case improvement
        case info
    }
    
    let type: InsightType
    let title: String
    let message: String
    let icon: String
}

// MARK: - Validation Errors

enum ValidationError: LocalizedError {
    case emptyTitle
    case titleTooLong
    case invalidTimeRange
    case durationTooShort
    case durationTooLong
    case notesTooLong
    case categoryTooLong
    
    var errorDescription: String? {
        switch self {
        case .emptyTitle:
            return "Please enter a title for your time block"
        case .titleTooLong:
            return "Title must be less than 100 characters"
        case .invalidTimeRange:
            return "End time must be after start time"
        case .durationTooShort:
            return "Time blocks must be at least 1 minute long"
        case .durationTooLong:
            return "Time blocks cannot exceed 24 hours"
        case .notesTooLong:
            return "Notes must be less than 500 characters"
        case .categoryTooLong:
            return "Category must be less than 50 characters"
        }
    }
}
