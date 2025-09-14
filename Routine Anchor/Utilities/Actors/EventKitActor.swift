//
//  EventKitActor.swift
//  Routine Anchor
//
//  Created by Christopher Simonson on 9/12/25.
//

import Foundation
@preconcurrency import EventKit

@MainActor
final class EventKitActor {
    private let store = EKEventStore()

    // MARK: Authorization
    func authorizationStatus() -> EKAuthorizationStatus {
        EKEventStore.authorizationStatus(for: .event)
    }

    func requestAccess() async throws {
        print("Requesting calendar access…")
        _ = try await store.requestFullAccessToEvents()
        print("Calendar access returned")
    }

    // MARK: Calendars
    func calendars() -> [EKCalendar] {
        store.calendars(for: .event)
    }

    func calendar(withIdentifier id: String) -> EKCalendar? {
        store.calendar(withIdentifier: id)
    }

    // MARK: Events
    func createEvent(
        in calendarId: String,
        title: String,
        notes: String? = nil,
        start: Date,
        end: Date
    ) throws -> (eventId: String, lastModified: Date?) {
        guard let cal = store.calendar(withIdentifier: calendarId) else {
            throw NSError(domain: "EventKitClient", code: 1,
                          userInfo: [NSLocalizedDescriptionKey: "Calendar not found"])
        }
        let ev = EKEvent(eventStore: store)
        ev.calendar = cal
        ev.title = title
        ev.notes = notes
        ev.startDate = start
        ev.endDate = end
        try store.save(ev, span: .thisEvent, commit: true)
        return (ev.eventIdentifier, ev.lastModifiedDate)
    }

    func updateEvent(
        eventId: String,
        title: String? = nil,
        notes: String? = nil,
        start: Date? = nil,
        end: Date? = nil
    ) throws -> (eventId: String, lastModified: Date?) {
        guard let ev = store.event(withIdentifier: eventId) else {
            throw NSError(domain: "EventKitClient", code: 2,
                          userInfo: [NSLocalizedDescriptionKey: "Event not found"])
        }
        if let title { ev.title = title }
        if let notes { ev.notes = notes }
        if let start { ev.startDate = start }
        if let end { ev.endDate = end }
        try store.save(ev, span: .thisEvent, commit: true)
        return (ev.eventIdentifier, ev.lastModifiedDate)
    }

    func deleteEvent(eventId: String) throws {
        guard let ev = store.event(withIdentifier: eventId) else { return }
        try store.remove(ev, span: .thisEvent, commit: true)
    }
    
    // Delete one event by its identifier (safe if already gone)
    func deleteEvent(withIdentifier id: String) throws {
        if let ev = store.event(withIdentifier: id) {
            try store.remove(ev, span: .thisEvent, commit: true)
        }
    }

    // Convenience: delete all linked events for a set of blocks
    func deleteEvents(for blocks: [TimeBlock]) {
        for block in blocks {
            if let id = block.calendarEventId {
                try? deleteEvent(withIdentifier: id)
            }
        }
    }

    func events(in range: DateInterval, calendarIds: [String]? = nil) -> [EKEvent] {
        let cals: [EKCalendar]
        if let ids = calendarIds, !ids.isEmpty {
            cals = ids.compactMap { store.calendar(withIdentifier: $0) }
        } else {
            cals = store.calendars(for: .event)
        }
        let predicate = store.predicateForEvents(withStart: range.start, end: range.end, calendars: cals)
        return store.events(matching: predicate)
    }
}

