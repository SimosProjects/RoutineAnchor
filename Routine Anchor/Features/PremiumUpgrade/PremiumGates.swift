//
//  PremiumGates.swift
//  Routine Anchor
//
//  Premium gating components and views
//
import SwiftUI

// MARK: - Premium Gate View
struct PremiumGateView: View {
    @Environment(\.themeManager) private var themeManager
    let feature: String
    let description: String
    let icon: String
    let onUpgrade: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            // Icon and crown
            ZStack {
                Image(systemName: icon)
                    .font(.system(size: 40, weight: .light))
                    .foregroundStyle(.white.opacity(0.3))
                
                Image(systemName: "crown.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Color.anchorWarning)
                    .offset(x: 20, y: -20)
            }
            
            VStack(spacing: 12) {
                Text(feature)
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundStyle(themeManager?.currentTheme.textPrimaryColor ?? Theme.defaultTheme.textPrimaryColor)
                    .multilineTextAlignment(.center)
                
                Text(description)
                    .font(.system(size: 16))
                    .foregroundStyle((themeManager?.currentTheme.textPrimaryColor ?? Theme.defaultTheme.textPrimaryColor).opacity(0.7))
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
            }
            
            DesignedButton(
                title: "Upgrade to Premium",
                style: .gradient,
                action: onUpgrade
            )
        }
        .padding(24)
        .themedGlassMorphism(cornerRadius: 20)
        .padding(.horizontal)
    }
}

// MARK: - Time Block Limit Gate
struct TimeBlockLimitGate: View {
    @Environment(\.themeManager) private var themeManager
    let currentCount: Int
    let limit: Int
    let onUpgrade: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            // Progress indicator
            VStack(spacing: 8) {
                HStack {
                    Text("Daily Time Blocks")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(themeManager?.currentTheme.textPrimaryColor ?? Theme.defaultTheme.textPrimaryColor)
                    
                    Spacer()
                    
                    Text("\(currentCount)/\(limit)")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle((themeManager?.currentTheme.textPrimaryColor ?? Theme.defaultTheme.textPrimaryColor).opacity(0.8))
                }
                
                ProgressView(value: Double(currentCount), total: Double(limit))
                    .progressViewStyle(LinearProgressViewStyle(tint: Color.anchorWarning))
                    .scaleEffect(y: 2)
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
    
    var body: some View {
        VStack(spacing: 20) {
            // Icon and crown
            ZStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 40, weight: .light))
                    .foregroundStyle(.white.opacity(0.3))
                
                Image(systemName: "crown.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Color.anchorWarning)
                    .offset(x: 20, y: -20)
            }
            
            VStack(spacing: 12) {
                Text("Advanced Analytics")
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundStyle(themeManager?.currentTheme.textPrimaryColor ?? Theme.defaultTheme.textPrimaryColor)
                    .multilineTextAlignment(.center)
                
                Text("Unlock detailed insights, productivity trends, and personalized recommendations to optimize your routine.")
                    .font(.system(size: 16))
                    .foregroundStyle((themeManager?.currentTheme.textPrimaryColor ?? Theme.defaultTheme.textPrimaryColor).opacity(0.7))
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
            }
            
            DesignedButton(
                title: "Upgrade to Premium",
                style: .gradient,
                action: onUpgrade
            )
        }
        .padding(24)
        .themedGlassMorphism(cornerRadius: 20)
        .padding(.horizontal)
    }
}

// MARK: - Templates Gate
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

// MARK: - Themes Gate
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

// MARK: - Widgets Gate
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
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "crown.fill")
                .font(.system(size: 12, weight: .medium))
            
            Text("PRO")
                .font(.system(size: 12, weight: .bold))
        }
        .foregroundStyle(themeManager?.currentTheme.textPrimaryColor ?? Theme.defaultTheme.textPrimaryColor)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [Color.anchorWarning, Color.anchorGreen],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
        )
    }
}

// MARK: - Premium Feature Card
struct PremiumFeatureCard: View {
    let feature: PremiumManager.PremiumFeature
    let isLocked: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                // Icon with lock overlay
                ZStack {
                    Image(systemName: feature.icon)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundStyle(isLocked ? .white.opacity(0.3) : .white)
                    
                    if isLocked {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Color.anchorWarning)
                            .offset(x: 12, y: -12)
                    }
                }
                
                VStack(spacing: 4) {
                    Text(feature.displayName)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(isLocked ? .white.opacity(0.5) : .white)
                        .multilineTextAlignment(.center)
                    
                    if isLocked {
                        PremiumBadge()
                            .scaleEffect(0.8)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 100)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        isLocked
                        ? Color.white.opacity(0.05)
                        : Color.anchorBlue.opacity(0.1)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                isLocked
                                ? Color.white.opacity(0.1)
                                : Color.anchorBlue.opacity(0.3),
                                lineWidth: 1
                            )
                    )
            )
        }
        .disabled(isLocked)
        .scaleEffect(isLocked ? 0.95 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isLocked)
    }
}

// MARK: - Premium Mini Prompt
struct PremiumMiniPrompt: View {
    @Environment(\.themeManager) private var themeManager
    let title: String
    let subtitle: String
    let onUpgrade: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "crown.fill")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Color.anchorWarning)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(themeManager?.currentTheme.textPrimaryColor ?? Theme.defaultTheme.textPrimaryColor)
                
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundStyle((themeManager?.currentTheme.textPrimaryColor ?? Theme.defaultTheme.textPrimaryColor).opacity(0.7))
            }
            
            Spacer()
            
            Button("Upgrade") {
                onUpgrade()
                HapticManager.shared.anchorSelection()
            }
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(themeManager?.currentTheme.textPrimaryColor ?? Theme.defaultTheme.textPrimaryColor)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(Color.anchorBlue)
            )
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.anchorBlue.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.anchorBlue.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - Usage Examples and View Modifiers
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
