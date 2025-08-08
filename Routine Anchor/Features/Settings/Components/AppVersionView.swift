//
//  AppVersionView.swift
//  Routine Anchor
//
//  Created by Christopher Simonson on 8/9/25.
//
import SwiftUI

struct AppVersionView: View {
    var body: some View {
        VStack(spacing: 8) {
            Text("Routine Anchor")
                .font(TypographyConstants.Body.emphasized)
                .foregroundStyle(Color.premiumTextPrimary)

            Text("Version \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")")
                .font(TypographyConstants.UI.caption)
                .foregroundStyle(Color.premiumTextSecondary)

            Text("© 2025 Simo's Media & Tech, LLC.")
                .font(TypographyConstants.UI.caption)
                .foregroundStyle(Color.premiumTextTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .glassMorphism()
    }
}

