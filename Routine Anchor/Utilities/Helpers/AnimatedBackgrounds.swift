//
//  AnimatedBackgrounds.swift
//  Routine Anchor
//
//  Created by Christopher Simonson on 7/23/25.
//
import SwiftUI

struct AnimatedGradientBackground: View {
    @State private var animateGradient = false

    var body: some View {
        LinearGradient(
            colors: [
                Color(red: 0.05, green: 0.05, blue: 0.15),
                Color(red: 0.08, green: 0.05, blue: 0.2),
                Color(red: 0.05, green: 0.08, blue: 0.25)
            ],
            startPoint: animateGradient ? .topLeading : .bottomLeading,
            endPoint: animateGradient ? .bottomTrailing : .topTrailing
        )
        .ignoresSafeArea()
        .overlay(
            RadialGradient(
                colors: [
                    Color(red: 0.2, green: 0.3, blue: 0.8).opacity(0.3),
                    Color.clear
                ],
                center: .top,
                startRadius: 100,
                endRadius: 400
            )
            .ignoresSafeArea()
        )
        .onAppear {
            withAnimation(.easeInOut(duration: 5).repeatForever(autoreverses: true)) {
                animateGradient.toggle()
            }
        }
    }
}

struct AnimatedMeshBackground: View {
    @State private var phase: CGFloat = 0

    var body: some View {
        Canvas { context, size in
            let gridSize = 30
            let dotSize: CGFloat = 2

            for x in stride(from: 0, to: Int(size.width), by: gridSize) {
                for y in stride(from: 0, to: Int(size.height), by: gridSize) {
                    let xPos = CGFloat(x)
                    let yPos = CGFloat(y)
                    let distance = sqrt(pow(xPos - size.width/2, 2) + pow(yPos - size.height/2, 2))
                    let wave = sin(distance * 0.01 - phase) * 0.5 + 0.5

                    context.fill(
                        Path(ellipseIn: CGRect(x: xPos - dotSize/2, y: yPos - dotSize/2, width: dotSize, height: dotSize)),
                        with: .color(.white.opacity(0.1 * wave))
                    )
                }
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 4).repeatForever(autoreverses: false)) {
                phase = .pi * 2
            }
        }
    }
}

struct ThemedAnimatedBackground: View {
    @Environment(\.themeManager) private var themeManager
    private var theme: AppTheme { themeManager?.currentTheme ?? PredefinedThemes.classic }

    // Simple animation phase
    @State private var phase: Double = 0

    var body: some View {
        ZStack {
            theme.heroBackground

            // Subtle animated “aurora” blobs
            TimelineView(.animation) { context in
                let t = context.date.timeIntervalSinceReferenceDate
                ZStack {
                    auroraBlob(color: theme.accentPrimaryColor.opacity(0.18),
                               size: 280,
                               x: sin(t / 7.0) * 80,
                               y: cos(t / 9.0) * 60)

                    auroraBlob(color: theme.accentSecondaryColor.opacity(0.16),
                               size: 320,
                               x: cos(t / 6.0) * 90,
                               y: sin(t / 8.0) * 70)

                    auroraBlob(color: theme.statusInfoColor.opacity(0.10),
                               size: 360,
                               x: sin(t / 5.0) * -70,
                               y: cos(t / 7.0) * -60)
                }
                .compositingGroup()
                .blendMode(.plusLighter)
                .allowsHitTesting(false)
                .animation(.linear(duration: 1.0), value: t)
            }

            // Gentle vignette to keep edges readable
            LinearGradient(
                colors: [Color.black.opacity(0.35), .clear, Color.black.opacity(0.35)],
                startPoint: .top, endPoint: .bottom
            )
            .allowsHitTesting(false)
        }
        .onAppear {
            withAnimation(.linear(duration: 12).repeatForever(autoreverses: true)) {
                phase = 1
            }
        }
    }

    // MARK: - Pieces

    private func auroraBlob(color: Color, size: CGFloat, x: Double, y: Double) -> some View {
        Circle()
            .fill(color)
            .frame(width: size, height: size)
            .blur(radius: 80)
            .offset(x: x, y: y)
    }
}
