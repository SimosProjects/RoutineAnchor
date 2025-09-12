//
//  ThemeIntegration.swift
//  Routine Anchor
//
//  Integration guide and helper extensions for theme system
//
import SwiftUI

// MARK: - Themed Animated Background
struct ThemedAnimatedBackground: View {
    enum Kind { case hero, generic }
    var kind: Kind = .hero
    var showGlow: Bool = true
    var showOrbs: Bool = true

    @Environment(\.themeManager) private var themeManager
    @State private var orbitPhase: CGFloat = 0
    @State private var pulsePhase: CGFloat = 0

    private var theme: Theme {
        themeManager?.currentTheme ?? Theme.defaultTheme
    }

    var body: some View {
        ZStack {
            // Base gradient
            backgroundLayer
                .ignoresSafeArea()

            // Optional vignette/glow
            if showGlow {
                RadialGradient(
                    colors: [
                        theme.colorScheme.primaryAccent.color.opacity(theme.glowIntensitySecondary),
                        .clear
                    ],
                    center: .center,
                    startRadius: 0,
                    endRadius: 620
                )
                .opacity(theme.colorScheme.glassOpacity)
                .blendMode(.softLight)
                .ignoresSafeArea()
            }

            // Animated “orbs” (subtle)
            if showOrbs {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    theme.colorScheme.primaryAccent.color.opacity(0.12),
                                    .clear
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 220
                            )
                        )
                        .frame(width: 380, height: 380)
                        .offset(
                            x: cos(Double(i) * 1.7 + Double(orbitPhase)) * 110,
                            y: sin(Double(i) * 1.3 + Double(orbitPhase)) * 120
                        )
                        .scaleEffect(1 + 0.08 * CGFloat(sin(Double(pulsePhase) + Double(i))))
                        .blur(radius: 36)
                }
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 24).repeatForever(autoreverses: false)) {
                orbitPhase = .pi * 2
            }
            withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
                pulsePhase = .pi
            }
        }
        .animation(.easeInOut(duration: 0.3), value: theme.id)
    }

    // MARK: - Layers
    @ViewBuilder private var backgroundLayer: some View {
        switch kind {
        case .hero:
            LinearGradient(
                colors: theme.colorScheme.backgroundColors.map { $0.color },
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .generic:
            theme.primaryBackgroundColor
        }
    }
}

// MARK: - Shared hero background
struct ThemedHeroBackground: View {
    @Environment(\.themeManager) private var themeManager
    
    private var theme: Theme {
        themeManager?.currentTheme ?? Theme.defaultTheme
    }
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: theme.colorScheme.backgroundColors.map { $0.color },
                startPoint: .top, endPoint: .bottom
            )
            RadialGradient(
                colors: theme.colorScheme.backgroundColors.map { $0.color },
                center: .center, startRadius: 0, endRadius: 520
            )
        }
        .ignoresSafeArea()
    }
}


// MARK: - Settings Integration Component
struct ThemeSettingsRow: View {
    @Environment(\.themeManager) private var themeManager
    @State private var showThemeSelection = false
    
    var body: some View {
        let theme = themeManager?.currentTheme ?? Theme.defaultTheme
        
        Button {
            showThemeSelection = true
        } label: {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                colors: theme.colorScheme.backgroundColors.map { $0.color },
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 32, height: 32)

                    RoundedRectangle(cornerRadius: 8)
                        .stroke(theme.subtleTextColor.opacity(0.3), lineWidth: 1)
                        .frame(width: 32, height: 32)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text("Theme")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(theme.primaryTextColor)
                        
                        if themeManager?.currentTheme.isPremium == true {
                            Image(systemName: "crown.fill")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(theme.warning)
                        }
                    }
                    
                    Text(themeManager?.currentTheme.name ?? "Default")
                        .font(.system(size: 14))
                        .foregroundStyle(theme.secondaryTextColor)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(theme.secondaryTextColor)
            }
            .padding(.vertical, 4)
        }
        .sheet(isPresented: $showThemeSelection) {
            ThemeSelectionView()
        }
    }
}

// MARK: - Premium Manager Theme Integration
extension PremiumManager {
    /// Additional premium features for themes
    var canUsePremiumThemes: Bool {
        return hasPremiumAccess
    }
    
    /// Get count of available themes
    func availableThemeCount() -> Int {
        if hasPremiumAccess {
            return Theme.allAvailable.count
        } else {
            return Theme.freeThemes.count
        }
    }
    
    /// Check access to specific theme
    func canAccessTheme(_ themeId: String) -> Bool {
        guard let theme = Theme.allAvailable.first(where: { $0.id == themeId }) else {
            return false
        }
        return !theme.isPremium || hasPremiumAccess
    }
}

// MARK: - Theme-Aware Component Examples
struct ThemedButton: View {
    @Environment(\.themeManager) private var themeManager
    
    let title: String
    let style: ButtonStyle
    let action: () -> Void
    
    enum ButtonStyle {
        case primary, secondary, accent
    }
    
    var body: some View {
        let theme = themeManager?.currentTheme ?? Theme.defaultTheme
        
        Button(action: action) {
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(textColor(for: theme))
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(backgroundColorsLinear(for: theme))
                .cornerRadius(12)
        }
    }
    
    private func textColor(for theme: Theme) -> Color {
        switch style {
        case .primary, .accent:
            return theme.invertedTextColor
        case .secondary:
            return theme.primaryTextColor
        }
    }
    
    private func backgroundColorsLinear(for theme: Theme) -> LinearGradient {
        switch style {
        case .primary:
            // Use the theme's dedicated button gradient
            return LinearGradient(
                colors: theme.colorScheme.buttonGradient.map { $0.color },
                startPoint: .leading,
                endPoint: .trailing
            )
        case .secondary:
            // Solid fill using secondary button color (duplicated as a gradient)
            let c = theme.colorScheme.secondaryButton.color
            return LinearGradient(colors: [c, c], startPoint: .leading, endPoint: .trailing)
        case .accent:
            // Solid fill using accent button color
            let c = theme.buttonAccentColor
            return LinearGradient(colors: [c, c], startPoint: .leading, endPoint: .trailing)
        }
    }
}

// MARK: - Theme-Aware Card Component

struct ThemedCard<Content: View>: View {
    let content: Content
    let cornerRadius: CGFloat
    var useMaterial: Bool
    var materialOpacity: Double
    var useTint: Bool

    @Environment(\.themeManager) private var themeManager

    init(
        cornerRadius: CGFloat = 16,
        useMaterial: Bool = false,
        materialOpacity: Double = 0.16,
        useTint: Bool = true,
        @ViewBuilder content: () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.useMaterial = useMaterial
        self.materialOpacity = materialOpacity
        self.useTint = useTint
        self.content = content()
    }

    var body: some View {
        content
            .padding(20)
            .background(
                ZStack {
                    // Base surface
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill((themeManager?.currentTheme.elevatedBackgroundColor
                               ?? Theme.defaultTheme.elevatedBackgroundColor)
                              .opacity(0.95))

                    // Optional, subtle material (kept weak to avoid greying)
                    if useMaterial {
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(.thinMaterial)
                            .opacity(materialOpacity)
                    }

                    // Optional hue tint from theme (prevents neutral cast)
                    if useTint, glassEffect.opacity > 0 {
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(glassEffect.color.opacity(glassEffect.opacity))
                    }

                    // Soft inner highlight at the top edge (2% white)
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .strokeBorder(Color.white.opacity(0.02), lineWidth: 1)
                        .blendMode(.screen)
                        .mask(
                            LinearGradient(
                                gradient: .init(colors: [.white, .clear]),
                                startPoint: .top, endPoint: .center
                            )
                            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                        )
                }
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            )
            // Hairline border + shadow for separation
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color.white.opacity(0.06), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.28), radius: 14, x: 0, y: 8)
    }

    private var glassEffect: (color: Color, opacity: Double) {
        themeManager?.glassEffect ?? (Color.clear, 0.0)
    }
}


struct ThemedIconButton: View {
    let icon: String
    let style: ThemedButton.ButtonStyle
    let action: () -> Void
    
    @Environment(\.themeManager) private var themeManager
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isPressed = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isPressed = false
                action()
            }
        }) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(textColor)
                .frame(width: 40, height: 40)
                .background(backgroundColorsLinear)
                .cornerRadius(12)
                .shadow(
                    color: shadowColor,
                    radius: 8,
                    x: 0,
                    y: 4
                )
                .scaleEffect(isPressed ? 0.95 : 1)
        }
    }
    
    private var textColor: Color {
        themeManager?.currentTheme.primaryTextColor ?? Theme.defaultTheme.primaryTextColor
    }
    
    private var backgroundColorsLinear: LinearGradient {
        guard let theme = themeManager?.currentTheme else {
            return LinearGradient(
                colors: [Theme.defaultTheme.buttonPrimaryColor, Theme.defaultTheme.buttonSecondaryColor],
                startPoint: .leading,
                endPoint: .trailing
            )
        }
        
        switch style {
        case .primary:
            return LinearGradient(
                colors: [theme.buttonPrimaryColor, theme.buttonSecondaryColor],
                startPoint: .leading,
                endPoint: .trailing
            )
        case .secondary:
            return LinearGradient(
                colors: [theme.colorScheme.primaryUIElement.color.opacity(0.3)],
                startPoint: .leading,
                endPoint: .trailing
            )
        case .accent:
            return LinearGradient(
                colors: [theme.buttonAccentColor],
                startPoint: .leading,
                endPoint: .trailing
            )
        }
    }
    
    private var shadowColor: Color {
        switch style {
        case .primary:
            return themeManager?.currentTheme.buttonPrimaryColor.opacity(0.3) ??
                   Theme.defaultTheme.buttonPrimaryColor.opacity(0.3)
        case .secondary:
            return themeManager?.currentTheme.colorScheme.secondaryUIElement.color.opacity(0.2) ??
                   Theme.defaultTheme.colorScheme.secondaryUIElement.color.opacity(0.2)
        case .accent:
            return themeManager?.currentTheme.buttonAccentColor.opacity(0.3) ??
                   Theme.defaultTheme.buttonAccentColor.opacity(0.3)
        }
    }
}

extension UINavigationBar {
    static func applyThemedAppearance(_ theme: Theme) {
        let c = UIColor(theme.primaryTextColor)
        let app = UINavigationBarAppearance()
        app.configureWithTransparentBackground()
        app.backgroundEffect = nil
        app.backgroundColor = .clear
        app.titleTextAttributes      = [.foregroundColor: c]
        app.largeTitleTextAttributes = [.foregroundColor: c]

        let nav = UINavigationBar.appearance()
        nav.standardAppearance   = app
        nav.scrollEdgeAppearance = app
        nav.compactAppearance    = app
    }
}

struct ThemedNavBarModifier: ViewModifier {
    let theme: Theme
    func body(content: Content) -> some View {
        content
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(.hidden, for: .navigationBar)
            .onAppear { UINavigationBar.applyThemedAppearance(theme) }
            .onChange(of: theme.id) { _, _ in
                UINavigationBar.applyThemedAppearance(theme)
            }
    }
}

extension View {
    func themedNavBar(_ theme: Theme) -> some View { modifier(ThemedNavBarModifier(theme: theme)) }
}

// MARK: - Debug Theme Switcher (Development Only)
#if DEBUG
struct DebugThemeSwitcher: View {
    @Environment(\.themeManager) private var themeManager
    
    // Theme color helpers
    private var themePrimaryText: Color {
        themeManager?.currentTheme.primaryTextColor ?? Theme.defaultTheme.primaryTextColor
    }
    
    private var themeSecondaryText: Color {
        themeManager?.currentTheme.secondaryTextColor ?? Theme.defaultTheme.secondaryTextColor
    }
    
    var body: some View {
        if let themeManager = themeManager {
            ThemedCard(cornerRadius: 12) {
                VStack(spacing: 12) {
                    Text("Debug Theme Switcher")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(themePrimaryText)
                    
                    HStack(spacing: 8) {
                        Button("Random") {
                            themeManager.switchToRandomTheme()
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(themeManager.currentTheme.colorScheme.primaryUIElement.color)
                        .foregroundStyle(themePrimaryText)
                        .cornerRadius(8)
                        
                        Button("Next") {
                            themeManager.cycleToNextTheme()
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(themeManager.currentTheme.colorScheme.success.color)
                        .foregroundStyle(themePrimaryText)
                        .cornerRadius(8)
                        
                        Button("Default") {
                            themeManager.resetToDefaultTheme()
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(themeManager.currentTheme.colorScheme.success.color)
                        .foregroundStyle(themePrimaryText)
                        .cornerRadius(8)
                    }
                    
                    Text("Current: \(themeManager.currentTheme.name)")
                        .font(.system(size: 12))
                        .foregroundStyle(themeSecondaryText)
                }
            }
        }
    }
}
#endif

// MARK: - Theme System Health Check
struct ThemeSystemHealthCheck {
    static func validateThemeSystem() -> [String] {
        var issues: [String] = []
        
        // Check all themes have valid colors
        for theme in Theme.allAvailable {
            if theme.colorScheme.backgroundColors.isEmpty {
                issues.append("Theme '\(theme.name)' has no background gradient colors")
            }
            
            if theme.name.isEmpty {
                issues.append("Theme with id '\(theme.id)' has no name")
            }
        }
        
        // Check for duplicate IDs
        let ids = Theme.allAvailable.map { $0.id }
        let uniqueIds = Set(ids)
        if ids.count != uniqueIds.count {
            issues.append("Duplicate theme IDs found")
        }
        
        // Check premium/free balance
        let premiumCount = Theme.premiumThemes.count
        let freeCount = Theme.freeThemes.count
        if freeCount == 0 {
            issues.append("No free themes available")
        }
        if premiumCount == 0 {
            issues.append("No premium themes available")
        }
        
        return issues
    }
}
