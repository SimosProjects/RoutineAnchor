//
//  AdBannerView.swift
//  Routine Anchor
//
//  Fixed banner ad component with crash prevention
//
import SwiftUI
import GoogleMobileAds

struct AdBannerView: UIViewRepresentable {
    @Environment(\.premiumManager) private var premiumManager
    
    let adSize: AdSize
    
    init(adSize: AdSize = AdSizeBanner) {
        self.adSize = adSize
    }
    
    func makeUIView(context: Context) -> BannerView {
        let bannerView = BannerView(adSize: adSize)
        bannerView.adUnitID = "ca-app-pub-3940256099942544/2934735716" // Test ID
        
        // Set delegate for error handling
        bannerView.delegate = context.coordinator
        
        // Set root view controller safely
        setRootViewController(for: bannerView)
        
        return bannerView
    }
    
    func updateUIView(_ bannerView: BannerView, context: Context) {
        // Only load ads if user is not premium and view is properly configured
        guard premiumManager?.shouldShowAds == true,
              bannerView.rootViewController != nil else {
            return
        }
        
        // Don't reload if already loaded
        guard bannerView.responseInfo == nil else {
            return
        }
        
        let request = Request()
        bannerView.load(request)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    private func setRootViewController(for bannerView: BannerView) {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            bannerView.rootViewController = rootViewController
        } else {
            print("⚠️ Could not set root view controller for banner ad")
        }
    }
    
    // MARK: - Coordinator
    class Coordinator: NSObject, BannerViewDelegate {
        
        func bannerViewDidReceiveAd(_ bannerView: BannerView) {
            print("✅ Banner ad loaded successfully")
        }
        
        func bannerView(_ bannerView: BannerView, didFailToReceiveAdWithError error: Error) {
            print("❌ Banner ad failed to load: \(error.localizedDescription)")
        }
        
        func bannerViewWillPresentScreen(_ bannerView: BannerView) {
            print("🎬 Banner ad will present screen")
        }
        
        func bannerViewDidDismissScreen(_ bannerView: BannerView) {
            print("✅ Banner ad did dismiss screen")
        }
    }
}

// MARK: - Styled Ad Banner with Upgrade Prompt (Fixed)
struct StyledAdBanner: View {
    @Environment(\.premiumManager) private var premiumManager
    @State private var showUpgrade = false
    
    var body: some View {
        if premiumManager?.shouldShowAds == true {
            VStack(spacing: 12) {
                // Ad Banner with error boundary
                AdBannerView()
                    .frame(height: 50)
                    .background(Color.black.opacity(0.1))
                    .cornerRadius(8)
                    .clipped() // Prevent overflow issues
                
                // Upgrade prompt
                HStack(spacing: 8) {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.anchorWarning)
                    
                    Text("Remove ads with Premium")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.white.opacity(0.7))
                    
                    Spacer()
                    
                    Button("Upgrade") {
                        showUpgrade = true
                        HapticManager.shared.anchorSelection()
                    }
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.anchorBlue)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.anchorBlue.opacity(0.2))
                    .cornerRadius(6)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial)
                .cornerRadius(8)
            }
            .padding(.horizontal, 20)
            .sheet(isPresented: $showUpgrade) {
                if let premiumManager = premiumManager {
                    PremiumUpgradeView(premiumManager: premiumManager)
                }
            }
        }
    }
}
