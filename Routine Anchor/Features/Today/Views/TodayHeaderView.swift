//
//  TodayHeaderView.swift
//  Routine Anchor
//
//  Header section for Today view with navigation and progress
//
import SwiftUI

struct TodayHeaderView: View {
    let viewModel: TodayViewModel
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
                Text(greetingText)
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.white.opacity(0.8))
                
                if isSpecialDay {
                    Image(systemName: specialDayIcon)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.premiumWarning)
                        .scaleEffect(animationPhase == 0 ? 1.0 : 1.2)
                        .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: animationPhase)
                }
            }
            .opacity(greetingOpacity)
            .offset(y: greetingOpacity < 1 ? -10 : 0)
            
            // Date with day of week
            VStack(alignment: .leading, spacing: 2) {
                Text(currentDateText)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                
                if let motivationalQuote = getDailyQuote() {
                    Text(motivationalQuote)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundStyle(Color.white.opacity(0.6))
                        .lineLimit(1)
                }
            }
            .opacity(dateOpacity)
            .offset(y: dateOpacity < 1 ? -10 : 0)
        }
        .onAppear {
            animateHeaderElements()
        }
    }
    
    // MARK: - Action Buttons
    private var actionButtons: some View {
        HStack(spacing: 16) {
            // Summary button (with badge if needed)
            NavigationButton(
                icon: viewModel.shouldShowSummary ? "chart.pie.fill" : "chart.pie",
                gradient: [Color.premiumGreen, Color.premiumTeal]
            ) {
                HapticManager.shared.premiumImpact()
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
                gradient: [Color.premiumPurple, Color.premiumBlue]
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
                    gradient: [Color.premiumWarning, Color.premiumTeal]
                ) {
                    HapticManager.shared.lightImpact()
                    showingQuickStats = true
                }
                .opacity(buttonsOpacity)
                .scaleEffect(buttonsOpacity)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func animateHeaderElements() {
        withAnimation(.easeOut(duration: 0.6).delay(0.1)) {
            greetingOpacity = 1
        }
        
        withAnimation(.easeOut(duration: 0.6).delay(0.2)) {
            dateOpacity = 1
        }
        
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.3)) {
            buttonsOpacity = 1
        }
        
        withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
            animationPhase = 1
        }
    }
    
    // MARK: - Computed Properties
    
    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        let name = UserDefaults.standard.string(forKey: "userName") ?? ""
        let personalizedGreeting = name.isEmpty ? "" : ", \(name)"
        
        switch hour {
        case 5..<12: return "Good morning\(personalizedGreeting)"
        case 12..<17: return "Good afternoon\(personalizedGreeting)"
        case 17..<22: return "Good evening\(personalizedGreeting)"
        default: return "Good night\(personalizedGreeting)"
        }
    }
    
    private var currentDateText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: Date())
    }
    
    private var isSpecialDay: Bool {
        // Check for special occasions
        let calendar = Calendar.current
        let components = calendar.dateComponents([.month, .day], from: Date())
        
        // Examples of special days
        if components.month == 1 && components.day == 1 { return true } // New Year
        if components.month == 12 && components.day == 25 { return true } // Christmas
        
        // Check if it's Friday (weekend start)
        let weekday = calendar.component(.weekday, from: Date())
        if weekday == 6 { return true } // Friday
        
        return false
    }
    
    private var specialDayIcon: String {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.month, .day], from: Date())
        
        if components.month == 1 && components.day == 1 { return "sparkles" }
        if components.month == 12 && components.day == 25 { return "snowflake" }
        
        let weekday = calendar.component(.weekday, from: Date())
        if weekday == 6 { return "party.popper" }
        
        return "star"
    }
    
    private func getDailyQuote() -> String? {
        let quotes = [
            "Small steps lead to big changes",
            "Consistency is the key to success",
            "Today's effort is tomorrow's strength",
            "Progress over perfection",
            "One block at a time",
            "Your routine shapes your future",
            "Focus on what matters most"
        ]
        
        // Use date as seed for consistent daily quote
        let calendar = Calendar.current
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: Date()) ?? 1
        let index = dayOfYear % quotes.count
        
        return quotes[index]
    }
}

// MARK: - Notification Badge
struct NotificationBadge: View {
    @State private var isAnimating = false
    
    var body: some View {
        Circle()
            .fill(Color.premiumError)
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

// MARK: - Enhanced Navigation Button
extension NavigationButton {
    struct BadgeModifier: ViewModifier {
        let showBadge: Bool
        
        func body(content: Content) -> some View {
            content.overlay(
                showBadge ?
                Circle()
                    .fill(Color.premiumError)
                    .frame(width: 8, height: 8)
                    .offset(x: 12, y: -12)
                : nil
            )
        }
    }
}

// MARK: - Weather Widget (Optional Enhancement)
struct WeatherWidget: View {
    @State private var temperature: String = "--"
    @State private var weatherIcon: String = "sun.max"
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: weatherIcon)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.white.opacity(0.7))
            
            Text(temperature)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(Color.white.opacity(0.7))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(Color.white.opacity(0.1))
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
                .foregroundStyle(Color.premiumWarning)
            
            Text("\(streakCount)")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(Color.premiumWarning)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(Color.premiumWarning.opacity(0.15))
        )
        .overlay(
            Capsule()
                .stroke(Color.premiumWarning.opacity(0.3), lineWidth: 1)
        )
    }
}
