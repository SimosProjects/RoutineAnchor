//
//  NextStepRow.swift
//  Routine Anchor
//
//  Created by Christopher Simonson on 7/19/25.
//
import SwiftUI

struct NextStepRow: View {
    let number: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            // Step number
            Text(number)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .frame(width: 28, height: 28)
                .background(Color.primaryBlue)
                .clipShape(Circle())
            
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
