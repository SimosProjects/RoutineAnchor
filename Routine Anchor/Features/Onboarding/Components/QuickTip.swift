//
//  QuickTip.swift
//  Routine Anchor
//
//  Created by Christopher Simonson on 7/20/25.
//
import SwiftUI
import UserNotifications

struct QuickTip: View {
    let number: String
    let text: String
    let delay: Double
    
    @Environment(\.themeManager) private var themeManager
    @State private var isVisible = false
    
    var body: some View {
        HStack(spacing: 12) {
            Text(number)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(themeManager?.currentTheme.primaryTextColor ?? Theme.defaultTheme.primaryTextColor)
                .frame(width: 28, height: 28)
                .background(
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color(red: 0.2, green: 0.8, blue: 0.5), Color(red: 0.2, green: 0.7, blue: 0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
            
            Text(text)
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundStyle(themeManager?.currentTheme.primaryTextColor ?? Theme.defaultTheme.primaryTextColor)
            
            Spacer()
        }
        .opacity(isVisible ? 1 : 0)
        .offset(x: isVisible ? 0 : -20)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(delay)) {
                isVisible = true
            }
        }
    }
}
