//
//  ProgressBar.swift
//  Routine Anchor
//
//  Created by Christopher Simonson on 7/21/25.
//
import SwiftUI

// MARK: - Progress Bar
struct ProgressBar: View {
    @Environment(\.themeManager) private var themeManager
    let progress: Double
    let color: Color
    let animated: Bool
    
    @State private var animatedProgress: CGFloat = 0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Track
                Capsule()
                    .fill(Color(themeManager?.currentTheme.colorScheme.uiElementPrimary.color ?? Theme.defaultTheme.colorScheme.uiElementPrimary.color))
                    .frame(height: 4)
                
                // Progress
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [color, color.opacity(0.7)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(
                        width: geometry.size.width * animatedProgress,
                        height: 4
                    )
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
