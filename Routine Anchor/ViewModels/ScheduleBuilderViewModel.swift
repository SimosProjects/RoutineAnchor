//
//  ScheduleBuilderViewModel.swift
//  Routine Anchor - Premium Version
//
import SwiftUI
import SwiftData
import Combine

@MainActor
class ScheduleBuilderViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var timeBlocks: [TimeBlock] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showSuccessAnimation = false
    @Published var lastActionMessage: String?
    
    // MARK: - Analytics
    @Published var totalMinutes: Int = 0
    @Published var completionRate: Double = 0.0
    @Published var streakDays: Int = 0
    @Published var todayProgress: Double = 0.0
    
    // MARK: - UI State
    @Published var selectedFilter: FilterType = .all
    @Published var sortOrder: SortOrder = .chronological
    @Published var searchText: String = ""
    
    // MARK: - Dependencies
    private let modelContext: ModelContext
    private let dataManager: DataManagerProtocol
    private let notificationManager: NotificationManagerProtocol
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Enums
    enum FilterType: String, CaseIterable {
        case all = "All"
        case work = "Work"
        case personal = "Personal"
        case health = "Health"
        case learning = "Learning"
        case social = "Social"
        case other = "Other"
        
        var icon: String {
            switch self {
            case .all: return "square.grid.2x2"
            case .work: return "briefcase.fill"
            case .personal: return "house.fill"
            case .health: return "heart.fill"
            case .learning: return "book.fill"
            case .social: return "person.2.fill"
            case .other: return "star.fill"
            }
        }
        
        var gradient: [Color] {
            switch self {
            case .all: return [Color.premiumBlue, Color.premiumPurple]
            case .work: return [Color.premiumBlue, Color.premiumPurple]
            case .personal: return [Color.premiumGreen, Color.premiumTeal]
            case .health: return [Color.premiumGreen, Color.premiumBlue]
            case .learning: return [Color.premiumPurple, Color.premiumBlue]
            case .social: return [Color.premiumTeal, Color.premiumBlue]
            case .other: return [Color.premiumTextSecondary, Color.premiumTextTertiary]
            }
        }
    }
    
    enum SortOrder: String, CaseIterable {
        case chronological = "Time"
        case duration = "Duration"
        case alphabetical = "Name"
        case category = "Category"
        
        var icon: String {
            switch self {
            case .chronological: return "clock.arrow.circlepath"
            case .duration: return "timer"
            case .alphabetical: return "textformat.abc"
            case .category: return "folder"
            }
        }
    }
    
    // MARK: - Initialization
    init(modelContext: ModelContext,
         dataManager: DataManagerProtocol = DataManager.shared as! DataManagerProtocol,
         notificationManager: NotificationManagerProtocol = NotificationManager.shared as! NotificationManagerProtocol) {
        self.modelContext = modelContext
        self.dataManager = dataManager
        self.notificationManager = notificationManager
        
        setupBindings()
        loadTimeBlocks()
    }
    
    // MARK: - Setup
    private func setupBindings() {
        // Search debouncing
        $searchText
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.filterTimeBlocks()
            }
            .store(in: &cancellables)
        
        // Filter and sort changes
        $selectedFilter
            .combineLatest($sortOrder)
            .sink { [weak self] _, _ in
                self?.filterTimeBlocks()
            }
            .store(in: &cancellables)
        
        // Time blocks changes
        $timeBlocks
            .sink { [weak self] blocks in
                self?.updateAnalytics(blocks: blocks)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Data Loading
    func loadTimeBlocks() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let blocks = try await dataManager.fetchTimeBlocks(from: modelContext)
                
                await MainActor.run {
                    self.timeBlocks = blocks
                    self.isLoading = false
                    self.filterTimeBlocks()
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to load time blocks: \(error.localizedDescription)"
                    self.isLoading = false
                    HapticManager.shared.error()
                }
            }
        }
    }
    
    // MARK: - CRUD Operations
    
    func addTimeBlock(title: String,
                      startTime: Date,
                      endTime: Date,
                      notes: String? = nil,
                      category: String? = nil,
                      icon: String? = nil) {
        
        Task {
            do {
                let newBlock = TimeBlock(
                    title: title,
                    startTime: startTime,
                    endTime: endTime,
                    notes: notes,
                    icon: icon,
                    category: category
                )
                
                modelContext.insert(newBlock)
                try modelContext.save()
                
                await MainActor.run {
                    self.timeBlocks.append(newBlock)
                    self.filterTimeBlocks()
                    self.showSuccessMessage("Time block added!")
                    HapticManager.shared.success()
                }
                
                // Schedule notification
                await notificationManager.scheduleTimeBlockNotification(for: newBlock)
                
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to add time block: \(error.localizedDescription)"
                    HapticManager.shared.error()
                }
            }
        }
    }
    
    func updateTimeBlock(_ timeBlock: TimeBlock) {
        Task {
            do {
                try modelContext.save()
                
                await MainActor.run {
                    if let index = self.timeBlocks.firstIndex(where: { $0.id == timeBlock.id }) {
                        self.timeBlocks[index] = timeBlock
                    }
                    self.filterTimeBlocks()
                    self.showSuccessMessage("Time block updated!")
                    HapticManager.shared.success()
                }
                
                // Reschedule notification
                await notificationManager.cancelNotification(for: timeBlock.id.uuidString)
                await notificationManager.scheduleTimeBlockNotification(for: timeBlock)
                
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to update time block: \(error.localizedDescription)"
                    HapticManager.shared.error()
                }
            }
        }
    }
    
    func deleteTimeBlock(_ timeBlock: TimeBlock) {
        Task {
            do {
                modelContext.delete(timeBlock)
                try modelContext.save()
                
                await MainActor.run {
                    self.timeBlocks.removeAll { $0.id == timeBlock.id }
                    self.filterTimeBlocks()
                    self.showSuccessMessage("Time block deleted")
                    HapticManager.shared.success()
                }
                
                // Cancel notification
                await notificationManager.cancelNotification(for: timeBlock.id.uuidString)
                
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to delete time block: \(error.localizedDescription)"
                    HapticManager.shared.error()
                }
            }
        }
    }
    
    // MARK: - Batch Operations
    
    func deleteMultipleTimeBlocks(_ blocks: [TimeBlock]) {
        Task {
            do {
                for block in blocks {
                    modelContext.delete(block)
                    await notificationManager.cancelNotification(for: block.id.uuidString)
                }
                
                try modelContext.save()
                
                await MainActor.run {
                    let blockIds = blocks.map { $0.id }
                    self.timeBlocks.removeAll { blockIds.contains($0.id) }
                    self.filterTimeBlocks()
                    self.showSuccessMessage("\(blocks.count) blocks deleted")
                    HapticManager.shared.success()
                }
                
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to delete blocks: \(error.localizedDescription)"
                    HapticManager.shared.error()
                }
            }
        }
    }
    
    func duplicateTimeBlock(_ timeBlock: TimeBlock) {
        let calendar = Calendar.current
        let newStartTime = calendar.date(byAdding: .day, value: 1, to: timeBlock.startTime) ?? timeBlock.startTime
        let newEndTime = calendar.date(byAdding: .day, value: 1, to: timeBlock.endTime) ?? timeBlock.endTime
        
        addTimeBlock(
            title: "\(timeBlock.title) (Copy)",
            startTime: newStartTime,
            endTime: newEndTime,
            notes: timeBlock.notes,
            category: timeBlock.category,
            icon: timeBlock.icon
        )
    }
    
    // MARK: - Quick Actions
    
    func addQuickTimeBlock(type: QuickBlockType) {
        let calendar = Calendar.current
        let now = Date()
        
        switch type {
        case .morningRoutine:
            guard let start = calendar.date(bySettingHour: 7, minute: 0, second: 0, of: now),
                  let end = calendar.date(bySettingHour: 8, minute: 0, second: 0, of: now) else { return }
            
            addTimeBlock(
                title: "Morning Routine",
                startTime: start,
                endTime: end,
                category: "Personal",
                icon: "☀️"
            )
            
        case .workBlock:
            guard let start = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: now),
                  let end = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: now) else { return }
            
            addTimeBlock(
                title: "Deep Work Session",
                startTime: start,
                endTime: end,
                category: "Work",
                icon: "💼"
            )
            
        case .exercise:
            guard let start = calendar.date(bySettingHour: 17, minute: 0, second: 0, of: now),
                  let end = calendar.date(bySettingHour: 18, minute: 0, second: 0, of: now) else { return }
            
            addTimeBlock(
                title: "Exercise",
                startTime: start,
                endTime: end,
                category: "Health",
                icon: "💪"
            )
            
        case .break:
            let start = Date()
            guard let end = calendar.date(byAdding: .minute, value: 15, to: start) else { return }
            
            addTimeBlock(
                title: "Break",
                startTime: start,
                endTime: end,
                category: "Personal",
                icon: "☕"
            )
        }
    }
    
    enum QuickBlockType {
        case morningRoutine
        case workBlock
        case exercise
        case `break`
    }
    
    // MARK: - Filtering & Sorting
    
    private func filterTimeBlocks() {
        var filtered = timeBlocks
        
        // Apply category filter
        if selectedFilter != .all {
            filtered = filtered.filter { block in
                block.category?.lowercased() == selectedFilter.rawValue.lowercased()
            }
        }
        
        // Apply search
        if !searchText.isEmpty {
            filtered = filtered.filter { block in
                block.title.localizedCaseInsensitiveContains(searchText) ||
                (block.notes ?? "").localizedCaseInsensitiveContains(searchText) ||
                (block.category ?? "").localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Apply sort
        switch sortOrder {
        case .chronological:
            filtered.sort { $0.startTime < $1.startTime }
        case .duration:
            filtered.sort { $0.duration > $1.duration }
        case .alphabetical:
            filtered.sort { $0.title < $1.title }
        case .category:
            filtered.sort { ($0.category ?? "") < ($1.category ?? "") }
        }
        
        // Update if different
        if filtered != timeBlocks {
            timeBlocks = filtered
        }
    }
    
    // MARK: - Analytics
    
    private func updateAnalytics(blocks: [TimeBlock]) {
        // Calculate total minutes
        totalMinutes = blocks.reduce(0) { total, block in
            return total + block.durationMinutes
        }
        
        // Calculate completion rate (would need to check against DailyProgress)
        let completedBlocks = blocks.filter { $0.status == .completed }.count
        completionRate = blocks.isEmpty ? 0 : Double(completedBlocks) / Double(blocks.count)
        
        // Calculate today's progress
        let todayBlocks = blocks.filter { Calendar.current.isDateInToday($0.startTime) }
        let todayCompleted = todayBlocks.filter { $0.status == .completed }.count
        todayProgress = todayBlocks.isEmpty ? 0 : Double(todayCompleted) / Double(todayBlocks.count)
    }
    
    // MARK: - Computed Properties
    
    var hasTimeBlocks: Bool {
        !timeBlocks.isEmpty
    }
    
    var sortedTimeBlocks: [TimeBlock] {
        timeBlocks.sorted { $0.startTime < $1.startTime }
    }
    
    var formattedTotalDuration: String {
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        
        if hours > 0 && minutes > 0 {
            return "\(hours)h \(minutes)m"
        } else if hours > 0 {
            return "\(hours)h"
        } else {
            return "\(minutes)m"
        }
    }
    
    var categoryBreakdown: [(category: String, count: Int, percentage: Double)] {
        let grouped = Dictionary(grouping: timeBlocks) { $0.category ?? "Other" }
        let total = timeBlocks.count
        
        return grouped.map { category, blocks in
            let percentage = total > 0 ? Double(blocks.count) / Double(total) : 0
            return (category, blocks.count, percentage)
        }.sorted { $0.count > $1.count }
    }
    
    // MARK: - Schedule Management
    
    func saveSchedule() {
        Task {
            do {
                try modelContext.save()
                
                // Schedule all notifications
                await notificationManager.scheduleTimeBlockNotifications(for: timeBlocks)
                
                await MainActor.run {
                    self.showSuccessMessage("Schedule saved successfully!")
                }
                
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to save schedule: \(error.localizedDescription)"
                    HapticManager.shared.error()
                }
            }
        }
    }
    
    func resetRoutineStatus() {
        Task {
            do {
                for block in timeBlocks {
                    block.status = .notStarted
                }
                
                try modelContext.save()
                
                await MainActor.run {
                    self.filterTimeBlocks()
                    self.showSuccessMessage("All blocks reset")
                    HapticManager.shared.success()
                }
                
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to reset blocks: \(error.localizedDescription)"
                    HapticManager.shared.error()
                }
            }
        }
    }
    
    // MARK: - Import/Export
    
    func exportSchedule() async throws -> Data {
        let exportData = timeBlocks.map { block in
            [
                "title": block.title,
                "startTime": ISO8601DateFormatter().string(from: block.startTime),
                "endTime": ISO8601DateFormatter().string(from: block.endTime),
                "notes": block.notes ?? "",
                "category": block.category ?? "",
                "icon": block.icon ?? ""
            ]
        }
        
        return try JSONSerialization.data(withJSONObject: exportData, options: .prettyPrinted)
    }
    
    func importSchedule(from data: Data) async throws {
        guard let importData = try JSONSerialization.jsonObject(with: data) as? [[String: String]] else {
            throw ImportError.invalidFormat
        }
        
        let formatter = ISO8601DateFormatter()
        
        for blockData in importData {
            guard let title = blockData["title"],
                  let startTimeString = blockData["startTime"],
                  let endTimeString = blockData["endTime"],
                  let startTime = formatter.date(from: startTimeString),
                  let endTime = formatter.date(from: endTimeString) else {
                continue
            }
            
            addTimeBlock(
                title: title,
                startTime: startTime,
                endTime: endTime,
                notes: blockData["notes"],
                category: blockData["category"],
                icon: blockData["icon"]
            )
        }
    }
    
    enum ImportError: LocalizedError {
        case invalidFormat
        
        var errorDescription: String? {
            switch self {
            case .invalidFormat:
                return "Invalid import file format"
            }
        }
    }
    
    // MARK: - UI Helpers
    
    private func showSuccessMessage(_ message: String) {
        lastActionMessage = message
        showSuccessAnimation = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.showSuccessAnimation = false
            self.lastActionMessage = nil
        }
    }
    
    func clearError() {
        errorMessage = nil
    }
}

// MARK: - Protocol Definitions

protocol DataManagerProtocol {
    func fetchTimeBlocks(from context: ModelContext) async throws -> [TimeBlock]
}

protocol NotificationManagerProtocol {
    func scheduleTimeBlockNotification(for block: TimeBlock) async
    func scheduleTimeBlockNotifications(for blocks: [TimeBlock]) async
    func cancelNotification(for identifier: String) async
}

// MARK: - Mock Implementations for Preview

class MockDataManager: DataManagerProtocol {
    func fetchTimeBlocks(from context: ModelContext) async throws -> [TimeBlock] {
        return []
    }
}

class MockNotificationManager: NotificationManagerProtocol {
    func scheduleTimeBlockNotification(for block: TimeBlock) async {}
    func scheduleTimeBlockNotifications(for blocks: [TimeBlock]) async {}
    func cancelNotification(for identifier: String) async {}
}
