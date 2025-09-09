//
//  ThemeSelectionView.swift
//  Routine Anchor
//
//  Updated for AppTheme + ThemeManager
//  - Uses PredefinedThemes.all as the catalog
//  - Calls themeManager.setTheme(_:) to switch & persist
//  - Optional premium gating via premiumManager.hasPremiumAccess
//

import SwiftUI

struct ThemeSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.themeManager) private var themeManager

    // If your app provides this, premium gating is enforced. If not present, this compiles fine and premium themes are selectable.
    @Environment(\.premiumManager) private var premiumManager

    @State private var showPremiumAlert = false
    @State private var pendingSelection: AppTheme?

    private var active: AppTheme { themeManager?.currentTheme ?? PredefinedThemes.classic }

    // Catalog from our predefined themes
    private let catalog: [AppTheme] = PredefinedThemes.all
    private var freeThemes: [AppTheme]    { catalog.filter { !$0.isPremium } }
    private var premiumThemes: [AppTheme] { catalog.filter {  $0.isPremium } }

    var body: some View {
        NavigationStack {
            ZStack {
                // Full-screen gradient from the *active* theme
                active.heroBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        header
                        currentThemePreview
                        themeSection(title: "Free Themes", themes: freeThemes, locked: false)

                        if !premiumThemes.isEmpty {
                            themeSection(title: "Premium Themes",
                                         themes: premiumThemes,
                                         locked: !(premiumManager?.hasPremiumAccess ?? false))
                            premiumFootnote
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
            }
            .navigationTitle("Themes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(active.primaryTextColor)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(active.primaryTextColor)
                        .font(.system(size: 17, weight: .semibold))
                }
            }
            .alert("Premium Required", isPresented: $showPremiumAlert, presenting: pendingSelection) { _ in
                Button("OK", role: .cancel) { pendingSelection = nil }
            } message: { selection in
                Text("“\(selection.name)” is a premium theme.")
            }
        }
    }

    // MARK: - Sections

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Customize your look")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(active.primaryTextColor)
            Text("Pick a theme to instantly change colors across the app.")
                .font(.system(size: 15))
                .foregroundStyle(active.secondaryTextColor)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var currentThemePreview: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Current Theme")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(active.primaryTextColor)

            ThemeCard(theme: active,
                      isSelected: true,
                      isAccessible: true,
                      size: .large,
                      onTap: {})
            .shadow(color: active.accentPrimaryColor.opacity(0.25), radius: 12, x: 0, y: 6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func themeSection(title: String, themes: [AppTheme], locked: Bool) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(active.primaryTextColor)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 2), spacing: 16) {
                ForEach(themes, id: \.name) { item in
                    let isSelected   = item.name == active.name
                    let isAccessible = locked ? false : true

                    ThemeCard(theme: item,
                              isSelected: isSelected,
                              isAccessible: isAccessible,
                              size: .medium) {
                        handleSelection(item, accessible: isAccessible)
                    }
                }
            }
        }
    }

    private var premiumFootnote: some View {
        HStack(spacing: 8) {
            Image(systemName: "crown.fill")
                .foregroundStyle(active.statusWarningColor)
            Text("Premium themes require an active Premium subscription.")
                .font(.system(size: 13))
                .foregroundStyle(active.secondaryTextColor)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, -4)
    }

    // MARK: - Actions

    private func handleSelection(_ selection: AppTheme, accessible: Bool) {
        if selection.isPremium {
            // If there's a premium manager and access is false, block selection.
            if let hasAccess = premiumManager?.hasPremiumAccess, hasAccess == false {
                pendingSelection = selection
                showPremiumAlert = true
                HapticManager.shared.anchorError()
                return
            }
            // If there's no premium manager in the environment, default to allowing selection.
        }

        themeManager?.setTheme(selection)
        HapticManager.shared.lightImpact()
    }
}

// MARK: - Theme Card

private struct ThemeCard: View {
    @Environment(\.themeManager) private var themeManager

    let theme: AppTheme
    let isSelected: Bool
    let isAccessible: Bool
    let size: CardSize
    let onTap: () -> Void

    enum CardSize {
        case small
        case medium
        case large

        var dim: CGFloat {
            switch self {
            case .small:  return 90
            case .medium: return 132
            case .large:  return 172
            }
        }

        var radius: CGFloat {
            switch self {
            case .small:  return 12
            case .medium: return 16
            case .large:  return 20
            }
        }
    }


    private var active: AppTheme { themeManager?.currentTheme ?? PredefinedThemes.classic }

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                ZStack {
                    // Theme preview tile
                    RoundedRectangle(cornerRadius: size.radius, style: .continuous)
                        .fill(theme.heroBackgroundGradient) // ShapeStyle variant for fills
                        .frame(width: size.dim, height: size.dim)

                    // Gentle glass overlay for consistency on busy gradients
                    RoundedRectangle(cornerRadius: size.radius, style: .continuous)
                        .fill(theme.surfaceGlassColor.opacity(0.10))
                        .frame(width: size.dim, height: size.dim)

                    // Selected ring
                    if isSelected {
                        RoundedRectangle(cornerRadius: size.radius, style: .continuous)
                            .stroke(Color.white, lineWidth: 3)
                            .frame(width: size.dim, height: size.dim)

                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(.white)
                            .background(Circle().fill(Color.black.opacity(0.25)))
                            .offset(x: size.dim/2 - 14, y: -size.dim/2 + 14)
                    }

                    // Lock overlay if not accessible
                    if !isAccessible {
                        RoundedRectangle(cornerRadius: size.radius, style: .continuous)
                            .fill(Color.black.opacity(0.35))
                            .frame(width: size.dim, height: size.dim)
                        Image(systemName: "lock.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                }

                // Name / description use the *active* theme’s text colors for UI consistency
                VStack(spacing: 2) {
                    Text(theme.name)
                        .font(.system(size: size == .large ? 16 : 14, weight: .semibold))
                        .foregroundStyle(active.primaryTextColor)
                        .lineLimit(1)

                    if size != .small {
                        Text(theme.description)
                            .font(.system(size: 11))
                            .foregroundStyle(active.secondaryTextColor.opacity(0.9))
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .buttonStyle(.plain)
        .disabled(isSelected && isAccessible == true)
        .scaleEffect(isSelected ? 1.04 : 1.0)
        .opacity(isAccessible ? 1.0 : 0.85)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

#Preview {
    ThemeSelectionView()
        .environment(\.themeManager, ThemeManager.preview())
        // .environment(\.premiumManager, PremiumManager())
        .preferredColorScheme(.dark)
}
