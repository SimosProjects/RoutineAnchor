//
//  PremiumGates.swift
//  Routine Anchor
//
//  Lightweight premium gates adapted to AppTheme tokens.
//
import SwiftUI

// MARK: - Premium Gate View
struct PremiumGateView: View {
    @Environment(\.themeManager) private var themeManager

    let feature: String
    let description: String
    let icon: String
    let onUpgrade: () -> Void

    private var theme: AppTheme { themeManager?.currentTheme ?? PredefinedThemes.classic }

    var body: some View {
        ThemedCard(cornerRadius: 20) {
            VStack(spacing: 20) {
                ZStack {
                    Image(systemName: icon)
                        .font(.system(size: 40, weight: .light))
                        .foregroundStyle(theme.subtleTextColor.opacity(0.6))

                    Image(systemName: "crown.fill")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(theme.statusWarningColor)
                        .offset(x: 20, y: -20)
                }

                VStack(spacing: 12) {
                    Text(feature)
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .foregroundStyle(theme.primaryTextColor)
                        .multilineTextAlignment(.center)

                    Text(description)
                        .font(.system(size: 16))
                        .foregroundStyle(theme.primaryTextColor.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                }

                DesignedButton(title: "Upgrade to Premium", style: .gradient, action: onUpgrade)
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - Time Block Limit Gate
struct TimeBlockLimitGate: View {
    @Environment(\.themeManager) private var themeManager

    let currentCount: Int
    let limit: Int
    let onUpgrade: () -> Void

    private var theme: AppTheme { themeManager?.currentTheme ?? PredefinedThemes.classic }

    var body: some View {
        VStack(spacing: 16) {
            VStack(spacing: 8) {
                HStack {
                    Text("Daily Time Blocks")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(theme.primaryTextColor)
                    Spacer()
                    Text("\(currentCount)/\(limit)")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(theme.primaryTextColor.opacity(0.85))
                }

                ProgressView(value: Double(currentCount), total: Double(limit))
                    .tint(theme.statusWarningColor)
                    .scaleEffect(y: 1.6)
            }

            PremiumGateView(
                feature: "Unlimited Time Blocks",
                description: "You've reached your daily limit of \(limit) time blocks. Upgrade to create unlimited blocks and supercharge your productivity.",
                icon: "calendar.badge.plus",
                onUpgrade: onUpgrade
            )
        }
    }
}

// MARK: - Analytics Gate
struct AnalyticsGate: View {
    @Environment(\.themeManager) private var themeManager
    let onUpgrade: () -> Void

    private var theme: AppTheme { themeManager?.currentTheme ?? PredefinedThemes.classic }

    var body: some View {
        ThemedCard(cornerRadius: 20) {
            VStack(spacing: 20) {
                ZStack {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 40, weight: .light))
                        .foregroundStyle(theme.subtleTextColor.opacity(0.6))

                    Image(systemName: "crown.fill")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(theme.statusWarningColor)
                        .offset(x: 20, y: -20)
                }

                VStack(spacing: 12) {
                    Text("Advanced Analytics")
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .foregroundStyle(theme.primaryTextColor)
                        .multilineTextAlignment(.center)

                    Text("Unlock detailed insights, productivity trends, and personalized recommendations to optimize your routine.")
                        .font(.system(size: 16))
                        .foregroundStyle(theme.primaryTextColor.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                }

                DesignedButton(title: "Upgrade to Premium", style: .gradient, action: onUpgrade)
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - Templates / Themes / Widgets Gates
struct TemplatesGate: View {
    let currentCount: Int
    let limit: Int
    let onUpgrade: () -> Void
    var body: some View {
        PremiumGateView(
            feature: "Unlimited Templates",
            description: "Save and reuse unlimited routine templates. You've used \(currentCount) of \(limit) free templates.",
            icon: "doc.on.doc.fill",
            onUpgrade: onUpgrade
        )
    }
}

struct ThemesGate: View {
    let onUpgrade: () -> Void
    var body: some View {
        PremiumGateView(
            feature: "Premium Themes",
            description: "Customize your experience with beautiful premium themes and personalization options.",
            icon: "paintbrush.fill",
            onUpgrade: onUpgrade
        )
    }
}

struct WidgetsGate: View {
    let onUpgrade: () -> Void
    var body: some View {
        PremiumGateView(
            feature: "Widgets & Complications",
            description: "Add Routine Anchor widgets to your home screen and Apple Watch for quick access to your schedule.",
            icon: "widget.medium",
            onUpgrade: onUpgrade
        )
    }
}

// MARK: - Premium Badge
struct PremiumBadge: View {
    @Environment(\.themeManager) private var themeManager
    private var theme: AppTheme { themeManager?.currentTheme ?? PredefinedThemes.classic }

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "crown.fill").font(.system(size: 12, weight: .medium))
            Text("PRO").font(.system(size: 12, weight: .bold))
        }
        .foregroundStyle(theme.invertedTextColor)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule().fill(
                LinearGradient(colors: [theme.statusWarningColor, theme.statusSuccessColor],
                               startPoint: .leading, endPoint: .trailing)
            )
        )
    }
}

// MARK: - Premium Feature Card
struct PremiumFeatureCard: View {
    @Environment(\.themeManager) private var themeManager

    let feature: PremiumManager.PremiumFeature
    let isLocked: Bool
    let onTap: () -> Void

    private var theme: AppTheme { themeManager?.currentTheme ?? PredefinedThemes.classic }

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                ZStack {
                    Image(systemName: feature.icon)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundStyle(isLocked ? theme.subtleTextColor.opacity(0.65) : theme.primaryTextColor)
                    if isLocked {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(theme.statusWarningColor)
                            .offset(x: 12, y: -12)
                    }
                }

                VStack(spacing: 4) {
                    Text(feature.displayName)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(isLocked ? theme.subtleTextColor : theme.primaryTextColor)
                        .multilineTextAlignment(.center)

                    if isLocked { PremiumBadge().scaleEffect(0.8) }
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 100)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(
                        isLocked
                        ? theme.surfaceCardColor.opacity(0.85)
                        : theme.surfaceCardColor.opacity(0.95)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(theme.glassMaterialOverlay)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(isLocked ? theme.borderColor.opacity(0.9)
                                              : theme.accentPrimaryColor.opacity(0.35),
                                    lineWidth: 1)
                    )
            )
        }
        .disabled(isLocked)
        .scaleEffect(isLocked ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isLocked)
    }
}

// MARK: - Premium Mini Prompt
struct PremiumMiniPrompt: View {
    @Environment(\.themeManager) private var themeManager

    let title: String
    let subtitle: String
    let onUpgrade: () -> Void

    private var theme: AppTheme { themeManager?.currentTheme ?? PredefinedThemes.classic }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "crown.fill")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(theme.statusWarningColor)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(theme.primaryTextColor)

                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundStyle(theme.primaryTextColor.opacity(0.7))
            }

            Spacer()

            Button("Upgrade") {
                onUpgrade()
                HapticManager.shared.anchorSelection()
            }
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(theme.invertedTextColor)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Capsule().fill(theme.accentPrimaryColor))
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(theme.surfaceCardColor.opacity(0.92))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(theme.glassMaterialOverlay)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(theme.accentPrimaryColor.opacity(0.35), lineWidth: 1)
                )
        )
    }
}

// MARK: - View helpers
extension View {
    /// Apply premium gating to a view
    func premiumGated(
        isUnlocked: Bool,
        feature: String,
        description: String,
        icon: String,
        onUpgrade: @escaping () -> Void
    ) -> some View {
        Group {
            if isUnlocked {
                self
            } else {
                PremiumGateView(
                    feature: feature,
                    description: description,
                    icon: icon,
                    onUpgrade: onUpgrade
                )
            }
        }
    }

    /// Add a premium badge overlay
    func premiumBadged() -> some View {
        overlay(
            PremiumBadge()
                .offset(x: 8, y: -8),
            alignment: .topTrailing
        )
    }
}
