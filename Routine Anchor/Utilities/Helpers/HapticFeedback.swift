//
//  HapticFeedback.swift
//  Routine Anchor
//
//  Created by Christopher Simonson on 7/21/25.
//  Swift 6 Compatible Version
//
import UIKit
import SwiftUI

/// Manages haptic feedback throughout the app with premium patterns
@MainActor
final class HapticManager: Sendable {
    static let shared = HapticManager()
    
    // MARK: - Private Properties
    private let lightImpactGenerator = UIImpactFeedbackGenerator(style: .light)
    private let mediumImpactGenerator = UIImpactFeedbackGenerator(style: .medium)
    private let heavyImpactGenerator = UIImpactFeedbackGenerator(style: .heavy)
    private let selectionGenerator = UISelectionFeedbackGenerator()
    private let notificationGenerator = UINotificationFeedbackGenerator()
    
    private init() {
        // Prepare generators for better performance
        prepareGenerators()
    }
    
    // MARK: - Preparation
    private func prepareGenerators() {
        lightImpactGenerator.prepare()
        mediumImpactGenerator.prepare()
        heavyImpactGenerator.prepare()
        selectionGenerator.prepare()
        notificationGenerator.prepare()
    }
    
    // MARK: - Basic Impact Feedback
    
    /// Light impact - for subtle interactions like button taps
    func lightImpact() {
        guard isHapticsEnabled else { return }
        lightImpactGenerator.impactOccurred()
    }
    
    /// Medium impact - for standard UI interactions
    func mediumImpact() {
        guard isHapticsEnabled else { return }
        mediumImpactGenerator.impactOccurred()
    }
    
    /// Heavy impact - for significant actions
    func heavyImpact() {
        guard isHapticsEnabled else { return }
        heavyImpactGenerator.impactOccurred()
    }
    
    // MARK: - Selection Feedback
    
    /// Selection feedback - for tab changes, picker selections
    func selection() {
        guard isHapticsEnabled else { return }
        selectionGenerator.selectionChanged()
    }
    
    // MARK: - Notification Feedback
    
    /// Success notification - for completed actions
    func success() {
        guard isHapticsEnabled else { return }
        notificationGenerator.notificationOccurred(.success)
    }
    
    /// Warning notification - for important alerts
    func warning() {
        guard isHapticsEnabled else { return }
        notificationGenerator.notificationOccurred(.warning)
    }
    
    /// Error notification - for failed actions
    func error() {
        guard isHapticsEnabled else { return }
        notificationGenerator.notificationOccurred(.error)
    }
    
    // MARK: - Premium Patterns
    
    /// Premium impact with custom intensity - for elevated experiences
    func premiumImpact() {
        guard isHapticsEnabled else { return }
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred(intensity: 0.8)
    }
    
    /// Premium success - double tap for emphasis
    func premiumSuccess() {
        guard isHapticsEnabled else { return }
        notificationGenerator.notificationOccurred(.success)
        
        // Add a second subtle tap for premium feel
        Task {
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            await MainActor.run {
                self.lightImpactGenerator.impactOccurred(intensity: 0.6)
            }
        }
    }
    
    /// Premium selection - enhanced selection feedback
    func premiumSelection() {
        guard isHapticsEnabled else { return }
        selectionGenerator.selectionChanged()
        
        // Add subtle follow-up
        Task {
            try? await Task.sleep(nanoseconds: 50_000_000) // 0.05 seconds
            await MainActor.run {
                self.lightImpactGenerator.impactOccurred(intensity: 0.4)
            }
        }
    }
    
    /// Premium error - more pronounced error feedback
    func premiumError() {
        guard isHapticsEnabled else { return }
        notificationGenerator.notificationOccurred(.error)
        
        // Add vibration pattern for emphasis
        Task {
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            await MainActor.run {
                self.mediumImpactGenerator.impactOccurred(intensity: 0.7)
            }
        }
    }
    
    // MARK: - Context-Specific Patterns
    
    /// Time block completion - celebratory pattern
    func timeBlockCompleted() {
        guard isHapticsEnabled else { return }
        notificationGenerator.notificationOccurred(.success)
        
        Task {
            try? await Task.sleep(nanoseconds: 150_000_000) // 0.15 seconds
            await MainActor.run {
                self.lightImpactGenerator.impactOccurred(intensity: 0.8)
            }
            
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            await MainActor.run {
                self.lightImpactGenerator.impactOccurred(intensity: 0.6)
            }
        }
    }
    
    /// Time block skipped - gentle disappointment
    func timeBlockSkipped() {
        guard isHapticsEnabled else { return }
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred(intensity: 0.5)
    }
    
    /// Time block started - motivational tap
    func timeBlockStarted() {
        guard isHapticsEnabled else { return }
        mediumImpactGenerator.impactOccurred(intensity: 0.9)
    }
    
    /// Routine saved - accomplishment pattern
    func routineSaved() {
        guard isHapticsEnabled else { return }
        mediumImpactGenerator.impactOccurred()
        
        Task {
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            await MainActor.run {
                self.lightImpactGenerator.impactOccurred(intensity: 0.7)
            }
        }
    }
    
    /// Daily goal achieved - celebration pattern
    func dailyGoalAchieved() {
        guard isHapticsEnabled else { return }
        notificationGenerator.notificationOccurred(.success)
        
        Task {
            try? await Task.sleep(nanoseconds: 120_000_000) // 0.12 seconds
            await MainActor.run {
                self.mediumImpactGenerator.impactOccurred(intensity: 0.8)
            }
            
            try? await Task.sleep(nanoseconds: 120_000_000) // 0.12 seconds
            await MainActor.run {
                self.lightImpactGenerator.impactOccurred(intensity: 0.9)
            }
            
            try? await Task.sleep(nanoseconds: 120_000_000) // 0.12 seconds
            await MainActor.run {
                self.lightImpactGenerator.impactOccurred(intensity: 0.6)
            }
        }
    }
    
    /// Navigation transition - smooth transition feel
    func navigationTransition() {
        guard isHapticsEnabled else { return }
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred(intensity: 0.6)
    }
    
    /// Pull to refresh - encouraging feedback
    func pullToRefresh() {
        guard isHapticsEnabled else { return }
        lightImpactGenerator.impactOccurred(intensity: 0.8)
    }
    
    /// Data refresh completed
    func refreshCompleted() {
        guard isHapticsEnabled else { return }
        lightImpactGenerator.impactOccurred(intensity: 0.7)
    }
    
    // MARK: - Onboarding Patterns
    
    /// Onboarding step completed
    func onboardingStepCompleted() {
        guard isHapticsEnabled else { return }
        mediumImpactGenerator.impactOccurred(intensity: 0.8)
    }
    
    /// Onboarding completed - welcome pattern
    func onboardingCompleted() {
        guard isHapticsEnabled else { return }
        notificationGenerator.notificationOccurred(.success)
        
        Task {
            try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
            await MainActor.run {
                self.lightImpactGenerator.impactOccurred(intensity: 0.8)
            }
            
            try? await Task.sleep(nanoseconds: 150_000_000) // 0.15 seconds
            await MainActor.run {
                self.lightImpactGenerator.impactOccurred(intensity: 0.6)
            }
        }
    }
    
    // MARK: - Settings Patterns
    
    /// Setting enabled
    func settingEnabled() {
        guard isHapticsEnabled else { return }
        mediumImpactGenerator.impactOccurred(intensity: 0.7)
    }
    
    /// Setting disabled
    func settingDisabled() {
        guard isHapticsEnabled else { return }
        lightImpactGenerator.impactOccurred(intensity: 0.5)
    }
    
    /// Reset action confirmed
    func resetConfirmed() {
        guard isHapticsEnabled else { return }
        heavyImpactGenerator.impactOccurred()
    }
    
    // MARK: - Validation Patterns
    
    /// Form validation error
    func validationError() {
        guard isHapticsEnabled else { return }
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred(intensity: 0.6)
    }
    
    /// Form submitted successfully
    func formSubmitted() {
        guard isHapticsEnabled else { return }
        notificationGenerator.notificationOccurred(.success)
    }
    
    // MARK: - Utility Methods
    
    /// Check if haptics are available and enabled
    var isHapticsAvailable: Bool {
        // UIDevice must be accessed on MainActor
        return UIDevice.current.userInterfaceIdiom == .phone
    }
    
    /// Check if haptics are enabled
    var isHapticsEnabled: Bool {
        // Check device availability first
        guard isHapticsAvailable else { return false }
        
        // If the user has never set a preference, default to enabled
        if UserDefaults.standard.object(forKey: "hapticsEnabled") == nil {
            return true // Default to enabled
        }
        // Otherwise, use their explicit preference
        return UserDefaults.standard.bool(forKey: "hapticsEnabled")
    }
    
    /// Enable/disable haptics globally
    func setHapticsEnabled(_ enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: "hapticsEnabled")
    }
}

// MARK: - Convenience Extensions
extension HapticManager {
    
    /// Quick access methods with shorter names for common actions
    func tap() { lightImpact() }
    func select() { selection() }
    func confirm() { success() }
    func deny() { error() }
    func warn() { warning() }
}

// MARK: - SwiftUI Integration
extension View {
    /// Convenience modifier to add haptic feedback to any view
    func hapticFeedback(_ style: HapticStyle, on trigger: some Equatable) -> some View {
        self.onChange(of: trigger) { _, _ in
            Task { @MainActor in
                switch style {
                case .light: HapticManager.shared.lightImpact()
                case .medium: HapticManager.shared.mediumImpact()
                case .heavy: HapticManager.shared.heavyImpact()
                case .selection: HapticManager.shared.selection()
                case .success: HapticManager.shared.success()
                case .warning: HapticManager.shared.warning()
                case .error: HapticManager.shared.error()
                case .premium: HapticManager.shared.premiumImpact()
                }
            }
        }
    }
    
    /// Add haptic feedback to button taps
    func hapticTap(_ style: HapticStyle = .light) -> some View {
        self.onTapGesture {
            Task { @MainActor in
                switch style {
                case .light: HapticManager.shared.lightImpact()
                case .medium: HapticManager.shared.mediumImpact()
                case .heavy: HapticManager.shared.heavyImpact()
                case .selection: HapticManager.shared.selection()
                case .success: HapticManager.shared.success()
                case .warning: HapticManager.shared.warning()
                case .error: HapticManager.shared.error()
                case .premium: HapticManager.shared.premiumImpact()
                }
            }
        }
    }
}

enum HapticStyle: Sendable {
    case light, medium, heavy, selection, success, warning, error, premium
}
