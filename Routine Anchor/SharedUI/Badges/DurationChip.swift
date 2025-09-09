//
//  DurationChip.swift
//  Routine Anchor
//

import SwiftUI

struct DurationChip: View {
    let minutes: Int
    let isSelected: Bool
    let action: () -> Void

    @Environment(\.themeManager) private var themeManager
    @State private var isPressed = false

    private var theme: AppTheme { themeManager?.currentTheme ?? PredefinedThemes.classic }
    private var accent: Color { theme.statusWarningColor } 
    private let corner: CGFloat = 10

    private var displayText: String {
        if minutes < 60 {
            return "\(minutes)m"
        } else {
            let h = minutes / 60
            let m = minutes % 60
            return m == 0 ? "\(h)h" : "\(h)h \(m)m"
        }
    }

    var body: some View {
        Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) { action() }
        } label: {
            Text(displayText)
                .font(.system(size: 14, weight: isSelected ? .bold : .semibold))
                .foregroundStyle(isSelected ? theme.invertedTextColor : accent)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(backgroundFill)
                .overlay(borderStroke)
                .shadow(color: isSelected ? accent.opacity(0.30) : .clear, radius: 8, x: 0, y: 4)
                .contentShape(RoundedRectangle(cornerRadius: corner, style: .continuous))
        }
        .buttonStyle(.plain)
        .scaleEffect(isPressed ? 0.95 : (isSelected ? 1.05 : 1.0))
        .animation(.spring(response: 0.28, dampingFraction: 0.8), value: isSelected)
        .animation(.spring(response: 0.20, dampingFraction: 0.85), value: isPressed)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity) { pressing in
            isPressed = pressing
        } perform: {}

    }

    // MARK: - Pieces

    private var backgroundFill: some View {
        let shape = RoundedRectangle(cornerRadius: corner, style: .continuous)
        return Group {
            if isSelected {
                shape.fill(
                    LinearGradient(colors: [accent, accent.opacity(0.85)],
                                   startPoint: .topLeading, endPoint: .bottomTrailing)
                )
            } else {
                shape.fill(accent.opacity(0.15))
            }
        }
    }

    private var borderStroke: some View {
        RoundedRectangle(cornerRadius: corner, style: .continuous)
            .stroke(isSelected ? accent.opacity(0.95) : accent.opacity(0.35),
                    lineWidth: isSelected ? 2 : 1)
    }
}
