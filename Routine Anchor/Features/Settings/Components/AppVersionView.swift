//
//  AppVersionView.swift
//  Routine Anchor
//
//  Created by Christopher Simonson on 8/9/25.
//

import SwiftUI
import UIKit

struct AppVersionView: View {
    @Environment(\.themeManager) private var themeManager

    // Theme helpers
    private var theme: Theme { themeManager?.currentTheme ?? Theme.defaultTheme }
    private var scheme: ThemeColorScheme { theme.colorScheme }

    // App info
    private var version: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
    private var build: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""
    }
    private var year: String { String(Calendar.current.component(.year, from: Date())) }

    private var copyString: String {
        build.isEmpty ? "v\(version)" : "v\(version) (\(build))"
    }

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "app.clipboard")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(scheme.workflowPrimary.color.opacity(0.9))

            Text("Routine Anchor")
                .font(TypographyConstants.Body.emphasized)
                .foregroundStyle(theme.primaryTextColor)

            Text("Version \(version)\(build.isEmpty ? "" : " (\(build))")")
                .font(TypographyConstants.UI.caption)
                .foregroundStyle(theme.secondaryTextColor)
                .accessibilityIdentifier("AppVersionLabel")

            Text("© \(year) Simo's Media & Tech, LLC.")
                .font(TypographyConstants.UI.caption)
                .foregroundStyle(theme.subtleTextColor)
        }
        .multilineTextAlignment(.center)
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(scheme.surface2.color.opacity(0.9))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(scheme.border.color.opacity(0.85), lineWidth: 1)
        )
        .contentShape(Rectangle()) // make entire card tappable
        .onTapGesture {
            UIPasteboard.general.string = copyString
            HapticManager.shared.lightImpact()
        }
        .contextMenu {
            Button("Copy version") {
                UIPasteboard.general.string = copyString
                HapticManager.shared.lightImpact()
            }
        }
        .accessibilityIdentifier("AppVersionView")
    }
}
