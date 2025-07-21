//
//  HapticFeedback.swift
//  Routine Anchor
//
//  Created by Christopher Simonson on 7/21/25.
//
import UIKit

/// Manages haptic feedback throughout the app with premium patterns
class HapticManager {
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
        lightImpactGenerator.impactOccurred()
    }
    
    /// Medium impact - for standard UI interactions
    func mediumImpact() {
        mediumImpactGenerator.impactOccurred()
    }
    
    /// Heavy impact - for significant actions
    func heavyImpact() {
        heavyImpactGenerator.impactOccurred()
    }
    
    // MARK: - Selection Feedback
    
    /// Selection feedback - for tab changes, picker selections
    func selection() {
        selectionGenerator.selectionChanged()
    }
    
    // MARK: - Notification Feedback
    
    /// Success notification - for completed actions
    func success() {
        notificationGenerator.notificationOccurred(.success)
    }
    
    /// Warning notification - for important alerts
    func warning() {
        notificationGenerator.notificationOccurred(.warning)
    }
    
    /// Error notification - for failed actions
    func error() {
        notificationGenerator.notificationOccurred(.error)
    }
    
    // MARK: - Premium Patterns
    
    /// Premium impact with custom intensity - for elevated experiences
    func premiumImpact() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred(intensity: 0.8)
    }
    
    /// Premium success - double tap for emphasis
    func premiumSuccess() {
        notificationGenerator.notificationOccurred(.success)
        
        // Add a second subtle tap for premium feel
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.lightImpactGenerator.impactOccurred(intensity: 0.6)
        }
    }
    
    /// Premium selection - enhanced selection feedback
    func premiumSelection() {
        selectionGenerator.selectionChanged()
        
        // Add subtle follow-up
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            self.lightImpactGenerator.impactOccurred(intensity: 0.4)
        }
    }
    
    /// Premium error - more pronounced error feedback
    func premiumError() {
        notificationGenerator.notificationOccurred(.error)
        
        // Add vibration pattern for emphasis
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.mediumImpactGenerator.impactOccurred(intensity: 0.7)
        }
    }
    
    // MARK: - Context-Specific Patterns
    
    /// Time block completion - celebratory pattern
    func timeBlockCompleted() {
        // Success with follow-up
        notificationGenerator.notificationOccurred(.success)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            self.lightImpactGenerator.impactOccurred(intensity: 0.8)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            self.lightImpactGenerator.impactOccurred(intensity: 0.6)
        }
    }
    
    /// Time block skipped - gentle disappointment
    func timeBlockSkipped() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred(intensity: 0.5)
    }
    
    /// Time block started - motivational tap
    func timeBlockStarted() {
        mediumImpactGenerator.impactOccurred(intensity: 0.9)
    }
    
    /// Routine saved - accomplishment pattern
    func routineSaved() {
        mediumImpactGenerator.impactOccurred()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.lightImpactGenerator.impactOccurred(intensity: 0.7)
        }
    }
    
    /// Daily goal achieved - celebration pattern
    func dailyGoalAchieved() {
        // Triple tap celebration
        notificationGenerator.notificationOccurred(.success)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            self.mediumImpactGenerator.impactOccurred(intensity: 0.8)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.24) {
            self.lightImpactGenerator.impactOccurred(intensity: 0.9)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.36) {
            self.lightImpactGenerator.impactOccurred(intensity: 0.6)
        }
    }
    
    /// Navigation transition - smooth transition feel
    func navigationTransition() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred(intensity: 0.6)
    }
    
    /// Pull to refresh - encouraging feedback
    func pullToRefresh() {
        lightImpactGenerator.impactOccurred(intensity: 0.8)
    }
    
    /// Data refresh completed
    func refreshCompleted() {
        lightImpactGenerator.impactOccurred(intensity: 0.7)
    }
    
    // MARK: - Onboarding Patterns
    
    /// Onboarding step completed
    func onboardingStepCompleted() {
        mediumImpactGenerator.impactOccurred(intensity: 0.8)
    }
    
    /// Onboarding completed - welcome pattern
    func onboardingCompleted() {
        notificationGenerator.notificationOccurred(.success)
        
        // Welcoming sequence
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.lightImpactGenerator.impactOccurred(intensity: 0.8)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            self.lightImpactGenerator.impactOccurred(intensity: 0.6)
        }
    }
    
    // MARK: - Settings Patterns
    
    /// Setting enabled
    func settingEnabled() {
        mediumImpactGenerator.impactOccurred(intensity: 0.7)
    }
    
    /// Setting disabled
    func settingDisabled() {
        lightImpactGenerator.impactOccurred(intensity: 0.5)
    }
    
    /// Reset action confirmed
    func resetConfirmed() {
        heavyImpactGenerator.impactOccurred()
    }
    
    // MARK: - Validation Patterns
    
    /// Form validation error
    func validationError() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred(intensity: 0.6)
    }
    
    /// Form submitted successfully
    func formSubmitted() {
        notificationGenerator.notificationOccurred(.success)
    }
    
    // MARK: - Utility Methods
    
    /// Check if haptics are available and enabled
    var isHapticsAvailable: Bool {
        return UIDevice.current.userInterfaceIdiom == .phone
    }
    
    /// Perform haptic only if available and user hasn't disabled them
    private func performHaptic(_ hapticClosure: () -> Void) {
        guard isHapticsAvailable else { return }
        
        // Check user's haptic preferences
        if isHapticsEnabled {
            hapticClosure()
        }
    }
    
    /// Enable/disable haptics globally
    func setHapticsEnabled(_ enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: "hapticsEnabled")
    }
    
    /// Check if haptics are enabled
    var isHapticsEnabled: Bool {
        // If the user has never set a preference, default to enabled
        if UserDefaults.standard.object(forKey: "hapticsEnabled") == nil {
            return true // Default to enabled
        }
        // Otherwise, use their explicit preference
        return UserDefaults.standard.bool(forKey: "hapticsEnabled")
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
import SwiftUI

extension View {
    /// Convenience modifier to add haptic feedback to any view
    func hapticFeedback(_ style: HapticStyle, on trigger: some Equatable) -> some View {
        self.onChange(of: trigger) { _, _ in
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
    
    /// Add haptic feedback to button taps
    func hapticTap(_ style: HapticStyle = .light) -> some View {
        self.onTapGesture {
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

enum HapticStyle {
    case light, medium, heavy, selection, success, warning, error, premium
}
