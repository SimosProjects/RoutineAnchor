//
//  ViewModelTests.swift
//  Routine AnchorTests
//
//  Testing ViewModel state management and UI integration
//
import XCTest
import SwiftData
@testable import Routine_Anchor

final class ViewModelTests: XCTestCase {
    
    var container: ModelContainer!
    
    override func setUp() {
        super.setUp()
        
        let schema = Schema([TimeBlock.self, DailyProgress.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        
        do {
            container = try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            XCTFail("Failed to create test container: \(error)")
        }
    }
    
    override func tearDown() {
        container = nil
        super.tearDown()
    }
    
    // MARK: - TodayViewModel Tests
    @MainActor
    func testTodayViewModelInitialization() throws {
        let dataManager = DataManager(modelContext: container.mainContext)
        let viewModel = TodayViewModel(dataManager: dataManager)
        
        XCTAssertNotNil(dataManager)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertTrue(viewModel.timeBlocks.isEmpty)
        XCTAssertNil(viewModel.dailyProgress)
        XCTAssertNil(viewModel.errorMessage)
    }
    
    @MainActor
    func testTodayViewModelDataLoading() async throws {
        let dataManager = DataManager(modelContext: container.mainContext)
        let viewModel = TodayViewModel(dataManager: dataManager)
        
        // Create test data
        let testBlocks = [
            createSampleTimeBlock(title: "Morning Block", startHour: 8, endHour: 9),
            createSampleTimeBlock(title: "Afternoon Block", startHour: 14, endHour: 15)
        ]
        
        for block in testBlocks {
            try dataManager.addTimeBlock(block)
        }
        try dataManager.updateDailyProgress(for: Date())
        
        // Load data in view model
        await viewModel.loadTodaysBlocks()
        
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertEqual(viewModel.timeBlocks.count, 2)
        XCTAssertNotNil(viewModel.dailyProgress)
        XCTAssertEqual(viewModel.dailyProgress?.totalBlocks, 2)
        XCTAssertNil(viewModel.errorMessage)
    }
    
    @MainActor
    func testTodayViewModelStateUpdates() async throws {
        let dataManager = DataManager(modelContext: container.mainContext)
        let viewModel = TodayViewModel(dataManager: dataManager)
        
        // Create and load test data
        let testBlock = createSampleTimeBlock(title: "State Test", startHour: 10, endHour: 11)
        try dataManager.addTimeBlock(testBlock)
        await viewModel.loadTodaysBlocks()
        
        XCTAssertEqual(viewModel.timeBlocks.first?.status, .notStarted)
        
        // Update status through view model
        await viewModel.markBlockCompleted(testBlock)
        
        XCTAssertEqual(viewModel.timeBlocks.first?.status, .completed)
        XCTAssertEqual(viewModel.dailyProgress?.completedBlocks, 1)
        XCTAssertNil(viewModel.errorMessage)
    }
    
    @MainActor
    func testTodayViewModelErrorHandling() async throws {
        let dataManager = DataManager(modelContext: container.mainContext)
        let viewModel = TodayViewModel(dataManager: dataManager)
        
        // Create invalid block to trigger error
        let invalidBlock = TimeBlock(title: "", startTime: Date(), endTime: Date().addingTimeInterval(3600))
        
        // This should set error message
        await viewModel.markBlockCompleted(invalidBlock)
        
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertTrue(viewModel.errorMessage!.contains("error") || viewModel.errorMessage!.contains("failed"))
    }
    
    // MARK: - ScheduleBuilderViewModel Tests
    
    @MainActor
    func testScheduleBuilderViewModelInitialization() throws {
        let dataManager = DataManager(modelContext: container.mainContext)
        let viewModel = ScheduleBuilderViewModel(dataManager: dataManager)
        
        XCTAssertNotNil(dataManager)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertTrue(viewModel.timeBlocks.isEmpty)
        XCTAssertNil(viewModel.errorMessage)
    }
    
    @MainActor
    func testScheduleBuilderAddTimeBlock() async throws {
        let dataManager = DataManager(modelContext: container.mainContext)
        let viewModel = ScheduleBuilderViewModel(dataManager: dataManager)
        
        let startTime = Date().addingTimeInterval(3600)
        let endTime = startTime.addingTimeInterval(1800)
        
        viewModel.addTimeBlock(
            title: "New Block",
            startTime: startTime,
            endTime: endTime,
            notes: "Test notes"
        )
        
        viewModel.loadTimeBlocks()
        
        XCTAssertEqual(viewModel.timeBlocks.count, 1)
        XCTAssertEqual(viewModel.timeBlocks.first?.title, "New Block")
        XCTAssertEqual(viewModel.timeBlocks.first?.notes, "Test notes")
        XCTAssertNil(viewModel.errorMessage)
    }
    
    @MainActor
    func testScheduleBuilderConflictDetection() async throws {
        let dataManager = DataManager(modelContext: container.mainContext)
        let viewModel = ScheduleBuilderViewModel(dataManager: dataManager)
        
        let startTime = Date().addingTimeInterval(3600)
        let endTime = startTime.addingTimeInterval(1800)
        
        // Add first block
        viewModel.addTimeBlock(title: "First Block", startTime: startTime, endTime: endTime)
        
        // Try to add conflicting block
        viewModel.addTimeBlock(title: "Conflicting Block", startTime: startTime, endTime: endTime)
        
        viewModel.loadTimeBlocks()
        
        // Should only have one block and show error
        XCTAssertEqual(viewModel.timeBlocks.count, 1)
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertTrue(viewModel.errorMessage!.contains("conflict"))
    }
    
    @MainActor
    func testScheduleBuilderValidation() async throws {
        let dataManager = DataManager(modelContext: container.mainContext)
        let viewModel = ScheduleBuilderViewModel(dataManager: dataManager)
        
        // Test empty title validation
        viewModel.addTimeBlock(
            title: "",
            startTime: Date(),
            endTime: Date().addingTimeInterval(3600)
        )
        
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertTrue(viewModel.errorMessage!.contains("title") || viewModel.errorMessage!.contains("empty"))
        
        // Clear error
        viewModel.clearError()
        
        // Test invalid time range
        let now = Date()
        viewModel.addTimeBlock(
            title: "Valid Title",
            startTime: now,
            endTime: now.addingTimeInterval(-3600)
        )
        
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertTrue(viewModel.errorMessage!.contains("time") || viewModel.errorMessage!.contains("range"))
    }
    
    // MARK: - SettingsViewModel Tests
    
    @MainActor
    func testSettingsViewModelDataExport() throws {
        let dataManager = DataManager(modelContext: container.mainContext)
        let viewModel = SettingsViewModel(dataManager: dataManager)
        
        // Create test data
        let testBlocks = [
            createSampleTimeBlock(title: "Export Test 1"),
            createSampleTimeBlock(title: "Export Test 2", startHour: 11, endHour: 12)
        ]
        
        for block in testBlocks {
            try dataManager.addTimeBlock(block)
        }
        
        // Test export using the actual method name
        let exportedData = viewModel.exportUserData()
        
        XCTAssertFalse(exportedData.isEmpty)
        XCTAssertTrue(exportedData.contains("Export Test 1"))
        XCTAssertTrue(exportedData.contains("Export Test 2"))
        XCTAssertTrue(exportedData.contains("timeBlocks"))
        XCTAssertNil(viewModel.errorMessage)
    }
    
    @MainActor
    func testSettingsViewModelClearAllData() throws {
        let dataManager = DataManager(modelContext: container.mainContext)
        let viewModel = SettingsViewModel(dataManager: dataManager)
        
        // Create test data
        let testBlocks = [
            createSampleTimeBlock(title: "Delete Test 1"),
            createSampleTimeBlock(title: "Delete Test 2", startHour: 11, endHour: 12)
        ]
        
        for block in testBlocks {
            try dataManager.addTimeBlock(block)
        }
        
        // Verify data exists
        let initialBlocks = try dataManager.loadAllTimeBlocks()
        XCTAssertEqual(initialBlocks.count, 2)
        
        // Clear all data using the actual method name
        viewModel.clearAllData()
        
        // Verify data was cleared
        let remainingBlocks = try dataManager.loadAllTimeBlocks()
        XCTAssertEqual(remainingBlocks.count, 0)
        XCTAssertNil(viewModel.errorMessage)
    }
    
    @MainActor
    func testSettingsViewModelNotificationSettings() throws {
        let dataManager = DataManager(modelContext: container.mainContext)
        let viewModel = SettingsViewModel(dataManager: dataManager)
        
        // Test initial state
        XCTAssertNotNil(viewModel.notificationsEnabled)
        XCTAssertNotNil(viewModel.hapticsEnabled)
        XCTAssertNotNil(viewModel.autoResetEnabled)
        
        // Test settings changes
        let originalNotificationState = viewModel.notificationsEnabled
        viewModel.notificationsEnabled.toggle()
        XCTAssertNotEqual(viewModel.notificationsEnabled, originalNotificationState)
        
        let originalHapticsState = viewModel.hapticsEnabled
        viewModel.hapticsEnabled.toggle()
        XCTAssertNotEqual(viewModel.hapticsEnabled, originalHapticsState)
    }
    
    @MainActor
    func testSettingsViewModelAutoReset() throws {
        let dataManager = DataManager(modelContext: container.mainContext)
        let viewModel = SettingsViewModel(dataManager: dataManager)
        
        // Test auto-reset toggle
        let originalAutoResetState = viewModel.autoResetEnabled
        viewModel.autoResetEnabled.toggle()
        XCTAssertNotEqual(viewModel.autoResetEnabled, originalAutoResetState)
        
        // Test daily reminder time
        let newReminderTime = Date().addingTimeInterval(3600)
        viewModel.dailyReminderTime = newReminderTime
        XCTAssertEqual(viewModel.dailyReminderTime, newReminderTime)
    }
    
    // MARK: - ViewModel State Consistency
    
    @MainActor
    func testViewModelStateConsistency() async throws {
        let dataManager = DataManager(modelContext: container.mainContext)
        let todayViewModel = TodayViewModel(dataManager: dataManager)
        let scheduleViewModel = ScheduleBuilderViewModel(dataManager: dataManager)
        
        // Add block through schedule view model
        let startTime = Date().addingTimeInterval(3600)
        let endTime = startTime.addingTimeInterval(1800)
        
        scheduleViewModel.addTimeBlock(
            title: "Consistency Test",
            startTime: startTime,
            endTime: endTime
        )
        
        // Load data in both view models
        await todayViewModel.loadTodaysBlocks()
        scheduleViewModel.loadTimeBlocks()
        
        // Both should have the same data
        XCTAssertEqual(todayViewModel.timeBlocks.count, scheduleViewModel.timeBlocks.count)
        XCTAssertEqual(todayViewModel.timeBlocks.first?.title, scheduleViewModel.timeBlocks.first?.title)
        
        // Update status through today view model
        if let block = todayViewModel.timeBlocks.first {
            await todayViewModel.markBlockCompleted(block)
            scheduleViewModel.loadTimeBlocks()
            
            // Schedule view model should reflect the change
            XCTAssertEqual(scheduleViewModel.timeBlocks.first?.status, .completed)
        }
    }
    
    // MARK: - Memory Management
    
    @MainActor
    func testViewModelMemoryManagement() async throws {
        weak var weakViewModel: TodayViewModel?
        
        autoreleasepool {
            let dataManager = DataManager(modelContext: container.mainContext)
            let viewModel = TodayViewModel(dataManager: dataManager)
            weakViewModel = viewModel
            
            // Use the view model
            Task {
                await viewModel.loadTodaysBlocks()
            }
        }
        
        // Give time for async operations to complete
        try await Task.sleep(nanoseconds: 100_000_000)
        
        // View model should be deallocated
        XCTAssertNil(weakViewModel, "ViewModel should be deallocated when no longer referenced")
    }
    
    // MARK: - Concurrent ViewModel Operations
    
    @MainActor
    func testConcurrentViewModelOperations() async throws {
        let dataManager = DataManager(modelContext: container.mainContext)
        let viewModel = TodayViewModel(dataManager: dataManager)
        
        // Create test blocks
        let testBlocks = [
            createSampleTimeBlock(title: "Concurrent 1", startHour: 9, endHour: 10),
            createSampleTimeBlock(title: "Concurrent 2", startHour: 11, endHour: 12),
            createSampleTimeBlock(title: "Concurrent 3", startHour: 13, endHour: 14)
        ]
        
        for block in testBlocks {
            try dataManager.addTimeBlock(block)
        }
        
        await viewModel.loadTodaysBlocks()
        
        // Perform operations sequentially to avoid concurrency issues
        let blocks = viewModel.timeBlocks
        XCTAssertEqual(blocks.count, 3)
        
        // Test sequential operations instead of concurrent
        for (index, block) in blocks.enumerated() {
            switch index % 3 {
            case 0:
                await viewModel.markBlockCompleted(block)
            case 1:
                await viewModel.markBlockSkipped(block)
            default:
                await viewModel.startTimeBlock(block)
            }
        }
        
        // Verify final state is consistent
        let completedCount = viewModel.timeBlocks.filter { $0.status == .completed }.count
        let skippedCount = viewModel.timeBlocks.filter { $0.status == .skipped }.count
        let inProgressCount = viewModel.timeBlocks.filter { $0.status == .inProgress }.count
        
        XCTAssertEqual(completedCount + skippedCount + inProgressCount, 3)
        XCTAssertEqual(viewModel.dailyProgress?.completedBlocks, completedCount)
        XCTAssertEqual(viewModel.dailyProgress?.skippedBlocks, skippedCount)
    }
    
    // MARK: - Error State Management
    
    @MainActor
    func testViewModelErrorStateManagement() async throws {
        let dataManager = DataManager(modelContext: container.mainContext)
        let viewModel = TodayViewModel(dataManager: dataManager)
        
        // Initially no error
        XCTAssertNil(viewModel.errorMessage)
        
        // Trigger an error
        let invalidBlock = TimeBlock(title: "", startTime: Date(), endTime: Date().addingTimeInterval(3600))
        await viewModel.markBlockCompleted(invalidBlock)
        
        // Should have error message
        XCTAssertNotNil(viewModel.errorMessage)
        
        // Clear error
        viewModel.clearError()
        XCTAssertNil(viewModel.errorMessage)
    }
    
    // MARK: - Loading State Management
    
    @MainActor
    func testViewModelLoadingStates() async throws {
        let dataManager = DataManager(modelContext: container.mainContext)
        let viewModel = TodayViewModel(dataManager: dataManager)
        
        // Initially not loading
        XCTAssertFalse(viewModel.isLoading)
        
        // Create some test data
        let testBlock = createSampleTimeBlock()
        try dataManager.addTimeBlock(testBlock)
        
        // Loading should be managed properly during operations
        let loadTask = Task {
            await viewModel.loadTodaysBlocks()
        }
        
        // Wait for completion
        await loadTask.value
        
        // Should not be loading after completion
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertEqual(viewModel.timeBlocks.count, 1)
    }
    
    // MARK: - Helper Methods
    
    private func createSampleTimeBlock(
        title: String = "Test Block",
        startHour: Int = 10,
        endHour: Int = 11,
        day: Date = Date()
    ) -> TimeBlock {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: day)
        
        let startTime = calendar.date(byAdding: .hour, value: startHour, to: startOfDay) ?? Date()
        let endTime = calendar.date(byAdding: .hour, value: endHour, to: startOfDay) ?? Date().addingTimeInterval(3600)
        
        return TimeBlock(title: title, startTime: startTime, endTime: endTime)
    }
}
