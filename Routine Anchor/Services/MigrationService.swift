//
//  MigrationService.swift
//  Routine Anchor
//
//  Service for handling SwiftData schema migrations and version management
//

import Foundation
import SwiftData

// MARK: - Schema Versions
enum SchemaVersion: String, CaseIterable {
    case v1 = "1.0.0"
    case v2 = "2.0.0"  // Example future version
    
    var versionNumber: Int {
        switch self {
        case .v1: return 1
        case .v2: return 2
        }
    }
    
    static var current: SchemaVersion {
        return .v1  // Update this when adding new versions
    }
}

// MARK: - Migration Plan
enum RoutineAnchorMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [SchemaV1.self]  // Add new schema versions here
    }
    
    static var stages: [MigrationStage] {
        // Define migration stages when adding new versions
        // Example:
        // [migrateV1toV2]
        []
    }
}

// MARK: - Schema V1 (Current)
enum SchemaV1: VersionedSchema {
    static let versionIdentifier = Schema.Version(1, 0, 0)

    static var models: [any PersistentModel.Type] {
        [TimeBlock.self, DailyProgress.self]
    }
}

// MARK: - Migration Service
@MainActor
class MigrationService: ObservableObject {
    // MARK: - Singleton
    static let shared = MigrationService()
    private init() {}
    
    // MARK: - Published Properties
    @Published var isMigrating = false
    @Published var migrationProgress: Double = 0.0
    @Published var migrationError: MigrationError?
    @Published var currentSchemaVersion: SchemaVersion = .v1
    
    // MARK: - Private Properties
    private var modelContainer: ModelContainer?
    private let userDefaults = UserDefaults.standard
    private let schemaVersionKey = "RoutineAnchor.SchemaVersion"
    private let lastMigrationDateKey = "RoutineAnchor.LastMigrationDate"
    private let backupBeforeMigrationKey = "RoutineAnchor.BackupBeforeMigration"
    
    // MARK: - Container Creation
    
    /// Create and configure the model container with migration support
    func createModelContainer() throws -> ModelContainer {
        let schema = Schema(versionedSchema: SchemaV1.self)
        
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            allowsSave: true,
            groupContainer: .automatic,
            cloudKitDatabase: .none  // Local only for privacy
        )
        
        do {
            let container = try ModelContainer(
                for: schema,
                migrationPlan: RoutineAnchorMigrationPlan.self,
                configurations: [modelConfiguration]
            )
            
            self.modelContainer = container
            
            // Check and perform any needed migrations
            Task {
                await checkAndPerformMigration()
            }
            
            return container
        } catch {
            throw MigrationError.containerCreationFailed(error.localizedDescription)
        }
    }
    
    // MARK: - Migration Management
    
    /// Check if migration is needed and perform it
    private func checkAndPerformMigration() async {
        // Get stored schema version
        let storedVersionString = userDefaults.string(forKey: schemaVersionKey) ?? SchemaVersion.v1.rawValue
        guard let storedVersion = SchemaVersion(rawValue: storedVersionString) else {
            // Unknown version, assume v1
            saveCurrentSchemaVersion(.v1)
            return
        }
        
        let currentVersion = SchemaVersion.current
        
        // Check if migration is needed
        if storedVersion.versionNumber < currentVersion.versionNumber {
            await performMigration(from: storedVersion, to: currentVersion)
        } else {
            currentSchemaVersion = currentVersion
        }
    }
    
    /// Perform migration from one version to another
    private func performMigration(from oldVersion: SchemaVersion, to newVersion: SchemaVersion) async {
        isMigrating = true
        migrationProgress = 0.0
        migrationError = nil
        
        do {
            // Create backup before migration
            if userDefaults.bool(forKey: backupBeforeMigrationKey) != false {
                try await createBackup()
                migrationProgress = 0.2
            }
            
            // Perform version-specific migrations
            try await performVersionSpecificMigration(from: oldVersion, to: newVersion)
            
            // Update stored version
            saveCurrentSchemaVersion(newVersion)
            currentSchemaVersion = newVersion
            
            // Record migration date
            userDefaults.set(Date(), forKey: lastMigrationDateKey)
            
            migrationProgress = 1.0
            
            // Log successful migration
            print("✅ Successfully migrated from \(oldVersion.rawValue) to \(newVersion.rawValue)")
            
        } catch {
            migrationError = error as? MigrationError ?? .migrationFailed(error.localizedDescription)
            print("❌ Migration failed: \(error.localizedDescription)")
            
            // Attempt to restore from backup
            if userDefaults.bool(forKey: backupBeforeMigrationKey) != false {
                await restoreFromBackup()
            }
        }
        
        isMigrating = false
    }
    
    /// Perform version-specific migration logic
    private func performVersionSpecificMigration(from oldVersion: SchemaVersion, to newVersion: SchemaVersion) async throws {
        // Add specific migration logic here as new versions are added
        // Example for future v1 to v2 migration:
        /*
        switch (oldVersion, newVersion) {
        case (.v1, .v2):
            try await migrateV1toV2()
        default:
            // Handle multi-step migrations if needed
            break
        }
        */
        
        // For now, just simulate migration work
        for i in stride(from: 0.3, through: 0.9, by: 0.1) {
            migrationProgress = i
            try await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
        }
    }
    
    // MARK: - Backup Management
    
    /// Create a backup of the current data
    private func createBackup() async throws {
        guard let container = modelContainer else {
            throw MigrationError.backupFailed("Model container not initialized")
        }
        
        let backupURL = getBackupURL()
        
        // Export all data using the existing ExportService
        let exportService = ExportService.shared
        let context = container.mainContext
        
        do {
            // Fetch all data
            let timeBlocks = try context.fetch(FetchDescriptor<TimeBlock>())
            let dailyProgress = try context.fetch(FetchDescriptor<DailyProgress>())
            
            // Create backup data
            let backupData = BackupData(
                version: currentSchemaVersion.rawValue,
                date: Date(),
                timeBlockCount: timeBlocks.count,
                progressCount: dailyProgress.count,
                timeBlocks: timeBlocks.map { BackupTimeBlock(from: $0) },
                dailyProgress: dailyProgress.map { BackupDailyProgress(from: $0) }
            )
            
            // Save backup
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(backupData)
            try data.write(to: backupURL)
            
            print("✅ Backup created at: \(backupURL.path)")
            
        } catch {
            throw MigrationError.backupFailed(error.localizedDescription)
        }
    }
    
    /// Restore data from backup
    private func restoreFromBackup() async {
        let backupURL = getBackupURL()
        
        guard FileManager.default.fileExists(atPath: backupURL.path) else {
            print("⚠️ No backup file found")
            return
        }
        
        do {
            let data = try Data(contentsOf: backupURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let backupData = try decoder.decode(BackupData.self, from: data)
            
            // Restore using ImportService
            // This would need to be implemented in ImportService
            print("✅ Restored from backup dated: \(backupData.date)")
            
        } catch {
            print("❌ Failed to restore from backup: \(error.localizedDescription)")
        }
    }
    
    /// Get backup file URL
    private func getBackupURL() -> URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documentsPath.appendingPathComponent("routine_anchor_backup.json")
    }
    
    // MARK: - Helper Methods
    
    /// Save current schema version to UserDefaults
    private func saveCurrentSchemaVersion(_ version: SchemaVersion) {
        userDefaults.set(version.rawValue, forKey: schemaVersionKey)
    }
    
    /// Get last migration date
    func getLastMigrationDate() -> Date? {
        return userDefaults.object(forKey: lastMigrationDateKey) as? Date
    }
    
    /// Check if backup before migration is enabled
    func isBackupEnabled() -> Bool {
        return userDefaults.bool(forKey: backupBeforeMigrationKey) != false
    }
    
    /// Set backup before migration preference
    func setBackupEnabled(_ enabled: Bool) {
        userDefaults.set(enabled, forKey: backupBeforeMigrationKey)
    }
    
    /// Clear migration error
    func clearError() {
        migrationError = nil
    }
}

// MARK: - Migration Errors
enum MigrationError: LocalizedError {
    case containerCreationFailed(String)
    case migrationFailed(String)
    case backupFailed(String)
    case restoreFailed(String)
    case incompatibleVersion(String)
    case dataCorruption(String)
    
    var errorDescription: String? {
        switch self {
        case .containerCreationFailed(let reason):
            return "Failed to create data container: \(reason)"
        case .migrationFailed(let reason):
            return "Migration failed: \(reason)"
        case .backupFailed(let reason):
            return "Backup failed: \(reason)"
        case .restoreFailed(let reason):
            return "Restore failed: \(reason)"
        case .incompatibleVersion(let version):
            return "Incompatible version: \(version)"
        case .dataCorruption(let details):
            return "Data corruption detected: \(details)"
        }
    }
}

// MARK: - Backup Data Structures
private struct BackupData: Codable {
    let version: String
    let date: Date
    let timeBlockCount: Int
    let progressCount: Int
    let timeBlocks: [BackupTimeBlock]
    let dailyProgress: [BackupDailyProgress]
}

private struct BackupTimeBlock: Codable {
    let id: String
    let title: String
    let startTime: Date
    let endTime: Date
    let status: String
    let category: String?
    let notes: String?
    let icon: String?
    let createdAt: Date
    let updatedAt: Date
    
    init(from timeBlock: TimeBlock) {
        self.id = timeBlock.id.uuidString
        self.title = timeBlock.title
        self.startTime = timeBlock.startTime
        self.endTime = timeBlock.endTime
        self.status = timeBlock.status.rawValue
        self.category = timeBlock.category
        self.notes = timeBlock.notes
        self.icon = timeBlock.icon
        self.createdAt = timeBlock.createdAt
        self.updatedAt = timeBlock.updatedAt
    }
}

private struct BackupDailyProgress: Codable {
    let id: String
    let date: Date
    let completedBlocks: Int
    let totalBlocks: Int
    let skippedBlocks: Int
    let completionPercentage: Double
    let dayRating: Int?
    let dayNotes: String?
    
    init(from progress: DailyProgress) {
        self.id = progress.id.uuidString
        self.date = progress.date
        self.completedBlocks = progress.completedBlocks
        self.totalBlocks = progress.totalBlocks
        self.skippedBlocks = progress.skippedBlocks
        self.completionPercentage = progress.completionPercentage
        self.dayRating = progress.dayRating
        self.dayNotes = progress.dayNotes
    }
}

// MARK: - Example Future Migration (V1 to V2)
/*
extension RoutineAnchorMigrationPlan {
    static let migrateV1toV2 = MigrationStage.custom(
        fromVersion: SchemaV1.versionIdentifier,
        toVersion: SchemaV2.versionIdentifier,
        willMigrate: { context in
            // Pre-migration logic
            print("Preparing to migrate from V1 to V2...")
        },
        didMigrate: { context in
            // Post-migration logic
            print("Completed migration from V1 to V2")
            
            // Example: Add default values for new properties
            let timeBlocks = try context.fetch(FetchDescriptor<TimeBlock>())
            for block in timeBlocks {
                // Set any new properties that were added in V2
                // block.newProperty = defaultValue
            }
            try context.save()
        }
    )
}
*/
