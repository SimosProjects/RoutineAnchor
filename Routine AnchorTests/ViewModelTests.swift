//
//  ViewModelTests.swift
//  Routine AnchorTests
//
//  ViewModel testing without segfaults
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
    
    // MARK: - Basic ViewModel Initialization Tests
    
    @MainActor
    func testTodayViewModelBasicInitialization() throws {
        let dataManager = DataManager(modelContext: container.mainContext)
        let viewModel = TodayViewModel(dataManager: dataManager)
        
        // Test basic properties exist and have expected initial values
        XCTAssertNotNil(viewModel)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertTrue(viewModel.timeBlocks.isEmpty)
        XCTAssertNil(viewModel.errorMessage)
    }
    
    @MainActor
    func testScheduleBuilderViewModelBasicInitialization() throws {
        let dataManager = DataManager(modelContext: container.mainContext)
        let viewModel = ScheduleBuilderViewModel(dataManager: dataManager)
        
        // Test basic properties exist and have expected initial values
        XCTAssertNotNil(viewModel)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertTrue(viewModel.timeBlocks.isEmpty)
        XCTAssertNil(viewModel.errorMessage)
    }
    
    @MainActor
    func testSettingsViewModelBasicInitialization() throws {
        let dataManager = DataManager(modelContext: container.mainContext)
        let viewModel = SettingsViewModel(dataManager: dataManager)
        
        // Test basic properties exist
        XCTAssertNotNil(viewModel)
        XCTAssertNotNil(viewModel.notificationsEnabled)
        XCTAssertNotNil(viewModel.hapticsEnabled)
        XCTAssertNotNil(viewModel.autoResetEnabled)
    }
    
    // MARK: - Simple Data Loading Tests
    
    @MainActor
    func testTodayViewModelWithExistingData() throws {
        let dataManager = DataManager(modelContext: container.mainContext)
        
        // Create test data directly in DataManager
        let testBlock = createSampleTimeBlock(title: "Test Block")
        try dataManager.addTimeBlock(testBlock)
        
        // Create ViewModel after data exists
        let viewModel = TodayViewModel(dataManager: dataManager)
        
        // Test that ViewModel can be created with existing data
        XCTAssertNotNil(viewModel)
        XCTAssertFalse(viewModel.isLoading)
    }
    
    // MARK: - Settings ViewModel Safe Tests
    
    @MainActor
    func testSettingsViewModelExportDataBasic() throws {
        let dataManager = DataManager(modelContext: container.mainContext)
        let viewModel = SettingsViewModel(dataManager: dataManager)
        
        // Create minimal test data
        let testBlock = createSampleTimeBlock(title: "Export Test")
        try dataManager.addTimeBlock(testBlock)
        
        // Test export returns non-empty string
        let exportedData = viewModel.exportUserData()
        XCTAssertFalse(exportedData.isEmpty)
        XCTAssertTrue(exportedData.contains("Export Test"))
    }
    
    @MainActor
    func testSettingsViewModelClearDataBasic() throws {
        let dataManager = DataManager(modelContext: container.mainContext)
        let viewModel = SettingsViewModel(dataManager: dataManager)
        
        // Create minimal test data
        let testBlock = createSampleTimeBlock(title: "Clear Test")
        try dataManager.addTimeBlock(testBlock)
        
        // Verify data exists
        let initialBlocks = try dataManager.loadAllTimeBlocks()
        XCTAssertEqual(initialBlocks.count, 1)
        
        // Clear data
        viewModel.clearAllData()
        
        // Verify data was cleared
        let remainingBlocks = try dataManager.loadAllTimeBlocks()
        XCTAssertEqual(remainingBlocks.count, 0)
    }
    
    @MainActor
    func testSettingsViewModelToggleSettings() throws {
        let dataManager = DataManager(modelContext: container.mainContext)
        let viewModel = SettingsViewModel(dataManager: dataManager)
        
        // Test notification toggle
        let originalNotificationState = viewModel.notificationsEnabled
        viewModel.notificationsEnabled.toggle()
        XCTAssertNotEqual(viewModel.notificationsEnabled, originalNotificationState)
        
        // Test haptics toggle
        let originalHapticsState = viewModel.hapticsEnabled
        viewModel.hapticsEnabled.toggle()
        XCTAssertNotEqual(viewModel.hapticsEnabled, originalHapticsState)
        
        // Test auto-reset toggle
        let originalAutoResetState = viewModel.autoResetEnabled
        viewModel.autoResetEnabled.toggle()
        XCTAssertNotEqual(viewModel.autoResetEnabled, originalAutoResetState)
    }
    
    // MARK: - Error State Testing
    
    @MainActor
    func testViewModelErrorClearing() throws {
        let dataManager = DataManager(modelContext: container.mainContext)
        let viewModel = TodayViewModel(dataManager: dataManager)
        
        // Initially no error
        XCTAssertNil(viewModel.errorMessage)
        
        // Test error clearing works (even if no error exists)
        viewModel.clearError()
        XCTAssertNil(viewModel.errorMessage)
    }
    
    // MARK: - Memory Safety Tests
    
    @MainActor
    func testViewModelCreationAndDestruction() throws {
        // Test that ViewModels can be created and destroyed safely
        autoreleasepool {
            let dataManager = DataManager(modelContext: container.mainContext)
            
            // Create ViewModels
            let todayViewModel = TodayViewModel(dataManager: dataManager)
            let scheduleViewModel = ScheduleBuilderViewModel(dataManager: dataManager)
            let settingsViewModel = SettingsViewModel(dataManager: dataManager)
            
            // Verify they exist
            XCTAssertNotNil(todayViewModel)
            XCTAssertNotNil(scheduleViewModel)
            XCTAssertNotNil(settingsViewModel)
            
            // They should be deallocated when autoreleasepool ends
        }
        
        // Test passed if we get here without crashing
        XCTAssertTrue(true)
    }
    
    // MARK: - Property Access Tests
    
    @MainActor
    func testTodayViewModelPropertyAccess() throws {
        let dataManager = DataManager(modelContext: container.mainContext)
        let viewModel = TodayViewModel(dataManager: dataManager)
        
        // Test all computed properties can be accessed without crashing
        let _ = viewModel.timeBlocks
        let _ = viewModel.dailyProgress
        let _ = viewModel.isLoading
        let _ = viewModel.errorMessage
        
        // Test computed properties that might exist
        let _ = viewModel.progressPercentage
        let _ = viewModel.hasScheduledBlocks
        
        // Test passed if we get here without crashing
        XCTAssertTrue(true)
    }
    
    @MainActor
    func testScheduleBuilderViewModelPropertyAccess() throws {
        let dataManager = DataManager(modelContext: container.mainContext)
        let viewModel = ScheduleBuilderViewModel(dataManager: dataManager)
        
        // Test all properties can be accessed without crashing
        let _ = viewModel.timeBlocks
        let _ = viewModel.isLoading
        let _ = viewModel.errorMessage
        
        // Test computed properties that might exist
        let _ = viewModel.hasTimeBlocks
        let _ = viewModel.totalDurationMinutes
        
        // Test passed if we get here without crashing
        XCTAssertTrue(true)
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
