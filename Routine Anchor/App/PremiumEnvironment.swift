//
//  PremiumEnvironment.swift
//  Routine Anchor
//
//  Environment key for PremiumManager
//
import SwiftUI

// MARK: - Environment Key
private struct PremiumManagerKey: EnvironmentKey {
    static let defaultValue: PremiumManager? = nil
}

extension EnvironmentValues {
    var premiumManager: PremiumManager? {
        get { self[PremiumManagerKey.self] }
        set { self[PremiumManagerKey.self] = newValue }
    }
}

// MARK: - View Extension
extension View {
    func premiumEnvironment(_ premiumManager: PremiumManager) -> some View {
        environment(\.premiumManager, premiumManager)
    }
}
