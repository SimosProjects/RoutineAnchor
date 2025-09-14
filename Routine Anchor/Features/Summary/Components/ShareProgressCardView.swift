//
//  ShareProgressCardView.swift
//  Routine Anchor
//

import SwiftUI

struct ShareProgressCardView: View {
    let dateRangeTitle: String
    let completionPercent: Int
    let totalBlocks: Int
    let completedBlocks: Int
    let skippedBlocks: Int
    let topCategories: [String: Int] // category -> count
    let notes: String?

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.black.opacity(0.90), Color.black.opacity(0.88)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )

            VStack(alignment: .leading, spacing: 18) {
                // Header
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Routine Anchor")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.7))
                        Text("Progress Summary")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                    }
                    Spacer()
                    Text(dateRangeTitle)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.75))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(.white.opacity(0.12), in: Capsule())
                }

                // Big KPI row
                HStack(spacing: 14) {
                    StatPill(title: "Completion", value: "\(completionPercent)%")
                    StatPill(title: "Blocks", value: "\(totalBlocks)")
                    StatPill(title: "Done", value: "\(completedBlocks)")
                    StatPill(title: "Skipped", value: "\(skippedBlocks)")
                }

                // Categories
                if !topCategories.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Top Categories")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.9))
                        ForEach(topCategories.sorted(by: { $0.value > $1.value }).prefix(5), id: \.key) { (name, count) in
                            HStack {
                                Text(name)
                                    .foregroundStyle(.white)
                                Spacer()
                                Text("\(count)")
                                    .foregroundStyle(.white.opacity(0.85))
                            }
                            .font(.system(size: 14, weight: .medium))
                            .padding(.vertical, 4)
                            .overlay(Divider().background(.white.opacity(0.15)), alignment: .bottom)
                        }
                    }
                }

                // Notes
                if let notes, !notes.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Highlights")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.9))
                        Text(notes)
                            .font(.system(size: 14))
                            .foregroundStyle(.white.opacity(0.9))
                            .lineLimit(6)
                    }
                }

                Spacer()

                // Footer
                HStack {
                    Text("Generated with Routine Anchor")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.white.opacity(0.55))
                    Spacer()
                }
            }
            .padding(24)
        }
    }
}

private struct StatPill: View {
    let title: String
    let value: String
    var body: some View {
        VStack(spacing: 6) {
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.white.opacity(0.75))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(.white.opacity(0.10), in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(.white.opacity(0.12), lineWidth: 1))
    }
}
