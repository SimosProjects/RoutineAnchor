//
//  TodayFloatingElements.swift
//  Routine Anchor
//
//  Floating UI elements for Today view
//
import SwiftUI

struct TodayFloatingElements: View {
    let viewModel: TodayViewModel
    @Binding var showingSummary: Bool
    
    // MARK: - State
    @State private var showQuickInsight = false
    @State private var showCompletionCelebration = false
    @State private var floatingOffset: CGFloat = 0
    @State private var pulseScale: CGFloat = 1.0
    
    var body: some View {
        VStack {
            Spacer()
            
            // Quick insights or actions
            VStack(spacing: 16) {
                // Completion celebration
                if viewModel.isDayComplete && showCompletionCelebration {
                    CompletionCelebrationCard(
                        performanceLevel: viewModel.performanceLevel,
                        onViewSummary: {
                            showingSummary = true
                        }
                    )
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.8).combined(with: .opacity),
                        removal: .scale(scale: 0.6).combined(with: .opacity)
                    ))
                }
                
                // Quick insight card
                if showQuickInsight {
                    if let nextBlock = viewModel.getNextUpcomingBlock(),
                       let timeUntil = viewModel.timeUntilNextBlock() {
                        QuickInsightCard(
                            title: "Up Next",
                            subtitle: nextBlock.title,
                            timeText: timeUntil,
                            color: Color.premiumBlue
                        )
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    } else if let currentBlock = viewModel.getCurrentBlock(),
                              let remainingTime = viewModel.remainingTimeForCurrentBlock() {
                        QuickInsightCard(
                            title: "Current",
                            subtitle: currentBlock.title,
                            timeText: remainingTime,
                            color: Color.premiumGreen
                        )
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
                
                // Floating action buttons
                FloatingActionButtons(
                    viewModel: viewModel,
                    onQuickAdd: {
                        // Navigate to quick add
                    },
                    onStartNext: {
                        viewModel.startNextBlock()
                    }
                )
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 120) // Above tab bar
        }
        .onAppear {
            checkForInsights()
            startAnimations()
        }
        .onChange(of: viewModel.isDayComplete) { _, isComplete in
            if isComplete {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.5)) {
                    showCompletionCelebration = true
                }
            }
        }
        .onChange(of: viewModel.sortedTimeBlocks) { _, _ in
            checkForInsights()
        }
    }
    
    // MARK: - Helper Methods
    
    private func checkForInsights() {
        let hasUpcoming = viewModel.getNextUpcomingBlock() != nil
        let hasCurrent = viewModel.getCurrentBlock() != nil
        
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            showQuickInsight = hasUpcoming || hasCurrent
        }
    }
    
    private func startAnimations() {
        // Floating animation
        withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
            floatingOffset = -10
        }
        
        // Pulse animation
        withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
            pulseScale = 1.1
        }
    }
}

// MARK: - Floating Action Buttons
struct FloatingActionButtons: View {
    let viewModel: TodayViewModel
    let onQuickAdd: () -> Void
    let onStartNext: () -> Void
    
    @State private var showButtons = false
    @State private var buttonsExpanded = false
    
    var body: some View {
        HStack(spacing: 16) {
            // Secondary actions (shown when expanded)
            if buttonsExpanded {
                HStack(spacing: 12) {
                    // Start next block button
                    if viewModel.getNextUpcomingBlock() != nil {
                        MiniFloatingButton(
                            icon: "play.circle",
                            color: Color.premiumGreen,
                            action: onStartNext
                        )
                        .transition(.scale.combined(with: .opacity))
                    }
                    
                    // Quick stats button
                    if viewModel.hasScheduledBlocks {
                        MiniFloatingButton(
                            icon: "chart.pie",
                            color: Color.premiumPurple,
                            action: {
                                // Show quick stats
                            }
                        )
                        .transition(.scale.combined(with: .opacity))
                    }
                }
            }
            
            Spacer()
            
            // Main floating action button
            if viewModel.hasScheduledBlocks && !viewModel.isDayComplete {
                MainFloatingButton(
                    isExpanded: $buttonsExpanded,
                    primaryAction: onQuickAdd
                )
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.5)) {
                showButtons = true
            }
        }
    }
}

// MARK: - Main Floating Button
struct MainFloatingButton: View {
    @Binding var isExpanded: Bool
    let primaryAction: () -> Void
    
    @State private var isPressed = false
    @State private var pulseScale: CGFloat = 1.0
    
    var body: some View {
        Button(action: {
            HapticManager.shared.premiumImpact()
            
            if isExpanded {
                primaryAction()
            } else {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    isExpanded.toggle()
                }
            }
        }) {
            ZStack {
                // Pulse effect
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.premiumBlue.opacity(0.3), Color.premiumPurple.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 56, height: 56)
                    .scaleEffect(pulseScale)
                    .opacity(1.0 - (pulseScale - 1.0))
                
                // Main button
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.premiumBlue, Color.premiumPurple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 56, height: 56)
                    .overlay(
                        Image(systemName: isExpanded ? "xmark" : "plus")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundStyle(.white)
                            .rotationEffect(.degrees(isExpanded ? 45 : 0))
                    )
                    .shadow(
                        color: Color.premiumBlue.opacity(0.4),
                        radius: 12,
                        x: 0,
                        y: 6
                    )
                    .scaleEffect(isPressed ? 0.95 : 1.0)
            }
        }
        .onLongPressGesture(minimumDuration: 0.5) {
            // Long press for quick add
            HapticManager.shared.premiumSuccess()
            primaryAction()
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                pulseScale = 1.4
            }
        }
    }
}

// MARK: - Mini Floating Button
struct MiniFloatingButton: View {
    let icon: String
    let color: Color
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            HapticManager.shared.lightImpact()
            action()
        }) {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [color, color.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(.white)
                )
                .shadow(
                    color: color.opacity(0.3),
                    radius: 8,
                    x: 0,
                    y: 4
                )
                .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .pressEvents(onPress: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isPressed = true
            }
        }, onRelease: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isPressed = false
            }
        })
    }
}

// MARK: - Completion Celebration Card
struct CompletionCelebrationCard: View {
    let performanceLevel: PerformanceLevel
    let onViewSummary: () -> Void
    
    @State private var cardScale: CGFloat = 0.8
    @State private var showConfetti = false
    
    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                // Celebration icon
                Text(performanceLevel.emoji)
                    .font(.system(size: 36))
                    .scaleEffect(showConfetti ? 1.2 : 1.0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.6).repeatCount(3, autoreverses: true), value: showConfetti)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Day Complete!")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    
                    Text(completionMessage)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(performanceLevel.color)
                }
                
                Spacer()
                
                // Close button
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        // Dismiss card
                    }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(Color.white.opacity(0.3))
                }
            }
            
            // Action button
            Button(action: onViewSummary) {
                HStack(spacing: 8) {
                    Image(systemName: "chart.pie.fill")
                        .font(.system(size: 14, weight: .medium))
                    
                    Text("View Summary")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    LinearGradient(
                        colors: [performanceLevel.color, performanceLevel.color.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(10)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            LinearGradient(
                                colors: [
                                    performanceLevel.color.opacity(0.15),
                                    performanceLevel.color.opacity(0.05)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    LinearGradient(
                        colors: [
                            performanceLevel.color.opacity(0.5),
                            performanceLevel.color.opacity(0.2)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: performanceLevel.color.opacity(0.3), radius: 20, x: 0, y: 10)
        .scaleEffect(cardScale)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                cardScale = 1.0
                showConfetti = true
            }
        }
        .overlay(
            // Confetti overlay
            showConfetti ? ConfettiView(isActive: $showConfetti) : nil
        )
    }
    
    private var completionMessage: String {
        switch performanceLevel {
        case .excellent: return "Outstanding performance!"
        case .good: return "Great job today!"
        case .fair: return "Good progress!"
        case .poor: return "You showed up!"
        case .none: return "Ready for tomorrow!"
        }
    }
}

// MARK: - Press Events Modifier
struct PressEvents: ViewModifier {
    let onPress: () -> Void
    let onRelease: () -> Void
    
    func body(content: Content) -> some View {
        content
            .onLongPressGesture(
                minimumDuration: 0,
                maximumDistance: .infinity,
                pressing: { isPressing in
                    if isPressing {
                        onPress()
                    } else {
                        onRelease()
                    }
                },
                perform: {}
            )
    }
}

extension View {
    func pressEvents(onPress: @escaping () -> Void, onRelease: @escaping () -> Void) -> some View {
        modifier(PressEvents(onPress: onPress, onRelease: onRelease))
    }
}
