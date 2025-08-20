//
//  AdManager.swift
//  Routine Anchor
//
//  Manages Google AdMob integration with premium gating
//

import Foundation
import GoogleMobileAds
import SwiftUI

@MainActor
class AdManager: NSObject, ObservableObject {
    @Published var isAdLoaded = false
    @Published var adError: Error?
    
    // Test Ad Unit IDs (replace with real ones later)
    private let bannerAdUnitID = "ca-app-pub-3940256099942544/2934735716"
    private let interstitialAdUnitID = "ca-app-pub-3940256099942544/4411468910"
    
    private var interstitialAd: InterstitialAd?
    
    override init() {
        super.init()
        initializeAdMob()
    }
    
    // MARK: - Initialization
    private func initializeAdMob() {
        MobileAds.shared.start()
        print("✅ AdMob initialization started")
        // Load interstitial ad after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.loadInterstitialAd()
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
        let request = Request()
        
        InterstitialAd.load(with: interstitialAdUnitID, request: request, completionHandler: { [weak self] ad, error in
            if let error = error {
                print("❌ Failed to load interstitial ad: \(error)")
                self?.adError = error
                return
            }
            
            if let ad = ad {
                print("✅ Interstitial ad loaded successfully")
                self?.interstitialAd = ad
                self?.isAdLoaded = true
                self?.adError = nil
            }
        })
    }
    
    func showInterstitialAd() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            print("❌ Could not find root view controller")
            return
        }
        
        if let interstitialAd = interstitialAd {
            // Clear the reference before presenting to avoid memory issues
            let adToPresent = interstitialAd
            self.interstitialAd = nil
            
            adToPresent.present(from: rootViewController)
            print("✅ Showing interstitial ad")
            
            // Load next ad after a delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                self?.loadInterstitialAd()
            }
        } else {
            print("❌ Interstitial ad not ready")
        }
    }
}
