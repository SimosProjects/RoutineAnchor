//
//  PremiumUpgradeView.swift
//  Routine Anchor
//

import SwiftUI
import StoreKit

struct PremiumUpgradeView: View {
    @Environment(\.themeManager) private var themeManager
    @Environment(\.dismiss) private var dismiss
    @Environment(\.premiumManager) private var premiumManager

    @State private var selectedProduct: Product?
    @State private var showingFeatureDetail = false
    @State private var animationPhase = 0.0

    var body: some View {
        ZStack {
            ThemedAnimatedBackground()
                .ignoresSafeArea()

            if (premiumManager?.isLoading == true) && ((premiumManager?.products.isEmpty) ?? true) {
                loadingView
            } else {
                ScrollView {
                    VStack(spacing: 32) {
                        headerSection
                        featuresSection
                        pricingSection
                        purchaseSection
                        restoreSection
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 32)
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .task {
            await loadProductsAndSetDefaults()
        }
        .onAppear { startAnimations() }
    }

    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: 20) {
            Spacer()
            ProgressView().scaleEffect(1.5).tint(.white)
            Text("Loading Premium Plans...")
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle((themeManager?.currentTheme.primaryTextColor ?? Theme.defaultTheme.primaryTextColor).opacity(0.8))
            Spacer()
        }
    }

    // MARK: - Header
    private var headerSection: some View {
        VStack(spacing: 20) {
            HStack {
                Spacer()
                Button(action: { closeView() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle((themeManager?.currentTheme.primaryTextColor ?? Theme.defaultTheme.primaryTextColor).opacity(0.8))
                }
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
            }

            Image(systemName: "crown.fill")
                .font(.system(size: 60, weight: .medium))
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            themeManager?.currentTheme.colorScheme.warning.color ?? Theme.defaultTheme.colorScheme.warning.color,
                            themeManager?.currentTheme.colorScheme.success.color ?? Theme.defaultTheme.colorScheme.success.color
                        ],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                )
                .floatModifier(amplitude: 8, duration: 3)
                .scaleEffect(1.0 + sin(animationPhase * .pi * 2) * 0.05)

            VStack(spacing: 12) {
                Text("Upgrade to Premium")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(themeManager?.currentTheme.primaryTextColor ?? Theme.defaultTheme.primaryTextColor)
                    .multilineTextAlignment(.center)

                Text("Unlock the full potential of Routine Anchor")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle((themeManager?.currentTheme.primaryTextColor ?? Theme.defaultTheme.primaryTextColor).opacity(0.8))
                    .multilineTextAlignment(.center)
            }
        }
    }

    // MARK: - Features
    private var featuresSection: some View {
        VStack(spacing: 20) {
            Text("Premium Features")
                .font(.system(size: 24, weight: .semibold, design: .rounded))
                .foregroundStyle(themeManager?.currentTheme.primaryTextColor ?? Theme.defaultTheme.primaryTextColor)

            VStack(spacing: 16) {
                PremiumFeatureRow(feature: .unlimitedTimeBlocks, delay: 0.1)
                PremiumFeatureRow(feature: .advancedAnalytics,  delay: 0.2)
                PremiumFeatureRow(feature: .premiumThemes,      delay: 0.3)
                PremiumFeatureRow(feature: .unlimitedTemplates, delay: 0.4)
                PremiumFeatureRow(feature: .widgets,            delay: 0.5)
            }
        }
        .padding(24)
        .themedGlassMorphism(cornerRadius: 20)
    }

    // MARK: - Pricing
    private var pricingSection: some View {
        VStack(spacing: 16) {
            Text("Choose Your Plan")
                .font(.system(size: 24, weight: .semibold, design: .rounded))
                .foregroundStyle(themeManager?.currentTheme.primaryTextColor ?? Theme.defaultTheme.primaryTextColor)

            if (premiumManager?.products.isEmpty ?? true) {
                VStack(spacing: 12) {
                    Text("Unable to load pricing")
                        .font(.system(size: 16))
                        .foregroundStyle((themeManager?.currentTheme.primaryTextColor ?? Theme.defaultTheme.primaryTextColor).opacity(0.7))

                    Button("Retry") {
                        Task { await loadProductsAndSetDefaults() }
                    }
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(themeManager?.currentTheme.colorScheme.normal.color ?? Theme.defaultTheme.colorScheme.normal.color)
                }
                .padding(20)
                .background(Color(themeManager?.currentTheme.colorScheme.primaryUIElement.color ?? Theme.defaultTheme.colorScheme.primaryUIElement.color))
                .cornerRadius(12)
            } else {
                VStack(spacing: 12) {
                    if let yearly = premiumManager?.yearlyProduct {
                        PremiumPricingCard(
                            product: yearly,
                            isSelected: selectedProduct?.id == yearly.id,
                            savings: premiumManager?.monthlySavings,
                            isRecommended: true
                        ) {
                            selectedProduct = yearly
                            HapticManager.shared.anchorSelection()
                        }
                    }
                    if let monthly = premiumManager?.monthlyProduct {
                        PremiumPricingCard(
                            product: monthly,
                            isSelected: selectedProduct?.id == monthly.id,
                            savings: nil,
                            isRecommended: false
                        ) {
                            selectedProduct = monthly
                            HapticManager.shared.anchorSelection()
                        }
                    }
                }
            }
        }
    }

    // MARK: - Purchase
    private var purchaseSection: some View {
        VStack(spacing: 16) {
            if let selected = selectedProduct {
                DesignedButton(
                    title: (premiumManager?.purchaseInProgress == true) ? "Processing..." : "Start Premium - \(selected.displayPrice)",
                    style: .gradient
                ) {
                    Task { await attemptPurchase(selected) }
                }
                .disabled((premiumManager?.isLoading ?? true) || (premiumManager?.purchaseInProgress ?? false))
                .opacity(((premiumManager?.isLoading ?? false) || (premiumManager?.purchaseInProgress ?? false)) ? 0.6 : 1.0)

                // Simple billing hints
                if selected.id.contains("yearly") {
                    VStack(spacing: 4) {
                        Text("• Billed annually")
                        Text("• Cancel anytime in Settings")
                    }
                    .font(.system(size: 14))
                    .foregroundStyle((themeManager?.currentTheme.secondaryTextColor ?? Theme.defaultTheme.secondaryTextColor).opacity(0.85))
                } else {
                    Text("• Billed monthly, cancel anytime")
                        .font(.system(size: 14))
                        .foregroundStyle((themeManager?.currentTheme.secondaryTextColor ?? Theme.defaultTheme.secondaryTextColor).opacity(0.85))
                }
            } else {
                VStack(spacing: 8) {
                    Text("Select a plan to continue")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle((themeManager?.currentTheme.secondaryTextColor ?? Theme.defaultTheme.secondaryTextColor).opacity(0.85))

                    if let yearly = premiumManager?.yearlyProduct {
                        Button("Select Recommended Plan") {
                            selectedProduct = yearly
                            HapticManager.shared.anchorSelection()
                        }
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(themeManager?.currentTheme.colorScheme.normal.color ?? Theme.defaultTheme.colorScheme.normal.color)
                    }
                }
                .padding(.vertical, 16)
            }

            if (premiumManager?.isLoading == true) || (premiumManager?.purchaseInProgress == true) {
                HStack(spacing: 8) {
                    ProgressView().scaleEffect(0.8).tint(.white)
                    Text("Processing...")
                        .font(.system(size: 14))
                        .foregroundStyle((themeManager?.currentTheme.primaryTextColor ?? Theme.defaultTheme.primaryTextColor).opacity(0.7))
                }
            }

            if let errorMessage = premiumManager?.errorMessage {
                VStack(spacing: 8) {
                    Text(errorMessage)
                        .font(.system(size: 14))
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    Button("Dismiss") { premiumManager?.clearError() }
                        .font(.system(size: 14))
                        .foregroundStyle((themeManager?.currentTheme.primaryTextColor ?? Theme.defaultTheme.primaryTextColor).opacity(0.7))
                }
            }
        }
    }

    // MARK: - Restore
    private var restoreSection: some View {
        VStack(spacing: 12) {
            Button("Restore Purchases") {
                Task { await attemptRestore() }
            }
            .font(.system(size: 16, weight: .medium))
            .foregroundStyle((themeManager?.currentTheme.primaryTextColor ?? Theme.defaultTheme.primaryTextColor).opacity(0.7))
            .disabled(premiumManager?.isLoading ?? true)

            HStack(spacing: 4) {
                Button("Terms") {
                    if let url = URL(string: "https://routineanchor.com/terms") { UIApplication.shared.open(url) }
                }
                Text("•")
                Button("Privacy") {
                    if let url = URL(string: "https://routineanchor.com/privacy") { UIApplication.shared.open(url) }
                }
            }
            .font(.system(size: 12))
            .foregroundStyle((themeManager?.currentTheme.subtleTextColor ?? Theme.defaultTheme.subtleTextColor))
        }
    }

    // MARK: - Helpers
    private func startAnimations() {
        withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
            animationPhase = 1.0
        }
    }

    private func closeView() {
        HapticManager.shared.lightImpact()
        dismiss()
        NotificationCenter.default.post(name: Notification.Name("dismissPremiumUpgrade"), object: nil)
    }

    private func loadProductsAndSetDefaults() async {
        guard let pm = premiumManager else { return }
        await pm.loadProducts()
        if selectedProduct == nil, let yearly = pm.yearlyProduct {
            selectedProduct = yearly
        }
    }

    private func attemptPurchase(_ product: Product) async {
        guard let pm = premiumManager else { return }
        do {
            try await pm.purchase(product)
            if pm.userIsPremium {
                await MainActor.run { closeView() }
            }
        } catch {
            HapticManager.shared.anchorError()
        }
    }

    private func attemptRestore() async {
        guard let pm = premiumManager else { return }
        await pm.restorePurchases()
        if pm.userIsPremium {
            await MainActor.run { closeView() }
        } else {
            HapticManager.shared.lightImpact()
        }
    }
}

// MARK: - Pricing Card
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
                if isRecommended {
                    HStack {
                        Spacer()
                        Text("MOST POPULAR")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(themeManager?.currentTheme.primaryTextColor ?? Theme.defaultTheme.primaryTextColor)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(themeManager?.currentTheme.colorScheme.success.color ?? Theme.defaultTheme.colorScheme.success.color))
                        Spacer()
                    }
                }

                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(product.displayName)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(themeManager?.currentTheme.primaryTextColor ?? Theme.defaultTheme.primaryTextColor)

                        if let s = savings, !s.isEmpty {
                            Text("Save \(s)")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(.green)
                        }
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text(product.displayPrice)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(themeManager?.currentTheme.primaryTextColor ?? Theme.defaultTheme.primaryTextColor)

                        Text(product.id.contains("yearly") ? "per year" : "per month")
                            .font(.system(size: 12))
                            .foregroundStyle((themeManager?.currentTheme.secondaryTextColor ?? Theme.defaultTheme.secondaryTextColor).opacity(0.85))
                    }
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        isSelected
                        ? (themeManager?.currentTheme.colorScheme.normal.color ?? Theme.defaultTheme.colorScheme.normal.color)
                        : Color(themeManager?.currentTheme.colorScheme.secondaryUIElement.color ?? Theme.defaultTheme.colorScheme.secondaryUIElement.color),
                        lineWidth: isSelected ? 2 : 1
                    )
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                isSelected
                                ? (themeManager?.currentTheme.colorScheme.normal.color ?? Theme.defaultTheme.colorScheme.normal.color).opacity(0.1)
                                : Color(themeManager?.currentTheme.colorScheme.primaryUIElement.color ?? Theme.defaultTheme.colorScheme.primaryUIElement.color).opacity(0.5)
                            )
                    )
            )
        }
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

// MARK: - Feature Row
struct PremiumFeatureRow: View {
    @Environment(\.themeManager) private var themeManager
    let feature: PremiumManager.PremiumFeature
    let delay: Double
    @State private var isVisible = false

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: feature.icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(featureColor)
                .frame(width: 32, height: 32)
                .background(Circle().fill(featureColor.opacity(0.15)))

            VStack(alignment: .leading, spacing: 4) {
                Text(feature.displayName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(themeManager?.currentTheme.primaryTextColor ?? Theme.defaultTheme.primaryTextColor)

                Text(feature.description)
                    .font(.system(size: 14))
                    .foregroundStyle((themeManager?.currentTheme.primaryTextColor ?? Theme.defaultTheme.primaryTextColor).opacity(0.7))
                    .lineLimit(2)
            }

            Spacer()
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
            return themeManager?.currentTheme.colorScheme.normal.color ?? Theme.defaultTheme.colorScheme.normal.color
        case .advancedAnalytics:
            return themeManager?.currentTheme.colorScheme.primaryAccent.color ?? Theme.defaultTheme.colorScheme.primaryAccent.color
        case .premiumThemes:
            return themeManager?.currentTheme.colorScheme.success.color ?? Theme.defaultTheme.colorScheme.success.color
        case .unlimitedTemplates:
            return themeManager?.currentTheme.colorScheme.secondaryUIElement.color ?? Theme.defaultTheme.colorScheme.secondaryUIElement.color
        case .widgets:
            return themeManager?.currentTheme.colorScheme.warning.color ?? Theme.defaultTheme.colorScheme.warning.color
        default:
            return themeManager?.currentTheme.colorScheme.normal.color ?? Theme.defaultTheme.colorScheme.normal.color
        }
    }
}

#Preview {
    // Preview with a fresh manager in the environment
    PremiumUpgradeView()
        .environment(\.premiumManager, PremiumManager())
        .environment(\.themeManager, ThemeManager(premiumManager: PremiumManager()))
}
