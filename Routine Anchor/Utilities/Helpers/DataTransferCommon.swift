//
//  DataTransferCommon.swift
//  Routine Anchor
//
//  Common structures and utilities for data import/export
//

import Foundation

// MARK: - Export/Import Formats

enum DataTransferFormat: String, CaseIterable {
    case json = "JSON"
    case csv = "CSV"
    case text = "Plain Text"
    
    var fileExtension: String {
        switch self {
        case .json: return "json"
        case .csv: return "csv"
        case .text: return "txt"
        }
    }
    
    var mimeType: String {
        switch self {
        case .json: return "application/json"
        case .csv: return "text/csv"
        case .text: return "text/plain"
        }
    }
}

// MARK: - Data Transfer Models

struct TimeBlockExportItem: Codable {
    let id: String
    let title: String
    let startTime: Date
    let endTime: Date
    let status: String
    let category: String?
    let icon: String?
    let notes: String?
    let createdAt: Date
    
    init(from timeBlock: TimeBlock) {
        self.id = timeBlock.id.uuidString
        self.title = timeBlock.title
        self.startTime = timeBlock.startTime
        self.endTime = timeBlock.endTime
        self.status = timeBlock.status.rawValue
        self.category = timeBlock.category
        self.icon = timeBlock.icon
        self.notes = timeBlock.notes
        self.createdAt = timeBlock.createdAt
    }
}

struct DailyProgressExportItem: Codable {
    let id: String
    let date: Date
    let completionPercentage: Double
    let completedBlocks: Int
    let totalBlocks: Int
    let skippedBlocks: Int
    let dayRating: Int?
    let dayNotes: String?
    
    init(from progress: DailyProgress) {
        self.id = progress.id.uuidString
        self.date = progress.date
        self.completionPercentage = progress.completionPercentage
        self.completedBlocks = progress.completedBlocks
        self.totalBlocks = progress.totalBlocks
        self.skippedBlocks = progress.skippedBlocks
        self.dayRating = progress.dayRating
        self.dayNotes = progress.dayNotes
    }
}

struct TimeBlocksExportData: Codable {
    let exportDate: Date
    let version: String
    let timeBlocks: [TimeBlockExportItem]
}

struct DailyProgressExportData: Codable {
    let exportDate: Date
    let version: String
    let dailyProgress: [DailyProgressExportItem]
}

struct CompleteExportData: Codable {
    let exportDate: Date
    let version: String
    let timeBlocks: [TimeBlockExportItem]
    let dailyProgress: [DailyProgressExportItem]
}

// MARK: - CSV Utilities

struct CSVUtilities {
    /// Escape a string for CSV format
    static func escapeCSV(_ string: String) -> String {
        if string.contains("\"") || string.contains(",") || string.contains("\n") {
            return "\"\(string.replacingOccurrences(of: "\"", with: "\"\""))\""
        }
        return string
    }
    
    /// Parse a CSV line into fields
    static func parseCSVLine(_ line: String) -> [String] {
        var fields: [String] = []
        var currentField = ""
        var insideQuotes = false
        
        for char in line {
            if char == "\"" {
                insideQuotes.toggle()
            } else if char == "," && !insideQuotes {
                fields.append(currentField)
                currentField = ""
            } else {
                currentField.append(char)
            }
        }
        
        // Add the last field
        fields.append(currentField)
        
        // Clean up fields
        return fields.map { field in
            var cleaned = field.trimmingCharacters(in: .whitespaces)
            // Remove surrounding quotes and unescape doubled quotes
            if cleaned.hasPrefix("\"") && cleaned.hasSuffix("\"") {
                cleaned = String(cleaned.dropFirst().dropLast())
                cleaned = cleaned.replacingOccurrences(of: "\"\"", with: "\"")
            }
            return cleaned
        }
    }
}

// MARK: - DateFormatter Extension

extension DateFormatter {
    static let dataTransferFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.timeZone = TimeZone.current
        return formatter
    }()
    
    static let dataTransferDateOnlyFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
}
