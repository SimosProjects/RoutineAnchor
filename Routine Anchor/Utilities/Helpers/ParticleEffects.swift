//
//  ParticleEffects.swift
//  Routine Anchor
//
//  Created by Christopher Simonson on 7/23/25.
//
import SwiftUI

struct ParticleSystem {
    var particles: [Particle] = []

    mutating func startEmitting() {
        for _ in 0..<20 {
            particles.append(Particle())
        }
    }
}

struct Particle: Identifiable {
    let id = UUID()
    var position: CGPoint = CGPoint(
        x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
        y: CGFloat.random(in: 0...UIScreen.main.bounds.height)
    )
    var opacity: Double = Double.random(in: 0.1...0.3)
    var scale: CGFloat = CGFloat.random(in: 0.5...1.5)
}

struct ParticleEffectView: View {
    let system: ParticleSystem
    @State private var animate = false

    var body: some View {
        GeometryReader { geometry in
            ForEach(system.particles) { particle in
                Circle()
                    .fill(Color.blue.opacity(particle.opacity))
                    .frame(width: 4 * particle.scale, height: 4 * particle.scale)
                    .position(particle.position)
                    .blur(radius: 2)
                    .offset(y: animate ? -geometry.size.height : 0)
                    .animation(
                        .linear(duration: Double.random(in: 20...40))
                            .repeatForever(autoreverses: false),
                        value: animate
                    )
            }
        }
        .onAppear {
            animate = true
        }
    }
}

