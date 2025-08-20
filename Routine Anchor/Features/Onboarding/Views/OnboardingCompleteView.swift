//
//  OnboardingCompleteView.swift
//  Routine Anchor
//
//  Created by Christopher Simonson on 7/19/25.
//
import SwiftUI
import UserNotifications

// MARK: - Setup Complete View
struct SetupCompleteView: View {
    let onFinish: () -> Void
    @State private var appearAnimation = false
    @State private var confettiAnimation = false
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    Spacer().frame(height: max(geometry.safeAreaInsets.top, 60))
                    
                    // Success animation
                    ZStack {
                        // Confetti effect
                        ConfettiView(isActive: $confettiAnimation)
                            .allowsHitTesting(false)
                        
                        // Success icon
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color(red: 0.2, green: 0.8, blue: 0.5).opacity(0.2), Color(red: 0.2, green: 0.7, blue: 0.7).opacity(0.1)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 140, height: 140)
                                .blur(radius: 20)
                            
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color(red: 0.2, green: 0.8, blue: 0.5), Color(red: 0.2, green: 0.7, blue: 0.7)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 100, height: 100)
                                .overlay(
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 50, weight: .bold))
                                        .foregroundStyle(.white)
                                )
                                .shadow(color: Color(red: 0.2, green: 0.7, blue: 0.5).opacity(0.4), radius: 30, x: 0, y: 15)
                        }
                        .scaleEffect(appearAnimation ? 1 : 0)
                        .rotationEffect(.degrees(appearAnimation ? 0 : -180))
                    }
                    .padding(.bottom, 40)
                    
                    VStack(spacing: 24) {
                        VStack(spacing: 16) {
                            Text("You're All Set!")
                                .font(.system(size: 38, weight: .bold, design: .rounded))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Color(red: 0.2, green: 0.8, blue: 0.5), Color(red: 0.2, green: 0.7, blue: 0.7)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                            
                            Text("Your journey to a more\nbalanced life starts now")
                                .font(.system(size: 20, weight: .regular, design: .rounded))
                                .foregroundStyle(Color.white.opacity(0.7))
                                .multilineTextAlignment(.center)
                                .lineSpacing(4)
                        }
                        .opacity(appearAnimation ? 1 : 0)
                        .offset(y: appearAnimation ? 0 : 20)
                        
                        // Quick start tips
                        VStack(spacing: 12) {
                            QuickTip(
                                number: "1",
                                text: "Start with just 3-4 time blocks",
                                delay: 0.4
                            )
                            QuickTip(
                                number: "2",
                                text: "Be honest when checking in",
                                delay: 0.5
                            )
                            QuickTip(
                                number: "3",
                                text: "Celebrate small wins daily",
                                delay: 0.6
                            )
                        }
                        .padding(.top, 20)
                        .padding(.horizontal, 40)
                    }
                    
                    Spacer(minLength: 60)
                    
                    // Final CTA
                    VStack(spacing: 20) {
                        DesignedButton(
                            title: "Create My First Routine",
                            style: .gradient,
                            action: {
                                HapticManager.shared.success()
                                onFinish()
                            }
                        )
                        
                        Text("Let's make today count 🚀")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundStyle(Color.white.opacity(0.6))
                            .opacity(appearAnimation ? 1 : 0)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 20)
                }
                .frame(minHeight: geometry.size.height)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
                appearAnimation = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                confettiAnimation = true
            }
        }
    }
}
