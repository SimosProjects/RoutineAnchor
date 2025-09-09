//
//  TodayHeaderView.swift
//  Routine Anchor
//
//  Header area for Today: greeting/date + quick action buttons + (optional) progress.
//

import SwiftUI

struct TodayHeaderView: View {
    let viewModel: TodayViewModel
    @Environment(\.themeManager) private var themeManager
    @Binding var showingSettings: Bool
    @Binding var showingSummary: Bool
    @Binding var showingQuickStats: Bool

    // MARK: - Local animation state
    @State private var greetingOpacity: Double = 0
    @State private var dateOpacity: Double = 0
    @State private var buttonsOpacity: Double = 0
    @State private var progressCardScale: CGFloat = 0.9
    @State private var animationPhase = 0

    // Resolve the theme once per render pass.
    private var theme: AppTheme { themeManager?.currentTheme ?? PredefinedThemes.classic }

    var body: some View {
        VStack(spacing: 24) {
            navigationBar

            if viewModel.hasScheduledBlocks {
                ProgressOverviewCard(viewModel: viewModel) // assumed existing
                    .scaleEffect(progressCardScale)
                    .opacity(progressCardScale > 0.95 ? 1 : 0)
                    .onAppear {
                        withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.4)) {
                            progressCardScale = 1.0
                        }
                    }
                    .padding(.horizontal, 24)
            }
        }
        .onAppear { animationPhase = 1 }
    }

    // MARK: - Navigation Bar

    private var navigationBar: some View {
        HStack {
            dateAndGreetingSection
            Spacer()
            actionButtons
        }
        .padding(.horizontal, 24)
    }

    // Left side: greeting + date/quote
    private var dateAndGreetingSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Greeting
            HStack(spacing: 6) {
                Text(viewModel.greetingText)
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundStyle(theme.secondaryTextColor)

                if viewModel.isSpecialDay {
                    Image(systemName: viewModel.specialDayIcon)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(theme.statusWarningColor) // semantic status color
                        .scaleEffect(animationPhase == 0 ? 1.0 : 1.2)
                        .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: animationPhase)
                }
            }
            .opacity(greetingOpacity)
            .offset(y: greetingOpacity < 1 ? 10 : 0)
            .onAppear {
                withAnimation(.easeOut(duration: 0.8)) { greetingOpacity = 1 }
                animationPhase = 1
            }

            // Date + quote
            VStack(alignment: .leading, spacing: 2) {
                Text(viewModel.currentDateText)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(theme.primaryTextColor)
                    .opacity(dateOpacity)
                    .offset(y: dateOpacity < 1 ? 10 : 0)
                    .onAppear {
                        withAnimation(.easeOut(duration: 0.8).delay(0.2)) { dateOpacity = 1 }
                    }

                Text(viewModel.dailyQuote)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(theme.subtleTextColor)
                    .lineLimit(1)
            }
            .opacity(dateOpacity)
            .offset(y: dateOpacity < 1 ? 10 : 0)
        }
    }

    // Right side: actions
    private var actionButtons: some View {
        HStack(spacing: 16) {
            // Summary (badge shown when there’s something to review)
            NavigationButton( // assumed existing
                icon: viewModel.shouldShowSummary ? "chart.pie.fill" : "chart.pie",
                style: .success
            ) {
                HapticManager.shared.impact()
                showingSummary = true
            }
            .overlay(
                viewModel.shouldShowSummary && !viewModel.isDayComplete
                ? NotificationBadge().offset(x: 12, y: -12)
                : nil
            )
            .opacity(buttonsOpacity)
            .scaleEffect(buttonsOpacity)

            // Settings
            NavigationButton(icon: "gearshape.fill", style: .secondary) {
                HapticManager.shared.lightImpact()
                showingSettings = true
            }
            .opacity(buttonsOpacity)
            .scaleEffect(buttonsOpacity)

            // Quick stats (visible when there are scheduled blocks)
            if viewModel.hasScheduledBlocks {
                NavigationButton(icon: "bolt.fill", style: .accent) {
                    HapticManager.shared.lightImpact()
                    NotificationCenter.default.post(name: .showQuickStats, object: nil)
                }
                .opacity(buttonsOpacity)
                .scaleEffect(buttonsOpacity)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8).delay(0.4)) { buttonsOpacity = 1 }
        }
    }
}

// MARK: - Tiny helpers used in header

/// Pulsing dot used as a subtle “unread/attention” indicator.
struct NotificationBadge: View {
    @Environment(\.themeManager) private var themeManager
    @State private var isAnimating = false

    private var theme: AppTheme { themeManager?.currentTheme ?? PredefinedThemes.classic }

    var body: some View {
        Circle()
            .fill(theme.statusErrorColor) // semantic status color
            .frame(width: 8, height: 8)
            .scaleEffect(isAnimating ? 1.2 : 1.0)
            .opacity(isAnimating ? 0.8 : 1.0)
            .onAppear {
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    isAnimating = true
                }
            }
    }
}
