//
//  PremiumIntegration.swift
//  Routine Anchor
//
//  Environment plumbing for PremiumManager so views can use
//  `@Environment(\.premiumManager)` consistently.
//

import SwiftUI

// MARK: - Environment Key

private struct PremiumManagerKey: EnvironmentKey {
    static let defaultValue: PremiumManager? = nil
}

// MARK: - Environment Values

extension EnvironmentValues {
    /// Access the PremiumManager from the environment.
    var premiumManager: PremiumManager? {
        get { self[PremiumManagerKey.self] }
        set { self[PremiumManagerKey.self] = newValue }
    }
}

// MARK: - View Convenience

extension View {
    /// Inject a PremiumManager into the view hierarchy.
    func premiumManager(_ manager: PremiumManager) -> some View {
        environment(\.premiumManager, manager)
    }
}

// MARK: - Preview Helper

#if DEBUG
extension PremiumManager {
    /// Lightweight preview instance (no network/StoreKit work guaranteed).
    static func preview() -> PremiumManager {
        let m = PremiumManager()
        m.hasPremiumAccess = false
        return m
    }
}
#endif
