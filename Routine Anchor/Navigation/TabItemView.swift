//
//  TabItemView.swift
//  Routine Anchor
//
//  Created by Christopher Simonson on 7/23/25.
//
import SwiftUI

struct TabItemView: View {
    let icon: String
    let selectedIcon: String
    let title: String
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: isSelected ? selectedIcon : icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(
                    isSelected ?
                    LinearGradient(
                        colors: [Color.anchorBlue, Color.anchorPurple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ) :
                    LinearGradient(
                        colors: [Color.white.opacity(0.6), Color.white.opacity(0.6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .scaleEffect(isSelected ? 1.1 : 1.0)
                .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isSelected)

            Text(title)
                .font(.system(size: 10, weight: isSelected ? .semibold : .medium))
                .foregroundStyle(
                    isSelected ? Color.anchorBlue : Color.white.opacity(0.6)
                )
        }
    }
}

