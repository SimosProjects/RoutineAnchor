//
//  DataValidationTests.swift
//  Routine Anchor
//
//  Created by Christopher Simonson on 8/18/25.
//
import XCTest
import SwiftData
@testable import Routine_Anchor

@MainActor
final class DataValidationTests: XCTestCase {
    
    func testEmptyTitleValidation() {
        let block = TimeBlock(
            title: "",
            startTime: Date(),
            endTime: Date().addingTimeInterval(3600)
        )
        
        XCTAssertFalse(block.isValid)
        XCTAssertTrue(block.validationErrors.contains { $0.contains("empty") || $0.contains("Title") })
    }
    
    func testWhitespaceOnlyTitle() {
        let block = TimeBlock(
            title: "   \n\t  ",
            startTime: Date(),
            endTime: Date().addingTimeInterval(3600)
        )
        
        XCTAssertFalse(block.isValid)
    }
    
    func testValidTitle() {
        let block = TimeBlock(
            title: "Morning Workout",
            startTime: Date(),
            endTime: Date().addingTimeInterval(3600)
        )
        
        XCTAssertTrue(block.isValid)
        XCTAssertTrue(block.validationErrors.isEmpty)
    }
    
    func testTitleWithSpecialCharacters() {
        let block = TimeBlock(
            title: "📚 Study Session #1 - Math & Science!",
            startTime: Date(),
            endTime: Date().addingTimeInterval(3600)
        )
        
        XCTAssertTrue(block.isValid)
    }
    
    func testInvalidTimeRange() {
        let startTime = Date()
        let endTime = startTime.addingTimeInterval(-3600) // End before start
        
        let block = TimeBlock(
            title: "Invalid Block",
            startTime: startTime,
            endTime: endTime
        )
        
        XCTAssertFalse(block.isValid)
        XCTAssertTrue(block.validationErrors.contains { $0.contains("time") || $0.contains("range") })
    }
    
    func testDurationTooShort() {
        let startTime = Date()
        let endTime = startTime.addingTimeInterval(30) // 30 seconds
        
        let block = TimeBlock(
            title: "Too Short",
            startTime: startTime,
            endTime: endTime
        )
        
        XCTAssertFalse(block.isValid)
    }
    
    func testDurationTooLong() {
        let startTime = Date()
        let endTime = startTime.addingTimeInterval(90000) // > 24 hours
        
        let block = TimeBlock(
            title: "Too Long",
            startTime: startTime,
            endTime: endTime
        )
        
        XCTAssertFalse(block.isValid)
    }
    
    func testNotesTooLong() {
        let longNotes = String(repeating: "a", count: 501)
        let block = TimeBlock(
            title: "Valid Title",
            startTime: Date(),
            endTime: Date().addingTimeInterval(3600),
            notes: longNotes
        )
        
        XCTAssertFalse(block.isValid)
    }
}
