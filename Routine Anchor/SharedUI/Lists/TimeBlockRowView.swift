//
//  TimeBlockRowView.swift
//  Routine Anchor
//
//  Uses AppTheme semantics:
//  - surfaceCardColor / borderColor for the container
//  - accentPrimary/secondary + status colors for accents
//

import SwiftUI

struct TimeBlockRowView: View {
    @Environment(\.themeManager) private var themeManager

    let timeBlock: TimeBlock
    let showActions: Bool
    let onStart:   (() -> Void)?
    let onComplete:(() -> Void)?
    let onSkip:    (() -> Void)?
    let onEdit:    (() -> Void)?
    let onDelete:  (() -> Void)?

    @State private var isPressed = false
    @State private var shimmerPhase: CGFloat = 0

    private var theme: AppTheme { themeManager?.currentTheme ?? PredefinedThemes.classic }

    init(
        timeBlock: TimeBlock,
        showActions: Bool = true,
        onStart: (() -> Void)? = nil,
        onComplete: (() -> Void)? = nil,
        onSkip: (() -> Void)? = nil,
        onEdit: (() -> Void)? = nil,
        onDelete: (() -> Void)? = nil
    ) {
        self.timeBlock = timeBlock
        self.showActions = showActions
        self.onStart = onStart
        self.onComplete = onComplete
        self.onSkip = onSkip
        self.onEdit = onEdit
        self.onDelete = onDelete
    }

    var body: some View {
        HStack(spacing: 0) {
            // Left accent bar
            accentBar

            HStack(spacing: 16) {
                timeBadge
                mainContent
                Spacer(minLength: 8)
                if showActions { actionButtons }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        .background(backgroundLayer)
        .overlay(overlayStroke)
        .shadow(color: statusColor.opacity(0.20), radius: 12, x: 0, y: 6)
        .scaleEffect(isPressed ? 0.97 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
        .onAppear {
            withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
                shimmerPhase = 1
            }
        }
    }

    // MARK: - Accent Bar

    private var accentBar: some View {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
            .fill(
                LinearGradient(colors: accentColors, startPoint: .topLeading, endPoint: .bottomTrailing)
            )
            .frame(width: 5)
            .overlay(
                // Subtle shimmer when in-progress
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [.clear, theme.primaryTextColor.opacity(0.30), .clear],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
                    .offset(y: shimmerPhase * 100 - 50)
                    .opacity(timeBlock.status == .inProgress ? 1 : 0)
            )
    }

    // MARK: - Time Badge

    private var timeBadge: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .stroke(
                        LinearGradient(colors: [statusColor, statusColor.opacity(0.3)],
                                       startPoint: .topLeading, endPoint: .bottomTrailing),
                        lineWidth: 2
                    )
                    .frame(width: 42, height: 42)

                Circle()
                    .fill(
                        LinearGradient(colors: [statusColor.opacity(0.30), statusColor.opacity(0.10)],
                                       startPoint: .top, endPoint: .bottom)
                    )
                    .frame(width: 36, height: 36)
                    .overlay(
                        Circle().stroke(theme.primaryTextColor.opacity(0.20), lineWidth: 0.5)
                    )

                Image(systemName: timeBlock.status.iconName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(statusColor)
                    .shadow(color: statusColor.opacity(0.3), radius: 2, x: 0, y: 1)
            }

            VStack(spacing: 2) {
                Text(timeBlock.startTime.formatted(date: .omitted, time: .shortened))
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [theme.primaryTextColor, theme.primaryTextColor.opacity(0.9)],
                            startPoint: .top, endPoint: .bottom
                        )
                    )

                Text(timeBlock.formattedDuration)
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundStyle(theme.secondaryTextColor)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        Capsule().fill(theme.surfaceCardColor.opacity(0.30))
                    )
            }
        }
    }

    // MARK: - Main Content

    private var mainContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                if let emoji = timeBlock.icon {
                    Text(emoji)
                        .font(.system(size: 24))
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(timeBlock.title)
                        .font(.system(size: 19, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [theme.primaryTextColor, theme.primaryTextColor.opacity(0.95)],
                                startPoint: .leading, endPoint: .trailing
                            )
                        )
                        .lineLimit(1)

                    if let category = timeBlock.category {
                        HStack(spacing: 4) {
                            Image(systemName: "folder.fill")
                                .font(.system(size: 9, weight: .semibold))

                            Text(category.uppercased())
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .tracking(0.5)
                        }
                        .foregroundStyle(categoryColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(
                            Capsule()
                                .fill(categoryColor.opacity(0.20))
                                .overlay(Capsule().stroke(categoryColor.opacity(0.30), lineWidth: 0.5))
                        )
                    }
                }
            }

            if let notes = timeBlock.notes, !notes.isEmpty {
                Text(notes)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(theme.secondaryTextColor.opacity(0.9))
                    .lineLimit(2)
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(theme.surfaceCardColor.opacity(0.20))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .stroke(
                                        LinearGradient(
                                            colors: [theme.borderColor.opacity(0.30), theme.borderColor.opacity(0.10)],
                                            startPoint: .topLeading, endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 0.5
                                    )
                            )
                    )
            }

            if timeBlock.status == .inProgress {
                inlineProgressBar
            }
        }
    }

    // MARK: - Inline Progress

    private var inlineProgressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(theme.surfaceCardColor.opacity(0.30))
                    .frame(height: 4)

                Capsule()
                    .fill(LinearGradient(colors: [theme.accentPrimaryColor, theme.accentPrimaryColor.opacity(0.7)],
                                         startPoint: .leading, endPoint: .trailing))
                    .frame(width: geo.size.width * progressPercentage, height: 4)
                    .animation(.linear(duration: 1), value: progressPercentage)
            }
        }
        .frame(height: 4)
    }

    private var progressPercentage: CGFloat {
        guard timeBlock.status == .inProgress else { return 0 }
        let now = Date()
        let total = timeBlock.endTime.timeIntervalSince(timeBlock.startTime)
        let elapsed = now.timeIntervalSince(timeBlock.startTime)
        return CGFloat(min(max(elapsed / total, 0), 1))
    }

    // MARK: - Actions

    @ViewBuilder
    private var actionButtons: some View {
        HStack(spacing: 10) {
            if onStart != nil || onComplete != nil || onSkip != nil {
                todayViewActions
            } else if onEdit != nil || onDelete != nil {
                scheduleViewActions
            }
        }
    }

    @ViewBuilder
    private var todayViewActions: some View {
        switch timeBlock.status {
        case .notStarted:
            if let onStart { TimeBlockActionButton(icon: "play.fill", color: theme.statusSuccessColor, action: onStart, isLarge: true) }
        case .inProgress:
            HStack(spacing: 8) {
                if let onComplete { TimeBlockActionButton(icon: "checkmark.circle.fill", color: theme.statusSuccessColor, action: onComplete, isLarge: true) }
                if let onSkip     { TimeBlockActionButton(icon: "forward.fill", color: theme.statusWarningColor, action: onSkip) }
            }
        case .completed, .skipped:
            Image(systemName: timeBlock.status == .completed ? "checkmark.seal.fill" : "forward.circle.fill")
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(
                    LinearGradient(
                        colors: (timeBlock.status == .completed)
                        ? [theme.statusSuccessColor, theme.statusSuccessColor.opacity(0.7)]
                        : [theme.statusWarningColor, theme.statusWarningColor.opacity(0.7)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                )
        }
    }

    @ViewBuilder
    private var scheduleViewActions: some View {
        if let onEdit {
            TimeBlockActionButton(icon: "pencil.circle", color: theme.accentPrimaryColor, action: onEdit)
        }
        if let onDelete {
            TimeBlockActionButton(icon: "trash.circle", color: theme.statusErrorColor, action: onDelete)
        }
    }

    // MARK: - Background & Border

    private var backgroundLayer: some View {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [theme.surfaceCardColor.opacity(0.75), theme.surfaceCardColor.opacity(0.55)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [theme.surfaceGlassColor.opacity(0.15), theme.surfaceGlassColor.opacity(0.05)],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
            )
    }

    private var overlayStroke: some View {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
            .stroke(
                LinearGradient(
                    colors: [theme.borderColor.opacity(0.30), theme.borderColor.opacity(0.10)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                ),
                lineWidth: 1
            )
    }

    // MARK: - Color helpers

    private var statusColor: Color {
        switch timeBlock.status {
        case .notStarted: return theme.secondaryTextColor
        case .inProgress: return theme.accentPrimaryColor
        case .completed:  return theme.statusSuccessColor
        case .skipped:    return theme.statusWarningColor
        }
    }

    private var accentColors: [Color] {
        switch timeBlock.status {
        case .notStarted: return [theme.accentSecondaryColor, theme.accentSecondaryColor.opacity(0.7)]
        case .inProgress: return [theme.accentPrimaryColor, theme.accentPrimaryColor.opacity(0.7)]
        case .completed:  return [theme.statusSuccessColor, theme.statusSuccessColor.opacity(0.7)]
        case .skipped:    return [theme.statusWarningColor, theme.statusWarningColor.opacity(0.7)]
        }
    }

    private var categoryColor: Color {
        switch timeBlock.category?.lowercased() {
        case "work":     return theme.accentPrimaryColor
        case "personal": return theme.accentSecondaryColor
        case "health":   return theme.statusSuccessColor
        case "learning": return theme.accentSecondaryColor
        default:         return theme.secondaryTextColor
        }
    }
}

// MARK: - Action Button

struct TimeBlockActionButton: View {
    @Environment(\.themeManager) private var themeManager
    let icon: String
    let color: Color
    let action: () -> Void
    var isLarge: Bool = false

    @State private var isPressed = false
    private var theme: AppTheme { themeManager?.currentTheme ?? PredefinedThemes.classic }

    var body: some View {
        Button(action: {
            HapticManager.shared.lightImpact()
            action()
        }) {
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [color.opacity(0.30), color.opacity(0.10)],
                                         startPoint: .topLeading, endPoint: .bottomTrailing))
                Circle()
                    .fill(theme.surfaceGlassColor.opacity(0.10))
                    .blur(radius: 1)
                Circle()
                    .stroke(LinearGradient(colors: [color, color.opacity(0.5)],
                                           startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1.5)
                Image(systemName: icon)
                    .font(.system(size: isLarge ? 20 : 16, weight: .semibold))
                    .foregroundStyle(LinearGradient(colors: [color, color.opacity(0.8)],
                                                    startPoint: .top, endPoint: .bottom))
                    .shadow(color: color.opacity(0.3), radius: 2, x: 0, y: 1)
            }
            .frame(width: isLarge ? 44 : 36, height: isLarge ? 44 : 36)
            .scaleEffect(isPressed ? 0.9 : 1.0)
        }
        .buttonStyle(.plain)
        .onLongPressGesture(minimumDuration: .infinity, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) { isPressed = pressing }
        }, perform: {})
    }
}
