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

