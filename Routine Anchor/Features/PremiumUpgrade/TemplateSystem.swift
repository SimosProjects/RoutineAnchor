//
//  TemplateSystem.swift
//  Routine Anchor
//
//  Template management for routine time blocks
//
import SwiftUI
import SwiftData
import Foundation

// MARK: - Template Model
@Model
class RoutineTemplate {
    @Attribute(.unique) var id: UUID
    var name: String
    var templateDescription: String?
    var category: String?
    var icon: String?
    var createdAt: Date
    var updatedAt: Date
    var isDefault: Bool
    var isPremium: Bool
    
    // Template blocks stored as JSON
    @Attribute(.externalStorage) var blocksData: Data
    
    init(
        name: String,
        description: String? = nil,
        category: String? = nil,
        icon: String? = nil,
        blocks: [TemplateTimeBlock],
        isDefault: Bool = false,
        isPremium: Bool = false
    ) {
        self.id = UUID()
        self.name = name
        self.templateDescription = description
        self.category = category
        self.icon = icon
        self.createdAt = Date()
        self.updatedAt = Date()
        self.isDefault = isDefault
        self.isPremium = isPremium
        
        // Encode blocks to JSON
        self.blocksData = (try? JSONEncoder().encode(blocks)) ?? Data()
    }
    
    // Computed property to decode blocks
    var blocks: [TemplateTimeBlock] {
        get {
            (try? JSONDecoder().decode([TemplateTimeBlock].self, from: blocksData)) ?? []
        }
        set {
            blocksData = (try? JSONEncoder().encode(newValue)) ?? Data()
            updatedAt = Date()
        }
    }
}

// MARK: - Template Time Block
struct TemplateTimeBlock: Codable, Identifiable {
    let id: UUID
    var title: String
    var startHour: Int
    var startMinute: Int
    var durationMinutes: Int
    var notes: String?
    var category: String?
    var icon: String?
    
    init(
        title: String,
        startHour: Int,
        startMinute: Int = 0,
        durationMinutes: Int,
        notes: String? = nil,
        category: String? = nil,
        icon: String? = nil
    ) {
        self.id = UUID()
        self.title = title
        self.startHour = startHour
        self.startMinute = startMinute
        self.durationMinutes = durationMinutes
        self.notes = notes
        self.category = category
        self.icon = icon
    }
    
    var formattedStartTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        
        let calendar = Calendar.current
        let date = calendar.date(bySettingHour: startHour, minute: startMinute, second: 0, of: Date()) ?? Date()
        return formatter.string(from: date)
    }
    
    var formattedDuration: String {
        let hours = durationMinutes / 60
        let minutes = durationMinutes % 60
        
        if hours > 0 && minutes > 0 {
            return "\(hours)h \(minutes)m"
        } else if hours > 0 {
            return "\(hours)h"
        } else {
            return "\(minutes)m"
        }
    }
}

// MARK: - Template Manager
@MainActor
@Observable
class TemplateManager {
    private let modelContext: ModelContext
    private let premiumManager: PremiumManager
    
    var templates: [RoutineTemplate] = []
    var isLoading = false
    var errorMessage: String?
    
    init(modelContext: ModelContext, premiumManager: PremiumManager) {
        self.modelContext = modelContext
        self.premiumManager = premiumManager
        loadTemplates()
        createDefaultTemplatesIfNeeded()
    }
    
    // MARK: - Template Management
    
    func loadTemplates() {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let descriptor = FetchDescriptor<RoutineTemplate>(
                sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
            )
            templates = try modelContext.fetch(descriptor)
        } catch {
            errorMessage = "Failed to load templates: \(error.localizedDescription)"
        }
    }
    
    func saveTemplate(
        name: String,
        description: String?,
        category: String?,
        icon: String?,
        blocks: [TemplateTimeBlock]
    ) throws {
        // Check premium limits
        let userTemplateCount = templates.filter { !$0.isDefault }.count
        
        if !premiumManager.canCreateTemplate(currentTemplateCount: userTemplateCount) {
            throw TemplateError.premiumRequired
        }
        
        let template = RoutineTemplate(
            name: name,
            description: description,
            category: category,
            icon: icon,
            blocks: blocks,
            isDefault: false,
            isPremium: false
        )
        
        modelContext.insert(template)
        try modelContext.save()
        
        loadTemplates()
        HapticManager.shared.premiumSuccess()
    }
    
    func deleteTemplate(_ template: RoutineTemplate) throws {
        // Don't allow deleting default templates
        guard !template.isDefault else {
            throw TemplateError.cannotDeleteDefault
        }
        
        modelContext.delete(template)
        try modelContext.save()
        loadTemplates()
    }
    
    func applyTemplate(_ template: RoutineTemplate, to date: Date) -> [TimeBlock] {
        let calendar = Calendar.current
        var timeBlocks: [TimeBlock] = []
        
        for templateBlock in template.blocks {
            guard let startTime = calendar.date(
                bySettingHour: templateBlock.startHour,
                minute: templateBlock.startMinute,
                second: 0,
                of: date
            ) else { continue }
            
            let endTime = startTime.addingTimeInterval(TimeInterval(templateBlock.durationMinutes * 60))
            
            let timeBlock = TimeBlock(
                title: templateBlock.title,
                startTime: startTime,
                endTime: endTime,
                notes: templateBlock.notes,
                icon: templateBlock.icon,
                category: templateBlock.category
            )
            
            timeBlocks.append(timeBlock)
        }
        
        return timeBlocks
    }
    
    // MARK: - Default Templates
    
    private func createDefaultTemplatesIfNeeded() {
        // Check if default templates already exist
        let defaultTemplates = templates.filter { $0.isDefault }
        if !defaultTemplates.isEmpty { return }
        
        createDefaultTemplates()
    }
    
    private func createDefaultTemplates() {
        let defaultTemplates = [
            createMorningRoutineTemplate(),
            createWorkDayTemplate(),
            createWorkoutRoutineTemplate()
        ]
        
        for template in defaultTemplates {
            modelContext.insert(template)
        }
        
        do {
            try modelContext.save()
            loadTemplates()
        } catch {
            errorMessage = "Failed to create default templates: \(error.localizedDescription)"
        }
    }
    
    private func createMorningRoutineTemplate() -> RoutineTemplate {
        let blocks = [
            TemplateTimeBlock(title: "Morning Meditation", startHour: 6, startMinute: 30, durationMinutes: 15, category: "Health", icon: "🧘"),
            TemplateTimeBlock(title: "Exercise", startHour: 6, startMinute: 45, durationMinutes: 30, category: "Health", icon: "💪"),
            TemplateTimeBlock(title: "Healthy Breakfast", startHour: 7, startMinute: 15, durationMinutes: 30, category: "Health", icon: "🍽️"),
            TemplateTimeBlock(title: "Review Daily Goals", startHour: 7, startMinute: 45, durationMinutes: 15, category: "Personal", icon: "🎯")
        ]
        
        return RoutineTemplate(
            name: "Energizing Morning",
            description: "Start your day with mindfulness, movement, and intention",
            category: "Health",
            icon: "🌅",
            blocks: blocks,
            isDefault: true
        )
    }
    
    private func createWorkDayTemplate() -> RoutineTemplate {
        let blocks = [
            TemplateTimeBlock(title: "Deep Work Session", startHour: 9, startMinute: 0, durationMinutes: 90, category: "Work", icon: "💼"),
            TemplateTimeBlock(title: "Coffee Break", startHour: 10, startMinute: 30, durationMinutes: 15, category: "Personal", icon: "☕"),
            TemplateTimeBlock(title: "Meetings & Calls", startHour: 11, startMinute: 0, durationMinutes: 60, category: "Work", icon: "📞"),
            TemplateTimeBlock(title: "Lunch Break", startHour: 12, startMinute: 0, durationMinutes: 60, category: "Personal", icon: "🍽️"),
            TemplateTimeBlock(title: "Focused Work", startHour: 13, startMinute: 0, durationMinutes: 120, category: "Work", icon: "💻"),
            TemplateTimeBlock(title: "Admin Tasks", startHour: 15, startMinute: 0, durationMinutes: 30, category: "Work", icon: "📋")
        ]
        
        return RoutineTemplate(
            name: "Productive Workday",
            description: "Optimize your workday with focused sessions and strategic breaks",
            category: "Work",
            icon: "💼",
            blocks: blocks,
            isDefault: true
        )
    }
    
    private func createWorkoutRoutineTemplate() -> RoutineTemplate {
        let blocks = [
            TemplateTimeBlock(title: "Warm-up", startHour: 18, startMinute: 0, durationMinutes: 10, category: "Health", icon: "🏃"),
            TemplateTimeBlock(title: "Strength Training", startHour: 18, startMinute: 10, durationMinutes: 30, category: "Health", icon: "💪"),
            TemplateTimeBlock(title: "Cardio", startHour: 18, startMinute: 40, durationMinutes: 20, category: "Health", icon: "❤️"),
            TemplateTimeBlock(title: "Cool Down & Stretch", startHour: 19, startMinute: 0, durationMinutes: 10, category: "Health", icon: "🧘")
        ]
        
        return RoutineTemplate(
            name: "Evening Workout",
            description: "Complete evening fitness routine with warm-up and cool-down",
            category: "Health",
            icon: "💪",
            blocks: blocks,
            isDefault: true
        )
    }
    
    // MARK: - Premium Features
    
    var canCreateNewTemplate: Bool {
        let userTemplateCount = templates.filter { !$0.isDefault }.count
        return premiumManager.canCreateTemplate(currentTemplateCount: userTemplateCount)
    }
    
    var remainingFreeTemplates: Int {
        let userTemplateCount = templates.filter { !$0.isDefault }.count
        return max(0, PremiumManager.freeTemplateLimit - userTemplateCount)
    }
    
    func clearError() {
        errorMessage = nil
    }
}

// MARK: - Template Errors
enum TemplateError: Error, LocalizedError {
    case premiumRequired
    case cannotDeleteDefault
    case invalidBlocks
    
    var errorDescription: String? {
        switch self {
        case .premiumRequired:
            return "Premium subscription required to create more templates"
        case .cannotDeleteDefault:
            return "Cannot delete default templates"
        case .invalidBlocks:
            return "Template contains invalid time blocks"
        }
    }
}

// MARK: - Template Extensions
extension RoutineTemplate {
    var totalDuration: Int {
        blocks.reduce(0) { $0 + $1.durationMinutes }
    }
    
    var formattedDuration: String {
        let hours = totalDuration / 60
        let minutes = totalDuration % 60
        
        if hours > 0 && minutes > 0 {
            return "\(hours)h \(minutes)m"
        } else if hours > 0 {
            return "\(hours)h"
        } else {
            return "\(minutes)m"
        }
    }
    
    var blockCount: Int {
        blocks.count
    }
}
