//
//  ThemeSelectionView.swift
//  Routine Anchor
//
//  Theme selection UI for settings
//
import SwiftUI

struct ThemeSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.themeManager) private var themeManager
    @State private var selectedCategory: ThemeCategory = .minimal
    @State private var showPremiumUpgrade = false
    @State private var animationPhase = 0.0
    
    var body: some View {
        NavigationView {
            ZStack {
                // Animated background
                if let themeManager = themeManager {
                    themeManager.backgroundGradient
                        .ignoresSafeArea()
                        .animation(.easeInOut(duration: 0.5), value: themeManager.currentTheme.id)
                } else {
                    Theme.defaultTheme.backgroundGradient
                        .ignoresSafeArea()
                }
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        headerSection
                            .padding(.top, 50) // Add space for custom navigation bar
                        
                        // Current Theme Preview
                        currentThemePreview
                        
                        // Category Selector
                        categorySelector
                        
                        // Theme Grid
                        themeGrid
                        
                        // Premium Promotion (if needed)
                        if hasLockedThemes {
                            premiumPromotionSection
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .navigationBarTitleDisplayMode(.inline)
            .overlay(
                // Custom navigation bar
                VStack {
                    HStack {
                        Button("Cancel") {
                            dismiss()
                        }
                        .foregroundStyle(themeManager?.currentTheme.primaryTextColor ?? Theme.defaultTheme.primaryTextColor)
                        .font(.system(size: 17))
                        
                        Spacer()
                        
                        Button("Done") {
                            themeManager?.saveThemePreferences()
                            dismiss()
                        }
                        .foregroundStyle(themeManager?.currentTheme.primaryTextColor ?? Theme.defaultTheme.primaryTextColor)
                        .font(.system(size: 17, weight: .semibold))
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 15) // Increased padding from navigation bar
                    .background(
                        // Add a subtle background to ensure buttons are visible
                        Rectangle()
                            .fill(.ultraThinMaterial.opacity(0.3))
                            .blur(radius: 10)
                    )
                    
                    Spacer()
                }
                , alignment: .top
            )
        }
        .onAppear {
            startAnimations()
        }
        .sheet(isPresented: $showPremiumUpgrade) {
            if let premiumManager = themeManager?.premiumManager {
                PremiumUpgradeView(premiumManager: premiumManager)
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "paintbrush.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(themeManager?.currentTheme.primaryTextColor ?? Theme.defaultTheme.primaryTextColor)
                
                Text("Themes")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(themeManager?.currentTheme.primaryTextColor ?? Theme.defaultTheme.primaryTextColor)
                
                Spacer()
            }
            
            HStack {
                Text("Customize your Routine Anchor experience")
                    .font(.system(size: 16))
                    .foregroundStyle((themeManager?.currentTheme.primaryTextColor ?? Theme.defaultTheme.primaryTextColor).opacity(0.8))
                
                Spacer()
            }
        }
        .opacity(animationPhase)
        .offset(y: animationPhase == 0 ? -20 : 0)
        .animation(.easeOut(duration: 0.8).delay(0.1), value: animationPhase)
    }
    
    // MARK: - Current Theme Preview
    private var currentThemePreview: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Current Theme")
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundStyle(themeManager?.currentTheme.primaryTextColor ?? Theme.defaultTheme.primaryTextColor)
                
                Spacer()
            }
            
            if let themeManager = themeManager {
                ThemePreviewCard(
                    theme: themeManager.currentTheme,
                    isSelected: true,
                    isAccessible: true,
                    size: .large
                ) {
                    // Already selected - no action needed
                }
                .scaleEffect(1.02)
                .shadow(color: themeManager.currentTheme.buttonAccentColor.opacity(0.3), radius: 12, x: 0, y: 6)
            }
        }
        .opacity(animationPhase)
        .scaleEffect(animationPhase == 0 ? 0.9 : 1.0)
        .animation(.easeOut(duration: 0.8).delay(0.2), value: animationPhase)
    }
    
    // MARK: - Category Selector
    private var categorySelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(availableCategories, id: \.self) { category in
                    CategoryPill(
                        category: category,
                        isSelected: selectedCategory == category
                    ) {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            selectedCategory = category
                        }
                        HapticManager.shared.anchorSelection()
                    }
                }
            }
            .padding(.horizontal, 20)
        }
        .opacity(animationPhase)
        .offset(x: animationPhase == 0 ? -30 : 0)
        .animation(.easeOut(duration: 0.8).delay(0.3), value: animationPhase)
    }
    
    // MARK: - Theme Grid
    private var themeGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 2), spacing: 16) {
            ForEach(themesForSelectedCategory, id: \.id) { theme in
                let isAccessible = themeManager?.canAccessTheme(theme) ?? false
                let isSelected = themeManager?.currentTheme.id == theme.id
                
                ThemePreviewCard(
                    theme: theme,
                    isSelected: isSelected,
                    isAccessible: isAccessible,
                    size: .medium
                ) {
                    handleThemeSelection(theme)
                }
                .opacity(animationPhase)
                .scaleEffect(animationPhase == 0 ? 0.8 : 1.0)
                .animation(
                    .easeOut(duration: 0.6)
                        .delay(Double(themesForSelectedCategory.firstIndex(where: { $0.id == theme.id }) ?? 0) * 0.1 + 0.4),
                    value: animationPhase
                )
            }
        }
    }
    
    // MARK: - Premium Promotion
    private var premiumPromotionSection: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "crown.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(themeManager?.currentTheme.colorScheme.warningColor.color ?? Theme.defaultTheme.colorScheme.warningColor.color)
                
                Text("Premium Themes")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(themeManager?.currentTheme.primaryTextColor ?? Theme.defaultTheme.primaryTextColor)
                
                Spacer()
            }
            
            Text("Unlock beautiful premium themes and customize your experience")
                .font(.system(size: 14))
                .foregroundStyle((themeManager?.currentTheme.primaryTextColor ?? Theme.defaultTheme.primaryTextColor).opacity(0.8))
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Button(action: {
                showPremiumUpgrade = true
            }) {
                HStack {
                    Text("Upgrade to Premium")
                        .font(.system(size: 16, weight: .semibold))
                    
                    Image(systemName: "arrow.right")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundStyle(themeManager?.currentTheme.primaryTextColor ?? Theme.defaultTheme.primaryTextColor)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(
                    LinearGradient(
                        colors: [themeManager?.currentTheme.colorScheme.workflowPrimary.color ?? Theme.defaultTheme.colorScheme.workflowPrimary.color, themeManager?.currentTheme.colorScheme.organizationAccent.color ?? Theme.defaultTheme.colorScheme.organizationAccent.color],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
            }
        }
        .padding(20)
        .themedGlassMorphism(cornerRadius: 16)
        .opacity(animationPhase)
        .offset(y: animationPhase == 0 ? 20 : 0)
        .animation(.easeOut(duration: 0.8).delay(0.6), value: animationPhase)
    }
    
    // MARK: - Helper Properties
    private var availableCategories: [ThemeCategory] {
        themeManager?.availableCategories ?? [.minimal]
    }
    
    private var themesForSelectedCategory: [Theme] {
        let availableThemes = themeManager?.availableThemes ?? []
        let lockedThemes = themeManager?.lockedPremiumThemes ?? []
        let allThemes = availableThemes + lockedThemes
        
        return allThemes.filter { $0.category == selectedCategory }
    }
    
    private var hasLockedThemes: Bool {
        !(themeManager?.lockedPremiumThemes.isEmpty ?? true)
    }
    
    // MARK: - Actions
    private func handleThemeSelection(_ theme: Theme) {
        guard let themeManager = themeManager else { return }
        
        if themeManager.canAccessTheme(theme) {
            themeManager.switchToTheme(theme)
        } else {
            // Show premium upgrade
            showPremiumUpgrade = true
            HapticManager.shared.anchorError()
        }
    }
    
    private func startAnimations() {
        withAnimation(.easeOut(duration: 0.8)) {
            animationPhase = 1.0
        }
    }
}

// MARK: - Category Pill
struct CategoryPill: View {
    @Environment(\.themeManager) private var themeManager
    
    let category: ThemeCategory
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(category.displayName)
                .font(.system(size: 14, weight: isSelected ? .semibold : .medium))
                .foregroundStyle(isSelected ? .black : (themeManager?.currentTheme.primaryTextColor ?? Theme.defaultTheme.primaryTextColor).opacity(0.8))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(isSelected ? (themeManager?.currentTheme.primaryTextColor ?? Theme.defaultTheme.primaryTextColor) : Color(themeManager?.currentTheme.colorScheme.uiElementSecondary.color ?? Theme.defaultTheme.colorScheme.uiElementSecondary.color))
                )
        }
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

// MARK: - Theme Preview Card
struct ThemePreviewCard: View {
    @Environment(\.themeManager) private var themeManager
    
    let theme: Theme
    let isSelected: Bool
    let isAccessible: Bool
    let size: PreviewSize
    let action: () -> Void
    
    enum PreviewSize {
        case small, medium, large
        
        var dimensions: CGFloat {
            switch self {
            case .small: return 80
            case .medium: return 120
            case .large: return 160
            }
        }
        
        var cornerRadius: CGFloat {
            switch self {
            case .small: return 12
            case .medium: return 16
            case .large: return 20
            }
        }
    }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                // Theme Preview
                ZStack {
                    // Background gradient
                    RoundedRectangle(cornerRadius: size.cornerRadius)
                        .fill(theme.backgroundGradient)
                        .frame(width: size.dimensions, height: size.dimensions)
                    
                    // Glass effect overlay
                    RoundedRectangle(cornerRadius: size.cornerRadius)
                        .fill(theme.glassEffect.0.opacity(theme.glassEffect.1))
                        .frame(width: size.dimensions, height: size.dimensions)
                    
                    // Selected indicator
                    if isSelected {
                        RoundedRectangle(cornerRadius: size.cornerRadius)
                            .stroke(Color.white, lineWidth: 3)
                            .frame(width: size.dimensions, height: size.dimensions)
                        
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(themeManager?.currentTheme.primaryTextColor ?? Theme.defaultTheme.primaryTextColor)
                            .background(Circle().fill(theme.buttonAccentColor))
                            .offset(x: size.dimensions/2 - 10, y: -size.dimensions/2 + 10)
                    }
                    
                    // Lock indicator for premium themes
                    if !isAccessible {
                        ZStack {
                            RoundedRectangle(cornerRadius: size.cornerRadius)
                                .fill(Color.black.opacity(0.4))
                                .frame(width: size.dimensions, height: size.dimensions)
                            
                            VStack(spacing: 4) {
                                Image(systemName: "lock.fill")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(themeManager?.currentTheme.primaryTextColor ?? Theme.defaultTheme.primaryTextColor)
                                
                                Image(systemName: "crown.fill")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(themeManager?.currentTheme.colorScheme.warningColor.color ?? Theme.defaultTheme.colorScheme.warningColor.color)
                            }
                        }
                    }
                }
                
                // Theme Info
                VStack(spacing: 2) {
                    Text(theme.name)
                        .font(.system(size: size == .large ? 16 : 14, weight: .semibold))
                        .foregroundStyle(themeManager?.currentTheme.primaryTextColor ?? Theme.defaultTheme.primaryTextColor)
                        .multilineTextAlignment(.center)
                        .lineLimit(1)
                    
                    if size != .small {
                        Text(theme.description)
                            .font(.system(size: 11))
                            .foregroundStyle((themeManager?.currentTheme.primaryTextColor ?? Theme.defaultTheme.primaryTextColor).opacity(0.7))
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                    }
                }
            }
        }
        .disabled(isSelected && isAccessible)
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .opacity(isAccessible ? 1.0 : 0.8)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

// MARK: - Preview
#Preview {
    ThemeSelectionView()
        .environment(\.themeManager, ThemeManager.preview())
        .preferredColorScheme(.dark)
}
