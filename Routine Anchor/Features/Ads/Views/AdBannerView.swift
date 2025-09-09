//
//  AdBannerView.swift
//  Routine Anchor
//
//  Fixed banner ad component with crash prevention & premium gating.
//  Requires GoogleMobileAds SDK. Be sure to start the SDK in your App:
//  GADMobileAds.sharedInstance().start(completionHandler: nil)
//

import SwiftUI
import GoogleMobileAds

// MARK: - Raw Banner Host (UIViewRepresentable)

struct AdBannerView: UIViewRepresentable {
    @Environment(\.premiumManager) private var premiumManager

    /// Ad size; defaults to standard 320x50.
    let adSize: AdSize

    init(adSize: AdSize = AdSizeBanner) {
        self.adSize = adSize
    }

    func makeUIView(context: Context) -> BannerView {
        let bannerView = BannerView(adSize: adSize)
        bannerView.adUnitID = "ca-app-pub-3940256099942544/2934735716" // Google test banner ID
        bannerView.delegate = context.coordinator

        // Root VC must be set before load to avoid crashes.
        bannerView.rootViewController = findRootViewController()
        if bannerView.rootViewController == nil {
            // We’ll try again in updateUIView
            print("⚠️ GADBannerView: rootViewController not found at make time")
        }

        return bannerView
    }

    func updateUIView(_ bannerView: BannerView, context: Context) {
        // Gate by premium
        guard premiumManager?.shouldShowAds == true else { return }

        // Must have a root VC
        if bannerView.rootViewController == nil {
            bannerView.rootViewController = findRootViewController()
            if bannerView.rootViewController == nil {
                print("⚠️ GADBannerView: rootViewController still nil, skipping load")
                return
            }
        }

        // Avoid refetching if we already loaded one
        guard context.coordinator.hasLoaded == false else { return }

        bannerView.load(Request())
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    // MARK: - Helper
    private func findRootViewController() -> UIViewController? {
        // Best-effort top-most VC finder
        guard let scene = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .first(where: { $0.activationState == .foregroundActive }),
              let window = scene.windows.first(where: { $0.isKeyWindow }),
              var root = window.rootViewController else { return nil }

        while let presented = root.presentedViewController { root = presented }
        return root
    }

    // MARK: - Coordinator

    final class Coordinator: NSObject, BannerViewDelegate {
        var hasLoaded = false

        func bannerViewDidReceiveAd(_ bannerView: BannerView) {
            hasLoaded = true
            print("✅ Banner ad loaded successfully")
        }

        func bannerView(_ bannerView: BannerView, didFailToReceiveAdWithError error: any Error) {
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

// MARK: - Styled Wrapper + Premium Upsell

struct StyledAdBanner: View {
    @Environment(\.themeManager) private var themeManager
    @Environment(\.premiumManager) private var premiumManager
    @State private var showUpgrade = false

    private var theme: AppTheme { themeManager?.currentTheme ?? PredefinedThemes.classic }

    var body: some View {
        if premiumManager?.shouldShowAds == true {
            VStack(spacing: 12) {
                // Banner host
                AdBannerView(adSize: AdSizeBanner)
                    .frame(height: 50)
                    .background(theme.surfaceCardColor.opacity(0.20))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                // Inline Premium prompt
                HStack(spacing: 8) {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(theme.statusWarningColor)

                    Text("Remove ads with Premium")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(theme.secondaryTextColor)

                    Spacer()

                    Button {
                        showUpgrade = true
                        HapticManager.shared.anchorSelection()
                    } label: {
                        Text("Upgrade")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(theme.primaryTextColor)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(theme.accentPrimaryColor.opacity(0.20))
                            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
            .padding(.horizontal, 20)
            .sheet(isPresented: $showUpgrade) {
                PremiumUpgradeView()
                    .environment(\.premiumManager, premiumManager)
                    .environment(\.themeManager, themeManager)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
        }
    }
}
