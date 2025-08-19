//
//  ImportExportTests.swift
//  Routine Anchor
//
//  Created by Christopher Simonson on 8/18/25.
//
import XCTest
import SwiftData
@testable import Routine_Anchor

final class ImportExportTests: XCTestCase {
    
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
    
    @MainActor
    func testExportTimeBlocksAsJSON() throws {
        let timeBlocks = [
            createSampleTimeBlock(title: "Block 1"),
            createSampleTimeBlock(title: "Block 2", startHour: 11, endHour: 12)
        ]
        
        let exportService = ExportService.shared
        let jsonData = try exportService.exportTimeBlocks(timeBlocks, format: .json)
        
        XCTAssertGreaterThan(jsonData.count, 0)
        
        // Verify JSON is valid
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(TimeBlocksExportData.self, from: jsonData)
        XCTAssertEqual(decoded.timeBlocks.count, 2)
        XCTAssertEqual(decoded.timeBlocks[0].title, "Block 1")
    }
    
    @MainActor
    func testExportTimeBlocksAsCSV() throws {
        let timeBlocks = [createSampleTimeBlock(title: "CSV Test Block")]
        
        let exportService = ExportService.shared
        let csvData = try exportService.exportTimeBlocks(timeBlocks, format: .csv)
        
        XCTAssertGreaterThan(csvData.count, 0)
        
        let csvString = String(data: csvData, encoding: .utf8)!
        XCTAssertTrue(csvString.contains("CSV Test Block"))
        XCTAssertTrue(csvString.contains("Title,Start Time,End Time"))
    }
    
    @MainActor
    func testImportValidJSON() async throws {
        // Create export data
        let exportData = TimeBlocksExportData(
            exportDate: Date(),
            version: "1.0",
            timeBlocks: [
                TimeBlockExportItem(from: createSampleTimeBlock(title: "Imported Block"))
            ]
        )
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let jsonData = try encoder.encode(exportData)
        
        // Import the data - capture context in MainActor context
        let modelContext = container.mainContext
        let importService = ImportService.shared
        let result = try await importService.importJSON(jsonData, modelContext: modelContext)
        
        XCTAssertTrue(result.isSuccess)
        XCTAssertEqual(result.timeBlocksImported, 1)
        
        // Verify import worked
        let dataManager = DataManager(modelContext: container.mainContext)
        let blocks = try dataManager.loadAllTimeBlocks()
        XCTAssertEqual(blocks.count, 1)
        XCTAssertEqual(blocks.first?.title, "Imported Block")
    }
    
    @MainActor
    func testImportInvalidJSON() async throws {
        let invalidJSON = "{ invalid json }".data(using: .utf8)!
        
        // Capture context in MainActor context
        let modelContext = container.mainContext
        let importService = ImportService.shared
        
        do {
            let _ = try await importService.importJSON(invalidJSON, modelContext: modelContext)
            XCTFail("Should have thrown ImportError for invalid JSON")
        } catch {
            XCTAssertTrue(error is ImportError)
        }
    }
    
    private func createSampleTimeBlock(
        title: String = "Test Block",
        startHour: Int = 10,
        endHour: Int = 11
    ) -> TimeBlock {
        let startTime = Calendar.current.date(byAdding: .hour, value: startHour, to: Calendar.current.startOfDay(for: Date())) ?? Date()
        let endTime = Calendar.current.date(byAdding: .hour, value: endHour, to: Calendar.current.startOfDay(for: Date())) ?? Date().addingTimeInterval(3600)
        
        return TimeBlock(title: title, startTime: startTime, endTime: endTime)
    }
}
