//
//  PremiumUpgradeView.swift
//  Routine Anchor
//
//  Premium upgrade and subscription view
//
import SwiftUI
import StoreKit

struct PremiumUpgradeView: View {
    @Environment(\.dismiss) private var dismiss
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
            AnimatedGradientBackground()
                .ignoresSafeArea()
            
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
        .navigationBarHidden(true)
        .onAppear {
            startAnimations()
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 20) {
            // Close button
            HStack {
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
            
            // Premium crown
            Image(systemName: "crown.fill")
                .font(.system(size: 60, weight: .medium))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.anchorWarning, Color.anchorGreen],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .floatModifier(amplitude: 8, duration: 3)
                .scaleEffect(1.0 + sin(animationPhase * .pi * 2) * 0.05)
            
            VStack(spacing: 12) {
                Text("Upgrade to Premium")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                
                Text("Unlock the full potential of Routine Anchor")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    // MARK: - Features Section
    private var featuresSection: some View {
        VStack(spacing: 20) {
            Text("Premium Features")
                .font(.system(size: 24, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
            
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
        .glassMorphism(cornerRadius: 20)
    }
    
    // MARK: - Pricing Section
    private var pricingSection: some View {
        VStack(spacing: 16) {
            Text("Choose Your Plan")
                .font(.system(size: 24, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
            
            VStack(spacing: 12) {
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
    
    // MARK: - Purchase Section
    private var purchaseSection: some View {
        VStack(spacing: 16) {
            if let selectedProduct = selectedProduct {
                DesignedButton(
                    title: "Start Premium - \(selectedProduct.displayPrice)",
                    style: .gradient,
                    action: {
                        Task {
                            try await premiumManager.purchase(selectedProduct)
                            if premiumManager.userIsPremium {
                                dismiss()
                            }
                        }
                    }
                )
                .disabled(premiumManager.isLoading)
                .opacity(premiumManager.isLoading ? 0.6 : 1.0)
            } else {
                Text("Select a plan to continue")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.white.opacity(0.6))
                    .padding(.vertical, 16)
            }
            
            if premiumManager.isLoading {
                HStack(spacing: 8) {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Processing...")
                        .font(.system(size: 14))
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
            
            if let errorMessage = premiumManager.errorMessage {
                Text(errorMessage)
                    .font(.system(size: 14))
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
    }
    
    // MARK: - Restore Section
    private var restoreSection: some View {
        VStack(spacing: 12) {
            Button("Restore Purchases") {
                Task {
                    await premiumManager.restorePurchases()
                    if premiumManager.userIsPremium {
                        dismiss()
                    }
                }
            }
            .font(.system(size: 16, weight: .medium))
            .foregroundStyle(.white.opacity(0.7))
            .disabled(premiumManager.isLoading)
            
            // Terms and privacy
            HStack(spacing: 4) {
                Button("Terms") {
                    // TODO: Open terms URL
                    if let url = URL(string: "https://routineanchor.com/terms") {
                        UIApplication.shared.open(url)
                    }
                }
                Text("•")
                Button("Privacy") {
                    // TODO: Open privacy URL
                    if let url = URL(string: "https://routineanchor.com/privacy") {
                        UIApplication.shared.open(url)
                    }
                }
            }
            .font(.system(size: 12))
            .foregroundStyle(.white.opacity(0.5))
        }
    }
    
    // MARK: - Helper Methods
    private func startAnimations() {
        withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
            animationPhase = 1.0
        }
    }
}

// MARK: - Premium Feature Row
struct PremiumFeatureRow: View {
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
                    .foregroundStyle(.white)
                
                Text(feature.description)
                    .font(.system(size: 14))
                    .foregroundStyle(.white.opacity(0.7))
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
            return .anchorBlue
        case .advancedAnalytics:
            return .anchorPurple
        case .premiumThemes:
            return .anchorGreen
        case .unlimitedTemplates:
            return .anchorTeal
        case .widgets:
            return .anchorWarning
        default:
            return .anchorBlue
        }
    }
}

// MARK: - Premium Pricing Card
struct PremiumPricingCard: View {
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
                            .foregroundStyle(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(Color.anchorGreen)
                            )
                        Spacer()
                    }
                }
                
                // Title and price
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(product.displayName)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.white)
                        
                        if let savings = savings, !savings.isEmpty {
                            Text("Save \(savings)")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(.green)
                        }
                    }
                    
                    Spacer()
                    
                    Text(product.displayPrice)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(.white)
                }
                
                // Per month calculation for yearly
                if product.id.contains("yearly") {
                    HStack {
                        // Fixed: Convert Decimal to Double properly
                        let monthlyEquivalent = NSDecimalNumber(decimal: product.price).doubleValue / 12.0
                        Text("Just $\(String(format: "%.2f", monthlyEquivalent)) per month")
                            .font(.system(size: 14))
                            .foregroundStyle(.white.opacity(0.7))
                        Spacer()
                    }
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        isSelected ? Color.anchorBlue : Color.white.opacity(0.2),
                        lineWidth: isSelected ? 2 : 1
                    )
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                isSelected
                                ? Color.anchorBlue.opacity(0.1)
                                : Color.white.opacity(0.05)
                            )
                    )
            )
        }
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

// MARK: - Preview
#Preview {
    PremiumUpgradeView(premiumManager: PremiumManager())
}
