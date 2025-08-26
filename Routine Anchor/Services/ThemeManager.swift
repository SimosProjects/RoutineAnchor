//
//  ThemeManager.swift
//  Routine Anchor
//
//  Service for managing themes and theme switching
//
import SwiftUI
import Foundation

@MainActor
@Observable
class ThemeManager {
    // MARK: - Published Properties
    var currentTheme: Theme
    var isLoading = false
    var errorMessage: String?
    
    // MARK: - Dependencies
    let premiumManager: PremiumManager
    
    // MARK: - Constants
    private let currentThemeKey = "currentThemeId"
    private let themePreferencesKey = "themePreferences"
    
    // MARK: - Initialization
    init(premiumManager: PremiumManager) {
        self.premiumManager = premiumManager
        self.currentTheme = Theme.defaultTheme
        loadCurrentTheme()
    }
    
    // MARK: - Theme Management
    
    /// Available themes based on premium status
    var availableThemes: [Theme] {
        let allThemes = Theme.allAvailable
        
        if premiumManager.hasPremiumAccess {
            return allThemes
        } else {
            // Free users can only access free themes
            return allThemes.filter { !$0.isPremium }
        }
    }
    
    /// All themes (for preview purposes)
    var allThemes: [Theme] {
        Theme.allAvailable
    }
    
    /// Premium themes that user cannot access
    var lockedPremiumThemes: [Theme] {
        if premiumManager.hasPremiumAccess {
            return []
        } else {
            return Theme.allAvailable.filter { $0.isPremium }
        }
    }
    
    /// Check if user can access a specific theme
    func canAccessTheme(_ theme: Theme) -> Bool {
        if !theme.isPremium {
            return true // Free themes are always accessible
        }
        
        return premiumManager.hasPremiumAccess
    }
    
    /// Switch to a new theme
    func switchToTheme(_ theme: Theme) {
        guard canAccessTheme(theme) else {
            errorMessage = "This theme requires a premium subscription"
            HapticManager.shared.anchorError()
            return
        }
        
        isLoading = true
        
        // Animate theme change
        withAnimation(.easeInOut(duration: 0.3)) {
            currentTheme = theme
        }
        
        // Save theme preference
        saveCurrentTheme(theme)
        
        // Provide haptic feedback
        HapticManager.shared.anchorSuccess()
        
        // Clear any errors
        errorMessage = nil
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.isLoading = false
        }
        
        print("🎨 Theme switched to: \(theme.name)")
    }
    
    /// Reset to default theme
    func resetToDefaultTheme() {
        switchToTheme(Theme.defaultTheme)
    }
    
    // MARK: - Theme Categories
    
    /// Get themes by category
    func themes(for category: ThemeCategory) -> [Theme] {
        availableThemes.filter { $0.category == category }
    }
    
    /// Get available categories
    var availableCategories: [ThemeCategory] {
        let uniqueCategories = Set(availableThemes.map { $0.category })
        return ThemeCategory.allCases.filter { uniqueCategories.contains($0) }
    }
    
    // MARK: - Theme Persistence
    
    private func loadCurrentTheme() {
        let savedThemeId = UserDefaults.standard.string(forKey: currentThemeKey) ?? Theme.defaultTheme.id
        
        if let savedTheme = Theme.allAvailable.first(where: { $0.id == savedThemeId }) {
            // Check if user can still access this theme
            if canAccessTheme(savedTheme) {
                currentTheme = savedTheme
            } else {
                // User lost premium access, revert to default
                currentTheme = Theme.defaultTheme
                saveCurrentTheme(Theme.defaultTheme)
            }
        } else {
            // Theme not found, use default
            currentTheme = Theme.defaultTheme
        }
        
        print("🎨 Loaded theme: \(currentTheme.name)")
    }
    
    private func saveCurrentTheme(_ theme: Theme) {
        UserDefaults.standard.set(theme.id, forKey: currentThemeKey)
    }
    
    // MARK: - Theme Preferences
    
    /// Save user's theme preferences
    func saveThemePreferences() {
        let preferences = ThemePreferences(
            currentThemeId: currentTheme.id,
            lastUpdated: Date()
        )
        
        if let encoded = try? JSONEncoder().encode(preferences) {
            UserDefaults.standard.set(encoded, forKey: themePreferencesKey)
        }
    }
    
    /// Load user's theme preferences
    func loadThemePreferences() -> ThemePreferences? {
        guard let data = UserDefaults.standard.data(forKey: themePreferencesKey),
              let preferences = try? JSONDecoder().decode(ThemePreferences.self, from: data) else {
            return nil
        }
        
        return preferences
    }
    
    // MARK: - Premium Integration
    
    /// Handle premium status change
    func handlePremiumStatusChange() {
        // If user lost premium access and current theme is premium, switch to default
        if !premiumManager.hasPremiumAccess && currentTheme.isPremium {
            switchToTheme(Theme.defaultTheme)
        }
        
        // Clear any error messages when premium status changes
        errorMessage = nil
    }
    
    // MARK: - Theme Application Helpers
    
    /// Get the appropriate background gradient for current theme
    var backgroundGradient: some View {
        switch currentTheme.gradientStyle {
        case .linear:
            return AnyView(currentTheme.backgroundGradient)
        case .radial:
            return AnyView(currentTheme.radialBackgroundGradient)
        case .angular:
            return AnyView(currentTheme.angularBackgroundGradient)
        case .mesh:
            // Fallback to linear for mesh (iOS 18+ feature)
            return AnyView(currentTheme.backgroundGradient)
        }
    }
    
    /// Get glass morphism effect values
    var glassEffect: (color: Color, opacity: Double) {
        let (color, opacity) = currentTheme.glassEffect
        return (color: color, opacity: opacity)
    }
    
    // MARK: - Error Handling
    
    func clearError() {
        errorMessage = nil
    }
}

// MARK: - Theme Preferences Model
struct ThemePreferences: Codable {
    let currentThemeId: String
    let lastUpdated: Date
    
    init(currentThemeId: String, lastUpdated: Date = Date()) {
        self.currentThemeId = currentThemeId
        self.lastUpdated = lastUpdated
    }
}

// MARK: - Theme Environment Key
struct ThemeEnvironmentKey: EnvironmentKey {
    static let defaultValue: ThemeManager? = nil
}

extension EnvironmentValues {
    var themeManager: ThemeManager? {
        get { self[ThemeEnvironmentKey.self] }
        set { self[ThemeEnvironmentKey.self] = newValue }
    }
}

// MARK: - Theme-Aware View Modifier
struct ThemedView: ViewModifier {
    @Environment(\.themeManager) private var themeManager
    
    func body(content: Content) -> some View {
        if let themeManager = themeManager {
            content
                .background(
                    themeManager.backgroundGradient
                        .ignoresSafeArea()
                )
                .preferredColorScheme(themeManager.currentTheme.isLight ? .light : .dark)
        } else {
            content
        }
    }
}

extension View {
    func themedBackground() -> some View {
        modifier(ThemedView())
    }
}

// MARK: - Glass Morphism Modifier
struct GlassMorphismModifier: ViewModifier {
    @Environment(\.themeManager) private var themeManager
    let cornerRadius: CGFloat
    
    func body(content: Content) -> some View {
        if let themeManager = themeManager {
            let glassEffect = themeManager.glassEffect
            content
                .background(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(glassEffect.color.opacity(glassEffect.opacity))
                        .background(
                            RoundedRectangle(cornerRadius: cornerRadius)
                                .fill(.ultraThinMaterial)
                        )
                )
        } else {
            content
                .background(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(.ultraThinMaterial)
                )
        }
    }
}

extension View {
    func themedGlassMorphism(cornerRadius: CGFloat = 16) -> some View {
        modifier(GlassMorphismModifier(cornerRadius: cornerRadius))
    }
}

// MARK: - Theme Color Access
extension View {
    @ViewBuilder
    func themedForegroundStyle<S: ShapeStyle>(_ style: KeyPath<Theme, S>) -> some View {
        if let themeManager = EnvironmentValues().themeManager {
            self.foregroundStyle(themeManager.currentTheme[keyPath: style])
        } else {
            self.foregroundStyle(Theme.defaultTheme[keyPath: style])
        }
    }
}

// MARK: - Debug Helpers
extension ThemeManager {
    #if DEBUG
    /// Preview with specific theme
    static func preview(with theme: Theme = Theme.defaultTheme) -> ThemeManager {
        let premiumManager = PremiumManager()
        premiumManager.userIsPremium = true // Enable premium for preview
        let manager = ThemeManager(premiumManager: premiumManager)
        manager.currentTheme = theme
        return manager
    }
    
    /// Cycle through all themes for testing
    func cycleToNextTheme() {
        let themes = availableThemes
        guard let currentIndex = themes.firstIndex(where: { $0.id == currentTheme.id }) else {
            switchToTheme(themes.first ?? Theme.defaultTheme)
            return
        }
        
        let nextIndex = (currentIndex + 1) % themes.count
        switchToTheme(themes[nextIndex])
    }
    
    /// Get random theme for testing
    func switchToRandomTheme() {
        let themes = availableThemes
        let randomTheme = themes.randomElement() ?? Theme.defaultTheme
        switchToTheme(randomTheme)
    }
    #endif
}
