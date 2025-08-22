//
//  AdManager.swift
//  Routine Anchor
//
//  Manages Google AdMob integration with premium gating and proper crash prevention
//
import Foundation
import GoogleMobileAds
import SwiftUI

@MainActor
class AdManager: NSObject, ObservableObject {
    @Published var isAdLoaded = false
    @Published var adError: Error?
    @Published var isShowingAd = false
    
    // Test Ad Unit IDs (replace with real ones later)
    private let bannerAdUnitID = "ca-app-pub-3940256099942544/2934735716"
    private let interstitialAdUnitID = "ca-app-pub-3940256099942544/4411468910"
    
    private var interstitialAd: InterstitialAd?
    private var isLoadingAd = false
    
    override init() {
        super.init()
        initializeAdMob()
    }
    
    // MARK: - Initialization
    private func initializeAdMob() {
        MobileAds.shared.start { [weak self] status in
            DispatchQueue.main.async {
                print("✅ AdMob initialization completed with status: \(status)")
                // Load interstitial ad after a short delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self?.loadInterstitialAd()
                }
            }
        }
    }
    
    // MARK: - Banner Ads
    func createBannerView() -> BannerView {
        let bannerView = BannerView(adSize: AdSizeBanner)
        bannerView.adUnitID = bannerAdUnitID
        return bannerView
    }
    
    // MARK: - Interstitial Ads
    func loadInterstitialAd() {
        // Prevent multiple simultaneous loads
        guard !isLoadingAd else {
            print("⚠️ Ad already loading, skipping...")
            return
        }
        
        isLoadingAd = true
        let request = Request()
        
        InterstitialAd.load(with: interstitialAdUnitID, request: request) { [weak self] ad, error in
            DispatchQueue.main.async {
                self?.isLoadingAd = false
                
                if let error = error {
                    print("❌ Failed to load interstitial ad: \(error.localizedDescription)")
                    self?.adError = error
                    self?.isAdLoaded = false
                    return
                }
                
                if let ad = ad {
                    print("✅ Interstitial ad loaded successfully")
                    self?.interstitialAd = ad
                    self?.isAdLoaded = true
                    self?.adError = nil
                    
                    // Set the delegate AFTER loading completes
                    ad.fullScreenContentDelegate = self
                }
            }
        }
    }
    
    func showInterstitialAd() {
        // Safety checks
        guard !isShowingAd else {
            print("⚠️ Ad already showing, ignoring request")
            return
        }
        
        guard let interstitialAd = interstitialAd else {
            print("❌ Interstitial ad not ready")
            return
        }
        
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            print("❌ Could not find root view controller")
            return
        }
        
        // Set state before presenting
        isShowingAd = true
        
        // Present the ad
        interstitialAd.present(from: rootViewController)
        print("✅ Presenting interstitial ad")
    }
    
    // MARK: - Helper Methods
    private func cleanupAfterAdDismissal() {
        // Reset state
        isShowingAd = false
        isAdLoaded = false
        interstitialAd = nil
        
        // Load next ad after a short delay to prevent rapid successive loads
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
            self?.loadInterstitialAd()
        }
    }
    
    private func handleAdError(_ error: Error) {
        print("❌ Ad error: \(error.localizedDescription)")
        adError = error
        isShowingAd = false
        isAdLoaded = false
        
        // Retry loading after error with exponential backoff
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { [weak self] in
            self?.loadInterstitialAd()
        }
    }
}

// MARK: - FullScreenContentDelegate
extension AdManager: FullScreenContentDelegate {
    
    /// Called when the ad failed to present
    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        print("❌ Ad failed to present: \(error.localizedDescription)")
        handleAdError(error)
    }
    
    /// Called when the ad is dismissed - This is the critical method that prevents crashes
    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        print("✅ Ad did dismiss full screen content")
        
        // FIXED: Add delay to prevent immediate model context access
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.cleanupAfterAdDismissal()
            
            // FIXED: Post notification to refresh data after ad dismissal
            NotificationCenter.default.post(name: .refreshAllDataAfterAd, object: nil)
        }
    }
    
    /// Called when the ad will present (optional - newer versions may not have this)
    func adWillPresentFullScreenContent(_ ad: FullScreenPresentingAd) {
        print("🎬 Ad will present full screen content")
    }
}

// MARK: - Public Interface for Premium Checking
extension AdManager {
    
    /// Check if ads should be shown based on premium status
    func shouldShowAds(premiumManager: PremiumManager?) -> Bool {
        return premiumManager?.shouldShowAds ?? true
    }
    
    /// Conditionally show interstitial ad if user is not premium
    func showInterstitialIfAllowed(premiumManager: PremiumManager?) {
        guard shouldShowAds(premiumManager: premiumManager) else {
            print("🚫 User has premium, skipping ad")
            return
        }
        
        showInterstitialAd()
    }
}
