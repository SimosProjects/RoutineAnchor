//
//  CalendarLinkSection.swift
//  Routine Anchor
//

import SwiftUI
import EventKit
import UIKit

struct CalendarLinkSection: View {
    @Binding var linkToCalendar: Bool
    @Binding var selectedCalendarId: String?

    @StateObject private var vm = CalendarAccessViewModel()
    @State private var showChooser = false
    @State private var searchText = ""

    private var isLinked: Bool { (selectedCalendarId != nil) && linkToCalendar }

    // Unified items for the sheet list
    private var items: [(id: String, title: String, color: Color)] {
        vm.calendars.map { cal in
            (id: cal.calendarIdentifier,
             title: cal.title,
             color: Color(UIColor(cgColor: cal.cgColor)))
        }
        .filter { searchText.isEmpty ? true : $0.title.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        Section {
            // Main row — tap anywhere to open the chooser
            HStack {
                Label("Apple Calendar", systemImage: "calendar")
                    .labelStyle(.titleAndIcon)
                    .font(.body)

                Spacer(minLength: 12)

                if let id = selectedCalendarId,
                   let name = vm.name(for: id),
                   let dot = vm.color(for: id),
                   linkToCalendar {

                    HStack(spacing: 6) {
                        Circle().fill(dot).frame(width: 10, height: 10)
                        Text(name)
                            .font(.subheadline)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                } else {
                    Text("Not Linked")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Image(systemName: "chevron.right")
                    .font(.footnote)
                    .foregroundStyle(.tertiary)
            }
            .contentShape(Rectangle())
            .onTapGesture { showChooser = true }
            .accessibilityAddTraits(.isButton)

            // Helper hint (optional)
            if let id = selectedCalendarId,
               let name = vm.name(for: id),
               linkToCalendar {
                Label("Will create events in “\(name)”", systemImage: "calendar")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        } header: {
            Text("Calendar")
        }
        .onAppear {
            if vm.authState == .authorized, vm.calendars.isEmpty {
                vm.loadCalendars()
            }
        }
        .sheet(isPresented: $showChooser) {
            chooserSheet
        }
        .animation(.easeInOut(duration: 0.2), value: isLinked)
    }

    // MARK: - Chooser Sheet

    @ViewBuilder
    private var chooserSheet: some View {
        NavigationStack {
            switch vm.authState {
            case .notDetermined, .unknown:
                VStack(spacing: 16) {
                    Image(systemName: "lock.open")
                        .font(.system(size: 42, weight: .light))
                    Text("Allow Calendar Access")
                        .font(.headline)
                    Text("Grant access to choose a calendar and keep your time blocks in sync.")
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 24)
                    Button {
                        Task { @MainActor in
                            await vm.requestAccess()
                            if vm.authState == .authorized { vm.loadCalendars() }
                        }
                    } label: {
                        Label("Allow Access", systemImage: "hand.point.up.left.fill")
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
                .navigationTitle("Apple Calendar")
                .navigationBarTitleDisplayMode(.inline)

            case .denied, .restricted:
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 42, weight: .light))
                    Text("Calendar Access Disabled")
                        .font(.headline)
                    Text("Enable access in Settings → Privacy & Security → Calendars.")
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 24)
                    Link(destination: URL(string: UIApplication.openSettingsURLString)!) {
                        Label("Open Settings", systemImage: "gearshape.fill")
                    }
                }
                .padding()
                .navigationTitle("Apple Calendar")
                .navigationBarTitleDisplayMode(.inline)

            case .authorized:
                if vm.calendars.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "calendar.badge.exclamationmark")
                            .font(.system(size: 42, weight: .light))
                        Text("No Calendars Found").font(.headline)
                        Text("Add a calendar account in the Calendar app or iOS Settings, then tap Refresh.")
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 24)
                        Button("Refresh") { vm.loadCalendars() }
                    }
                    .padding()
                    .navigationTitle("Apple Calendar")
                    .navigationBarTitleDisplayMode(.inline)
                } else {
                    List {
                        // Unlink option
                        Section {
                            Button {
                                selectedCalendarId = nil
                                linkToCalendar = false
                                showChooser = false
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            } label: {
                                HStack {
                                    Image(systemName: "slash.circle")
                                    Text("Unlink")
                                    Spacer()
                                    if !isLinked { Image(systemName: "checkmark") }
                                }
                            }
                        }

                        // Calendars
                        Section("Calendars") {
                            ForEach(items, id: \.id) { item in
                                HStack {
                                    Circle().fill(item.color).frame(width: 12, height: 12)
                                    Text(item.title)
                                    Spacer()
                                    if item.id == selectedCalendarId, linkToCalendar {
                                        Image(systemName: "checkmark").foregroundStyle(.tint)
                                    }
                                }
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    selectedCalendarId = item.id
                                    linkToCalendar = true
                                    showChooser = false
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                    .navigationTitle("Apple Calendar")
                    .navigationBarTitleDisplayMode(.inline)
                    .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .automatic))
                }
            }
        }
    }
}

// MARK: - Previews

#Preview("Linked") {
    NavigationStack {
        Form {
            CalendarLinkSection(
                linkToCalendar: .constant(true),
                selectedCalendarId: .constant("work")
            )
        }
        .navigationTitle("Add Time Block")
    }
}

#Preview("Not Linked") {
    NavigationStack {
        Form {
            CalendarLinkSection(
                linkToCalendar: .constant(false),
                selectedCalendarId: .constant(nil)
            )
        }
        .navigationTitle("Add Time Block")
    }
}
