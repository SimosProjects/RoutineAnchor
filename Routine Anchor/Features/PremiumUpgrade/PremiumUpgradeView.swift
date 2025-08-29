//
//  PremiumUpgradeView.swift
//  Routine Anchor
//
//  Premium upgrade and subscription view
//
import SwiftUI
import StoreKit

struct PremiumUpgradeView: View {
    @Environment(\.themeManager) private var themeManager
    @Environment(\.dismiss) private var dismiss
    @Environment(\.presentationMode) private var presentationMode
    @State private var premiumManager: PremiumManager
    @State private var selectedProduct: Product?
    @State private var showingFeatureDetail = false
    @State private var animationPhase = 0.0
    
    init(premiumManager: PremiumManager) {
        self._premiumManager = State(initialValue: premiumManager)
    }
    
    var body: some View {
        ZStack {
            // Background
            ThemedAnimatedBackground()                .ignoresSafeArea()
            
            if premiumManager.isLoading && premiumManager.products.isEmpty {
                // Loading state
                loadingView
            } else {
                // Main content
                ScrollView {
                    VStack(spacing: 32) {
                        // Header
                        headerSection
                        
                        // Features
                        featuresSection
                        
                        // Pricing
                        pricingSection
                        
                        // Purchase buttons
                        purchaseSection
                        
                        // Restore purchases
                        restoreSection
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 32)
                }
            }
        }
        .navigationBarHidden(true)
        .task {
            // Load products on appear and auto-select recommended plan
            await loadProductsAndSetDefaults()
        }
        .onAppear {
            startAnimations()
        }
    }
    
    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            ProgressView()
                .scaleEffect(1.5)
                .tint(.white)
            
            Text("Loading Premium Plans...")
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle((themeManager?.currentTheme.textPrimaryColor ?? Theme.defaultTheme.textPrimaryColor).opacity(0.8))
            
            Spacer()
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 20) {
            // Close button
            HStack {
                Spacer()
                Button(action: { closeView() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle((themeManager?.currentTheme.textPrimaryColor ?? Theme.defaultTheme.textPrimaryColor).opacity(0.8))
                }
                .frame(width: 44, height: 44)
                .background(Color.clear)
                .contentShape(Rectangle())
            }
            
            // Premium crown
            Image(systemName: "crown.fill")
                .font(.system(size: 60, weight: .medium))
                .foregroundStyle(
                    LinearGradient(
                        colors: [themeManager?.currentTheme.colorScheme.warning.color ?? Theme.defaultTheme.colorScheme.warning.color, themeManager?.currentTheme.colorScheme.green.color ?? Theme.defaultTheme.colorScheme.green.color],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .floatModifier(amplitude: 8, duration: 3)
                .scaleEffect(1.0 + sin(animationPhase * .pi * 2) * 0.05)
            
            VStack(spacing: 12) {
                Text("Upgrade to Premium")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(themeManager?.currentTheme.textPrimaryColor ?? Theme.defaultTheme.textPrimaryColor)
                    .multilineTextAlignment(.center)
                
                Text("Unlock the full potential of Routine Anchor")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle((themeManager?.currentTheme.textPrimaryColor ?? Theme.defaultTheme.textPrimaryColor).opacity(0.8))
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    // MARK: - Features Section
    private var featuresSection: some View {
        VStack(spacing: 20) {
            Text("Premium Features")
                .font(.system(size: 24, weight: .semibold, design: .rounded))
                .foregroundStyle(themeManager?.currentTheme.textPrimaryColor ?? Theme.defaultTheme.textPrimaryColor)
            
            VStack(spacing: 16) {
                PremiumFeatureRow(
                    feature: .unlimitedTimeBlocks,
                    delay: 0.1
                )
                
                PremiumFeatureRow(
                    feature: .advancedAnalytics,
                    delay: 0.2
                )
                
                PremiumFeatureRow(
                    feature: .premiumThemes,
                    delay: 0.3
                )
                
                PremiumFeatureRow(
                    feature: .unlimitedTemplates,
                    delay: 0.4
                )
                
                PremiumFeatureRow(
                    feature: .widgets,
                    delay: 0.5
                )
            }
        }
        .padding(24)
        .themedGlassMorphism(cornerRadius: 20)
    }
    
    // MARK: - Pricing Section
    private var pricingSection: some View {
        VStack(spacing: 16) {
            Text("Choose Your Plan")
                .font(.system(size: 24, weight: .semibold, design: .rounded))
                .foregroundStyle(themeManager?.currentTheme.textPrimaryColor ?? Theme.defaultTheme.textPrimaryColor)
            
            if premiumManager.products.isEmpty {
                // Fallback when products aren't loaded
                VStack(spacing: 12) {
                    Text("Unable to load pricing")
                        .font(.system(size: 16))
                        .foregroundStyle((themeManager?.currentTheme.textPrimaryColor ?? Theme.defaultTheme.textPrimaryColor).opacity(0.7))
                    
                    Button("Retry") {
                        Task {
                            await loadProductsAndSetDefaults()
                        }
                    }
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(themeManager?.currentTheme.colorScheme.blue.color ?? Theme.defaultTheme.colorScheme.blue.color)
                }
                .padding(20)
                .background(Color(themeManager?.currentTheme.colorScheme.surfacePrimary.color ?? Theme.defaultTheme.colorScheme.surfacePrimary.color))
                .cornerRadius(12)
            } else {
                VStack(spacing: 12) {
                    // Yearly plan (recommended)
                    if let yearlyProduct = premiumManager.yearlyProduct {
                        PremiumPricingCard(
                            product: yearlyProduct,
                            isSelected: selectedProduct?.id == yearlyProduct.id,
                            savings: premiumManager.monthlySavings,
                            isRecommended: true
                        ) {
                            selectedProduct = yearlyProduct
                            HapticManager.shared.anchorSelection()
                        }
                    }
                    
                    // Monthly plan
                    if let monthlyProduct = premiumManager.monthlyProduct {
                        PremiumPricingCard(
                            product: monthlyProduct,
                            isSelected: selectedProduct?.id == monthlyProduct.id,
                            savings: nil,
                            isRecommended: false
                        ) {
                            selectedProduct = monthlyProduct
                            HapticManager.shared.anchorSelection()
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Purchase Section
    private var purchaseSection: some View {
        VStack(spacing: 16) {
            if let selectedProduct = selectedProduct {
                DesignedButton(
                    title: premiumManager.purchaseInProgress ? "Processing..." : "Start Premium - \(selectedProduct.displayPrice)",
                    style: .gradient,
                    action: {
                        Task {
                            await attemptPurchase(selectedProduct)
                        }
                    }
                )
                .disabled(premiumManager.isLoading || premiumManager.purchaseInProgress)
                .opacity(premiumManager.isLoading || premiumManager.purchaseInProgress ? 0.6 : 1.0)
                
                // Purchase details
                if selectedProduct.id.contains("yearly") {
                    VStack(spacing: 4) {
                        Text("• Billed annually")
                            .font(.system(size: 14))
                            .foregroundStyle((themeManager?.currentTheme.textSecondaryColor ?? Theme.defaultTheme.textSecondaryColor).opacity(0.85))
                        
                        Text("• Cancel anytime in Settings")
                            .font(.system(size: 14))
                            .foregroundStyle((themeManager?.currentTheme.textSecondaryColor ?? Theme.defaultTheme.textSecondaryColor).opacity(0.85))
                    }
                } else {
                    Text("• Billed monthly, cancel anytime")
                        .font(.system(size: 14))
                        .foregroundStyle((themeManager?.currentTheme.textSecondaryColor ?? Theme.defaultTheme.textSecondaryColor).opacity(0.85))
                }
                
            } else {
                VStack(spacing: 8) {
                    Text("Select a plan to continue")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle((themeManager?.currentTheme.textSecondaryColor ?? Theme.defaultTheme.textSecondaryColor).opacity(0.85))
                    
                    // Auto-select recommended plan button
                    if let yearlyProduct = premiumManager.yearlyProduct {
                        Button("Select Recommended Plan") {
                            selectedProduct = yearlyProduct
                            HapticManager.shared.anchorSelection()
                        }
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(themeManager?.currentTheme.colorScheme.blue.color ?? Theme.defaultTheme.colorScheme.blue.color)
                    }
                }
                .padding(.vertical, 16)
            }
            
            // Loading indicator
            if premiumManager.isLoading || premiumManager.purchaseInProgress {
                HStack(spacing: 8) {
                    ProgressView()
                        .scaleEffect(0.8)
                        .tint(.white)
                    Text("Processing...")
                        .font(.system(size: 14))
                        .foregroundStyle((themeManager?.currentTheme.textPrimaryColor ?? Theme.defaultTheme.textPrimaryColor).opacity(0.7))
                }
            }
            
            // Error handling
            if let errorMessage = premiumManager.errorMessage {
                VStack(spacing: 8) {
                    Text(errorMessage)
                        .font(.system(size: 14))
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Button("Dismiss") {
                        premiumManager.clearError()
                    }
                    .font(.system(size: 14))
                    .foregroundStyle((themeManager?.currentTheme.textPrimaryColor ?? Theme.defaultTheme.textPrimaryColor).opacity(0.7))
                }
            }
        }
    }
    
    // MARK: - Restore Section
    private var restoreSection: some View {
        VStack(spacing: 12) {
            Button("Restore Purchases") {
                Task {
                    await attemptRestore()
                }
            }
            .font(.system(size: 16, weight: .medium))
            .foregroundStyle((themeManager?.currentTheme.textPrimaryColor ?? Theme.defaultTheme.textPrimaryColor).opacity(0.7))
            .disabled(premiumManager.isLoading)
            
            // Terms and privacy
            HStack(spacing: 4) {
                Button("Terms") {
                    if let url = URL(string: "https://routineanchor.com/terms") {
                        UIApplication.shared.open(url)
                    }
                }
                Text("•")
                Button("Privacy") {
                    if let url = URL(string: "https://routineanchor.com/privacy") {
                        UIApplication.shared.open(url)
                    }
                }
            }
            .font(.system(size: 12))
            .foregroundStyle((themeManager?.currentTheme.textTertiaryColor ?? Theme.defaultTheme.textTertiaryColor))
        }
    }
    
    // MARK: - Helper Methods
    private func startAnimations() {
        withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
            animationPhase = 1.0
        }
    }
    
    private func closeView() {
        print("Close button tapped")
        
        HapticManager.shared.lightImpact()
        
        // Try multiple methods to ensure dismissal
        if #available(iOS 15.0, *) {
            dismiss()
        } else {
            presentationMode.wrappedValue.dismiss()
        }
        
        // Fallback: Post notification to parent to handle dismissal
        NotificationCenter.default.post(
            name: Notification.Name("dismissPremiumUpgrade"),
            object: nil
        )
    }
    
    // Load products and set defaults
    private func loadProductsAndSetDefaults() async {
        await premiumManager.loadProducts()
        
        // Auto-select yearly plan if available (recommended)
        if selectedProduct == nil, let yearlyProduct = premiumManager.yearlyProduct {
            selectedProduct = yearlyProduct
        }
    }
    
    // Purchase error handling
    private func attemptPurchase(_ product: Product) async {
        do {
            try await premiumManager.purchase(product)
            if premiumManager.userIsPremium {
                // Success - dismiss view
                await MainActor.run {
                    closeView()
                }
            }
        } catch {
            // Error is already handled by PremiumManager
            HapticManager.shared.anchorError()
        }
    }
    
    // Restore with feedback
    private func attemptRestore() async {
        await premiumManager.restorePurchases()
        if premiumManager.userIsPremium {
            await MainActor.run {
                closeView()
            }
        } else {
            // Show feedback that no purchases were found
            HapticManager.shared.lightImpact()
        }
    }
}

// MARK: - Enhanced Premium Pricing Card
struct PremiumPricingCard: View {
    @Environment(\.themeManager) private var themeManager
    let product: Product
    let isSelected: Bool
    let savings: String?
    let isRecommended: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                // Recommended badge
                if isRecommended {
                    HStack {
                        Spacer()
                        Text("MOST POPULAR")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(themeManager?.currentTheme.textPrimaryColor ?? Theme.defaultTheme.textPrimaryColor)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(themeManager?.currentTheme.colorScheme.green.color ?? Theme.defaultTheme.colorScheme.green.color)
                            )
                        Spacer()
                    }
                }
                
                // Title and price
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(product.displayName)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(themeManager?.currentTheme.textPrimaryColor ?? Theme.defaultTheme.textPrimaryColor)
                        
                        if let savings = savings, !savings.isEmpty {
                            Text("Save \(savings)")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(.green)
                        }
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(product.displayPrice)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(themeManager?.currentTheme.textPrimaryColor ?? Theme.defaultTheme.textPrimaryColor)
                        
                        // Show billing period
                        Text(product.id.contains("yearly") ? "per year" : "per month")
                            .font(.system(size: 12))
                            .foregroundStyle((themeManager?.currentTheme.textSecondaryColor ?? Theme.defaultTheme.textSecondaryColor).opacity(0.85))
                    }
                }
                
                // Per month calculation for yearly
                if product.id.contains("yearly") {
                    HStack {
                        let monthlyEquivalent = NSDecimalNumber(decimal: product.price).doubleValue / 12.0
                        Text("Just $\(String(format: "%.2f", monthlyEquivalent)) per month")
                            .font(.system(size: 14))
                            .foregroundStyle((themeManager?.currentTheme.textPrimaryColor ?? Theme.defaultTheme.textPrimaryColor).opacity(0.7))
                        Spacer()
                    }
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        isSelected ? themeManager?.currentTheme.colorScheme.blue.color ?? Theme.defaultTheme.colorScheme.blue.color : Color(themeManager?.currentTheme.colorScheme.surfaceSecondary.color ?? Theme.defaultTheme.colorScheme.surfaceSecondary.color),
                        lineWidth: isSelected ? 2 : 1
                    )
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                isSelected
                                ? themeManager?.currentTheme.colorScheme.blue.color ?? Theme.defaultTheme.colorScheme.blue.color.opacity(0.1)
                                : Color(themeManager?.currentTheme.colorScheme.surfacePrimary.color ?? Theme.defaultTheme.colorScheme.surfacePrimary.color).opacity(0.5)
                            )
                    )
            )
        }
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

// MARK: - Premium Feature Row
struct PremiumFeatureRow: View {
    @Environment(\.themeManager) private var themeManager
    let feature: PremiumManager.PremiumFeature
    let delay: Double
    @State private var isVisible = false
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            Image(systemName: feature.icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(featureColor)
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(featureColor.opacity(0.15))
                )
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(feature.displayName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(themeManager?.currentTheme.textPrimaryColor ?? Theme.defaultTheme.textPrimaryColor)
                
                Text(feature.description)
                    .font(.system(size: 14))
                    .foregroundStyle((themeManager?.currentTheme.textPrimaryColor ?? Theme.defaultTheme.textPrimaryColor).opacity(0.7))
                    .lineLimit(2)
            }
            
            Spacer()
            
            // Checkmark
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 20))
                .foregroundStyle(.green)
        }
        .opacity(isVisible ? 1 : 0)
        .offset(x: isVisible ? 0 : -20)
        .onAppear {
            withAnimation(.easeOut(duration: 0.6).delay(delay)) {
                isVisible = true
            }
        }
    }
    
    private var featureColor: Color {
        switch feature {
        case .unlimitedTimeBlocks:
            return themeManager?.currentTheme.colorScheme.blue.color ?? Theme.defaultTheme.colorScheme.blue.color
        case .advancedAnalytics:
            return themeManager?.currentTheme.colorScheme.purple.color ?? Theme.defaultTheme.colorScheme.purple.color
        case .premiumThemes:
            return themeManager?.currentTheme.colorScheme.green.color ?? Theme.defaultTheme.colorScheme.green.color
        case .unlimitedTemplates:
            return themeManager?.currentTheme.colorScheme.teal.color ?? Theme.defaultTheme.colorScheme.teal.color
        case .widgets:
            return themeManager?.currentTheme.colorScheme.warning.color ?? Theme.defaultTheme.colorScheme.warning.color
        default:
            return themeManager?.currentTheme.colorScheme.blue.color ?? Theme.defaultTheme.colorScheme.blue.color
        }
    }
}

// MARK: - Preview
#Preview {
    PremiumUpgradeView(premiumManager: PremiumManager())
}
