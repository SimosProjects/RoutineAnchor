//
//  ExportService.swift
//  Routine Anchor
//
//  Service for exporting user data in various formats
//
import Foundation
import SwiftData
import UniformTypeIdentifiers

@MainActor
class ExportService {
    // MARK: - Singleton
    static let shared = ExportService()
    private init() {}
    
    // MARK: - Export Formats
    typealias ExportFormat = DataTransferFormat
    
    // MARK: - Export Methods
    
    /// Export all time blocks in the specified format
    func exportTimeBlocks(_ timeBlocks: [TimeBlock], format: ExportFormat) throws -> Data {
        switch format {
        case .json:
            return try exportAsJSON(timeBlocks)
        case .csv:
            return try exportAsCSV(timeBlocks)
        case .text:
            return try exportAsText(timeBlocks)
        }
    }
    
    /// Export daily progress data
    func exportDailyProgress(_ progress: [DailyProgress], format: ExportFormat) throws -> Data {
        switch format {
        case .json:
            return try exportProgressAsJSON(progress)
        case .csv:
            return try exportProgressAsCSV(progress)
        case .text:
            return try exportProgressAsText(progress)
        }
    }
    
    /// Export combined user data (time blocks + progress)
    func exportAllData(timeBlocks: [TimeBlock], dailyProgress: [DailyProgress], format: ExportFormat) throws -> Data {
        switch format {
        case .json:
            return try exportAllAsJSON(timeBlocks: timeBlocks, progress: dailyProgress)
        case .csv:
            // For CSV, we'll create separate sections
            let timeBlocksCSV = try exportAsCSV(timeBlocks)
            let progressCSV = try exportProgressAsCSV(dailyProgress)
            
            var combined = "=== TIME BLOCKS ===\n".data(using: .utf8) ?? Data()
            combined.append(timeBlocksCSV)
            combined.append("\n\n=== DAILY PROGRESS ===\n".data(using: .utf8) ?? Data())
            combined.append(progressCSV)
            return combined
            
        case .text:
            let timeBlocksText = try exportAsText(timeBlocks)
            let progressText = try exportProgressAsText(dailyProgress)
            
            var combined = "ROUTINE ANCHOR DATA EXPORT\n".data(using: .utf8) ?? Data()
            combined.append("Generated: \(DateFormatter.exportDateFormatter.string(from: Date()))\n\n".data(using: .utf8) ?? Data())
            combined.append("=== TIME BLOCKS ===\n".data(using: .utf8) ?? Data())
            combined.append(timeBlocksText)
            combined.append("\n\n=== DAILY PROGRESS ===\n".data(using: .utf8) ?? Data())
            combined.append(progressText)
            return combined
        }
    }
    
    // MARK: - JSON Export
    
    private func exportAsJSON(_ timeBlocks: [TimeBlock]) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        
        let exportData = TimeBlocksExportData(
            exportDate: Date(),
            version: "1.0",
            timeBlocks: timeBlocks.map { TimeBlockExportItem(from: $0) }
        )
        
        return try encoder.encode(exportData)
    }
    
    private func exportProgressAsJSON(_ progress: [DailyProgress]) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        
        let exportData = DailyProgressExportData(
            exportDate: Date(),
            version: "1.0",
            dailyProgress: progress.map { DailyProgressExportItem(from: $0) }
        )
        
        return try encoder.encode(exportData)
    }
    
    private func exportAllAsJSON(timeBlocks: [TimeBlock], progress: [DailyProgress]) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        
        let exportData = CompleteExportData(
            exportDate: Date(),
            version: "1.0",
            timeBlocks: timeBlocks.map { TimeBlockExportItem(from: $0) },
            dailyProgress: progress.map { DailyProgressExportItem(from: $0) }
        )
        
        return try encoder.encode(exportData)
    }
    
    // MARK: - CSV Export
    
    private func exportAsCSV(_ timeBlocks: [TimeBlock]) throws -> Data {
        var csvString = "Title,Start Time,End Time,Status,Category,Icon,Notes,Created At\n"
        
        let dateFormatter = DateFormatter.exportDateFormatter
        
        for block in timeBlocks.sorted(by: { $0.startTime < $1.startTime }) {
            let title = escapeCSV(block.title)
            let startTime = dateFormatter.string(from: block.startTime)
            let endTime = dateFormatter.string(from: block.endTime)
            let status = block.status.rawValue
            let category = escapeCSV(block.category ?? "")
            let icon = block.icon ?? ""
            let notes = escapeCSV(block.notes ?? "")
            let createdAt = dateFormatter.string(from: block.createdAt)
            
            csvString += "\(title),\(startTime),\(endTime),\(status),\(category),\(icon),\(notes),\(createdAt)\n"
        }
        
        guard let data = csvString.data(using: .utf8) else {
            throw ExportError.encodingFailed
        }
        
        return data
    }
    
    private func exportProgressAsCSV(_ progress: [DailyProgress]) throws -> Data {
        var csvString = "Date,Completion Rate,Completed Blocks,Total Blocks,Skipped Blocks,Day Rating,Notes\n"
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .none
        
        for day in progress.sorted(by: { $0.date < $1.date }) {
            let date = dateFormatter.string(from: day.date)
            let completionRate = String(format: "%.1f%%", day.completionPercentage * 100)
            let completed = day.completedBlocks
            let total = day.totalBlocks
            let skipped = day.skippedBlocks
            let rating = day.dayRating != nil ? String(day.dayRating!) : ""
            let notes = escapeCSV(day.dayNotes ?? "")
            
            csvString += "\(date),\(completionRate),\(completed),\(total),\(skipped),\(rating),\(notes)\n"
        }
        
        guard let data = csvString.data(using: .utf8) else {
            throw ExportError.encodingFailed
        }
        
        return data
    }
    
    // MARK: - Text Export
    
    private func exportAsText(_ timeBlocks: [TimeBlock]) throws -> Data {
        var textString = ""
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .none
        dateFormatter.timeStyle = .short
        
        let groupedBlocks = Dictionary(grouping: timeBlocks) { block in
            Calendar.current.startOfDay(for: block.startTime)
        }
        
        for (date, blocks) in groupedBlocks.sorted(by: { $0.key < $1.key }) {
            let dayFormatter = DateFormatter()
            dayFormatter.dateStyle = .full
            dayFormatter.timeStyle = .none
            
            textString += "\n📅 \(dayFormatter.string(from: date))\n"
            textString += String(repeating: "-", count: 40) + "\n"
            
            for block in blocks.sorted(by: { $0.startTime < $1.startTime }) {
                let startTime = dateFormatter.string(from: block.startTime)
                let endTime = dateFormatter.string(from: block.endTime)
                let status = block.status == .completed ? "✅" : (block.status == .skipped ? "⏭️" : "⏰")
                
                textString += "\n\(block.icon ?? "📌") \(block.title)\n"
                textString += "   Time: \(startTime) - \(endTime) \(status)\n"
                
                if let category = block.category {
                    textString += "   Category: \(category)\n"
                }
                
                if let notes = block.notes, !notes.isEmpty {
                    textString += "   Notes: \(notes)\n"
                }
            }
        }
        
        guard let data = textString.data(using: .utf8) else {
            throw ExportError.encodingFailed
        }
        
        return data
    }
    
    private func exportProgressAsText(_ progress: [DailyProgress]) throws -> Data {
        var textString = "Daily Progress Summary\n"
        textString += String(repeating: "=", count: 40) + "\n\n"
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .none
        
        for day in progress.sorted(by: { $0.date < $1.date }) {
            let date = dateFormatter.string(from: day.date)
            let completionRate = String(format: "%.0f%%", day.completionPercentage * 100)
            
            textString += "📊 \(date)\n"
            textString += "   Completion: \(completionRate) (\(day.completedBlocks)/\(day.totalBlocks) blocks)\n"
            
            if day.skippedBlocks > 0 {
                textString += "   Skipped: \(day.skippedBlocks) blocks\n"
            }
            
            if let rating = day.dayRating {
                textString += "   Rating: \(String(repeating: "⭐", count: rating))\n"
            }
            
            if let notes = day.dayNotes, !notes.isEmpty {
                textString += "   Notes: \(notes)\n"
            }
            
            textString += "\n"
        }
        
        guard let data = textString.data(using: .utf8) else {
            throw ExportError.encodingFailed
        }
        
        return data
    }
    
    // MARK: - Helper Methods
    
    private func escapeCSV(_ string: String) -> String {
        if string.contains("\"") || string.contains(",") || string.contains("\n") {
            return "\"\(string.replacingOccurrences(of: "\"", with: "\"\""))\""
        }
        return string
    }
}

// MARK: - Export Error

enum ExportError: LocalizedError {
    case encodingFailed
    case noDataToExport
    
    var errorDescription: String? {
        switch self {
        case .encodingFailed:
            return "Failed to encode data for export"
        case .noDataToExport:
            return "No data available to export"
        }
    }
}

// MARK: - DateFormatter Extension

extension DateFormatter {
    static let exportDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.timeZone = TimeZone.current
        return formatter
    }()
}
