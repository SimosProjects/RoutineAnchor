//
//  MorphingShapes.swift
//  Routine Anchor
//
//  Created by Christopher Simonson on 7/23/25.
//
import SwiftUI

struct MorphingCircle: Shape {
    var morphProgress: CGFloat

    var animatableData: CGFloat {
        get { morphProgress }
        set { morphProgress = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let radius = min(rect.width, rect.height) / 2
        let center = CGPoint(x: rect.midX, y: rect.midY)
        var path = Path()

        for angle in stride(from: CGFloat(0), to: CGFloat(360), by: 10) {
            let radians = angle * .pi / 180
            let variation = sin(radians * 3 + morphProgress * .pi * 2) * 10 * morphProgress
            let adjustedRadius = radius + variation
            let x = center.x + adjustedRadius * cos(radians)
            let y = center.y + adjustedRadius * sin(radians)

            if angle == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }

        path.closeSubpath()
        return path
    }
}

