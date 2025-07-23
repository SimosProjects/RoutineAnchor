//
//  ConfettiView.swift
//  Routine Anchor
//
//  Created by Christopher Simonson on 7/23/25.
//
import SwiftUI

struct ConfettiView: View {
    @Binding var isActive: Bool
    @State private var particles: [ConfettiParticle] = []

    var body: some View {
        GeometryReader { geometry in
            ForEach(particles) { particle in
                Image(systemName: particle.symbol)
                    .font(.system(size: particle.size))
                    .foregroundStyle(particle.color)
                    .position(particle.position)
                    .rotationEffect(.degrees(particle.rotation))
                    .opacity(particle.opacity)
                    .animation(
                        .easeOut(duration: particle.duration),
                        value: particle.position
                    )
            }
        }
        .onChange(of: isActive) { _, newValue in
            if newValue {
                createParticles()
            }
        }
    }

    private func createParticles() {
        let symbols = ["star.fill", "heart.fill", "sparkle", "circle.fill"]
        let colors: [Color] = [.blue, .purple, .green, .yellow, .pink]

        for _ in 0..<30 {
            let particle = ConfettiParticle(
                symbol: symbols.randomElement()!,
                color: colors.randomElement()!,
                position: CGPoint(
                    x: UIScreen.main.bounds.width / 2,
                    y: UIScreen.main.bounds.height / 2
                ),
                targetPosition: CGPoint(
                    x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                    y: CGFloat.random(in: -100...UIScreen.main.bounds.height + 100)
                ),
                size: CGFloat.random(in: 10...20),
                duration: Double.random(in: 1.5...3),
                rotation: Double.random(in: 0...360),
                opacity: 1.0
            )

            particles.append(particle)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            for index in particles.indices {
                withAnimation(.easeOut(duration: particles[index].duration)) {
                    particles[index].position = particles[index].targetPosition
                    particles[index].opacity = 0
                }
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            particles.removeAll()
            isActive = false
        }
    }
}

struct ConfettiParticle: Identifiable {
    let id = UUID()
    let symbol: String
    let color: Color
    var position: CGPoint
    var targetPosition: CGPoint
    let size: CGFloat
    let duration: Double
    let rotation: Double
    var opacity: Double
}

