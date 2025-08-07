//
//  OnboardingViewModel.swift
//  Routine Anchor
//
//  Created by Christopher Simonson on 7/19/25.
//
import SwiftUI
import UserNotifications

@Observable
class OnboardingViewModel {
    // MARK: - Published Properties
    var currentStep: OnboardingStep = .welcome
    var notificationPermissionGranted = false
    var isRequestingPermission = false
    var errorMessage: String?
    var onboardingProgress: Double = 0.0
    
    // MARK: - Onboarding Steps
    enum OnboardingStep: Int, CaseIterable {
        case welcome = 0
        case permissions = 1
        case setup = 2
        
        var title: String {
            switch self {
            case .welcome: return "Welcome"
            case .permissions: return "Notifications"
            case .setup: return "Ready to Go"
            }
        }
        
        var progress: Double {
            return Double(self.rawValue + 1) / Double(OnboardingStep.allCases.count)
        }
    }
    
    // MARK: - Initialization
    init() {
        updateProgress()
    }
    
    // MARK: - Navigation
    
    /// Move to the next onboarding step
    func nextStep() {
        withAnimation(.easeInOut(duration: 0.3)) {
            switch currentStep {
            case .welcome:
                currentStep = .permissions
            case .permissions:
                currentStep = .setup
            case .setup:
                // Handled by parent - completion
                break
            }
            updateProgress()
        }
    }
    
    /// Move to the previous onboarding step
    func previousStep() {
        withAnimation(.easeInOut(duration: 0.3)) {
            switch currentStep {
            case .welcome:
                // Can't go back from welcome
                break
            case .permissions:
                currentStep = .welcome
            case .setup:
                currentStep = .permissions
            }
            updateProgress()
        }
    }
    
    /// Skip to a specific step
    func skipToStep(_ step: OnboardingStep) {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentStep = step
            updateProgress()
        }
    }
    
    // MARK: - Permission Management
    
    /// Request notification permissions
    @MainActor
    func requestNotificationPermission() {
        isRequestingPermission = true
        errorMessage = nil
        
        Task {
            do {
                let granted = try await UNUserNotificationCenter.current()
                    .requestAuthorization(options: [.alert, .badge, .sound])
                
                await MainActor.run {
                    self.notificationPermissionGranted = granted
                    self.isRequestingPermission = false
                    
                    if granted {
                        HapticManager.shared.success()
                        // Schedule welcome notification
                        self.scheduleWelcomeNotification()
                    } else {
                        HapticManager.shared.lightImpact()
                    }
                    
                    // Move to next step regardless
                    self.nextStep()
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to request permissions: \(error.localizedDescription)"
                    self.isRequestingPermission = false
                    self.notificationPermissionGranted = false
                    HapticManager.shared.error()
                    
                    // Still move to next step
                    self.nextStep()
                }
            }
        }
    }
    
    /// Skip notification permissions
    @MainActor
    func skipPermissions() {
        notificationPermissionGranted = false
        HapticManager.shared.lightImpact()
        nextStep()
    }
    
    /// Check current notification permission status
    @MainActor
    func checkNotificationPermissions() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.notificationPermissionGranted = settings.authorizationStatus == .authorized
            }
        }
    }
    
    // MARK: - Onboarding Completion
    
    /// Mark onboarding as completed
    @MainActor
    func completeOnboarding() {
        // Save onboarding completion
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        UserDefaults.standard.set(Date(), forKey: "onboardingCompletedAt")
        
        // Save permission preferences
        UserDefaults.standard.set(notificationPermissionGranted, forKey: "notificationsEnabled")
        
        // Analytics/tracking (if implemented)
        trackOnboardingCompletion()
        
        // Success feedback
        HapticManager.shared.success()
    }
    
    /// Reset onboarding (for development/testing)
    func resetOnboarding() {
        UserDefaults.standard.removeObject(forKey: "hasCompletedOnboarding")
        UserDefaults.standard.removeObject(forKey: "onboardingCompletedAt")
        currentStep = .welcome
        notificationPermissionGranted = false
        updateProgress()
    }
    
    // MARK: - Welcome Notification
    
    /// Schedule a welcome notification after onboarding
    private func scheduleWelcomeNotification() {
        guard notificationPermissionGranted else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Welcome to Routine Anchor!"
        content.body = "Ready to build your first daily routine? Tap to get started."
        content.sound = .default
        content.badge = 1
        
        // Schedule for 10 minutes after onboarding completion
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 600, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "welcomeNotification",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to schedule welcome notification: \(error)")
            }
        }
    }
    
    // MARK: - Helper Methods
    
    /// Update progress indicator
    private func updateProgress() {
        onboardingProgress = currentStep.progress
    }
    
    /// Track onboarding completion for analytics
    private func trackOnboardingCompletion() {
        // This would integrate with your analytics service
        // For now, just log completion
        print("Onboarding completed at: \(Date())")
        print("Notifications enabled: \(notificationPermissionGranted)")
    }
    
    /// Clear error messages
    func clearError() {
        errorMessage = nil
    }
    
    // MARK: - Validation
    
    /// Check if we can proceed to the next step
    var canProceedToNextStep: Bool {
        switch currentStep {
        case .welcome:
            return true // Always can proceed from welcome
        case .permissions:
            return true // Can proceed whether permissions granted or not
        case .setup:
            return true // Final step, ready to complete
        }
    }
    
    /// Check if onboarding has been completed before
    static func hasCompletedOnboarding() -> Bool {
        return UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
    }
    
    /// Get the date when onboarding was completed (if available)
    static func onboardingCompletionDate() -> Date? {
        return UserDefaults.standard.object(forKey: "onboardingCompletedAt") as? Date
    }
}

// MARK: - Onboarding Step Details
extension OnboardingViewModel {
    /// Get detailed information for the current step
    var currentStepInfo: OnboardingStepInfo {
        switch currentStep {
        case .welcome:
            return OnboardingStepInfo(
                title: "Welcome to Routine Anchor",
                subtitle: "Build consistent daily habits",
                description: "Create time-blocked routines and track your progress with gentle accountability.",
                primaryButtonTitle: "Get Started",
                secondaryButtonTitle: nil,
                features: [
                    "Smart time-based reminders",
                    "Simple check-ins for completed tasks",
                    "Daily progress tracking and insights"
                ]
            )
            
        case .permissions:
            return OnboardingStepInfo(
                title: "Stay on Track",
                subtitle: "Enable notifications",
                description: "Get gentle reminders when each time block begins, so you never miss a scheduled activity.",
                primaryButtonTitle: "Enable Notifications",
                secondaryButtonTitle: "Maybe Later",
                features: [
                    "Never miss a scheduled activity",
                    "Stay focused on your daily goals",
                    "Customize or disable anytime in Settings"
                ]
            )
            
        case .setup:
            return OnboardingStepInfo(
                title: "You're All Set!",
                subtitle: "Ready to build habits",
                description: "Create your first routine to get started with time-blocked productivity.",
                primaryButtonTitle: "Start Building Habits",
                secondaryButtonTitle: nil,
                features: [
                    "Create your first time block",
                    "Follow your schedule with reminders",
                    "Track your progress and celebrate wins"
                ]
            )
        }
    }
}

// MARK: - Onboarding Step Info Model
struct OnboardingStepInfo {
    let title: String
    let subtitle: String
    let description: String
    let primaryButtonTitle: String
    let secondaryButtonTitle: String?
    let features: [String]
}
