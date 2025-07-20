//
//  OnboardingFlow.swift
//  Routine Anchor
//
//  Created by Christopher Simonson on 7/19/25.
//
import SwiftUI
import UserNotifications

struct OnboardingFlow: View {
    @Binding var showOnboarding: Bool
    @State private var viewModel = OnboardingViewModel()
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [Color.backgroundPrimary, Color.appBackgroundSecondary]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Content based on current step
            Group {
                switch viewModel.currentStep {
                case .welcome:
                    WelcomeView(onContinue: viewModel.nextStep)
                case .permissions:
                    PermissionRequestView(
                        onAllow: viewModel.requestNotificationPermission,
                        onSkip: viewModel.skipPermissions
                    )
                case .setup:
                    OnboardingCompleteView(onFinish: completeOnboarding)
                }
            }
            .transition(.asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            ))
        }
        .animation(.easeInOut(duration: 0.3), value: viewModel.currentStep)
    }
    
    private func completeOnboarding() {
        // Mark onboarding as completed
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        
        // Haptic feedback
        HapticManager.shared.success()
        
        // Close onboarding with animation
        withAnimation(.easeInOut(duration: 0.5)) {
            showOnboarding = false
        }
    }
}
