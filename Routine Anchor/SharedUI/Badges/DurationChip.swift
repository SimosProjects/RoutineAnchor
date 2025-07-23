//
//  DurationChip.swift
//  Routine Anchor
//
//  Created by Christopher Simonson on 7/23/25.
//
import SwiftUI

struct DurationChip: View {
    let minutes: Int
    let action: () -> Void

    var body: some View {
        Button(action: {
            HapticManager.shared.lightImpact()
            action()
        }) {
            Text("\(minutes)m")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.premiumWarning)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.premiumWarning.opacity(0.15))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.premiumWarning.opacity(0.3), lineWidth: 1)
                )
        }
    }
}

