//
//  TimeBlockRowView.swift
//  Routine Anchor
//
//  Created by Christopher Simonson on 7/19/25.
//
import SwiftUI

struct TimeBlockRowView: View {
    let timeBlock: TimeBlock
    let onTap: (() -> Void)?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(timeBlock.title)
                .font(TypographyConstants.Headers.cardTitle)
                .foregroundColor(Color.textPrimary)
            
            Text("\(timeBlock.startTime.formatted(date: .omitted, time: .shortened)) - \(timeBlock.endTime.formatted(date: .omitted, time: .shortened))")
                .font(TypographyConstants.UI.timeBlock)
                .foregroundColor(Color.textSecondary)
            
            Text(timeBlock.status.displayName)
                .font(TypographyConstants.UI.status)
                .foregroundColor(statusColor)
        }
        .padding(16)
        .background(Color.cardBackground)
        .cornerRadius(12)
        .shadow(color: ColorConstants.UI.cardShadow, radius: 2, x: 0, y: 1)
        .onTapGesture {
            onTap?()
        }
    }
    
    private var statusColor: Color {
        switch timeBlock.status {
        case .completed: return ColorConstants.Status.completed
        case .inProgress: return ColorConstants.Status.inProgress
        case .notStarted: return ColorConstants.Status.upcoming
        case .skipped: return ColorConstants.Status.skipped
        default: return Color.textSecondary
        }
    }
}
