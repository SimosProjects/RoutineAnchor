//
//  ThemeIntegration.swift
//  Routine Anchor
//
//  SwiftUI Environment plumbing for ThemeManager.
//

import SwiftUI

private struct ThemeManagerKey: EnvironmentKey {
    static let defaultValue: ThemeManager? = nil
}

extension EnvironmentValues {
    var themeManager: ThemeManager? {
        get { self[ThemeManagerKey.self] }
        set { self[ThemeManagerKey.self] = newValue }
    }
}

extension View {
    /// Inject a ThemeManager into the environment.
    func themeManager(_ manager: ThemeManager?) -> some View {
        environment(\.themeManager, manager)
    }
}
