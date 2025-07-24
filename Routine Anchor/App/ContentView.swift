//
//  ContentView.swift
//  Routine Anchor
//
//  Created by Christopher Simonson on 7/19/25.
//
import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var showOnboarding = true
    
    var body: some View {
        Group {
            if showOnboarding {
                OnboardingFlow(showOnboarding: $showOnboarding)
            } else {
                MainTabView()
                    .environment(DataManager(modelContext: modelContext))
            }
        }
        .onAppear {
            checkFirstLaunch()
        }
    }
    
    private func checkFirstLaunch() {
        let hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
        showOnboarding = !hasCompletedOnboarding
    }
}

#Preview {
    ContentView()
}
