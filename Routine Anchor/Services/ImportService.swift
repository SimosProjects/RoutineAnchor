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
    struct ImportResult: Sendable {
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
        let fileExtension = fileURL.pathExtension.lowercased()
        let data = try Data(contentsOf: fileURL)
        
        switch fileExtension {
        case "json":
            return try await importJSON(data, modelContext: modelContext)
        case "csv":
            return try await importCSV(data, modelContext: modelContext)
        case "txt":
            return try await importTXT(data, modelContext: modelContext)
        default:
            throw ImportError.unsupportedFormat("File type .\(fileExtension) is not supported")
        }
    }
    
    // MARK: - JSON
    
    func importJSON(_ data: Data, modelContext: ModelContext) async throws -> ImportResult {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        var timeBlocksImported = 0
        var dailyProgressImported = 0
        var errors: [ImportError] = []
        
        if let complete = try? decoder.decode(CompleteExportData.self, from: data) {
            for block in complete.timeBlocks {
                do {
                    let tb = try createTimeBlock(from: block)
                    modelContext.insert(tb)
                    timeBlocksImported += 1
                } catch {
                    errors.append(.invalidTimeBlock(block.title, error.localizedDescription))
                }
            }
            for pg in complete.dailyProgress {
                do {
                    let dp = try createDailyProgress(from: pg)
                    modelContext.insert(dp)
                    dailyProgressImported += 1
                } catch {
                    errors.append(.invalidDailyProgress(pg.date.description, error.localizedDescription))
                }
            }
        } else if let onlyTB = try? decoder.decode(TimeBlocksExportData.self, from: data) {
            for block in onlyTB.timeBlocks {
                do {
                    let tb = try createTimeBlock(from: block)
                    modelContext.insert(tb)
                    timeBlocksImported += 1
                } catch {
                    errors.append(.invalidTimeBlock(block.title, error.localizedDescription))
                }
            }
        } else if let onlyDP = try? decoder.decode(DailyProgressExportData.self, from: data) {
            for pg in onlyDP.dailyProgress {
                do {
                    let dp = try createDailyProgress(from: pg)
                    modelContext.insert(dp)
                    dailyProgressImported += 1
                } catch {
                    errors.append(.invalidDailyProgress(pg.date.description, error.localizedDescription))
                }
            }
        } else {
            throw ImportError.invalidJSON("Unable to parse JSON data")
        }
        
        if timeBlocksImported > 0 || dailyProgressImported > 0 {
            try modelContext.save()
        }
        
        return ImportResult(timeBlocksImported: timeBlocksImported,
                            dailyProgressImported: dailyProgressImported,
                            errors: errors)
    }
    
    // MARK: - CSV (combined or standalone)
    
    func importCSV(_ data: Data, modelContext: ModelContext) async throws -> ImportResult {
        guard let csvString = String(data: data, encoding: .utf8) else {
            throw ImportError.invalidCSV("Unable to read CSV data")
        }
        
        var timeBlocksImported = 0
        var dailyProgressImported = 0
        var errors: [ImportError] = []
        
        // Combined export uses "=== " section boundaries; standalone files won't
        let sections = csvString.components(separatedBy: "=== ")
        for section in sections {
            let trimmed = section.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }
            
            if trimmed.contains("TIME BLOCKS") || trimmed.contains("Title,Start Time,End Time") {
                let result = try importTimeBlocksCSV(trimmed, modelContext: modelContext)
                timeBlocksImported += result.imported
                errors.append(contentsOf: result.errors)
            } else if trimmed.contains("DAILY PROGRESS") || trimmed.contains("Date,Completion Rate") {
                let result = try importDailyProgressCSV(trimmed, modelContext: modelContext)
                dailyProgressImported += result.imported
                errors.append(contentsOf: result.errors)
            }
        }
        
        if timeBlocksImported > 0 || dailyProgressImported > 0 {
            try modelContext.save()
        }
        
        return ImportResult(timeBlocksImported: timeBlocksImported,
                            dailyProgressImported: dailyProgressImported,
                            errors: errors)
    }
    
    // MARK: - CSV Parsing Helpers
    
    private func importTimeBlocksCSV(_ csvContent: String, modelContext: ModelContext) throws -> (imported: Int, errors: [ImportError]) {
        let lines = csvContent.components(separatedBy: .newlines)
        var imported = 0
        var errors: [ImportError] = []

        guard let headerIndex = lines.firstIndex(where: { $0.contains("Title,Start Time,End Time") }) else {
            return (0, [ImportError.invalidCSV("Time blocks header not found")])
        }

        // ✅ Track duplicates within this file (Title+Start+End)
        var seenKeys = Set<String>()

        for i in (headerIndex + 1)..<lines.count {
            let raw = lines[i].trimmingCharacters(in: .whitespacesAndNewlines)
            if raw.isEmpty { continue }
            let fields = parseCSVLine(raw)

            if fields.count >= 7 {
                do {
                    // Build a key before creating the model
                    let key = [
                        fields[0].trimmingCharacters(in: .whitespaces),
                        fields[1].trimmingCharacters(in: .whitespaces),
                        fields[2].trimmingCharacters(in: .whitespaces)
                    ].joined(separator: "||")

                    if seenKeys.contains(key) {
                        // Skip duplicates silently or record a soft warning
                        continue
                    }
                    seenKeys.insert(key)

                    let tb = try createTimeBlockFromCSV(fields)
                    modelContext.insert(tb)
                    imported += 1
                } catch {
                    let title = fields.first ?? "Untitled"
                    errors.append(.invalidTimeBlock(title, error.localizedDescription))
                }
            } else {
                let title = fields.first ?? "Untitled"
                errors.append(.invalidTimeBlock(title, "Row has \(fields.count) columns, expected ≥ 7"))
            }
        }

        return (imported, errors)
    }

    
    private func importDailyProgressCSV(_ csvContent: String, modelContext: ModelContext) throws -> (imported: Int, errors: [ImportError]) {
        let lines = csvContent.components(separatedBy: .newlines)
        var imported = 0
        var errors: [ImportError] = []
        
        // locate header
        guard let headerIndex = lines.firstIndex(where: { $0.contains("Date,Completion Rate") }) else {
            return (0, [ImportError.invalidCSV("Daily progress header not found")])
        }
        
        for i in (headerIndex + 1)..<lines.count {
            let raw = lines[i].trimmingCharacters(in: .whitespacesAndNewlines)
            if raw.isEmpty { continue }
            var fields = parseCSVLine(raw)
            
            // Handle unquoted medium-date with comma (e.g. "Sep 14, 2025") that split into 2 fields
            // Expected columns:
            // 0 Date (ISO "yyyy-MM-dd" OR "MMM d, yyyy")
            // 1 Completion Rate (string w/ or w/o "%")
            // 2 Completed Blocks
            // 3 Total Blocks
            // 4 Skipped Blocks
            // 5 Day Rating
            // 6 Day Notes
            if fields.count >= 8,                     // likely "Sep 14","2025",...
               fields[1].trimmingCharacters(in: .whitespaces).count == 4,
               CharacterSet.decimalDigits.isSuperset(of: CharacterSet(charactersIn: fields[1].trimmingCharacters(in: .whitespaces))) {
                // Merge date parts
                let mergedDate = fields[0].trimmingCharacters(in: .whitespaces) + ", " + fields[1].trimmingCharacters(in: .whitespaces)
                // Rebuild array: [ mergedDate, completion, completed, total, skipped, rating, notes, ...rest]
                var rebuilt: [String] = [mergedDate]
                rebuilt.append(contentsOf: fields.dropFirst(2))
                fields = rebuilt
            }
            
            if fields.count >= 7 {
                do {
                    let dp = try createDailyProgressFromCSV(fields)
                    modelContext.insert(dp)
                    imported += 1
                } catch {
                    let dateStr = fields.first ?? "Unknown Date"
                    errors.append(.invalidDailyProgress(dateStr, error.localizedDescription))
                }
            } else {
                let dateStr = fields.first ?? "Unknown Date"
                errors.append(.invalidDailyProgress(dateStr, "Row has \(fields.count) columns, expected ≥ 7"))
            }
        }
        
        return (imported, errors)
    }
    
    @MainActor
    private func importTXT(_ data: Data, modelContext: ModelContext) async throws -> ImportResult {
        guard let text = String(data: data, encoding: .utf8) else {
            throw ImportError.invalidData("Unable to read text data")
        }

        var timeBlocksImported = 0
        var dailyProgressImported = 0
        var errors: [ImportError] = []

        // Detect sectioned text exports like: "=== TIME BLOCKS ===" / "=== DAILY PROGRESS ==="
        var timeBlocksSection = text
        var dailyProgressSection: String? = nil
        let hasSections = text.contains("=== TIME BLOCKS") || text.contains("=== DAILY PROGRESS")

        if hasSections {
            // Split on the leading markers emitted by the text export
            let parts = text.components(separatedBy: "=== ")
            for part in parts {
                let trimmed = part.trimmingCharacters(in: .whitespacesAndNewlines)
                let header = trimmed.components(separatedBy: .newlines).first?.uppercased() ?? ""

                if header.hasPrefix("TIME BLOCKS") {
                    // Drop header line
                    timeBlocksSection = trimmed.components(separatedBy: .newlines).dropFirst().joined(separator: "\n")
                } else if header.hasPrefix("DAILY PROGRESS") {
                    // Drop header line
                    dailyProgressSection = trimmed.components(separatedBy: .newlines).dropFirst().joined(separator: "\n")
                }
            }
        }

        // 1) Parse time blocks from TXT
        do {
            timeBlocksImported += try importTimeBlocksFromTXT(timeBlocksSection, modelContext: modelContext)
        } catch {
            errors.append(.invalidData("Time block text parse failed: \(error.localizedDescription)"))
        }

        // 2) Parse daily progress from TXT (if present)
        if let dpSection = dailyProgressSection, !dpSection.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            do {
                dailyProgressImported += try importDailyProgressFromTXT(dpSection, modelContext: modelContext)
            } catch {
                errors.append(.invalidData("Daily progress text parse failed: \(error.localizedDescription)"))
            }
        }

        if timeBlocksImported > 0 || dailyProgressImported > 0 {
            try modelContext.save()
        }

        return ImportResult(
            timeBlocksImported: timeBlocksImported,
            dailyProgressImported: dailyProgressImported,
            errors: errors
        )
    }

    private func importDailyProgressFromTXT(_ section: String, modelContext: ModelContext) throws -> Int {
        // Split into logical records by blank lines
        let lines = section.components(separatedBy: .newlines)

        // Date formatters we’ll accept
        let iso = DateFormatter()
        iso.dateFormat = "yyyy-MM-dd"

        let medium = DateFormatter()
        medium.dateFormat = "MMM d, yyyy"          // e.g. "Sep 14, 2025"

        let full = DateFormatter()
        full.dateStyle = .full
        full.timeStyle = .none                     // e.g. "Sunday, September 14, 2025"

        func parseDate(_ s: String) -> Date? {
            let raw = s.trimmingCharacters(in: .whitespaces)
            let v = raw.hasPrefix("📊 ") ? String(raw.dropFirst(2)).trimmingCharacters(in: .whitespaces) : raw

            if let d = iso.date(from: v) { return d }
            if let d = medium.date(from: v) { return d }
            if let d = full.date(from: v) { return d }
            return nil
        }

        // Helpers to strip label prefixes (case-insensitive)
        func stripPrefix(_ label: String, from line: String) -> String? {
            let lower = line.lowercased()
            let needle = label.lowercased()
            guard let range = lower.range(of: needle) else { return nil }
            // Require it starts at beginning
            if range.lowerBound == lower.startIndex {
                let after = line[line.index(line.startIndex, offsetBy: label.count)...]
                return after.trimmingCharacters(in: .whitespaces)
            }
            return nil
        }

        // State for one record
        var currentDate: Date? = nil
        var completed: Int? = nil
        var total: Int? = nil
        var skipped: Int? = nil
        var rating: Int? = nil
        var notes: String? = nil

        func flushIfValid() throws -> Int {
            guard let date = currentDate else { return 0 }
            guard let c = completed, let t = total, let s = skipped else { return 0 }
            let dp = DailyProgress(date: date)
            dp.completedBlocks = c
            dp.totalBlocks = t
            dp.skippedBlocks = s
            if let r = rating, r > 0 { dp.dayRating = r }
            if let n = notes, !n.isEmpty { dp.dayNotes = n }
            modelContext.insert(dp)
            return 1
        }

        var imported = 0

        // Parse line-by-line
        for raw in lines {
            let line = raw.trimmingCharacters(in: .whitespaces)
            if line.isEmpty {
                // Blank line => end of record
                imported += (try flushIfValid())
                // reset
                currentDate = nil
                completed = nil
                total = nil
                skipped = nil
                rating = nil
                notes = nil
                continue
            }

            // Accept formats:
            // "Date: <date>"
            // or a bare date line
            if let rest = stripPrefix("Date:", from: line), let d = parseDate(rest) {
                // Starting a new record? Flush the previous one.
                imported += (try flushIfValid())
                // reset
                currentDate = d
                completed = nil; total = nil; skipped = nil; rating = nil; notes = nil
                continue
            }
            if currentDate == nil, let d = parseDate(line) {
                imported += (try flushIfValid())
                currentDate = d
                completed = nil; total = nil; skipped = nil; rating = nil; notes = nil
                continue
            }

            // Numbers: "Completed: 3", "Total: 4", "Skipped: 1"
            if let rest = stripPrefix("Completed:", from: line), let v = Int(rest) {
                completed = v; continue
            }
            if let rest = stripPrefix("Total:", from: line), let v = Int(rest) {
                total = v; continue
            }
            if let rest = stripPrefix("Skipped:", from: line), let v = Int(rest) {
                skipped = v; continue
            }

            // Rating: "Day Rating: 5" or "Rating: 5"
            if let rest = stripPrefix("Day Rating:", from: line), let v = Int(rest) {
                rating = v; continue
            }
            if let rest = stripPrefix("Rating:", from: line), let v = Int(rest) {
                rating = v; continue
            }

            // Notes: "Notes: some text"
            if let rest = stripPrefix("Notes:", from: line) {
                notes = rest; continue
            }
        }

        // Flush the last record if file doesn't end with a blank line
        imported += (try flushIfValid())

        return imported
    }

    private func importTimeBlocksFromTXT(_ section: String, modelContext: ModelContext) throws -> Int {
        var imported = 0

        let lines = section.components(separatedBy: .newlines)
        let dayFormatter = DateFormatter()
        dayFormatter.dateStyle = .full
        dayFormatter.timeStyle = .none

        let timeFormatter = DateFormatter()
        timeFormatter.dateStyle = .none
        timeFormatter.timeStyle = .short

        var currentDayDate: Date? = nil
        var i = 0

        // ✅ Deduplicate within this TXT import: title + start + end
        var seenKeys = Set<String>()

        func isDivider(_ s: String) -> Bool {
            let t = s.trimmingCharacters(in: .whitespaces)
            return !t.isEmpty && Set(t).count == 1 && (t.first == "-" || t.first == "—" || t.first == "_")
        }

        while i < lines.count {
            let line = lines[i].trimmingCharacters(in: .whitespaces)

            // Day header from exportAsText: "📅 <Full Date>"
            if line.hasPrefix("📅 ") {
                let dateStr = String(line.dropFirst(2)).trimmingCharacters(in: .whitespaces)
                currentDayDate = dayFormatter.date(from: dateStr)
                i += 1
                continue
            }

            // Skip non-block lines and noise
            if line.isEmpty || isDivider(line) || line.hasPrefix("📊 ") || line.localizedCaseInsensitiveContains("Daily Progress Summary") {
                i += 1
                continue
            }

            // A block's title line (e.g., "📌 Title" or "<emoji> Title")
            if currentDayDate != nil, !line.hasPrefix("===") {
                let titleLine = line
                // Support leading emoji icon
                let (icon, restTitle) = titleLine.peelLeadingEmoji()
                let title = restTitle.trimmingCharacters(in: .whitespaces)

                // Expect the next line to be "Time: 9:00 AM - 10:00 AM ⏰/✅/⏭️"
                let timeLine = (i + 1 < lines.count) ? lines[i + 1].trimmingCharacters(in: .whitespaces) : ""
                guard timeLine.lowercased().hasPrefix("time:"),
                      let dash = timeLine.range(of: "-"),
                      let day = currentDayDate
                else {
                    // Not a real block—advance one line and keep scanning
                    i += 1
                    continue
                }

                let left = timeLine[timeLine.index(timeLine.startIndex, offsetBy: 5)..<dash.lowerBound].trimmingCharacters(in: .whitespaces)
                let rightPart = timeLine[dash.upperBound...].trimmingCharacters(in: .whitespaces)
                let right = rightPart.split(separator: " ").first.map(String.init) ?? rightPart

                guard let startClock = timeFormatter.date(from: left),
                      let endClock   = timeFormatter.date(from: right)
                else {
                    i += 2
                    continue
                }

                // Combine day + time
                let cal = Calendar.current
                let start = cal.date(bySettingHour: cal.component(.hour, from: startClock),
                                     minute: cal.component(.minute, from: startClock),
                                     second: 0, of: day)!
                let end   = cal.date(bySettingHour: cal.component(.hour, from: endClock),
                                     minute: cal.component(.minute, from: endClock),
                                     second: 0, of: day)!

                // Optional Category / Notes lines
                var category: String? = nil
                var notes: String? = nil
                var j = i + 2
                while j < lines.count {
                    let l = lines[j].trimmingCharacters(in: .whitespaces)
                    if l.hasPrefix("Category:") {
                        category = l.replacingOccurrences(of: "Category:", with: "").trimmingCharacters(in: .whitespaces)
                    } else if l.hasPrefix("Notes:") {
                        notes = l.replacingOccurrences(of: "Notes:", with: "").trimmingCharacters(in: .whitespaces)
                    } else if l.isEmpty || isDivider(l) {
                        // skip blanks or dividers
                    } else if l.hasPrefix("📅 ") || l.hasPrefix("===") || l.hasPrefix("📊 ") {
                        break // next day/section
                    } else {
                        // Reached next block title
                        break
                    }
                    j += 1
                }

                // ✅ Dedupe
                let key = "\(title)|\(start.timeIntervalSince1970)|\(end.timeIntervalSince1970)"
                if !seenKeys.contains(key) {
                    let tb = TimeBlock(title: title, startTime: start, endTime: end, notes: notes, icon: icon, category: category)
                    modelContext.insert(tb)
                    imported += 1
                    seenKeys.insert(key)
                }

                i = j
                continue
            }

            i += 1
        }

        return imported
    }
    
    // MARK: - Model Creation (JSON)
    
    private func createTimeBlock(from data: TimeBlockExportItem) throws -> TimeBlock {
        // Re-hydrate dates from ISO
        let startTime = data.startTime
        let endTime = data.endTime
        
        let timeBlock = TimeBlock(
            title: data.title,
            startTime: startTime,
            endTime: endTime,
            notes: data.notes,
            icon: data.icon,
            category: data.category
        )
        
        // Preserve ID if present
        if let uuid = UUID(uuidString: data.id) {
            timeBlock.id = uuid
        }
        if let status = BlockStatus(rawValue: data.status) {
            timeBlock.status = status
        }
        return timeBlock
    }
    
    private func createDailyProgress(from data: DailyProgressExportItem) throws -> DailyProgress {
        let progress = DailyProgress(date: data.date)
        if let uuid = UUID(uuidString: data.id) {
            progress.id = uuid
        }
        progress.totalBlocks = data.totalBlocks
        progress.completedBlocks = data.completedBlocks
        progress.skippedBlocks = data.skippedBlocks
        progress.dayRating = data.dayRating
        progress.dayNotes = data.dayNotes
        return progress
    }
    
    // MARK: - Model Creation (CSV)
    
    private func createTimeBlockFromCSV(_ fields: [String]) throws -> TimeBlock {
        let df = DateFormatter.dataTransferFormatter
        guard let start = df.date(from: fields[1]),
              let end   = df.date(from: fields[2]) else {
            throw ImportError.invalidData("Invalid date/time for Start/End")
        }
        
        let tb = TimeBlock(
            title: fields[0],
            startTime: start,
            endTime: end,
            notes: fields.indices.contains(6) && !fields[6].isEmpty ? fields[6] : nil,
            icon: fields.indices.contains(5) && !fields[5].isEmpty ? fields[5] : nil,
            category: fields.indices.contains(4) && !fields[4].isEmpty ? fields[4] : nil
        )
        if fields.indices.contains(3), let status = BlockStatus(rawValue: fields[3]) {
            tb.status = status
        }
        return tb
    }
    
    private func createDailyProgressFromCSV(_ fields: [String]) throws -> DailyProgress {
        // Accept either ISO (yyyy-MM-dd) or medium ("MMM d, yyyy")
        let iso = DateFormatter.dataTransferDateOnlyFormatter
        let medium = DateFormatter()
        medium.dateFormat = "MMM d, yyyy" // platform-independent "Sep 14, 2025"
        
        let dateField = fields[0].trimmingCharacters(in: .whitespaces)
        let date: Date
        if let d = iso.date(from: dateField) {
            date = d
        } else if let d = medium.date(from: dateField) {
            date = d
        } else {
            throw ImportError.invalidData("Unrecognized date format '\(dateField)'")
        }
        
        // completion rate (not needed to build model, but be lenient)
        // let completionStr = fields[1].replacingOccurrences(of: "%", with: "").trimmingCharacters(in: .whitespaces)
        
        guard let completed = Int(fields[2].trimmingCharacters(in: .whitespaces)),
              let total     = Int(fields[3].trimmingCharacters(in: .whitespaces)),
              let skipped   = Int(fields[4].trimmingCharacters(in: .whitespaces)) else {
            throw ImportError.invalidData("Invalid counters (completed/total/skipped)")
        }
        
        let dp = DailyProgress(date: date)
        dp.completedBlocks = completed
        dp.totalBlocks = total
        dp.skippedBlocks = skipped
        
        if fields.indices.contains(5),
           let rating = Int(fields[5].trimmingCharacters(in: .whitespaces)),
           rating > 0 {
            dp.dayRating = rating
        }
        if fields.indices.contains(6) {
            let notes = fields[6].trimmingCharacters(in: .whitespaces)
            if !notes.isEmpty { dp.dayNotes = notes }
        }
        return dp
    }
    
    // MARK: - CSV Parsing Utility
    
    private func parseCSVLine(_ line: String) -> [String] {
        // Handles quoted fields and embedded commas, and leaves unquoted commas alone
        // (we do a special merge just for the date in daily-progress if needed)
        var result: [String] = []
        var current = ""
        var inQuotes = false
        var i = line.startIndex
        
        while i < line.endIndex {
            let ch = line[i]
            if ch == "\"" {
                let next = line.index(after: i)
                if inQuotes && next < line.endIndex && line[next] == "\"" {
                    current.append("\"")
                    i = next
                } else {
                    inQuotes.toggle()
                }
            } else if ch == "," && !inQuotes {
                result.append(current.trimmingCharacters(in: .whitespaces))
                current = ""
            } else {
                current.append(ch)
            }
            i = line.index(after: i)
        }
        result.append(current.trimmingCharacters(in: .whitespaces))
        return result
    }
}

// MARK: - Import Error

enum ImportError: LocalizedError, Sendable {
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
