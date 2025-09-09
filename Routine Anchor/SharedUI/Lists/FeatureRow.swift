//
//  FeatureRow.swift
//  Routine Anchor
//

import SwiftUI

struct FeatureRow: View {
    @Environment(\.themeManager) private var themeManager
    let icon: String
    let title: String
    let description: String

    private var theme: AppTheme { themeManager?.currentTheme ?? PredefinedThemes.classic }

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(theme.accentPrimaryColor)
                .frame(width: 28, height: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(TypographyConstants.Body.emphasized)
                    .foregroundStyle(theme.primaryTextColor)

                Text(description)
                    .font(TypographyConstants.UI.caption)
                    .foregroundStyle(theme.secondaryTextColor)
            }

            Spacer()
        }
    }
}
