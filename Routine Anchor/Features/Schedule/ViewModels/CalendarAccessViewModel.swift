//
//  CalendarAccessViewModel.swift
//  Routine Anchor
//

import Foundation
@preconcurrency import EventKit
import SwiftUI
import SwiftData

@MainActor
final class CalendarAccessViewModel: ObservableObject {
    enum AuthState {
        case unknown, notDetermined, authorized, denied, restricted
    }

    @Published var authState: AuthState = .unknown
    @Published var calendars: [EKCalendar] = []

    private var modelContext: ModelContext?
    private let store = EKEventStore()
    private var syncCoordinator: CalendarSyncCoordinator?

    init() {
        refreshAuthState()
        if case .authorized = authState {
            loadCalendars()
            startSyncIfNeeded()
        }
    }
    
    func attachModelContext(_ ctx: ModelContext) {
        self.modelContext = ctx
        // If already authorized when this arrives, start syncing
        startSyncIfNeeded()
    }

    func refreshAuthState() {
        switch EKEventStore.authorizationStatus(for: .event) {
        case .authorized, .fullAccess:
            authState = .authorized
        case .writeOnly:
            authState = .authorized
        case .notDetermined:
            authState = .notDetermined
        case .denied:
            authState = .denied
        case .restricted:
            authState = .restricted
        @unknown default:
            authState = .unknown
        }
        
        // If user revoked access, stop syncing
        if case .authorized = authState {
            startSyncIfNeeded()
        } else {
            syncCoordinator = nil
        }
    }

    func requestAccess() async {
        let localStore = EKEventStore()
        do {
            _ = try await localStore.requestFullAccessToEvents()
        } catch {
            // ignore – we reflect the state via refreshAuthState() below
        }

        // Now reflect UI state and load calendars if permitted
        refreshAuthState()
        if case .authorized = authState {
            loadCalendars()
            startSyncIfNeeded()
        }
    }

    func loadCalendars() {
        calendars = store
            .calendars(for: .event)
            .sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
    }

    func name(for id: String?) -> String? {
        guard let id,
              let cal = calendars.first(where: { $0.calendarIdentifier == id }) else { return nil }
        return cal.title
    }
    
    func color(for id: String?) -> Color? {
        guard let id,
              let cal = calendars.first(where: { $0.calendarIdentifier == id }) else { return nil }
        return Color(UIColor(cgColor: cal.cgColor))
    }
    
    private func startSyncIfNeeded() {
        guard syncCoordinator == nil,
              case .authorized = authState,
              let ctx = modelContext else { return }

        syncCoordinator = CalendarSyncCoordinator(store: store, modelContext: ctx)
    }
}

extension CalendarAccessViewModel {
    func reconcileLinkedBlocksIfNeeded() async {
        guard case .authorized = authState, let ctx = modelContext else { return }
        // Same logic as the coordinator:
        let descriptor = FetchDescriptor<TimeBlock>(
            predicate: #Predicate<TimeBlock> { $0.calendarEventId != nil }
        )
        let linked = (try? ctx.fetch(descriptor)) ?? []
        var didChange = false

        for block in linked {
            if let id = block.calendarEventId, store.event(withIdentifier: id) == nil {
                block.calendarEventId = nil
                block.calendarId = nil
                block.calendarLastModified = Date()
                didChange = true
            }
        }

        if didChange {
            try? ctx.save()
            NotificationCenter.default.post(name: .refreshTodayView, object: nil)
            NotificationCenter.default.post(name: .refreshScheduleView, object: nil)
        }
    }
}
