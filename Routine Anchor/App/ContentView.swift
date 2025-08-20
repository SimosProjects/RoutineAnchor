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
    @Environment(\.premiumManager) private var premiumManager
    @EnvironmentObject private var authManager: AuthenticationManager
    @EnvironmentObject private var adManager: AdManager
    @State private var showOnboarding = true
    
    var body: some View {
        Group {
            if showOnboarding {
                OnboardingFlow(showOnboarding: $showOnboarding)
            } else {
                MainTabView()
                    .environment(DataManager(modelContext: modelContext))
                    .environmentObject(authManager)
                    .environmentObject(adManager)
            }
        }
        .onAppear {
            checkFirstLaunch()
        }
    }
    
    private func checkFirstLaunch() {
        // Handle UI test state if needed
        #if DEBUG
        handleUITestState()
        #endif
        
        // Check if onboarding has been completed
        let hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
        showOnboarding = !hasCompletedOnboarding
        
        #if DEBUG
        // Log the state for debugging
        print("📱 ContentView - Onboarding completed: \(hasCompletedOnboarding), showing: \(showOnboarding)")
        #endif
    }
    
    #if DEBUG
    /// Handle UI test specific state checks
    private func handleUITestState() {
        // Check if we're in UI test mode
        let isUITesting = ProcessInfo.processInfo.arguments.contains("--uitesting") ||
                         ProcessInfo.processInfo.environment["UITEST_MODE"] == "1"
        
        guard isUITesting else { return }
        
        // Check if we should force onboarding to show
        let shouldResetOnboarding = ProcessInfo.processInfo.arguments.contains("--reset-onboarding") ||
                                   ProcessInfo.processInfo.environment["RESET_ONBOARDING"] == "1"
        
        if shouldResetOnboarding {
            // Double-check that the reset happened
            let hasCompleted = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
            if hasCompleted {
                // Force reset if it didn't happen in App init
                UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")
                UserDefaults.standard.synchronize()
                print("⚠️ UI Test: Force resetting onboarding in ContentView")
            } else {
                print("✅ UI Test: Onboarding already reset")
            }
        }
        
        // Log current state for debugging
        print("🧪 UI Test Mode Active")
        print("   - Reset Onboarding: \(shouldResetOnboarding)")
        print("   - Current hasCompletedOnboarding: \(UserDefaults.standard.bool(forKey: "hasCompletedOnboarding"))")
    }
    #endif
}

#Preview {
    ContentView()
        .modelContainer(for: [TimeBlock.self, DailyProgress.self, RoutineTemplate.self], inMemory: true)
        .environment(PremiumManager())
}
