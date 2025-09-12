//
//  SharedTimeBlockComponents.swift
//  Routine Anchor
//  Swift 6 Compatible Version
//
//  Created by Christopher Simonson on 7/22/25.
//

import SwiftUI

// MARK: - Shared Category Selector Component
struct CategorySelector: View {
    let categories: [String]
    @Environment(\.themeManager) private var themeManager
    @Binding var selectedCategory: String
    
    var body: some View {
        let theme  = (themeManager?.currentTheme ?? Theme.defaultTheme)
        let scheme = theme.colorScheme
        
        return LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
            // No category option
            CategoryChip(
                title: "No Category",
                isSelected: selectedCategory.isEmpty,
                color: theme.secondaryTextColor.opacity(0.85)
            ) {
                selectedCategory = ""
            }
            
            ForEach(categories, id: \.self) { category in
                CategoryChip(
                    title: category,
                    isSelected: selectedCategory == category,
                    color: categoryColor(for: category, scheme: scheme, theme: theme)
                ) {
                    selectedCategory = category
                }
            }
        }
    }
    
    private func categoryColor(for category: String, scheme: ThemeColorScheme, theme: Theme) -> Color {
        switch category.lowercased() {
        case "work":     return scheme.normal.color
        case "personal": return scheme.primaryAccent.color
        case "health":   return scheme.success.color
        case "learning": return scheme.secondaryUIElement.color
        case "social":   return scheme.warning.color
        default:         return theme.secondaryTextColor.opacity(0.85)
        }
    }
}

// MARK: - Shared Icon Selector Component
struct IconSelector: View {
    let icons: [String]
    @Binding var selectedIcon: String
    
    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
            // No icon option
            IconChip(icon: nil, isSelected: selectedIcon.isEmpty) {
                selectedIcon = ""
            }
            ForEach(icons, id: \.self) { icon in
                IconChip(icon: icon, isSelected: selectedIcon == icon) {
                    selectedIcon = icon
                }
            }
        }
    }
}

// MARK: - Shared Quick Duration Selector Component
struct QuickDurationSelector: View {
    @Binding var selectedDuration: Int?
    let onSelect: (Int) -> Void
    
    private let durations = [15, 30, 45, 60, 90, 120]
    
    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
            ForEach(durations, id: \.self) { minutes in
                DurationChip(
                    minutes: minutes,
                    isSelected: selectedDuration == minutes
                ) {
                    onSelect(minutes)
                }
            }
        }
    }
}

// MARK: - Shared History Row Component (for Edit view)
struct HistoryRow: View {
    @Environment(\.themeManager) private var themeManager
    let title: String
    let date: Date
    let icon: String
    
    var body: some View {
        let theme  = (themeManager?.currentTheme ?? Theme.defaultTheme)
        let scheme = theme.colorScheme
        
        return HStack(spacing: 12) {
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
            RoundedRectangle(cornerRadius: 10)
                .fill(scheme.secondaryBackground.color.opacity(0.55))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(scheme.border.color.opacity(0.8), lineWidth: 1)
        )
    }
}

// MARK: - Shared Base Form View
struct TimeBlockFormView<Content: View>: View {
    let title: String
    let icon: String
    let subtitle: String
    let content: Content
    let onDismiss: () -> Void
    
    @Environment(\.themeManager) private var themeManager
    @State private var animationPhase = 0
    @State private var isVisible = false
    
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
        let theme  = (themeManager?.currentTheme ?? Theme.defaultTheme)
        let scheme = theme.colorScheme

        return ZStack {
            ThemedHeroBackground()

            // Keep your overlays
            AnimatedMeshBackground()
                .opacity(0.3)
                .allowsHitTesting(false)

            ParticleEffectView()
                .allowsHitTesting(false)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    headerSection(theme: theme, scheme: scheme)
                    content
                        .padding(.bottom, 40)
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
            }
        }
        .navigationBarHidden(true)
        .task { await startAnimations() }
    }

    
    private func headerSection(theme: Theme, scheme: ThemeColorScheme) -> some View {
        VStack(spacing: 16) {
            HStack {
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(theme.primaryTextColor.opacity(0.8))
                        .frame(width: 36, height: 36)
                        .background(
                            Circle()
                                .fill(scheme.primaryUIElement.color.opacity(0.65))
                                .overlay(
                                    Circle().stroke(scheme.border.color.opacity(0.8), lineWidth: 1)
                                )
                        )
                        .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                }
                
                Spacer()
            }
            
            VStack(spacing: 12) {
                // Animated icon glow using hero tokens
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    (scheme.backgroundColors.first ?? scheme.primaryBackground).color.opacity(0.55),
                                    (scheme.backgroundColors.last  ?? scheme.secondaryBackground).color.opacity(0.25),
                                    .clear
                                ],
                                center: .center,
                                startRadius: 30,
                                endRadius: 90
                            )
                        )
                        .frame(width: 80, height: 80)
                        .blur(radius: 20)
                        .scaleEffect(animationPhase == 0 ? 1.0 : 1.3)
                    
                    Image(systemName: icon)
                        .font(.system(size: 48, weight: .light))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [scheme.normal.color, scheme.primaryAccent.color],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .scaleEffect(animationPhase == 0 ? 1.0 : 1.1)
                        .shadow(color: scheme.focusRing.color.opacity(0.35), radius: 20, x: 0, y: 10)
                }
                
                VStack(spacing: 8) {
                    Text(title)
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [scheme.normal.color, scheme.primaryAccent.color],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
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
