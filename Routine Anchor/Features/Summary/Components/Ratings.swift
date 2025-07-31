//
//  Rating.swift
//  Routine Anchor
//
//  Rating component for Daily Summary
//
import SwiftUI

struct Rating: View {
    @Binding var selectedRating: Int
    @Binding var dayNotes: String
    @State private var isExpanded = false
    @State private var isVisible = false
    @FocusState private var isNotesFocused: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("How was your day?")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    
                    Text("Rate your overall experience")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.7))
                }
                
                Spacer()
            }
            
            // Star rating
            HStack(spacing: 16) {
                ForEach(1...5, id: \.self) { rating in
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            selectedRating = rating
                            HapticManager.shared.lightImpact()
                        }
                    }) {
                        Image(systemName: rating <= selectedRating ? "star.fill" : "star")
                            .font(.system(size: 32, weight: .medium))
                            .foregroundStyle(
                                rating <= selectedRating ?
                                    Color.premiumWarning :
                                    Color.white.opacity(0.3)
                            )
                            .scaleEffect(rating == selectedRating ? 1.2 : 1.0)
                            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: selectedRating)
                    }
                }
            }
            .padding(.vertical, 8)
            
            // Rating message
            if selectedRating > 0 {
                Text(ratingMessage)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(ratingColor)
                    .multilineTextAlignment(.center)
                    .transition(.scale(scale: 0.8).combined(with: .opacity))
            }
            
            // Add notes section
            VStack(alignment: .leading, spacing: 8) {
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        isExpanded.toggle()
                        if isExpanded {
                            isNotesFocused = true
                        }
                    }
                }) {
                    HStack {
                        Image(systemName: isExpanded ? "note.text.badge.plus" : "note.text")
                            .font(.system(size: 14, weight: .medium))
                        
                        Text(isExpanded ? "Add reflection" : "Add notes (optional)")
                            .font(.system(size: 14, weight: .medium))
                        
                        Spacer()
                        
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Color.white.opacity(0.5))
                    }
                    .foregroundStyle(Color.white.opacity(0.8))
                }
                
                if isExpanded {
                    VStack(spacing: 8) {
                        // Text editor with premium styling
                        ZStack(alignment: .topLeading) {
                            if dayNotes.isEmpty {
                                Text("What went well? What could be improved?")
                                    .font(.system(size: 14))
                                    .foregroundStyle(Color.white.opacity(0.3))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 10)
                            }
                            
                            TextEditor(text: $dayNotes)
                                .font(.system(size: 14))
                                .foregroundStyle(.white)
                                .scrollContentBackground(.hidden)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 6)
                                .focused($isNotesFocused)
                        }
                        .frame(minHeight: 80, maxHeight: 120)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.05))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                        
                        // Character count
                        HStack {
                            Spacer()
                            Text("\(dayNotes.count)/500")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(Color.white.opacity(0.4))
                        }
                    }
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.9).combined(with: .opacity),
                        removal: .scale(scale: 0.9).combined(with: .opacity)
                    ))
                }
            }
        }
        .padding(20)
        .glassMorphism(cornerRadius: 20)
        .scaleEffect(isVisible ? 1 : 0.9)
        .opacity(isVisible ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
                isVisible = true
            }
        }
        .onChange(of: dayNotes) { _, newValue in
            if newValue.count > 500 {
                dayNotes = String(newValue.prefix(500))
            }
        }
    }
    
    // MARK: - Helper Properties
    
    private var ratingMessage: String {
        switch selectedRating {
        case 1: return "Tough day, but tomorrow's a fresh start! 🌱"
        case 2: return "Some challenges, but you pushed through! 💪"
        case 3: return "Steady progress, keep it up! 📊"
        case 4: return "Great job today! You're on track! 🎯"
        case 5: return "Outstanding! You crushed it! 🎉"
        default: return ""
        }
    }
    
    private var ratingColor: Color {
        switch selectedRating {
        case 1: return Color.premiumError
        case 2: return Color.premiumWarning
        case 3: return Color.premiumBlue
        case 4: return Color.premiumGreen
        case 5: return Color.premiumPurple
        default: return Color.white.opacity(0.7)
        }
    }
}

// MARK: - Preview
#Preview("Rating Component") {
    ZStack {
        AnimatedGradientBackground()
            .ignoresSafeArea()
        
        Rating(selectedRating: .constant(0), dayNotes: .constant(""))
            .padding()
    }
}
