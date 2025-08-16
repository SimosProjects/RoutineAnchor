//
//  PremiumButton.swift
//  Routine Anchor
//
//  Created by Christopher Simonson on 7/20/25.
//
import SwiftUI
import UserNotifications

struct PremiumButton: View {
    let title: String
    var style: ButtonStyle = .primary
    let action: () -> Void
    
    @State private var isPressed = false
    
    enum ButtonStyle {
        case primary, gradient
        case secondary
    }
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isPressed = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    isPressed = false
                }
                action()
            }
        }) {
            Text(title)
                .font(.system(size: 19, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 60)
                .background(
                    Group {
                        if style == .gradient {
                            LinearGradient(
                                colors: [Color(red: 0.2, green: 0.8, blue: 0.5), Color(red: 0.2, green: 0.7, blue: 0.7)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        } else {
                            LinearGradient(
                                colors: [Color(red: 0.3, green: 0.5, blue: 1.0), Color(red: 0.5, green: 0.3, blue: 1.0)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        }
                    }
                )
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
                .shadow(
                    color: style == .gradient ? Color(red: 0.2, green: 0.7, blue: 0.5).opacity(0.5) : Color(red: 0.3, green: 0.5, blue: 1.0).opacity(0.5),
                    radius: isPressed ? 15 : 30,
                    x: 0,
                    y: isPressed ? 8 : 15
                )
                .scaleEffect(isPressed ? 0.97 : 1)
        }
    }
}
