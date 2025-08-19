//
//  PremiumManager.swift
//  Routine Anchor
//
//  Premium subscription and feature management
//
import StoreKit
import SwiftUI
import Foundation

@MainActor
@Observable
class PremiumManager {
    // MARK: - Published Properties
    var userIsPremium = false
    var products: [Product] = []
    var isLoading = false
    var errorMessage: String?
    var purchaseInProgress = false
    var temporaryPremiumUntil: Date?
    
    // MARK: - Product IDs
    private let productIDs = [
        "com.simosmediatech.routineanchor.premium.monthly",
        "com.simosmediatech.routineanchor.premium.yearly"
    ]
    
    // MARK: - Premium Limits
    static let freeTimeBlockLimit = 3
    static let freeDailyBlocks = 3
    static let freeTemplateLimit = 3
    
    // MARK: - Initialization
    init() {
        loadUserPremiumStatus()
        Task {
            await loadProducts()
            await checkForExistingSubscriptions()
        }
    }
    
    // MARK: - Product Loading
    func loadProducts() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            products = try await Product.products(for: productIDs)
            print("✅ Loaded \(products.count) products")
        } catch {
            errorMessage = "Failed to load products: \(error.localizedDescription)"
            print("❌ Failed to load products: \(error)")
        }
    }
    
    // MARK: - Purchase Management
    func purchase(_ product: Product) async throws {
        guard !purchaseInProgress else { return }
        
        purchaseInProgress = true
        isLoading = true
        defer {
            purchaseInProgress = false
            isLoading = false
        }
        
        let result = try await product.purchase()
        
        switch result {
        case .success(let verification):
            switch verification {
            case .verified(let transaction):
                userIsPremium = true
                savePremiumStatus(true)
                await transaction.finish()
                HapticManager.shared.premiumSuccess()
                print("✅ Purchase successful: \(product.displayName)")
                
            case .unverified:
                throw PremiumError.verificationFailed
            }
            
        case .userCancelled:
            print("ℹ️ User cancelled purchase")
            break
            
        case .pending:
            print("⏳ Purchase pending")
            break
            
        @unknown default:
            throw PremiumError.unknownResult
        }
    }
    
    func restorePurchases() async {
        isLoading = true
        defer { isLoading = false }
        
        var foundSubscription = false
        
        for await result in Transaction.currentEntitlements {
            switch result {
            case .verified(let transaction):
                if productIDs.contains(transaction.productID) {
                    userIsPremium = true
                    savePremiumStatus(true)
                    foundSubscription = true
                    print("✅ Restored subscription: \(transaction.productID)")
                }
            case .unverified:
                print("⚠️ Unverified transaction found")
                break
            }
        }
        
        if !foundSubscription {
            userIsPremium = false
            savePremiumStatus(false)
            print("ℹ️ No valid subscriptions found")
        }
        
        HapticManager.shared.lightImpact()
    }
    
    private func checkForExistingSubscriptions() async {
        await restorePurchases()
    }
    
    // MARK: - Premium Status Management
    private func loadUserPremiumStatus() {
        userIsPremium = UserDefaults.standard.bool(forKey: "userIsPremium")
        
        // Load temporary premium
        if let tempDate = UserDefaults.standard.object(forKey: "temporaryPremiumUntil") as? Date {
            temporaryPremiumUntil = tempDate
        }
    }
    
    private func savePremiumStatus(_ isPremium: Bool) {
        UserDefaults.standard.set(isPremium, forKey: "userIsPremium")
    }
    
    // MARK: - Feature Access Control
    
    /// Whether the user has premium access (subscription or temporary)
    var hasPremiumAccess: Bool {
        if userIsPremium { return true }
        
        if let tempExpiry = temporaryPremiumUntil, Date() < tempExpiry {
            return true
        }
        
        return false
    }
    
    /// Whether ads should be shown
    var shouldShowAds: Bool {
        return !hasPremiumAccess
    }
    
    /// Check if user can create more time blocks today
    func canCreateTimeBlock(currentDailyCount: Int) -> Bool {
        if hasPremiumAccess { return true }
        return currentDailyCount < Self.freeTimeBlockLimit
    }
    
    /// Check if user can access advanced analytics
    var canAccessAdvancedAnalytics: Bool {
        return hasPremiumAccess
    }
    
    /// Check if user can use premium themes
    var canUsePremiumThemes: Bool {
        return hasPremiumAccess
    }
    
    /// Check if user can access unlimited templates
    func canCreateTemplate(currentTemplateCount: Int) -> Bool {
        if hasPremiumAccess { return true }
        return currentTemplateCount < Self.freeTemplateLimit
    }
    
    /// Check if user can access widgets
    var canAccessWidgets: Bool {
        return hasPremiumAccess
    }
    
    // MARK: - Temporary Premium (for rewarded ads)
    func grantTemporaryPremium(duration: TimeInterval = 24 * 60 * 60) {
        temporaryPremiumUntil = Date().addingTimeInterval(duration)
        UserDefaults.standard.set(temporaryPremiumUntil, forKey: "temporaryPremiumUntil")
        HapticManager.shared.premiumSuccess()
    }
    
    // MARK: - Pricing Information
    var monthlyProduct: Product? {
        products.first { $0.id.contains("monthly") }
    }
    
    var yearlyProduct: Product? {
        products.first { $0.id.contains("yearly") }
    }
    
    var monthlySavings: String {
        guard let monthly = monthlyProduct,
              let yearly = yearlyProduct else { return "" }
        
        let monthlyPrice = monthly.price
        let yearlyPrice = yearly.price
        let yearlyMonthlyEquivalent = yearlyPrice / 12
        let savings = monthlyPrice - yearlyMonthlyEquivalent
        let percentage = (savings / monthlyPrice) * 100
        
        return "\(Int(percentage))% off"
    }
    
    // MARK: - Error Handling
    func clearError() {
        errorMessage = nil
    }
}

// MARK: - Premium Errors
enum PremiumError: Error, LocalizedError {
    case verificationFailed
    case unknownResult
    case productNotFound
    
    var errorDescription: String? {
        switch self {
        case .verificationFailed:
            return "Purchase verification failed"
        case .unknownResult:
            return "Unknown purchase result"
        case .productNotFound:
            return "Product not found"
        }
    }
}

// MARK: - Premium Feature Flags
extension PremiumManager {
    enum PremiumFeature {
        case unlimitedTimeBlocks
        case advancedAnalytics
        case premiumThemes
        case unlimitedTemplates
        case widgets
        case smartScheduling
        case goalTracking
        case cloudSync
        
        var displayName: String {
            switch self {
            case .unlimitedTimeBlocks:
                return "Unlimited Time Blocks"
            case .advancedAnalytics:
                return "Advanced Analytics"
            case .premiumThemes:
                return "Premium Themes"
            case .unlimitedTemplates:
                return "Unlimited Templates"
            case .widgets:
                return "Widgets & Complications"
            case .smartScheduling:
                return "Smart Scheduling"
            case .goalTracking:
                return "Goal Tracking"
            case .cloudSync:
                return "Cloud Sync"
            }
        }
        
        var description: String {
            switch self {
            case .unlimitedTimeBlocks:
                return "Create as many time blocks as you need"
            case .advancedAnalytics:
                return "Deep insights into your productivity patterns"
            case .premiumThemes:
                return "Beautiful themes and customization options"
            case .unlimitedTemplates:
                return "Save and reuse unlimited routine templates"
            case .widgets:
                return "Quick access from your home screen"
            case .smartScheduling:
                return "AI-powered scheduling suggestions"
            case .goalTracking:
                return "Set and track long-term productivity goals"
            case .cloudSync:
                return "Sync your data across all devices"
            }
        }
        
        var icon: String {
            switch self {
            case .unlimitedTimeBlocks:
                return "infinity"
            case .advancedAnalytics:
                return "chart.line.uptrend.xyaxis"
            case .premiumThemes:
                return "paintbrush.fill"
            case .unlimitedTemplates:
                return "doc.on.doc.fill"
            case .widgets:
                return "widget.medium"
            case .smartScheduling:
                return "brain.head.profile"
            case .goalTracking:
                return "target"
            case .cloudSync:
                return "icloud.fill"
            }
        }
    }
    
    func hasAccess(to feature: PremiumFeature) -> Bool {
        return hasPremiumAccess
    }
}
