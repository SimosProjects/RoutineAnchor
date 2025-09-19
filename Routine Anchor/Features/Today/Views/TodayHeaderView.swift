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
    @State private var shouldShowSwipeHint = true
    @State private var greetingOpacity: Double = 0
    @State private var dateOpacity: Double = 0
    @State private var buttonsOpacity: Double = 0
    @State private var progressCardScale: CGFloat = 0.9
    @State private var animationPhase = 0
    
    // MARK: - Environment
    @Environment(\.colorScheme) var colorScheme
    
    // Theme color helpers
    private var themePrimaryText: Color {
        themeManager?.currentTheme.primaryTextColor ?? Theme.defaultTheme.primaryTextColor
    }
    
    private var themeSecondaryText: Color {
        themeManager?.currentTheme.secondaryTextColor ?? Theme.defaultTheme.secondaryTextColor
    }
    
    private var themeSubtleText: Color {
        themeManager?.currentTheme.subtleTextColor ?? Theme.defaultTheme.subtleTextColor
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
        VStack(spacing: 12) {

            // ROW 1: greeting + date + arrows/calendar
            VStack(alignment: .leading, spacing: 8) {
                // Greeting row
                HStack(spacing: 6) {
                    Text(viewModel.greetingText)
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundStyle(themeSecondaryText)

                    if viewModel.isSpecialDay {
                        Image(systemName: viewModel.specialDayIcon)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(themeManager?.currentTheme.colorScheme.warning.color
                                             ?? Theme.defaultTheme.colorScheme.warning.color)
                    }
                }
                .opacity(greetingOpacity)
                .offset(y: greetingOpacity < 1 ? 10 : 0)
                .onAppear {
                    withAnimation(.easeOut(duration: 0.8)) { greetingOpacity = 1 }
                    animationPhase = 1
                }

                // Date row: ←  [   DATE   ]  →  📅
                HStack(spacing: 12) {
                    circleButton("chevron.left", accessibility: "Previous Day") {
                        HapticManager.shared.lightImpact()
                        Task { await viewModel.goToPreviousDay() }
                    }

                    // Centered two-line date
                    VStack(spacing: 2) {
                        Text(weekdayTitle(for: viewModel.selectedDate))
                            .font(.system(size: 22, weight: .semibold, design: .rounded))
                            .foregroundStyle(themePrimaryText)
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                            .allowsTightening(true)

                        Text(dateSubtitle(for: viewModel.selectedDate))
                            .font(.system(size: 18, weight: .medium, design: .rounded))
                            .foregroundStyle(themeSecondaryText)
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                            .allowsTightening(true)
                    }
                    .frame(maxWidth: .infinity)
                    .opacity(dateOpacity)
                    .offset(y: dateOpacity < 1 ? 10 : 0)
                    .onAppear {
                        withAnimation(.easeOut(duration: 0.8).delay(0.2)) { dateOpacity = 1 }
                    }

                    HStack(spacing: 10) {
                        circleButton("chevron.right", accessibility: "Next Day") {
                            HapticManager.shared.lightImpact()
                            Task { await viewModel.goToNextDay() }
                        }
                        circleButton("calendar", accessibility: "Jump to Date") {
                            HapticManager.shared.lightImpact()
                            NotificationCenter.default.post(name: .showDatePicker, object: nil)
                        }
                    }
                }
            }
            
            if viewModel.atFreeHistoryFloor {
                HStack(spacing: 8) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 12, weight: .semibold))
                    Text("You’ve reached your free history limit (3 days). Upgrade to browse more.")
                        .font(.system(size: 12, weight: .semibold))
                        .lineLimit(2)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.ultraThinMaterial)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke((themeManager?.currentTheme.colorScheme.warning.color
                                 ?? Theme.defaultTheme.colorScheme.warning.color).opacity(0.25), lineWidth: 1)
                )
                .foregroundStyle(themeSecondaryText)
            }

            // ROW 2: quick action buttons aligned to the trailing edge
            if isViewingToday {
                HStack {
                    Spacer()
                    actionButtons
                }
                .opacity(buttonsOpacity)
                .onAppear {
                    withAnimation(.easeOut(duration: 0.8).delay(0.4)) { buttonsOpacity = 1 }
                }
            }
        }
        .padding(.horizontal, 24)
    }

    // Small circular control
    @ViewBuilder
    private func circleButton(_ systemName: String, accessibility: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(themePrimaryText.opacity(0.95))
                .frame(width: 34, height: 34)
                .background(Circle().fill(.ultraThinMaterial))
        }
        .accessibilityLabel(accessibility)
    }
    
    private var isViewingToday: Bool {
        Calendar.current.isDateInToday(viewModel.selectedDate)
    }
    
    private func weekdayTitle(for date: Date) -> String {
        if Calendar.current.isDateInToday(date) { return "Today" }
        let df = DateFormatter()
        df.dateFormat = "EEEE" // Wednesday
        return df.string(from: date)
    }

    private func dateSubtitle(for date: Date) -> String {
        let cal = Calendar.current
        let sameYear = cal.component(.year, from: date) == cal.component(.year, from: Date())
        let df = DateFormatter()
        df.dateFormat = sameYear ? "MMMM d" : "MMMM d, yyyy" // September 24 / September 24, 2026
        return df.string(from: date)
    }
    
    // MARK: - Big date/title
    private var dateRow: some View {
        Text(dateTitle(for: viewModel.selectedDate))
            .font(.system(size: 30, weight: .bold, design: .rounded))
            .foregroundStyle(themePrimaryText)
            .lineLimit(1)
            .minimumScaleFactor(0.85)
            .allowsTightening(true)
    }

    // Formats the big date title from selectedDate
    private func dateTitle(for date: Date) -> String {
        if Calendar.current.isDateInToday(date) { return "Today" }
        let df = DateFormatter()
        let sameYear = Calendar.current.component(.year, from: date) ==
                       Calendar.current.component(.year, from: Date())
        df.dateFormat = sameYear ? "EEEE, MMM d" : "EEEE, MMM d, yyyy"
        return df.string(from: date)
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
    @Environment(\.themeManager) private var themeManager
    @State private var isAnimating = false
    
    var body: some View {
        Circle()
            .fill(themeManager?.currentTheme.colorScheme.error.color ?? Theme.defaultTheme.colorScheme.error.color)
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
        themeManager?.currentTheme.secondaryTextColor ?? Theme.defaultTheme.secondaryTextColor
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
    @Environment(\.themeManager) private var themeManager
    
    let streakCount: Int
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "flame.fill")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(themeManager?.currentTheme.colorScheme.warning.color ?? Theme.defaultTheme.colorScheme.warning.color)
            
            Text("\(streakCount)")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(themeManager?.currentTheme.colorScheme.warning.color ?? Theme.defaultTheme.colorScheme.warning.color)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill((themeManager?.currentTheme.colorScheme.warning.color ?? Theme.defaultTheme.colorScheme.warning.color).opacity(0.15))
        )
        .overlay(
            Capsule()
                .stroke((themeManager?.currentTheme.colorScheme.warning.color ?? Theme.defaultTheme.colorScheme.warning.color).opacity(0.3), lineWidth: 1)
        )
    }
}
