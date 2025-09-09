//
//  TodayFloatingElements.swift
//  Routine Anchor
//
//  Floating UI that rides above Today content (FAB, quick insight, celebration).
//

import SwiftUI

// MARK: - Floating elements overlay for Today

struct TodayFloatingElements: View {
    let viewModel: TodayViewModel
    @Environment(\.themeManager) private var themeManager
    @Binding var showingSummary: Bool

    @State private var showQuickInsight = false
    @State private var showCompletionCelebration = false

    private var theme: AppTheme { themeManager?.currentTheme ?? PredefinedThemes.classic }

    var body: some View {
        VStack {
            Spacer()

            VStack(spacing: 16) {
                // Completion celebration card
                if viewModel.isDayComplete && showCompletionCelebration {
                    CompletionCelebrationCard(
                        performanceLevel: viewModel.performanceLevel,
                        onViewSummary: { showingSummary = true }
                    )
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.8).combined(with: .opacity),
                        removal: .scale(scale: 0.6).combined(with: .opacity)
                    ))
                }

                // Quick insight card (next or current block)
                if showQuickInsight {
                    if let nextBlock = viewModel.getNextUpcomingBlock(),
                       let timeUntil = viewModel.timeUntilNextBlock() {
                        // Assumes QuickInsightCard exists elsewhere
                        QuickInsightCard(
                            title: "Up Next",
                            subtitle: nextBlock.title,
                            timeText: timeUntil,
                            color: theme.accentPrimaryColor
                        )
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    } else if let currentBlock = viewModel.getCurrentBlock(),
                              let remainingTime = viewModel.remainingTimeForCurrentBlock() {
                        QuickInsightCard(
                            title: "Current",
                            subtitle: currentBlock.title,
                            timeText: remainingTime,
                            color: theme.statusSuccessColor
                        )
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }

                // Floating action buttons
                FloatingActionButtons(
                    viewModel: viewModel,
                    onQuickAdd: {
                        // Routed to TodayView listener
                        NotificationCenter.default.post(name: .showAddTimeBlockFromTab, object: nil)
                    },
                    onStartNext: { viewModel.startNextBlock() }
                )
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 120) // Keep above the tab bar
        }
        .onAppear {
            checkForInsights()
        }
        .onChange(of: viewModel.isDayComplete) { isComplete in
            if isComplete {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.5)) {
                    showCompletionCelebration = true
                }
            }
        }
        .onChange(of: viewModel.sortedTimeBlocks) { _ in
            checkForInsights()
        }
    }

    // MARK: - Helpers

    private func checkForInsights() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            showQuickInsight = (viewModel.getNextUpcomingBlock() != nil) || (viewModel.getCurrentBlock() != nil)
        }
    }
}

// MARK: - Floating Action Buttons row

struct FloatingActionButtons: View {
    let viewModel: TodayViewModel
    let onQuickAdd: () -> Void
    let onStartNext: () -> Void

    @Environment(\.themeManager) private var themeManager
    @State private var buttonsExpanded = false

    private var theme: AppTheme { themeManager?.currentTheme ?? PredefinedThemes.classic }

    var body: some View {
        HStack(spacing: 16) {
            // Secondary actions (when expanded)
            if buttonsExpanded {
                HStack(spacing: 12) {
                    if viewModel.getNextUpcomingBlock() != nil {
                        MiniFloatingButton(
                            icon: "play.circle",
                            color: theme.statusSuccessColor,
                            action: onStartNext
                        )
                        .transition(.scale.combined(with: .opacity))
                    }

                    if viewModel.hasScheduledBlocks {
                        MiniFloatingButton(
                            icon: "chart.pie",
                            color: theme.accentSecondaryColor,
                            action: {
                                // No-op placeholder; wire to Quick Stats or Analytics if needed.
                            }
                        )
                        .transition(.scale.combined(with: .opacity))
                    }
                }
            }

            Spacer()

            // Main FAB
            if viewModel.hasScheduledBlocks && !viewModel.isDayComplete {
                MainFloatingButton(isExpanded: $buttonsExpanded, primaryAction: onQuickAdd)
            }
        }
    }
}

// MARK: - Main Floating Button (FAB)

struct MainFloatingButton: View {
    @Environment(\.themeManager) private var themeManager
    @Binding var isExpanded: Bool
    let primaryAction: () -> Void

    @State private var isPressed = false
    @State private var pulseScale: CGFloat = 1.0

    private var theme: AppTheme { themeManager?.currentTheme ?? PredefinedThemes.classic }

    var body: some View {
        Button {
            HapticManager.shared.impact()
            if isExpanded {
                primaryAction()
            } else {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { isExpanded.toggle() }
            }
        } label: {
            ZStack {
                // Outer pulse
                Circle()
                    .fill(theme.actionPrimaryGradient)
                    .opacity(0.25)
                    .frame(width: 56, height: 56)
                    .scaleEffect(pulseScale)

                // Main circular button
                Circle()
                    .fill(theme.actionPrimaryGradient)
                    .frame(width: 56, height: 56)
                    .overlay(
                        Image(systemName: isExpanded ? "xmark" : "plus")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundStyle(theme.invertedTextColor)
                            .rotationEffect(.degrees(isExpanded ? 45 : 0))
                    )
                    .shadow(color: theme.accentPrimaryColor.opacity(0.4), radius: 12, x: 0, y: 6)
                    .scaleEffect(isPressed ? 0.95 : 1.0)
            }
        }
        .onLongPressGesture(minimumDuration: 0.5) {
            // Long press = quick add
            HapticManager.shared.anchorSuccess()
            primaryAction()
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) { pulseScale = 1.4 }
        }
        .pressEvents(
            onPress: { withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { isPressed = true } },
            onRelease: { withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { isPressed = false } }
        )
    }
}

// MARK: - Mini Floating Button

struct MiniFloatingButton: View {
    let icon: String
    let color: Color
    let action: () -> Void

    @Environment(\.themeManager) private var themeManager
    @State private var isPressed = false

    private var theme: AppTheme { themeManager?.currentTheme ?? PredefinedThemes.classic }

    var body: some View {
        Button {
            HapticManager.shared.lightImpact()
            action()
        } label: {
            Circle()
                .fill(LinearGradient(colors: [color, color.opacity(0.8)],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(theme.invertedTextColor)
                )
                .shadow(color: color.opacity(0.3), radius: 8, x: 0, y: 4)
                .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .pressEvents(
            onPress: { withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { isPressed = true } },
            onRelease:{ withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { isPressed = false } }
        )
        .buttonStyle(.plain)
    }
}

// MARK: - Completion Celebration Card

struct CompletionCelebrationCard: View {
    let performanceLevel: DailyProgress.PerformanceLevel
    let onViewSummary: () -> Void

    @Environment(\.themeManager) private var themeManager
    @State private var cardScale: CGFloat = 0.8
    @State private var showConfetti = false

    private var theme: AppTheme { themeManager?.currentTheme ?? PredefinedThemes.classic }

    var body: some View {
        // Resolve the level color via the new API
        let levelColor = performanceLevel.color(theme: theme)

        VStack(spacing: 16) {
            HStack(spacing: 12) {
                Text(performanceLevel.emoji)
                    .font(.system(size: 36))
                    .scaleEffect(showConfetti ? 1.2 : 1.0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.6).repeatCount(3, autoreverses: true),
                               value: showConfetti)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Day Complete!")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(theme.primaryTextColor)

                    Text(completionMessage)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(levelColor)
                }

                Spacer()

                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        // Caller decides visibility toggle
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(theme.subtleTextColor.opacity(0.6))
                }
                .buttonStyle(.plain)
            }

            Button(action: onViewSummary) {
                HStack(spacing: 8) {
                    Image(systemName: "chart.pie.fill").font(.system(size: 14, weight: .medium))
                    Text("View Summary").font(.system(size: 14, weight: .semibold))
                }
                .foregroundStyle(theme.invertedTextColor)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(LinearGradient(colors: [levelColor, levelColor.opacity(0.8)],
                                             startPoint: .leading, endPoint: .trailing))
                )
            }
            .buttonStyle(.plain)
        }
        .padding(20)
        .background(
            // Glassy card behind celebration
            ZStack {
                RoundedRectangle(cornerRadius: 20).fill(.ultraThinMaterial)
                RoundedRectangle(cornerRadius: 20)
                    .fill(LinearGradient(
                        colors: [levelColor.opacity(0.15), levelColor.opacity(0.05)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ))
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(LinearGradient(colors: [levelColor.opacity(0.5), levelColor.opacity(0.2)],
                                       startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1)
        )
        .shadow(color: levelColor.opacity(0.3), radius: 20, x: 0, y: 10)
        .scaleEffect(cardScale)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                cardScale = 1.0
                showConfetti = true
            }
        }
        // Assumes ConfettiView exists elsewhere
        .overlay(showConfetti ? ConfettiView(isActive: $showConfetti) : nil)
    }

    private var completionMessage: String {
        switch performanceLevel {
        case .excellent: return "Outstanding performance!"
        case .good:      return "Great job today!"
        case .fair:      return "Good progress!"
        case .poor:      return "You showed up!"
        case .none:      return "Ready for tomorrow!"
        }
    }
}

// MARK: - Press Events Modifier (small utility)

struct PressEvents: ViewModifier {
    let onPress: () -> Void
    let onRelease: () -> Void

    func body(content: Content) -> some View {
        content.onLongPressGesture(
            minimumDuration: 0,
            maximumDistance: .infinity,
            pressing: { isPressing in isPressing ? onPress() : onRelease() },
            perform: {}
        )
    }
}

extension View {
    func pressEvents(onPress: @escaping () -> Void, onRelease: @escaping () -> Void) -> some View {
        modifier(PressEvents(onPress: onPress, onRelease: onRelease))
    }
}
