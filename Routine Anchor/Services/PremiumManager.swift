//
//  PremiumManager.swift
//  Routine Anchor
//
//  Premium subscription and feature management with debug override.
//

import StoreKit
import SwiftUI
import Foundation

@MainActor
@Observable
class PremiumManager {
    // MARK: - Published-like (via @Observable) Properties
    var userIsPremium = false
    var products: [Product] = []
    var monthlyProduct: Product?
    var yearlyProduct: Product?

    var isLoading = false
    var purchaseInProgress = false
    var errorMessage: String?

    // MARK: - Debug Override
    private let debugPremiumKey = "premiumDebugOverride"
    private(set) var premiumDebugOverrideEnabled: Bool =
        UserDefaults.standard.bool(forKey: "premiumDebugOverride")

    /// Use this everywhere the UI needs to know if premium features are unlocked.
    /// True if the user has a valid entitlement OR the debug override is on.
    var isPremiumActive: Bool {
        userIsPremium || premiumDebugOverrideEnabled
    }

    // MARK: - Product Identifiers
    private let productIDs = [
        "com.simosmediatech.routineanchor.premium.monthly",
        "com.simosmediatech.routineanchor.premium.yearly"
    ]

    // MARK: - Free Limits
    static let freeTimeBlockLimit = 3
    static let freeDailyBlocks    = 3
    static let freeTemplateLimit  = 3

    // MARK: - Init
    init() {
        loadUserPremiumStatus()

        // Observe SettingsView’s debug toggle
        NotificationCenter.default.addObserver(
            forName: .premiumDebugOverrideChanged,
            object: nil,
            queue: .main
        ) { [weak self] note in
            guard let enabled = note.userInfo?["enabled"] as? Bool else { return }
            Task { @MainActor [weak self] in
                self?.setDebugPremium(enabled)
            }
        }

        Task {
            await loadProducts()
            await checkForExistingSubscriptions()
        }
    }

    // MARK: - Debug override API
    func setDebugPremium(_ enabled: Bool) {
        premiumDebugOverrideEnabled = enabled
        UserDefaults.standard.set(enabled, forKey: debugPremiumKey)
        broadcastStatusChange()
    }

    // MARK: - StoreKit: Load Products
    func loadProducts() async {
        isLoading = true
        defer { isLoading = false }

        do {
            products = try await Product.products(for: productIDs)
            for product in products {
                if product.id.contains("monthly") {
                    monthlyProduct = product
                } else if product.id.contains("yearly") {
                    yearlyProduct = product
                }
            }
            print("✅ Loaded \(products.count) products")
        } catch {
            errorMessage = "Failed to load products: \(error.localizedDescription)"
            print("❌ Failed to load products: \(error)")
        }
    }

    // MARK: - StoreKit: Purchase
    enum AnchorError: Error {
        case productUnavailable
        case verificationFailed
        case purchaseCancelled
        case unknown
    }

    func purchase(_ product: Product) async throws {
        purchaseInProgress = true
        defer { purchaseInProgress = false }

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                switch verification {
                case .verified(let transaction):
                    userIsPremium = true
                    savePremiumStatus(true)
                    await transaction.finish()
                    HapticManager.shared.anchorSuccess()
                    print("✅ Purchase successful: \(product.displayName)")
                    broadcastStatusChange()

                case .unverified:
                    throw AnchorError.verificationFailed
                }

            case .userCancelled:
                throw AnchorError.purchaseCancelled

            default:
                throw AnchorError.unknown
            }
        } catch {
            errorMessage = "Purchase failed: \(error.localizedDescription)"
            HapticManager.shared.anchorError()
            print("❌ Purchase failed: \(error)")
            throw error
        }
    }

    // MARK: - StoreKit: Restore
    func restorePurchases() async {
        isLoading = true
        defer { isLoading = false }

        do {
            var restored = false
            for await result in Transaction.currentEntitlements {
                switch result {
                case .verified(let transaction):
                    if transaction.productID.contains("premium") {
                        restored = true
                        userIsPremium = true
                        savePremiumStatus(true)
                        print("✅ Restored entitlement: \(transaction.productID)")
                    }
                case .unverified:
                    print("⚠️ Unverified entitlement present")
                }
            }
            if restored { broadcastStatusChange() }
        } catch {
            print("❌ Restore failed: \(error)")
            errorMessage = "Restore failed: \(error.localizedDescription)"
        }
    }

    // MARK: - Entitlement Check on Launch
    func checkForExistingSubscriptions() async {
        do {
            var found = false
            for await result in Transaction.currentEntitlements {
                switch result {
                case .verified(let transaction):
                    if transaction.productID.contains("premium") {
                        found = true
                        userIsPremium = true
                        savePremiumStatus(true)
                        print("✅ Existing entitlement detected: \(transaction.productID)")
                    }
                case .unverified:
                    print("⚠️ Unverified entitlement encountered")
                }
            }
            if found { broadcastStatusChange() }
        }
    }

    // MARK: - Local Persistence
    private let premiumKey = "userIsPremium"

    private func loadUserPremiumStatus() {
        userIsPremium = UserDefaults.standard.bool(forKey: premiumKey)
    }

    private func savePremiumStatus(_ value: Bool) {
        UserDefaults.standard.set(value, forKey: premiumKey)
    }

    func clearError() {
        errorMessage = nil
    }

    // MARK: - Business Rules / Gates (use isPremiumActive)
    /// Backwards-compatible property some parts of the app already use.
    /// Getter reflects *active* premium (entitlement OR debug). Setter flips real entitlement flag.
    var hasPremiumAccess: Bool {
        get { isPremiumActive }
        set {
            // Setter simulates entitlement for debug/QA flows.
            userIsPremium = newValue
            savePremiumStatus(newValue)
            broadcastStatusChange()
        }
    }

    /// Free users see ads unless premium is active.
    var shouldShowAds: Bool {
        !isPremiumActive
    }

    /// Whether free users have hit a limit for creating time blocks.
    func canCreateMoreBlocks(currentCount: Int) -> Bool {
        isPremiumActive || currentCount < Self.freeTimeBlockLimit
    }

    /// Whether free users can create more templates.
    func canCreateMoreTemplates(currentCount: Int) -> Bool {
        isPremiumActive || currentCount < Self.freeTemplateLimit
    }

    /// Feature gates (handy for views like analytics, themes, templates)
    var canAccessAdvancedAnalytics: Bool { isPremiumActive }
    var canAccessPremiumThemes: Bool     { isPremiumActive }
    var canUseUnlimitedTemplates: Bool   { isPremiumActive }

    // Friendly savings string for yearly vs monthly (simple for now)
    var monthlySavings: String? {
        guard monthlyProduct != nil, yearlyProduct != nil else { return nil }
        return "Best value"
    }

    // MARK: - Notifications
    private func broadcastStatusChange() {
        // Legacy name used in the project:
        NotificationCenter.default.post(name: .premiumStatusChanged, object: nil)
        // Also post a generic raw-name so views listening to "premiumStatusDidChange" update too.
        NotificationCenter.default.post(name: Notification.Name("premiumStatusDidChange"), object: nil)
    }
}

// MARK: - Premium Features
extension PremiumManager {
    enum PremiumFeature: String, CaseIterable, Identifiable, Sendable {
        case unlimitedTimeBlocks
        case advancedAnalytics
        case premiumThemes
        case unlimitedTemplates
        case widgets

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .unlimitedTimeBlocks: return "checkmark.circle.fill"
            case .advancedAnalytics:   return "chart.xyaxis.line"
            case .premiumThemes:       return "paintpalette.fill"
            case .unlimitedTemplates:  return "square.grid.2x2.fill"
            case .widgets:             return "rectangle.portrait.on.rectangle.portrait.angled"
            }
        }

        var displayName: String {
            switch self {
            case .unlimitedTimeBlocks: return "Unlimited Time Blocks"
            case .advancedAnalytics:   return "Advanced Analytics"
            case .premiumThemes:       return "Premium Themes"
            case .unlimitedTemplates:  return "Unlimited Templates"
            case .widgets:             return "Home & Lock Screen Widgets"
            }
        }

        var description: String {
            switch self {
            case .unlimitedTimeBlocks:
                return "Plan your day without limits."
            case .advancedAnalytics:
                return "Deep insights and performance trends."
            case .premiumThemes:
                return "Exclusive, high-contrast themes."
            case .unlimitedTemplates:
                return "Create and reuse as many as you like."
            case .widgets:
                return "Glanceable progress and quick actions."
            }
        }
    }

    /// If you ever want to drive the list dynamically in the UI:
    var availableFeatures: [PremiumFeature] {
        PremiumFeature.allCases
    }
}


#if DEBUG
// MARK: - Debug Controls (Optional helper UI)
struct DebugPremiumView: View {
    @Environment(\.themeManager) private var themeManager
    @Environment(\.premiumManager) private var premiumManager

    private var theme: AppTheme { themeManager?.currentTheme ?? PredefinedThemes.classic }

    var body: some View {
        VStack(spacing: 16) {
            Text("🧪 Debug Premium Controls")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(theme.primaryTextColor)

            HStack(spacing: 12) {
                DesignedButton(title: "Load Products", style: .surface, size: .medium, fullWidth: false) {
                    Task { await premiumManager?.loadProducts() }
                }
                DesignedButton(
                    title: (premiumManager?.isPremiumActive ?? false) ? "Set Free" : "Set Premium",
                    style: .gradient, size: .medium, fullWidth: false
                ) {
                    guard let pm = premiumManager else { return }
                    pm.setDebugPremium(!(pm.isPremiumActive))
                }
            }

            if let monthly = premiumManager?.monthlyProduct {
                DesignedButton(title: "Purchase Monthly", style: .surface, size: .medium, fullWidth: false) {
                    Task { try? await premiumManager?.purchase(monthly) }
                }
            }
            if let yearly = premiumManager?.yearlyProduct {
                DesignedButton(title: "Purchase Yearly", style: .surface, size: .medium, fullWidth: false) {
                    Task { try? await premiumManager?.purchase(yearly) }
                }
            }

            DesignedButton(title: "Restore Purchases", style: .surface, size: .medium, fullWidth: false) {
                Task { await premiumManager?.restorePurchases() }
            }

            if let products = premiumManager?.products, !products.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Loaded Products")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(theme.secondaryTextColor)

                    ForEach(products, id: \.id) { product in
                        HStack {
                            Text(product.displayName)
                                .foregroundStyle(theme.primaryTextColor)
                            Spacer()
                            Text(product.displayPrice)
                                .foregroundStyle(theme.secondaryTextColor)
                        }
                        .font(.system(size: 14))
                        .padding(.vertical, 4)
                    }
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: theme.cardCornerRadius, style: .continuous)
                        .fill(theme.surfaceCardColor.opacity(0.5))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: theme.cardCornerRadius, style: .continuous)
                        .stroke(theme.borderColor.opacity(0.9), lineWidth: 1)
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: theme.cardCornerRadius, style: .continuous)
                .fill(theme.surfaceCardColor.opacity(0.35))
        )
        .overlay(
            RoundedRectangle(cornerRadius: theme.cardCornerRadius, style: .continuous)
                .stroke(theme.borderColor.opacity(0.8), lineWidth: 1)
        )
        .padding()
    }
}
#endif
