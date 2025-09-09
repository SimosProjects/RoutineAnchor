//
//  SharedTimeBlockComponents.swift
//  Routine Anchor
//
//  Shared UI building blocks for Add/Edit flow.
//

import SwiftUI

// MARK: - Category Selector

struct CategorySelector: View {
    let categories: [String]
    @Environment(\.themeManager) private var themeManager
    @Binding var selectedCategory: String

    private var theme: AppTheme { themeManager?.currentTheme ?? PredefinedThemes.classic }

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
            CategoryChip(
                title: "No Category",
                isSelected: selectedCategory.isEmpty,
                color: theme.secondaryTextColor.opacity(0.85)
            ) { selectedCategory = "" }

            ForEach(categories, id: \.self) { category in
                CategoryChip(
                    title: category,
                    isSelected: selectedCategory == category,
                    color: categoryColor(for: category)
                ) { selectedCategory = category }
            }
        }
    }

    private func categoryColor(for category: String) -> Color {
        switch category.lowercased() {
        case "work":     return theme.accentPrimaryColor
        case "personal": return theme.accentSecondaryColor
        case "health":   return theme.statusSuccessColor
        case "learning": return theme.accentSecondaryColor
        case "social":   return theme.statusWarningColor
        default:         return theme.secondaryTextColor.opacity(0.85)
        }
    }
}

// MARK: - Icon Selector

struct IconSelector: View {
    let icons: [String]
    @Binding var selectedIcon: String

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
            IconChip(icon: nil, isSelected: selectedIcon.isEmpty) { selectedIcon = "" }
            ForEach(icons, id: \.self) { icon in
                IconChip(icon: icon, isSelected: selectedIcon == icon) { selectedIcon = icon }
            }
        }
    }
}

// MARK: - Quick Duration Selector

struct QuickDurationSelector: View {
    @Binding var selectedDuration: Int?
    let onSelect: (Int) -> Void

    private let durations = [15, 30, 45, 60, 90, 120]

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
            ForEach(durations, id: \.self) { minutes in
                DurationChip(minutes: minutes, isSelected: selectedDuration == minutes) {
                    onSelect(minutes)
                }
            }
        }
    }
}

// MARK: - History Row

struct HistoryRow: View {
    @Environment(\.themeManager) private var themeManager
    let title: String
    let date: Date
    let icon: String

    private var theme: AppTheme { themeManager?.currentTheme ?? PredefinedThemes.classic }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(theme.secondaryTextColor)
                .frame(width: 20, height: 20)

            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(theme.primaryTextColor)

            Spacer()

            Text(date.formatted(date: .abbreviated, time: .shortened))
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundStyle(theme.secondaryTextColor)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10).fill(theme.surfaceCardColor.opacity(0.55))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10).stroke(theme.borderColor.opacity(0.8), lineWidth: 1)
        )
    }
}

// MARK: - Base Form Scaffold

/// A simple scaffold used by both Add and Edit screens.
struct TimeBlockFormView<Content: View>: View {
    let title: String
    let icon: String
    let subtitle: String
    let content: Content
    let onDismiss: () -> Void

    @Environment(\.themeManager) private var themeManager
    @State private var animationPhase = 0
    @State private var isVisible = false

    private var theme: AppTheme { themeManager?.currentTheme ?? PredefinedThemes.classic }

    init(
        title: String,
        icon: String,
        subtitle: String,
        onDismiss: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.icon = icon
        self.subtitle = subtitle
        self.onDismiss = onDismiss
        self.content = content()
    }

    var body: some View {
        ZStack {
            ThemedAnimatedBackground()
                .ignoresSafeArea()

            // Optional overlays you already have.
            AnimatedMeshBackground().opacity(0.3).allowsHitTesting(false)
            ParticleEffectView().allowsHitTesting(false)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    headerSection
                    content.padding(.bottom, 40)
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
            }
        }
        .navigationBarHidden(true)
        .task { await startAnimations() }
    }

    private var headerSection: some View {
        VStack(spacing: 16) {
            HStack {
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(theme.primaryTextColor.opacity(0.8))
                        .frame(width: 36, height: 36)
                        .background(
                            Circle()
                                .fill(theme.surfaceCardColor.opacity(0.65))
                                .overlay(Circle().stroke(theme.borderColor.opacity(0.8), lineWidth: 1))
                        )
                        .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                }
                Spacer()
            }

            VStack(spacing: 12) {
                // Animated glow
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [theme.accentPrimaryColor.opacity(0.55),
                                         theme.accentSecondaryColor.opacity(0.25),
                                         .clear],
                                center: .center, startRadius: 30, endRadius: 90
                            )
                        )
                        .frame(width: 80, height: 80)
                        .blur(radius: 20)
                        .scaleEffect(animationPhase == 0 ? 1.0 : 1.3)

                    Image(systemName: icon)
                        .font(.system(size: 48, weight: .light))
                        .foregroundStyle(
                            LinearGradient(colors: [theme.accentPrimaryColor, theme.accentSecondaryColor],
                                           startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .scaleEffect(animationPhase == 0 ? 1.0 : 1.1)
                        .shadow(color: theme.accentPrimaryColor.opacity(0.35), radius: 20, x: 0, y: 10)
                }

                VStack(spacing: 8) {
                    Text(title)
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(colors: [theme.accentPrimaryColor, theme.accentSecondaryColor],
                                           startPoint: .leading, endPoint: .trailing)
                        )

                    Text(subtitle)
                        .font(.system(size: 18, weight: .medium, design: .rounded))
                        .foregroundStyle(theme.secondaryTextColor)
                }
            }
        }
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : -20)
    }

    @MainActor
    private func startAnimations() async {
        withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
            animationPhase = 1
        }
        withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.1)) {
            isVisible = true
        }
    }
}
