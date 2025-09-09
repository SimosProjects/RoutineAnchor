//
//  ThemeManager.swift
//  Routine Anchor
//
//  Holds the active AppTheme and persists the user's choice by theme name.
//

import SwiftUI

@MainActor
final class ThemeManager: ObservableObject {
    @Published private(set) var currentTheme: AppTheme

    private let storageKey = "selectedThemeName"
    private let catalog: [AppTheme]

    init(defaultTheme: AppTheme = PredefinedThemes.classic,
         catalog: [AppTheme] = PredefinedThemes.all) {
        self.catalog = catalog
        if let savedName = UserDefaults.standard.string(forKey: storageKey),
           let restored = catalog.first(where: { $0.name == savedName }) {
            self.currentTheme = restored
        } else {
            self.currentTheme = defaultTheme
        }
    }

    /// Change the active theme and persist by name.
    func setTheme(_ theme: AppTheme) {
        currentTheme = theme
        UserDefaults.standard.set(theme.name, forKey: storageKey)
    }

    /// Utility for previews/tests
    static func preview() -> ThemeManager {
        ThemeManager(defaultTheme: PredefinedThemes.classic)
    }
}
