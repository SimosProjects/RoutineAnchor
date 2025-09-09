//
//  PermissionRequestView.swift
//  Routine Anchor
//

import SwiftUI
import UserNotifications

// MARK: - Permission View
struct PermissionView: View {
    let onAllow: () -> Void
    let onSkip: () -> Void
    @Environment(\.themeManager) private var themeManager
    @State private var appearAnimation = false
    @State private var pulseAnimation = false

    private var theme: AppTheme { themeManager?.currentTheme ?? PredefinedThemes.classic }

    var body: some View {
        GeometryReader { geometry in
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    Spacer().frame(height: max(geometry.safeAreaInsets.top, 60))

                    // Animated notification visual
                    ZStack {
                        // Ripple effect
                        ForEach(0..<3) { index in
                            Circle()
                                .stroke(
                                    LinearGradient(
                                        colors: [theme.accentPrimaryColor.opacity(0.30),
                                                 theme.accentSecondaryColor.opacity(0.12)],
                                        startPoint: .topLeading, endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 2
                                )
                                .frame(width: 120 + CGFloat(index * 40),
                                       height: 120 + CGFloat(index * 40))
                                .scaleEffect(pulseAnimation ? 1.2 : 1)
                                .opacity(pulseAnimation ? 0 : 0.6)
                                .animation(
                                    .easeOut(duration: 2)
                                        .repeatForever(autoreverses: false)
                                        .delay(Double(index) * 0.3),
                                    value: pulseAnimation
                                )
                        }

                        // Central icon
                        RoundedRectangle(cornerRadius: 30)
                            .fill(
                                LinearGradient(
                                    colors: [theme.accentPrimaryColor, theme.accentSecondaryColor],
                                    startPoint: .topLeading, endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 100, height: 100)
                            .overlay(
                                Image(systemName: "bell.badge.fill")
                                    .font(.system(size: 40, weight: .medium))
                                    .foregroundStyle(theme.invertedTextColor)
                            )
                            .rotation3DEffect(.degrees(appearAnimation ? 0 : 180), axis: (x: 0, y: 1, z: 0))
                            .shadow(color: theme.accentPrimaryColor.opacity(0.4), radius: 30, x: 0, y: 15)
                    }
                    .scaleEffect(appearAnimation ? 1 : 0.5)
                    .opacity(appearAnimation ? 1 : 0)
                    .padding(.bottom, 40)

                    VStack(spacing: 24) {
                        VStack(spacing: 16) {
                            Text("Stay in Your Flow")
                                .font(.system(size: 36, weight: .bold, design: .rounded))
                                .foregroundStyle(
                                    LinearGradient(colors: [theme.accentPrimaryColor, theme.accentSecondaryColor],
                                                   startPoint: .leading, endPoint: .trailing)
                                )

                            Text("Gentle nudges at just the right moments keep you focused without the stress")
                                .font(.system(size: 18, weight: .regular, design: .rounded))
                                .foregroundStyle(theme.secondaryTextColor)
                                .multilineTextAlignment(.center)
                                .lineSpacing(4)
                                .padding(.horizontal, 20)
                        }
                        .opacity(appearAnimation ? 1 : 0)
                        .offset(y: appearAnimation ? 0 : 20)

                        // Interactive preview
                        NotificationPreview()
                            .opacity(appearAnimation ? 1 : 0)
                            .offset(y: appearAnimation ? 0 : 20)
                            .animation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.3), value: appearAnimation)
                    }
                    .padding(.top, 20)

                    Spacer(minLength: 60)

                    // Actions
                    VStack(spacing: 16) {
                        DesignedButton(title: "Enable Smart Reminders") {
                            HapticManager.shared.mediumImpact()
                            onAllow()
                        }

                        Button(action: {
                            HapticManager.shared.lightImpact()
                            onSkip()
                        }) {
                            Text("I'll set this up later")
                                .font(.system(size: 16, weight: .medium, design: .rounded))
                                .foregroundStyle(theme.secondaryTextColor.opacity(0.85))
                        }
                        .opacity(appearAnimation ? 1 : 0)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 20)
                }
                .frame(minHeight: geometry.size.height)
            }
        }
        .background(ThemedAnimatedBackground().ignoresSafeArea())
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) { appearAnimation = true }
            pulseAnimation = true
        }
    }
}
