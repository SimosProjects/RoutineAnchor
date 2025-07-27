//
//  ImportService.swift
//  Routine Anchor
//
//  Service for importing user data from various formats
//

import Foundation
import SwiftData

@MainActor
class ImportService {
    // MARK: - Singleton
    static let shared = ImportService()
    private init() {}
    
    // MARK: - Import Result
    struct ImportResult {
        let timeBlocksImported: Int
        let dailyProgressImported: Int
        let errors: [ImportError]
        
        var isSuccess: Bool {
            return errors.isEmpty && (timeBlocksImported > 0 || dailyProgressImported > 0)
        }
        
        var summary: String {
            if isSuccess {
                return "Successfully imported \(timeBlocksImported) time blocks and \(dailyProgressImported) progress records."
            } else if errors.isEmpty {
                return "No valid data found to import."
            } else {
                return "Import completed with \(errors.count) errors."
            }
        }
    }
    
    // MARK: - Import Methods
    
    /// Import data from a file URL
    func importData(from fileURL: URL, modelContext: ModelContext) async throws -> ImportResult {
        // Determine file type
        let fileExtension = fileURL.pathExtension.lowercased()
        let data = try Data(contentsOf: fileURL)
        
        switch fileExtension {
        case "json":
            return try await importJSON(data, modelContext: modelContext)
        case "csv":
            return try await importCSV(data, modelContext: modelContext)
        case "txt":
            throw ImportError.unsupportedFormat("Plain text import is not supported")
        default:
            throw ImportError.unsupportedFormat("File type .\(fileExtension) is not supported")
        }
    }
    
    /// Import JSON data
    private func importJSON(_ data: Data, modelContext: ModelContext) async throws -> ImportResult {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        var timeBlocksImported = 0
        var dailyProgressImported = 0
        var errors: [ImportError] = []
        
        // Try to decode as complete export first
        if let completeData = try? decoder.decode(CompleteExportData.self, from: data) {
            // Import time blocks
            for blockData in completeData.timeBlocks {
                do {
                    let timeBlock = try createTimeBlock(from: blockData)
                    modelContext.insert(timeBlock)
                    timeBlocksImported += 1
                } catch {
                    errors.append(.invalidTimeBlock(blockData.title, error.localizedDescription))
                }
            }
            
            // Import daily progress
            for progressData in completeData.dailyProgress {
                do {
                    let progress = try createDailyProgress(from: progressData)
                    modelContext.insert(progress)
                    dailyProgressImported += 1
                } catch {
                    errors.append(.invalidDailyProgress(progressData.date.description, error.localizedDescription))
                }
            }
        }
        // Try time blocks only
        else if let timeBlocksData = try? decoder.decode(TimeBlocksExportData.self, from: data) {
            for blockData in timeBlocksData.timeBlocks {
                do {
                    let timeBlock = try createTimeBlock(from: blockData)
                    modelContext.insert(timeBlock)
                    timeBlocksImported += 1
                } catch {
                    errors.append(.invalidTimeBlock(blockData.title, error.localizedDescription))
                }
            }
        }
        // Try daily progress only
        else if let progressData = try? decoder.decode(DailyProgressExportData.self, from: data) {
            for progress in progressData.dailyProgress {
                do {
                    let dailyProgress = try createDailyProgress(from: progress)
                    modelContext.insert(dailyProgress)
                    dailyProgressImported += 1
                } catch {
                    errors.append(.invalidDailyProgress(progress.date.description, error.localizedDescription))
                }
            }
        }
        else {
            throw ImportError.invalidJSON("Unable to parse JSON data")
        }
        
        // Save context if we imported anything
        if timeBlocksImported > 0 || dailyProgressImported > 0 {
            try modelContext.save()
        }
        
        return ImportResult(
            timeBlocksImported: timeBlocksImported,
            dailyProgressImported: dailyProgressImported,
            errors: errors
        )
    }
    
    /// Import CSV data
    private func importCSV(_ data: Data, modelContext: ModelContext) async throws -> ImportResult {
        guard let csvString = String(data: data, encoding: .utf8) else {
            throw ImportError.invalidCSV("Unable to read CSV data")
        }
        
        var timeBlocksImported = 0
        var dailyProgressImported = 0
        var errors: [ImportError] = []
        
        // Split into sections if it's a combined export
        let sections = csvString.components(separatedBy: "=== ")
        
        for section in sections {
            if section.contains("TIME BLOCKS") {
                let result = try importTimeBlocksCSV(section, modelContext: modelContext)
                timeBlocksImported += result.imported
                errors.append(contentsOf: result.errors)
            } else if section.contains("DAILY PROGRESS") {
                let result = try importDailyProgressCSV(section, modelContext: modelContext)
                dailyProgressImported += result.imported
                errors.append(contentsOf: result.errors)
            } else if !section.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                // Try to parse as standalone CSV
                if section.contains("Title,Start Time,End Time") {
                    let result = try importTimeBlocksCSV(section, modelContext: modelContext)
                    timeBlocksImported += result.imported
                    errors.append(contentsOf: result.errors)
                } else if section.contains("Date,Completion Rate") {
                    let result = try importDailyProgressCSV(section, modelContext: modelContext)
                    dailyProgressImported += result.imported
                    errors.append(contentsOf: result.errors)
                }
            }
        }
        
        // Save context if we imported anything
        if timeBlocksImported > 0 || dailyProgressImported > 0 {
            try modelContext.save()
        }
        
        return ImportResult(
            timeBlocksImported: timeBlocksImported,
            dailyProgressImported: dailyProgressImported,
            errors: errors
        )
    }
    
    // MARK: - CSV Parsing Helpers
    
    private func importTimeBlocksCSV(_ csvContent: String, modelContext: ModelContext) throws -> (imported: Int, errors: [ImportError]) {
        let lines = csvContent.components(separatedBy: .newlines)
        var imported = 0
        var errors: [ImportError] = []
        
        // Find header line
        var headerIndex = -1
        for (index, line) in lines.enumerated() {
            if line.contains("Title,Start Time,End Time") {
                headerIndex = index
                break
            }
        }
        
        guard headerIndex >= 0 else {
            return (0, [ImportError.invalidCSV("Time blocks header not found")])
        }
        
        // Parse data lines
        for i in (headerIndex + 1)..<lines.count {
            let line = lines[i].trimmingCharacters(in: .whitespacesAndNewlines)
            if line.isEmpty { continue }
            
            let fields = parseCSVLine(line)
            if fields.count >= 8 {
                do {
                    let timeBlock = try createTimeBlockFromCSV(fields)
                    modelContext.insert(timeBlock)
                    imported += 1
                } catch {
                    errors.append(.invalidTimeBlock(fields[0], error.localizedDescription))
                }
            }
        }
        
        return (imported, errors)
    }
    
    private func importDailyProgressCSV(_ csvContent: String, modelContext: ModelContext) throws -> (imported: Int, errors: [ImportError]) {
        let lines = csvContent.components(separatedBy: .newlines)
        var imported = 0
        var errors: [ImportError] = []
        
        // Find header line
        var headerIndex = -1
        for (index, line) in lines.enumerated() {
            if line.contains("Date,Completion Rate") {
                headerIndex = index
                break
            }
        }
        
        guard headerIndex >= 0 else {
            return (0, [ImportError.invalidCSV("Daily progress header not found")])
        }
        
        // Parse data lines
        for i in (headerIndex + 1)..<lines.count {
            let line = lines[i].trimmingCharacters(in: .whitespacesAndNewlines)
            if line.isEmpty { continue }
            
            let fields = parseCSVLine(line)
            if fields.count >= 7 {
                do {
                    let progress = try createDailyProgressFromCSV(fields)
                    modelContext.insert(progress)
                    imported += 1
                } catch {
                    errors.append(.invalidDailyProgress(fields[0], error.localizedDescription))
                }
            }
        }
        
        return (imported, errors)
    }
    
    // MARK: - Model Creation
    
    private func createTimeBlock(from data: TimeBlockExportItem) throws -> TimeBlock {
        let timeBlock = TimeBlock(
            title: data.title,
            startTime: data.startTime,
            endTime: data.endTime,
            notes: data.notes,
            icon: data.icon,
            category: data.category
        )
        
        // Set the ID if we have one from the export
        if let uuid = UUID(uuidString: data.id) {
            timeBlock.id = uuid
        }
        
        // Set status using the BlockStatus enum
        if let status = BlockStatus(rawValue: data.status) {
            timeBlock.status = status
        }
        
        return timeBlock
    }
    
    private func createDailyProgress(from data: DailyProgressExportItem) throws -> DailyProgress {
        let progress = DailyProgress(date: data.date)
        
        // Set the ID if we have one from the export
        if let uuid = UUID(uuidString: data.id) {
            progress.id = uuid
        }
        
        // Set the statistics
        progress.totalBlocks = data.totalBlocks
        progress.completedBlocks = data.completedBlocks
        progress.skippedBlocks = data.skippedBlocks
        
        // Calculate other values from the data if needed
        // Note: DailyProgressExportItem might not have all fields, so we calculate what we can
        if let completionPercentage = data.completionPercentage as? Double {
            // completionPercentage is read-only, so we can't set it directly
            // It's calculated from completedBlocks/totalBlocks automatically
        }
        
        progress.dayRating = data.dayRating
        progress.dayNotes = data.dayNotes
        
        return progress
    }
    
    private func createTimeBlockFromCSV(_ fields: [String]) throws -> TimeBlock {
        let dateFormatter = DateFormatter.dataTransferFormatter
        
        guard fields.count >= 8,
              let startTime = dateFormatter.date(from: fields[1]),
              let endTime = dateFormatter.date(from: fields[2]) else {
            throw ImportError.invalidData("Invalid CSV format")
        }
        
        let timeBlock = TimeBlock(
            title: fields[0],
            startTime: startTime,
            endTime: endTime,
            notes: fields[6].isEmpty ? nil : fields[6],
            icon: fields[5].isEmpty ? nil : fields[5],
            category: fields[4].isEmpty ? nil : fields[4]
        )
        
        // Set status using the BlockStatus enum
        if let status = BlockStatus(rawValue: fields[3]) {
            timeBlock.status = status
        }
        
        return timeBlock
    }
    
    private func createDailyProgressFromCSV(_ fields: [String]) throws -> DailyProgress {
        let dateFormatter = DateFormatter.dataTransferDateOnlyFormatter
        
        guard fields.count >= 7,
              let date = dateFormatter.date(from: fields[0]),
              let completedBlocks = Int(fields[2]),
              let totalBlocks = Int(fields[3]),
              let skippedBlocks = Int(fields[4]) else {
            throw ImportError.invalidData("Invalid CSV format")
        }
        
        let progress = DailyProgress(date: date)
        
        // Set the statistics
        progress.completedBlocks = completedBlocks
        progress.totalBlocks = totalBlocks
        progress.skippedBlocks = skippedBlocks
        
        if !fields[5].isEmpty, let rating = Int(fields[5]) {
            progress.dayRating = rating
        }
        
        if !fields[6].isEmpty {
            progress.dayNotes = fields[6]
        }
        
        return progress
    }
    
    // MARK: - CSV Parsing Utility
    
    private func parseCSVLine(_ line: String) -> [String] {
        return CSVUtilities.parseCSVLine(line)
    }
}

// MARK: - Import Error

enum ImportError: LocalizedError {
    case unsupportedFormat(String)
    case invalidJSON(String)
    case invalidCSV(String)
    case invalidData(String)
    case invalidTimeBlock(String, String)
    case invalidDailyProgress(String, String)
    
    var errorDescription: String? {
        switch self {
        case .unsupportedFormat(let format):
            return "Unsupported file format: \(format)"
        case .invalidJSON(let reason):
            return "Invalid JSON: \(reason)"
        case .invalidCSV(let reason):
            return "Invalid CSV: \(reason)"
        case .invalidData(let reason):
            return "Invalid data: \(reason)"
        case .invalidTimeBlock(let title, let reason):
            return "Failed to import time block '\(title)': \(reason)"
        case .invalidDailyProgress(let date, let reason):
            return "Failed to import progress for \(date): \(reason)"
        }
    }
}
