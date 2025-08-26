//
//  TodayHeaderView.swift
//  Routine Anchor
//
//  Header section for Today view with navigation and progress
//
import SwiftUI

struct TodayHeaderView: View {
    let viewModel: TodayViewModel
    @Environment(\.themeManager) private var themeManager
    @Binding var showingSettings: Bool
    @Binding var showingSummary: Bool
    @Binding var showingQuickStats: Bool
    
    // MARK: - State
    @State private var greetingOpacity: Double = 0
    @State private var dateOpacity: Double = 0
    @State private var buttonsOpacity: Double = 0
    @State private var progressCardScale: CGFloat = 0.9
    @State private var animationPhase = 0
    
    // MARK: - Environment
    @Environment(\.colorScheme) var colorScheme
    
    // Theme color helpers
    private var themePrimaryText: Color {
        themeManager?.currentTheme.textPrimaryColor ?? Theme.defaultTheme.textPrimaryColor
    }
    
    private var themeSecondaryText: Color {
        themeManager?.currentTheme.textSecondaryColor ?? Theme.defaultTheme.textSecondaryColor
    }
    
    private var themeTertiaryText: Color {
        themeManager?.currentTheme.textTertiaryColor ?? Theme.defaultTheme.textTertiaryColor
    }
    
    var body: some View {
        VStack(spacing: 24) {
            // Top navigation bar
            navigationBar
            
            // Progress overview (if has data)
            if viewModel.hasScheduledBlocks {
                ProgressOverviewCard(viewModel: viewModel)
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
        .onAppear {
            animationPhase = 1
        }
    }
    
    // MARK: - Navigation Bar
    private var navigationBar: some View {
        HStack {
            // Date and greeting
            dateAndGreetingSection
            
            Spacer()
            
            // Action buttons
            actionButtons
        }
        .padding(.horizontal, 24)
    }
    
    // MARK: - Date and Greeting Section
    private var dateAndGreetingSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Animated greeting
            HStack(spacing: 6) {
                Text(viewModel.greetingText)
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundStyle(themeSecondaryText)
                
                if viewModel.isSpecialDay {
                    Image(systemName: viewModel.specialDayIcon)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.anchorWarning)
                        .scaleEffect(animationPhase == 0 ? 1.0 : 1.2)
                        .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: animationPhase)
                }
            }
            .opacity(greetingOpacity)
            .offset(y: greetingOpacity < 1 ? 10 : 0)
            .onAppear {
                withAnimation(.easeOut(duration: 0.8)) {
                    greetingOpacity = 1
                }
                animationPhase = 1
            }
            
            // Date with day of week
            VStack(alignment: .leading, spacing: 2) {
                Text(viewModel.currentDateText)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(themePrimaryText)
                    .opacity(dateOpacity)
                    .offset(y: dateOpacity < 1 ? 10 : 0)
                    .onAppear {
                        withAnimation(.easeOut(duration: 0.8).delay(0.2)) {
                            dateOpacity = 1
                        }
                    }
                
                Text(viewModel.dailyQuote)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(themeTertiaryText)
                    .lineLimit(1)
            }
            .opacity(dateOpacity)
            .offset(y: dateOpacity < 1 ? 10 : 0)
        }
    }
    
    // MARK: - Action Buttons
    private var actionButtons: some View {
        HStack(spacing: 16) {
            // Summary button (with badge if needed)
            NavigationButton(
                icon: viewModel.shouldShowSummary ? "chart.pie.fill" : "chart.pie",
                style: .success
            ) {
                HapticManager.shared.impact()
                showingSummary = true
            }
            .overlay(
                // Badge for unviewed summary
                viewModel.shouldShowSummary && !viewModel.isDayComplete ?
                NotificationBadge()
                    .offset(x: 12, y: -12)
                : nil
            )
            .opacity(buttonsOpacity)
            .scaleEffect(buttonsOpacity)
            
            // Settings button
            NavigationButton(
                icon: "gearshape.fill",
                style: .secondary
            ) {
                HapticManager.shared.lightImpact()
                showingSettings = true
            }
            .opacity(buttonsOpacity)
            .scaleEffect(buttonsOpacity)
            
            // Quick stats button
            if viewModel.hasScheduledBlocks {
                NavigationButton(
                    icon: "bolt.fill",
                    style: .accent
                ) {
                    HapticManager.shared.lightImpact()
                    // Post notification to show quick stats
                    NotificationCenter.default.post(
                        name: .showQuickStats,
                        object: nil
                    )
                }
                .opacity(buttonsOpacity)
                .scaleEffect(buttonsOpacity)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8).delay(0.4)) {
                buttonsOpacity = 1
            }
        }
    }
}

// MARK: - Notification Badge
struct NotificationBadge: View {
    @State private var isAnimating = false
    
    var body: some View {
        Circle()
            .fill(Color.anchorError)
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

// MARK: - Weather Widget (Optional Enhancement)
struct WeatherWidget: View {
    @Environment(\.themeManager) private var themeManager
    @State private var temperature: String = "--"
    @State private var weatherIcon: String = "sun.max"
    
    private var themeSecondaryText: Color {
        themeManager?.currentTheme.textSecondaryColor ?? Theme.defaultTheme.textSecondaryColor
    }
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: weatherIcon)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(themeSecondaryText)
            
            Text(temperature)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(themeSecondaryText)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(themeSecondaryText.opacity(0.1))
        )
        .onAppear {
            // Fetch weather data
            fetchWeather()
        }
    }
    
    private func fetchWeather() {
        // Mock weather data - integrate with weather service
        temperature = "72°"
        weatherIcon = "sun.max"
    }
}

// MARK: - Streak Indicator (Optional Enhancement)
struct StreakIndicator: View {
    let streakCount: Int
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "flame.fill")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.anchorWarning)
            
            Text("\(streakCount)")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(Color.anchorWarning)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(Color.anchorWarning.opacity(0.15))
        )
        .overlay(
            Capsule()
                .stroke(Color.anchorWarning.opacity(0.3), lineWidth: 1)
        )
    }
}
