//
//  OnboardingFlow.swift
//  Routine Anchor
//
import SwiftUI
import UserNotifications

struct OnboardingFlow: View {
    @Binding var showOnboarding: Bool
    @Environment(\.themeManager) private var themeManager
    @State private var viewModel = OnboardingViewModel()
    @State private var animationPhase = 0

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ThemedAnimatedBackground()
                AnimatedMeshBackground()
                    .opacity(0.3)
                    .allowsHitTesting(false)
                ParticleEffectView()
                    .allowsHitTesting(false)

                VStack(spacing: 0) {
                    TabView(selection: $viewModel.currentStep) {
                        WelcomeView(onContinue: viewModel.nextStep)
                            .tag(OnboardingViewModel.OnboardingStep.welcome)

                        PermissionView(
                            onAllow: viewModel.requestNotificationPermission,
                            onSkip: viewModel.skipPermissions
                        )
                        .tag(OnboardingViewModel.OnboardingStep.permissions)

                        SetupCompleteView(onFinish: completeOnboarding)
                            .tag(OnboardingViewModel.OnboardingStep.setup)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .animation(.spring(response: 0.8, dampingFraction: 0.85), value: viewModel.currentStep)

                    // Page indicators
                    HStack(spacing: 12) {
                        ForEach(OnboardingViewModel.OnboardingStep.allCases, id: \.self) { step in
                            RoundedRectangle(cornerRadius: 4)
                                .fill(
                                    viewModel.currentStep == step ?
                                    LinearGradient(
                                        colors: [Color(red: 0.4, green: 0.6, blue: 1.0), Color(red: 0.6, green: 0.4, blue: 1.0)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    ) : LinearGradient(
                                        colors: [Color.white.opacity(0.2), Color.white.opacity(0.2)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: viewModel.currentStep == step ? 32 : 8, height: 8)
                                .animation(.spring(response: 0.4, dampingFraction: 0.7), value: viewModel.currentStep)
                        }
                    }
                    .padding(.bottom, 50)
                }
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                    animationPhase = 1
                }
            }
        }
    }

    private func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            HapticManager.shared.success()
            showOnboarding = false
        }
    }
}

// MARK: - Supporting Views
struct NotificationPreview: View {
    @Environment(\.themeManager) private var themeManager
    @State private var showNotification = false
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Image(systemName: "bell.badge.fill")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(Color(red: 0.4, green: 0.6, blue: 1.0))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Time for: Morning Routine")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(themeManager?.currentTheme.textPrimaryColor ?? Theme.defaultTheme.textPrimaryColor)
                    
                    Text("Your 7:00 AM block is starting now")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.white.opacity(0.7))
                }
                
                Spacer()
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.1))
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.ultraThinMaterial)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.3), radius: 15, x: 0, y: 8)
            .scaleEffect(showNotification ? 1 : 0.8)
            .opacity(showNotification ? 1 : 0)
        }
        .padding(.horizontal, 40)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.5)) {
                showNotification = true
            }
        }
    }
}
