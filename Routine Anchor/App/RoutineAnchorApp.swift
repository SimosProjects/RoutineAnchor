//
//  Routine_AnchorApp.swift
//  Routine Anchor
//
//  Created by Christopher Simonson on 7/19/25.
//
import SwiftUI
import SwiftData

@main
struct RoutineAnchorApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(for: [TimeBlock.self, DailyProgress.self])
        }
    }
}
