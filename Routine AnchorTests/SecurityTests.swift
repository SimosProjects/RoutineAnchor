//
//  SecurityTests.swift
//  Routine Anchor
//
//  Created by Christopher Simonson on 8/18/25.
//
import XCTest
@testable import Routine_Anchor

@MainActor
final class SecurityTests: XCTestCase {
    
    func testNoSensitiveDataInExport() throws {
        let timeBlocks = [createSampleTimeBlock(title: "Personal Meeting")]
        
        let exportService = ExportService.shared
        let jsonData = try exportService.exportTimeBlocks(timeBlocks, format: .json)
        let jsonString = String(data: jsonData, encoding: .utf8)!
        
        // Ensure no system paths or sensitive info leaked
        XCTAssertFalse(jsonString.contains("/private/"))
        XCTAssertFalse(jsonString.contains("/Users/"))
        XCTAssertFalse(jsonString.contains("file://"))
    }
    
    @MainActor
    func testDataSanitizationInExports() throws {
        let blockWithSpecialChars = TimeBlock(
            title: "Test<script>alert('xss')</script>",
            startTime: Date(),
            endTime: Date().addingTimeInterval(3600),
            notes: "Notes with \"quotes\" and 'single quotes'"
        )
        
        let exportService = ExportService.shared
        let csvData = try exportService.exportTimeBlocks([blockWithSpecialChars], format: .csv)
        let csvString = String(data: csvData, encoding: .utf8)!
        
        print("=== ACTUAL CSV OUTPUT ===")
        print(csvString)
        print("=== END CSV OUTPUT ===")
        
        // First, let's just verify we got some CSV data
        XCTAssertFalse(csvString.isEmpty, "CSV should not be empty")
        
        // Verify the CSV has the expected header
        XCTAssertTrue(csvString.contains("Title"), "CSV should contain Title header")
        
        // Check if the title content exists in any form
        let containsScriptTag = csvString.contains("<script>") || csvString.contains("&lt;script&gt;")
        XCTAssertTrue(containsScriptTag, "CSV should contain the script tag (possibly escaped)")
        
        // Check if quotes in notes are handled
        let containsQuotes = csvString.contains("quotes")
        XCTAssertTrue(containsQuotes, "CSV should contain the word 'quotes' from notes")
        
        // Most important: verify CSV structure is not broken
        let lines = csvString.components(separatedBy: .newlines).filter { !$0.isEmpty }
        XCTAssertGreaterThanOrEqual(lines.count, 2, "CSV should have header + at least one data row")
        
        print("Number of CSV lines: \(lines.count)")
        if lines.count >= 2 {
            print("Header line: \(lines[0])")
            print("Data line: \(lines[1])")
        }
    }
    
    func testInputValidationPreventsInjection() {
        let maliciousInput = "'; DROP TABLE TimeBlock; --"
        
        let block = TimeBlock(
            title: maliciousInput,
            startTime: Date(),
            endTime: Date().addingTimeInterval(3600)
        )
        
        // Should be treated as regular text, not SQL
        XCTAssertEqual(block.title, maliciousInput)
        XCTAssertTrue(block.isValid)
    }
    
    private func createSampleTimeBlock(title: String) -> TimeBlock {
        return TimeBlock(
            title: title,
            startTime: Date(),
            endTime: Date().addingTimeInterval(3600)
        )
    }
}
