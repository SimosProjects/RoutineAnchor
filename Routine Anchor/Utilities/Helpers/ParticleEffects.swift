//
//  ParticleEffects.swift
//  Routine Anchor
//
//  Created by Christopher Simonson on 7/23/25.
//
import SwiftUI

@MainActor
class ParticleSystem: ObservableObject {
    @Published var particles: [Particle] = []

    func startEmitting(screenSize: CGSize) {
        var newParticles: [Particle] = []
        for _ in 0..<20 {
            let position = CGPoint(
                x: CGFloat.random(in: 0...screenSize.width),
                y: CGFloat.random(in: 0...screenSize.height)
            )
            let opacity = Double.random(in: 0.1...0.3)
            let scale = CGFloat.random(in: 0.5...1.5)
            newParticles.append(Particle(position: position, opacity: opacity, scale: scale))
        }
        // No need for DispatchQueue.main.async because @MainActor guarantees main thread
        self.particles = newParticles
    }
}

struct Particle: Identifiable {
    let id = UUID()
    var position: CGPoint
    var opacity: Double
    var scale: CGFloat
    
    // Explicit initializer, no UIKit inside struct
    init(position: CGPoint, opacity: Double, scale: CGFloat) {
        self.position = position
        self.opacity = opacity
        self.scale = scale
    }
}

struct ParticleEffectView: View {
    @StateObject var system = ParticleSystem()
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
            .onAppear {
                system.startEmitting(screenSize: geometry.size)
                animate = true
            }
        }
    }
}

