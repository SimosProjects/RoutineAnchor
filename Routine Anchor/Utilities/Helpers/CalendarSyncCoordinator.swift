//
//  Untitled.swift
//  Routine Anchor
//
//  Created by Christopher Simonson on 9/14/25.
//

import EventKit
import SwiftData

@MainActor
final class CalendarSyncCoordinator: NSObject {
    private let store: EKEventStore
    private let modelContext: ModelContext

    init(store: EKEventStore, modelContext: ModelContext) {
        self.store = store
        self.modelContext = modelContext
        super.init()

        // Selector-based observer avoids the non-Sendable token entirely
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(eventStoreChanged(_:)),
            name: .EKEventStoreChanged,
            object: store
        )
    }

    deinit {
        // Safe in nonisolated deinit because we aren't reading any non-Sendable token
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func eventStoreChanged(_ note: Notification) {
        Task { @MainActor in
            await handleEventStoreChanged()
        }
    }

    private func handleEventStoreChanged() async {
        let descriptor = FetchDescriptor<TimeBlock>(
            predicate: #Predicate<TimeBlock> { $0.calendarEventId != nil }
        )
        let linkedBlocks = (try? modelContext.fetch(descriptor)) ?? []
        var didChange = false

        for block in linkedBlocks {
            guard let eventId = block.calendarEventId else { continue }
            if store.event(withIdentifier: eventId) == nil {
                block.calendarEventId = nil
                block.calendarId = nil
                block.calendarLastModified = Date()
                didChange = true
            }
        }

        if didChange {
            try? modelContext.save()
            NotificationCenter.default.post(name: .refreshTodayView, object: nil)
            NotificationCenter.default.post(name: .refreshScheduleView, object: nil)
        }
    }
}
