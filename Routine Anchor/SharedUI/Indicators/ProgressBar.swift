//
//  ProgressBar.swift
//  Routine Anchor
//

import SwiftUI

/// Linear progress bar using theme tokens.
/// - `color` drives the fill gradient
/// - Track uses `surfaceCardColor`
struct ProgressBar: View {
    @Environment(\.themeManager) private var themeManager
    let progress: Double     // 0...1
    let color: Color
    let animated: Bool

    @State private var animatedProgress: CGFloat = 0
    private var theme: AppTheme { themeManager?.currentTheme ?? PredefinedThemes.classic }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Track
                Capsule()
                    .fill(theme.surfaceCardColor.opacity(0.30))
                    .frame(height: 4)

                // Progress
                Capsule()
                    .fill(LinearGradient(colors: [color, color.opacity(0.70)],
                                         startPoint: .leading, endPoint: .trailing))
                    .frame(width: geometry.size.width * animatedProgress, height: 4)
            }
        }
        .frame(height: 4)
        .onAppear {
            if animated {
                withAnimation(.spring(response: 1.0, dampingFraction: 0.8).delay(0.5)) {
                    animatedProgress = CGFloat(progress)
                }
            } else {
                animatedProgress = CGFloat(progress)
            }
        }
        .onChange(of: progress) { _, newValue in
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                animatedProgress = CGFloat(newValue)
            }
        }
    }
}
