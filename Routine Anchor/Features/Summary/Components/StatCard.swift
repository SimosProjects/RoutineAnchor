//
//  StatCard.swift
//  Routine Anchor
//
//  Statistic card component for displaying metrics
//
import SwiftUI

struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    let icon: String
    
    @State private var isVisible = false
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .medium))
                .foregroundStyle(color)
            
            VStack(spacing: 4) {
                Text(value)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.6))
                    .textCase(.uppercase)
                    .tracking(0.5)
                
                Text(subtitle)
                    .font(.system(size: 11, weight: .regular))
                    .foregroundStyle(Color.white.opacity(0.5))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(color.opacity(0.1))
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
        .scaleEffect(isVisible ? 1 : 0.8)
        .opacity(isVisible ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2)) {
                isVisible = true
            }
        }
    }
}

// MARK: - Preview
#Preview("Stat Cards") {
    ZStack {
        AnimatedGradientBackground()
            .ignoresSafeArea()
        
        HStack(spacing: 12) {
            StatCard(
                title: "Completed",
                value: "8",
                subtitle: "blocks",
                color: Color.premiumGreen,
                icon: "checkmark.circle.fill"
            )
            
            StatCard(
                title: "Time",
                value: "5h 30m",
                subtitle: "tracked",
                color: Color.premiumBlue,
                icon: "clock.fill"
            )
            
            StatCard(
                title: "Skipped",
                value: "2",
                subtitle: "blocks",
                color: Color.premiumWarning,
                icon: "forward.circle.fill"
            )
        }
        .padding()
    }
}
