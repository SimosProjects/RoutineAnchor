//
//  SharedTimeBlockComponents.swift
//  Routine Anchor
//
//  Created by Christopher Simonson on 7/22/25.
//

import SwiftUI

// MARK: - Shared Category Selector Component
struct CategorySelector: View {
    let categories: [String]
    @Binding var selectedCategory: String
    
    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
            // No category option
            CategoryChip(
                title: "No Category",
                isSelected: selectedCategory.isEmpty,
                color: Color.white.opacity(0.6)
            ) {
                selectedCategory = ""
            }
            
            ForEach(categories, id: \.self) { category in
                CategoryChip(
                    title: category,
                    isSelected: selectedCategory == category,
                    color: categoryColor(for: category)
                ) {
                    selectedCategory = category
                }
            }
        }
    }
    
    private func categoryColor(for category: String) -> Color {
        switch category.lowercased() {
        case "work": return Color.premiumBlue
        case "personal": return Color.premiumPurple
        case "health": return Color.premiumGreen
        case "learning": return Color.premiumTeal
        case "social": return Color.premiumWarning
        default: return Color.white.opacity(0.6)
        }
    }
}

// MARK: - Shared Icon Selector Component
struct IconSelector: View {
    let icons: [String]
    @Binding var selectedIcon: String
    
    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
            // No icon option
            IconChip(
                icon: nil,
                isSelected: selectedIcon.isEmpty
            ) {
                selectedIcon = ""
            }
            
            ForEach(icons, id: \.self) { icon in
                IconChip(
                    icon: icon,
                    isSelected: selectedIcon == icon
                ) {
                    selectedIcon = icon
                }
            }
        }
    }
}

// MARK: - Shared Quick Duration Selector Component
struct QuickDurationSelector: View {
    let onSelect: (Int) -> Void
    
    private let durations = [15, 30, 45, 60, 90, 120]
    
    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
            ForEach(durations, id: \.self) { minutes in
                DurationChip(minutes: minutes) {
                    onSelect(minutes)
                }
            }
        }
    }
}

// MARK: - Shared History Row Component (for Edit view)
struct HistoryRow: View {
    let title: String
    let date: Date
    let icon: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.white.opacity(0.6))
                .frame(width: 20, height: 20)
            
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white)
            
            Spacer()
            
            Text(date.formatted(date: .abbreviated, time: .shortened))
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundStyle(Color.white.opacity(0.6))
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}

// MARK: - Shared Base Form View
struct PremiumTimeBlockFormView<Content: View>: View {
    let title: String
    let icon: String
    let subtitle: String
    let content: Content
    let onDismiss: () -> Void
    
    @State private var particleSystem = ParticleSystem()
    @State private var animationPhase = 0
    @State private var isVisible = false
    
    init(
        title: String,
        icon: String,
        subtitle: String,
        onDismiss: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.icon = icon
        self.subtitle = subtitle
        self.onDismiss = onDismiss
        self.content = content()
    }
    
    var body: some View {
        ZStack {
            // Premium animated background
            AnimatedGradientBackground()
                .ignoresSafeArea()
            
            AnimatedMeshBackground()
                .opacity(0.3)
                .allowsHitTesting(false)
            
            ParticleEffectView(system: particleSystem)
                .allowsHitTesting(false)
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Header
                    headerSection
                    
                    // Form content
                    content
                        .padding(.bottom, 40)
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            startAnimations()
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            HStack {
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.8))
                        .frame(width: 36, height: 36)
                        .background(
                            Circle()
                                .fill(.ultraThinMaterial)
                                .background(
                                    Circle().fill(Color.white.opacity(0.1))
                                )
                        )
                        .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                }
                
                Spacer()
            }
            
            VStack(spacing: 12) {
                // Animated icon
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.premiumBlue.opacity(0.4),
                                    Color.premiumPurple.opacity(0.2),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 30,
                                endRadius: 80
                            )
                        )
                        .frame(width: 80, height: 80)
                        .blur(radius: 20)
                        .scaleEffect(animationPhase == 0 ? 1.0 : 1.3)
                    
                    Image(systemName: icon)
                        .font(.system(size: 48, weight: .light))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.premiumBlue, Color.premiumPurple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .scaleEffect(animationPhase == 0 ? 1.0 : 1.1)
                        .shadow(color: Color.premiumBlue.opacity(0.4), radius: 20, x: 0, y: 10)
                }
                
                VStack(spacing: 8) {
                    Text(title)
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.premiumBlue, Color.premiumPurple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    
                    Text(subtitle)
                        .font(.system(size: 18, weight: .medium, design: .rounded))
                        .foregroundStyle(Color.white.opacity(0.7))
                }
            }
        }
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : -20)
    }
    
    private func startAnimations() {
        particleSystem.startEmitting()
        
        withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
            animationPhase = 1
        }
        
        withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.1)) {
            isVisible = true
        }
    }
}
