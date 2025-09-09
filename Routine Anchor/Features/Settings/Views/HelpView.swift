//
//  HelpView.swift
//  Routine Anchor
//

import SwiftUI

struct HelpView: View {
    @Environment(\.themeManager) private var themeManager
    @Environment(\.dismiss) private var dismiss
    @State private var animationPhase = 0
    @State private var searchText = ""
    @State private var animationTask: Task<Void, Never>?
    @State private var selectedCategory: HelpCategory = .gettingStarted

    private var theme: AppTheme { themeManager?.currentTheme ?? PredefinedThemes.classic }

    // Category tint using semantic tokens
    private func categoryColor(for category: HelpCategory) -> Color {
        switch category {
        case .all:              return theme.accentPrimaryColor
        case .gettingStarted:   return theme.statusSuccessColor
        case .timeBlocks:       return theme.accentSecondaryColor
        case .notifications:    return theme.statusWarningColor
        case .settings:         return theme.accentPrimaryColor.opacity(0.85)
        case .troubleshooting:  return theme.statusErrorColor
        }
    }

    var body: some View {
        ZStack {
            ThemedAnimatedBackground()
            AnimatedMeshBackground().opacity(0.3).allowsHitTesting(false)
            ParticleEffectView().allowsHitTesting(false)

            VStack(spacing: 0) {
                headerSection
                searchSection
                categoryPicker

                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(filteredHelpItems, id: \.id) { item in
                            HelpItemView(item: item, categoryColor: categoryColor(for: item.category))
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
                .background(Color.clear)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            animationTask = Task { @MainActor in
                while !Task.isCancelled {
                    withAnimation(.easeInOut(duration: 2)) { animationPhase = 1 }
                    try? await Task.sleep(nanoseconds: 2_000_000_000)
                }
            }
        }
        .onDisappear { animationTask?.cancel(); animationTask = nil }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 16) {
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(theme.primaryTextColor.opacity(0.85))
                        .frame(width: 32, height: 32)
                        .background(
                            Circle()
                                .fill(.ultraThinMaterial)
                                .background(Circle().fill(theme.color.surface.card.opacity(0.7)))
                        )
                }
                Spacer()
                Button(action: contactSupport) {
                    HStack(spacing: 6) {
                        Image(systemName: "envelope").font(.system(size: 14, weight: .medium))
                        Text("Support").font(.system(size: 14, weight: .medium))
                    }
                    .foregroundStyle(theme.accentPrimaryColor)
                    .padding(.horizontal, 12).padding(.vertical, 6)
                    .background(theme.color.surface.card.opacity(0.7))
                    .cornerRadius(8)
                }
            }

            VStack(spacing: 12) {
                Image(systemName: "questionmark.circle")
                    .font(.system(size: 48, weight: .light))
                    .foregroundStyle(
                        LinearGradient(colors: [theme.accentPrimaryColor, theme.accentSecondaryColor],
                                       startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .scaleEffect(animationPhase == 0 ? 1.0 : 1.1)
                    .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: animationPhase)

                Text("Help & Support")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(theme.primaryTextColor)

                Text("Find answers and get the most out of Routine Anchor")
                    .font(.system(size: 14))
                    .foregroundStyle(theme.secondaryTextColor)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 20)
    }

    // MARK: - Search

    private var searchSection: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(theme.secondaryTextColor)

            TextField("Search help topics...", text: $searchText)
                .font(.system(size: 15))
                .foregroundStyle(theme.primaryTextColor)
                .textFieldStyle(.plain)

            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(theme.secondaryTextColor)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .background(
                    RoundedRectangle(cornerRadius: 12).fill(theme.color.surface.card.opacity(0.55))
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12).stroke(theme.borderColor, lineWidth: 1)
        )
        .padding(.horizontal, 24)
        .padding(.top, 16)
    }

    // MARK: - Category Picker

    private var categoryPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(HelpCategory.allCases, id: \.self) { category in
                    HelpCategoryChip(
                        category: category,
                        categoryColor: categoryColor(for: category),
                        isSelected: selectedCategory == category,
                        action: { selectedCategory = category }
                    )
                }
            }.padding(.horizontal, 24)
        }
        .padding(.top, 16)
    }

    // MARK: - Data

    private var filteredHelpItems: [HelpItem] {
        let scoped = helpItems.filter { selectedCategory == .all || $0.category == selectedCategory }
        guard !searchText.isEmpty else { return scoped }
        return scoped.filter { item in
            item.title.localizedCaseInsensitiveContains(searchText) ||
            item.content.localizedCaseInsensitiveContains(searchText) ||
            item.keywords.contains { $0.localizedCaseInsensitiveContains(searchText) }
        }
    }

    // MARK: - Actions

    private func contactSupport() {
        HapticManager.shared.lightImpact()
        if let url = URL(string: "mailto:support@routineanchor.com?subject=Help%20Request") {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Chips, Models, Items (unchanged except theming)

private struct HelpCategoryChip: View {
    @Environment(\.themeManager) private var themeManager
    let category: HelpCategory
    let categoryColor: Color
    let isSelected: Bool
    let action: () -> Void
    private var theme: AppTheme { themeManager?.currentTheme ?? PredefinedThemes.classic }

    var body: some View {
        Button(action: { HapticManager.shared.lightImpact(); action() }) {
            HStack(spacing: 6) {
                Image(systemName: category.icon).font(.system(size: 14, weight: .medium))
                Text(category.title).font(.system(size: 14, weight: .medium))
            }
            .foregroundStyle(isSelected ? theme.textInverted : theme.secondaryTextColor)
            .padding(.horizontal, 12).padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? categoryColor : theme.color.surface.card.opacity(0.7))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8).stroke(isSelected ? .clear : theme.borderColor, lineWidth: 1)
            )
        }
        .scaleEffect(isSelected ? 1.0 : 0.95)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

private enum HelpCategory: CaseIterable {
    case all, gettingStarted, timeBlocks, notifications, settings, troubleshooting

    var title: String {
        switch self {
        case .all: return "All"
        case .gettingStarted: return "Getting Started"
        case .timeBlocks: return "Time Blocks"
        case .notifications: return "Notifications"
        case .settings: return "Settings"
        case .troubleshooting: return "Troubleshooting"
        }
    }
    var icon: String {
        switch self {
        case .all: return "grid.circle"
        case .gettingStarted: return "play.circle"
        case .timeBlocks: return "clock"
        case .notifications: return "bell"
        case .settings: return "gear"
        case .troubleshooting: return "wrench"
        }
    }
}

private struct HelpItem { let id = UUID(); let category: HelpCategory; let title: String; let content: String; let keywords: [String] }

private let helpItems: [HelpItem] = [
    .init(category: .gettingStarted, title: "Welcome to Routine Anchor",
          content: "Routine Anchor helps you build consistent daily routines through time-blocking.\n\nTo get started:\n1) Create your first time block\n2) Set your daily routine\n3) Track your progress",
          keywords: ["welcome","start","new"]),
    .init(category: .timeBlocks, title: "Understanding Time Block Status",
          content: "Not Started, In Progress, Completed, Skipped. Update status by tapping on blocks.",
          keywords: ["status","completed","skipped"]),
    .init(category: .notifications, title: "Setting Up Notifications",
          content: "Enable notifications in Settings to get reminders for block start times.",
          keywords: ["notification","reminder"]),
    .init(category: .settings, title: "Customizing Your Experience",
          content: "Adjust haptics, daily reminders, export/backup, and privacy options.",
          keywords: ["preferences","haptics","backup"]),
    .init(category: .troubleshooting, title: "App Performance Issues",
          content: "Restart the app/device, check for updates, and ensure storage space.",
          keywords: ["slow","crash","update"])
]

private struct HelpItemView: View {
    @Environment(\.themeManager) private var themeManager
    let item: HelpItem
    let categoryColor: Color
    @State private var isExpanded = false
    @State private var isVisible = false
    private var theme: AppTheme { themeManager?.currentTheme ?? PredefinedThemes.classic }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                HapticManager.shared.lightImpact()
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) { isExpanded.toggle() }
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: item.category.icon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(categoryColor)
                        .frame(width: 24, height: 24)
                    Text(item.title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(theme.primaryTextColor)
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(theme.secondaryTextColor)
                }
                .padding(16)
            }
            .buttonStyle(.plain)

            if isExpanded {
                VStack(alignment: .leading, spacing: 12) {
                    Divider().background(theme.borderColor.opacity(0.6))
                    Text(item.content)
                        .font(.system(size: 14))
                        .foregroundStyle(theme.secondaryTextColor)
                        .lineSpacing(2)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)
                }
                .transition(.asymmetric(insertion: .opacity.combined(with: .move(edge: .top)),
                                        removal: .opacity.combined(with: .move(edge: .top))))
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .background(RoundedRectangle(cornerRadius: 12).fill(theme.color.surface.card.opacity(0.55)))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(LinearGradient(colors: [categoryColor.opacity(0.3), categoryColor.opacity(0.1)],
                                       startPoint: .topLeading, endPoint: .bottomTrailing),
                        lineWidth: 1)
        )
        .shadow(color: categoryColor.opacity(0.1), radius: 8, x: 0, y: 4)
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : 20)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) { isVisible = true }
        }
    }
}

#Preview { HelpView() }
