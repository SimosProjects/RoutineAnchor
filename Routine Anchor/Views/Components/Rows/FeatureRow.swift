//
//  FeatureRow.swift
//  Routine Anchor
//
//  Created by Christopher Simonson on 7/19/25.
//
import SwiftUI

// MARK: - Supporting Views
struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(Color.primaryBlue)
                .frame(width: 28, height: 28)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(TypographyConstants.Body.emphasized)
                    .foregroundColor(Color.textPrimary)
                
                Text(description)
                    .font(TypographyConstants.UI.caption)
                    .foregroundColor(Color.textSecondary)
            }
            
            Spacer()
        }
    }
}
