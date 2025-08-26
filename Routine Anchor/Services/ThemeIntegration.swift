//
//  ThemeIntegration.swift
//  Routine Anchor
//
//  Integration guide and helper extensions for theme system
//
import SwiftUI

// MARK: - Themed Animated Background
struct ThemedAnimatedBackground: View {
    @Environment(\.themeManager) private var themeManager
    @State private var animationPhase = 0.0
    @State private var pulsePhase = 0.0
    
    var body: some View {
        ZStack {
            if let themeManager = themeManager {
                // Main background gradient
                themeManager.backgroundGradient
                
                // Animated overlay effects based on theme
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    themeManager.currentTheme.accentColor.opacity(0.1),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 200
                            )
                        )
                        .frame(width: 400, height: 400)
                        .offset(
                            x: cos(animationPhase + Double(index) * 2.0) * 100,
                            y: sin(animationPhase + Double(index) * 1.5) * 120
                        )
                        .scaleEffect(1.0 + sin(pulsePhase + Double(index)) * 0.1)
                        .blur(radius: 40)
                        .animation(.linear(duration: 20).repeatForever(autoreverses: false), value: animationPhase)
                        .animation(.easeInOut(duration: 4).repeatForever(autoreverses: true), value: pulsePhase)
                }
            } else {
                // Fallback to default theme
                Theme.defaultTheme.backgroundGradient
            }
        }
        .onAppear {
            animationPhase = 2 * .pi
            pulsePhase = .pi
        }
        .animation(.easeInOut(duration: 1.0), value: themeManager?.currentTheme.id)
    }
}

// MARK: - Theme-Aware Color Extensions
extension Color {
    // Current theme colors
    static var themed: ThemedColors {
        ThemedColors()
    }
}

@MainActor
struct ThemedColors {
    @Environment(\.themeManager) private var themeManager
    
    var primary: Color {
        themeManager?.currentTheme.primaryColor ?? Theme.defaultTheme.primaryColor
    }
    
    var secondary: Color {
        themeManager?.currentTheme.secondaryColor ?? Theme.defaultTheme.secondaryColor
    }
    
    var accent: Color {
        themeManager?.currentTheme.accentColor ?? Theme.defaultTheme.accentColor
    }
    
    var textPrimary: Color {
        themeManager?.currentTheme.textPrimaryColor ?? Theme.defaultTheme.textPrimaryColor
    }
    
    var textSecondary: Color {
        themeManager?.currentTheme.textSecondaryColor ?? Theme.defaultTheme.textSecondaryColor
    }
}

// MARK: - Settings Integration Component
struct ThemeSettingsRow: View {
    @Environment(\.themeManager) private var themeManager
    @State private var showThemeSelection = false
    
    var body: some View {
        Button(action: {
            showThemeSelection = true
        }) {
            HStack(spacing: 16) {
                // Theme preview
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(themeManager?.currentTheme.backgroundGradient ?? Theme.defaultTheme.backgroundGradient)
                        .frame(width: 32, height: 32)
                    
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(.white.opacity(0.3), lineWidth: 1)
                        .frame(width: 32, height: 32)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text("Theme")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(.white)
                        
                        if themeManager?.currentTheme.isPremium == true {
                            Image(systemName: "crown.fill")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(Color.anchorWarning)
                        }
                    }
                    
                    Text(themeManager?.currentTheme.name ?? "Default")
                        .font(.system(size: 14))
                        .foregroundStyle(.white.opacity(0.7))
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white.opacity(0.6))
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
    let title: String
    let style: ButtonStyle
    let action: () -> Void
    
    enum ButtonStyle {
        case primary, secondary, accent
    }
    
    @Environment(\.themeManager) private var themeManager
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(textColor)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(backgroundGradient)
                .cornerRadius(12)
        }
    }
    
    private var textColor: Color {
        switch style {
        case .primary, .accent:
            return .white
        case .secondary:
            return themeManager?.currentTheme.textPrimaryColor ?? .white
        }
    }
    
    private var backgroundGradient: LinearGradient {
        guard let theme = themeManager?.currentTheme else {
            return LinearGradient(colors: [.blue], startPoint: .leading, endPoint: .trailing)
        }
        
        switch style {
        case .primary:
            return LinearGradient(
                colors: [theme.primaryColor, theme.secondaryColor],
                startPoint: .leading,
                endPoint: .trailing
            )
        case .secondary:
            return LinearGradient(
                colors: [theme.colorScheme.surfacePrimary.color.opacity(0.3)],
                startPoint: .leading,
                endPoint: .trailing
            )
        case .accent:
            return LinearGradient(
                colors: [theme.accentColor],
                startPoint: .leading,
                endPoint: .trailing
            )
        }
    }
}

// MARK: - Theme-Aware Card Component
struct ThemedCard<Content: View>: View {
    let content: Content
    let cornerRadius: CGFloat
    
    @Environment(\.themeManager) private var themeManager
    
    init(cornerRadius: CGFloat = 16, @ViewBuilder content: () -> Content) {
        self.cornerRadius = cornerRadius
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(glassEffect.color.opacity(glassEffect.opacity))
                    .background(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(.ultraThinMaterial)
                    )
            )
    }
    
    private var glassEffect: (color: Color, opacity: Double) {
        themeManager?.glassEffect ?? (Color.white, 0.1)
    }
}

// MARK: - Migration Helper for Existing Views
struct ThemeMigrationHelpers {
    /*
     Use these helpers to gradually migrate your existing views to use themes:
     
     1. Replace hardcoded colors:
        OLD: .foregroundStyle(.white)
        NEW: .foregroundStyle(Color.themed.textPrimary)
     
     2. Replace cards:
        OLD: VStack { content }.padding(20).glassMorphism(cornerRadius: 16)
        NEW: ThemedCard { VStack { content } }
     
     3. Replace buttons:
        OLD: Custom button implementations
        NEW: ThemedButton(title: "Text", style: .primary) { action }
     */
}

// MARK: - Debug Theme Switcher (Development Only)
#if DEBUG
struct DebugThemeSwitcher: View {
    @Environment(\.themeManager) private var themeManager
    
    var body: some View {
        if let themeManager = themeManager {
            VStack(spacing: 12) {
                Text("🎨 Debug Theme Switcher")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                
                HStack(spacing: 8) {
                    Button("Random") {
                        themeManager.switchToRandomTheme()
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue)
                    .foregroundStyle(.white)
                    .cornerRadius(8)
                    
                    Button("Next") {
                        themeManager.cycleToNextTheme()
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.green)
                    .foregroundStyle(.white)
                    .cornerRadius(8)
                    
                    Button("Default") {
                        themeManager.resetToDefaultTheme()
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.orange)
                    .foregroundStyle(.white)
                    .cornerRadius(8)
                }
                
                Text("Current: \(themeManager.currentTheme.name)")
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.8))
            }
            .padding(16)
            .themedGlassMorphism(cornerRadius: 12)
        }
    }
}

// Add this to any view during development:
// .overlay(alignment: .topTrailing) { DebugThemeSwitcher().padding() }
#endif

// MARK: - Theme System Health Check
struct ThemeSystemHealthCheck {
    static func validateThemeSystem() -> [String] {
        var issues: [String] = []
        
        // Check all themes have valid colors
        for theme in Theme.allAvailable {
            if theme.colorScheme.gradientColors.isEmpty {
                issues.append("Theme '\(theme.name)' has no gradient colors")
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

// MARK: - Performance Optimization Tips
/*
 Theme Performance Tips:
 
 1. Theme changes trigger view updates - use @Environment properly
 2. Avoid creating Theme objects in view body - use static references
 3. Cache computed gradients in theme objects for better performance
 4. Use .animation() selectively on theme-dependent properties
 5. Consider using @StateObject for ThemeManager at app level
 
 Memory Management:
 - Themes are lightweight structs - no memory concerns
 - Color objects are cached by SwiftUI automatically
 - ThemeManager observes premium status changes efficiently
 */
