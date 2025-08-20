//
//  AdBannerView.swift
//  Routine Anchor
//
//  Banner ad component with premium gating
//
import SwiftUI
import GoogleMobileAds

struct AdBannerView: UIViewRepresentable {
    @Environment(\.premiumManager) private var premiumManager
    @StateObject private var adManager = AdManager()
    
    let adSize: AdSize
    
    init(adSize: AdSize = AdSizeBanner) {
        self.adSize = adSize
    }
    
    func makeUIView(context: Context) -> BannerView {
        let bannerView = BannerView(adSize: adSize)
        bannerView.adUnitID = "ca-app-pub-3940256099942544/2934735716" // Test ID
        
        // Set root view controller
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            bannerView.rootViewController = rootViewController
        }
        
        return bannerView
    }
    
    func updateUIView(_ bannerView: BannerView, context: Context) {
        // Only load ads if user is not premium
        if premiumManager?.shouldShowAds == true {
            bannerView.load(Request())
        }
    }
}

// MARK: - Styled Ad Banner with Upgrade Prompt
struct StyledAdBanner: View {
    @Environment(\.premiumManager) private var premiumManager
    
    var body: some View {
        if premiumManager?.shouldShowAds == true {
            VStack(spacing: 12) {
                // Ad Banner
                AdBannerView()
                    .frame(height: 50)
                    .background(Color.black.opacity(0.1))
                    .cornerRadius(8)
                
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
                        // TODO: Show premium upgrade
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
        }
    }
}
