//
//  SharedTimeBlockComponents.swift
//  Routine Anchor
//
//  Created by Christopher Simonson on 7/22/25.
//

import SwiftUI

// MARK: - Shared Form Data Model
class TimeBlockFormData: ObservableObject {
    @Published var title = ""
    @Published var startTime = Date()
    @Published var endTime = Date()
    @Published var notes = ""
    @Published var category = ""
    @Published var selectedIcon = ""
    @Published var validationErrors: [String] = []
    @Published var isFormValid = false
    @Published var hasChanges = false
    
    // Constants
    let categories = ["Work", "Personal", "Health", "Learning", "Social", "Other"]
    let icons = ["💼", "🏠", "💪", "📚", "👥", "🎯", "☕", "🍽️", "🧘", "🎵", "📱", "🚗"]
    
    // Original data for comparison (used in edit mode)
    private var originalTitle = ""
    private var originalStartTime = Date()
    private var originalEndTime = Date()
    private var originalNotes = ""
    private var originalCategory = ""
    private var originalIcon = ""
    
    init() {
        setupDefaultTimes()
    }
    
    init(from timeBlock: TimeBlock) {
        // Initialize with existing data for editing
        self.title = timeBlock.title
        self.startTime = timeBlock.startTime
        self.endTime = timeBlock.endTime
        self.notes = timeBlock.notes ?? ""
        self.category = timeBlock.category ?? ""
        self.selectedIcon = timeBlock.icon ?? ""
        
        // Store original values for change detection
        self.originalTitle = timeBlock.title
        self.originalStartTime = timeBlock.startTime
        self.originalEndTime = timeBlock.endTime
        self.originalNotes = timeBlock.notes ?? ""
        self.originalCategory = timeBlock.category ?? ""
        self.originalIcon = timeBlock.icon ?? ""
    }
    
    private func setupDefaultTimes() {
        let calendar = Calendar.current
        let now = Date()
        let nextHour = calendar.date(byAdding: .hour, value: 1, to: now) ?? now
        
        self.startTime = calendar.dateInterval(of: .hour, for: nextHour)?.start ?? nextHour
        self.endTime = calendar.date(byAdding: .hour, value: 1, to: nextHour) ?? nextHour
    }
    
    func validateForm() {
        validationErrors.removeAll()
        
        // Title validation
        if title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            validationErrors.append("Title is required")
        } else if title.count < 3 {
            validationErrors.append("Title must be at least 3 characters")
        }
        
        // Time validation
        if startTime >= endTime {
            validationErrors.append("End time must be after start time")
        }
        
        let duration = durationMinutes
        if duration < 1 {
            validationErrors.append("Duration must be at least 1 minute")
        }
        
        if duration > 24 * 60 {
            validationErrors.append("Duration cannot exceed 24 hours")
        }
        
        isFormValid = validationErrors.isEmpty
    }
    
    func checkForChanges() {
        hasChanges = title != originalTitle ||
                    startTime != originalStartTime ||
                    endTime != originalEndTime ||
                    notes != originalNotes ||
                    category != originalCategory ||
                    selectedIcon != originalIcon
    }
    
    func setDuration(minutes: Int) {
        endTime = Calendar.current.date(byAdding: .minute, value: minutes, to: startTime) ?? endTime
        validateForm()
    }
    
    var durationMinutes: Int {
        max(0, Int(endTime.timeIntervalSince(startTime) / 60))
    }
    
    var durationColor: Color {
        switch durationMinutes {
        case 0:
            return Color.premiumError
        case 1...30:
            return Color.premiumWarning
        case 31...120:
            return Color.premiumGreen
        case 121...240:
            return Color.premiumBlue
        default:
            return Color.premiumWarning
        }
    }
    
    func prepareForSave() -> (title: String, notes: String?, category: String?) {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalNotes = trimmedNotes.isEmpty ? nil : trimmedNotes
        let finalCategory = category.isEmpty ? nil : category
        
        return (trimmedTitle, finalNotes, finalCategory)
    }
}

// MARK: - Shared Form Section Component
struct PremiumFormSection<Content: View>: View {
    let title: String
    let icon: String
    let color: Color
    let content: Content
    
    @State private var isVisible = false
    
    init(title: String, icon: String, color: Color, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.color = color
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section header
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(color)
                    .frame(width: 28, height: 28)
                
                Text(title)
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                
                Spacer()
            }
            
            // Section content
            content
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.08),
                                    Color.white.opacity(0.04)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    LinearGradient(
                        colors: [
                            color.opacity(0.3),
                            color.opacity(0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: color.opacity(0.2), radius: 12, x: 0, y: 6)
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : 20)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2)) {
                isVisible = true
            }
        }
    }
}

// MARK: - Shared Text Field Component
struct PremiumTextField: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    let icon: String
    let isMultiline: Bool
    
    init(title: String, text: Binding<String>, placeholder: String, icon: String, isMultiline: Bool = false) {
        self.title = title
        self._text = text
        self.placeholder = placeholder
        self.icon = icon
        self.isMultiline = isMultiline
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.premiumBlue)
                
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
            }
            
            Group {
                if isMultiline {
                    TextField(placeholder, text: $text, axis: .vertical)
                        .lineLimit(2...4)
                } else {
                    TextField(placeholder, text: $text)
                }
            }
            .font(.system(size: 16, weight: .medium))
            .foregroundStyle(.white)
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
        }
    }
}

// MARK: - Shared Time Picker Component
struct PremiumTimePicker: View {
    let title: String
    @Binding var selection: Date
    let icon: String
    let isDisabled: Bool
    
    init(title: String, selection: Binding<Date>, icon: String, isDisabled: Bool = false) {
        self.title = title
        self._selection = selection
        self.icon = icon
        self.isDisabled = isDisabled
    }
    
    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(isDisabled ? Color.white.opacity(0.4) : Color.premiumGreen)
                
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(isDisabled ? Color.white.opacity(0.4) : .white)
            }
            
            DatePicker("", selection: $selection, displayedComponents: .hourAndMinute)
                .datePickerStyle(.compact)
                .labelsHidden()
                .accentColor(Color.premiumGreen)
                .colorScheme(.dark)
                .disabled(isDisabled)
                .opacity(isDisabled ? 0.6 : 1.0)
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isDisabled ? Color.white.opacity(0.05) : Color.white.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    isDisabled ? Color.white.opacity(0.1) : Color.white.opacity(0.2),
                    lineWidth: 1
                )
        )
    }
}

// MARK: - Shared Duration Card Component
struct DurationCard: View {
    let minutes: Int
    let color: Color
    
    private var formattedDuration: String {
        let hours = minutes / 60
        let mins = minutes % 60
        
        if hours > 0 && mins > 0 {
            return "\(hours)h \(mins)m"
        } else if hours > 0 {
            return "\(hours)h"
        } else {
            return "\(mins)m"
        }
    }
    
    var body: some View {
        HStack {
            Image(systemName: "clock.badge")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(color)
            
            Text("Duration:")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(.white)
            
            Spacer()
            
            Text(formattedDuration)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(color)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.15))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
    }
}

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

// MARK: - Shared Category Chip Component
struct CategoryChip: View {
    let title: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            HapticManager.shared.lightImpact()
            action()
        }) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(isSelected ? .white : color)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(isSelected ? color : Color.white.opacity(0.1))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(color.opacity(0.5), lineWidth: 1)
                )
        }
        .scaleEffect(isSelected ? 1.0 : 0.95)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
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

// MARK: - Shared Icon Chip Component
struct IconChip: View {
    let icon: String?
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            HapticManager.shared.lightImpact()
            action()
        }) {
            Group {
                if let icon = icon {
                    Text(icon)
                        .font(.system(size: 20))
                } else {
                    Image(systemName: "minus")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.6))
                }
            }
            .frame(width: 44, height: 44)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.premiumTeal.opacity(0.3) : Color.white.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isSelected ? Color.premiumTeal : Color.white.opacity(0.2),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
        }
        .scaleEffect(isSelected ? 1.1 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
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

// MARK: - Shared Duration Chip Component
struct DurationChip: View {
    let minutes: Int
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            HapticManager.shared.lightImpact()
            action()
        }) {
            Text("\(minutes)m")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.premiumWarning)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.premiumWarning.opacity(0.15))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.premiumWarning.opacity(0.3), lineWidth: 1)
                )
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
