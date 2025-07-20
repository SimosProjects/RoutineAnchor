//
//  BenefitRow.swift
//  Routine Anchor
//
//  Created by Christopher Simonson on 7/19/25.
//
import SwiftUI

struct BenefitRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Color.primaryBlue)
                .frame(width: 20, height: 20)
            
            Text(text)
                .font(TypographyConstants.Body.secondary)
                .foregroundColor(Color.textSecondary)
            
            Spacer()
        }
    }
}
