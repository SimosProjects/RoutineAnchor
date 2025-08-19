//
//  TestHelpers.swift
//  Routine Anchor
//
//  Created by Christopher Simonson on 8/18/25.
//
import Foundation
import SwiftData
@testable import Routine_Anchor

// MARK: - Test Data Manager Creation
@MainActor
func createTestDataManager() throws -> (DataManager, ModelContainer) {
    let schema = Schema([
        TimeBlock.self,
        DailyProgress.self
    ])
    
    let configuration = ModelConfiguration(
        schema: schema,
        isStoredInMemoryOnly: true,
        allowsSave: true
    )
    
    let container = try ModelContainer(
        for: schema,
        configurations: [configuration]
    )
    
    let dataManager = DataManager(modelContext: container.mainContext)
    return (dataManager, container)
}

// MARK: - Sample Data Creation
func createSampleTimeBlock(
    title: String = "Test Block",
    startHour: Int = 10,
    endHour: Int = 11,
    day: Date = Date()
) -> TimeBlock {
    let calendar = Calendar.current
    let startOfDay = calendar.startOfDay(for: day)
    
    let startTime = calendar.date(
        byAdding: .hour,
        value: startHour,
        to: startOfDay
    ) ?? Date()
    
    let endTime = calendar.date(
        byAdding: .hour,
        value: endHour,
        to: startOfDay
    ) ?? Date().addingTimeInterval(3600)
    
    return TimeBlock(
        title: title,
        startTime: startTime,
        endTime: endTime
    )
}

func createSampleDailyProgress(
    for date: Date = Date(),
    totalBlocks: Int = 5,
    completedBlocks: Int = 3
) -> DailyProgress {
    let progress = DailyProgress(date: date)
    progress.totalBlocks = totalBlocks
    progress.completedBlocks = completedBlocks
    progress.skippedBlocks = 1
    return progress
}

// MARK: - Test Assertions
extension TimeBlock {
    var isValidForTesting: Bool {
        return !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
               startTime < endTime &&
               endTime.timeIntervalSince(startTime) >= 60 &&
               endTime.timeIntervalSince(startTime) <= 86400
    }
}
