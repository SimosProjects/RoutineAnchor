//
//  AddTimeBlockView.swift
//  Routine Anchor - Premium Version
//
import SwiftUI

struct AddTimeBlockView: View {
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Form Data
    @State private var title = ""
    @State private var startTime = Date()
    @State private var endTime = Date()
    @State private var notes = ""
    @State private var category = ""
    @State private var selectedIcon = ""
    
    // MARK: - UI State
    @State private var showingValidationErrors = false
    @State private var validationErrors: [String] = []
    @State private var isFormValid = false
    @State private var selectedQuickDuration: Int? = nil
    @State private var animationPhase = 0.0
    @State private var showSuccessAnimation = false
    
    // MARK: - Callback
    let onSave: (String, Date, Date, String?, String?, String?) -> Void
    
    // MARK: - Constants
    private let categories = ["Work", "Personal", "Health", "Learning", "Social", "Other"]
    private let icons = ["💼", "🏠", "💪", "📚", "👥", "🎯", "☕", "🍽️", "🧘", "🎵", "📱", "🚗"]
    private let quickDurations = [15, 30, 45, 60, 90, 120]
    
    init(onSave: @escaping (String, Date, Date, String?, String?, String?) -> Void) {
        self.onSave = onSave
        
        // Set default times
        let calendar = Calendar.current
        let now = Date()
        let nextHour = calendar.date(byAdding: .hour, value: 1, to: now) ?? now
        
        self._startTime = State(initialValue: calendar.dateInterval(of: .hour, for: nextHour)?.start ?? nextHour)
        self._endTime = State(initialValue: calendar.date(byAdding: .hour, value: 1, to: nextHour) ?? nextHour)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Premium Background
                Color.premiumBackground
                    .ignoresSafeArea()
                
                AnimatedMeshBackground()
                    .opacity(0.2)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Basic Information
                        basicInfoSection
                        
                        // Time Selection
                        timeSection
                        
                        // Quick Duration Pills
                        quickDurationSection
                        
                        // Category Selection
                        categorySection
                        
                        // Icon Selection
                        iconSection
                        
                        // Save Button
                        saveButton
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 24)
                }
            }
            .navigationTitle("New Time Block")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Text("Cancel")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(Color.premiumTextSecondary)
                    }
                }
            }
            .preferredColorScheme(.dark)
            .onChange(of: title) { _ in validateForm() }
            .onChange(of: startTime) { _ in validateForm() }
            .onChange(of: endTime) { _ in validateForm() }
            .onAppear {
                withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
                    animationPhase = 1.0
                }
            }
        }
    }
    
    // MARK: - Basic Info Section
    private var basicInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label {
                Text("Basic Information")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
            } icon: {
                Image(systemName: "doc.text.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.premiumBlue)
            }
            
            VStack(spacing: 16) {
                // Title Field
                PremiumTextField(
                    placeholder: "Time block title",
                    text: $title,
                    icon: "pencil",
                    isValid: title.count >= 3 || title.isEmpty
                )
                
                // Notes Field
                PremiumTextEditor(
                    placeholder: "Add notes (optional)",
                    text: $notes,
                    minHeight: 80
                )
            }
            .padding(20)
            .glassMorphism(cornerRadius: 16)
        }
    }
    
    // MARK: - Time Section
    private var timeSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label {
                Text("Schedule")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
            } icon: {
                Image(systemName: "clock.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.premiumPurple)
            }
            
            VStack(spacing: 20) {
                // Start Time
                PremiumTimePicker(
                    title: "Start time",
                    selection: $startTime,
                    icon: "play.circle.fill",
                    accentColor: Color.premiumGreen
                )
                
                // End Time
                PremiumTimePicker(
                    title: "End time",
                    selection: $endTime,
                    icon: "stop.circle.fill",
                    accentColor: Color.premiumError
                )
                
                // Duration Display
                HStack {
                    Image(systemName: "timer")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.premiumBlue)
                    
                    Text("Duration")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.premiumTextSecondary)
                    
                    Spacer()
                    
                    Text(formattedDuration)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(durationGradient)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.premiumBlue.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.premiumBlue.opacity(0.2), lineWidth: 1)
                        )
                )
            }
            .padding(20)
            .glassMorphism(cornerRadius: 16)
            
            if startTime >= endTime {
                ErrorBanner(message: "End time must be after start time")
            } else if durationMinutes > 480 {
                WarningBanner(message: "Long blocks may be hard to complete")
            }
        }
    }
    
    // MARK: - Quick Duration Section
    private var quickDurationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label {
                Text("Quick Duration")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.premiumTextSecondary)
            } icon: {
                Image(systemName: "timer")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.premiumTeal)
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(quickDurations, id: \.self) { minutes in
                        PremiumPill(
                            title: "\(minutes)m",
                            isSelected: selectedQuickDuration == minutes,
                            gradient: [Color.premiumTeal, Color.premiumBlue]
                        ) {
                            setDuration(minutes: minutes)
                            selectedQuickDuration = minutes
                            HapticManager.shared.lightImpact()
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Category Section
    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label {
                Text("Category")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
            } icon: {
                Image(systemName: "folder.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.premiumGreen)
            }
            
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 12) {
                ForEach(categories, id: \.self) { cat in
                    PremiumCategoryCard(
                        title: cat,
                        isSelected: category == cat,
                        icon: categoryIcon(for: cat),
                        gradient: categoryGradient(for: cat)
                    ) {
                        category = (category == cat) ? "" : cat
                        HapticManager.shared.lightImpact()
                    }
                }
            }
            .padding(20)
            .glassMorphism(cornerRadius: 16)
        }
    }
    
    // MARK: - Icon Section
    private var iconSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label {
                Text("Icon (Optional)")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
            } icon: {
                Image(systemName: "star.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.premiumWarning)
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    // No icon option
                    Button {
                        selectedIcon = ""
                        HapticManager.shared.lightImpact()
                    } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(selectedIcon.isEmpty ? Color.premiumBlue.opacity(0.2) : Color.clear)
                                .frame(width: 56, height: 56)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(
                                            selectedIcon.isEmpty ? Color.premiumBlue : Color.white.opacity(0.1),
                                            lineWidth: 2
                                        )
                                )
                            
                            Image(systemName: "minus.circle")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundStyle(selectedIcon.isEmpty ? Color.premiumBlue : Color.premiumTextTertiary)
                        }
                    }
                    
                    // Icon options
                    ForEach(icons, id: \.self) { icon in
                        Button {
                            selectedIcon = icon
                            HapticManager.shared.lightImpact()
                        } label: {
                            Text(icon)
                                .font(.system(size: 28))
                                .frame(width: 56, height: 56)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(selectedIcon == icon ? Color.premiumBlue.opacity(0.2) : Color.white.opacity(0.05))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(
                                                    selectedIcon == icon ? Color.premiumBlue : Color.white.opacity(0.1),
                                                    lineWidth: 2
                                                )
                                        )
                                )
                                .scaleEffect(selectedIcon == icon ? 1.1 : 1.0)
                                .animation(.spring(response: 0.3), value: selectedIcon)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 4)
            }
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.03))
            )
        }
    }
    
    // MARK: - Save Button
    private var saveButton: some View {
        Button {
            saveTimeBlock()
        } label: {
            ZStack {
                // Animated gradient background
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: isFormValid ?
                                [Color.premiumBlue, Color.premiumPurple] :
                                [Color.white.opacity(0.1), Color.white.opacity(0.05)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 56)
                
                if isFormValid {
                    // Glow effect
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [Color.premiumBlue, Color.premiumPurple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(height: 56)
                        .blur(radius: 20)
                        .opacity(0.5)
                        .scaleEffect(animationPhase > 0.5 ? 1.1 : 0.9)
                }
                
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20, weight: .semibold))
                    
                    Text("Create Time Block")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundStyle(isFormValid ? .white : Color.premiumTextTertiary)
            }
        }
        .disabled(!isFormValid)
        .animation(.spring(response: 0.4), value: isFormValid)
    }
    
    // MARK: - Helper Methods
    private var formattedDuration: String {
        let minutes = Calendar.current.dateComponents([.minute], from: startTime, to: endTime).minute ?? 0
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
    
    private var durationMinutes: Int {
        Calendar.current.dateComponents([.minute], from: startTime, to: endTime).minute ?? 0
    }
    
    private var durationGradient: LinearGradient {
        let colors: [Color] = if durationMinutes > 240 {
            [Color.premiumError, Color.premiumWarning]
        } else if durationMinutes > 120 {
            [Color.premiumWarning, Color.premiumTeal]
        } else {
            [Color.premiumGreen, Color.premiumTeal]
        }
        
        return LinearGradient(colors: colors, startPoint: .leading, endPoint: .trailing)
    }
    
    private func validateForm() {
        validationErrors.removeAll()
        
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedTitle.isEmpty {
            validationErrors.append("Title is required")
        } else if trimmedTitle.count < 3 {
            validationErrors.append("Title must be at least 3 characters")
        }
        
        if startTime >= endTime {
            validationErrors.append("End time must be after start time")
        }
        
        isFormValid = validationErrors.isEmpty && !trimmedTitle.isEmpty
    }
    
    private func setDuration(minutes: Int) {
        endTime = Calendar.current.date(byAdding: .minute, value: minutes, to: startTime) ?? endTime
        validateForm()
    }
    
    private func saveTimeBlock() {
        validateForm()
        
        guard isFormValid else {
            showingValidationErrors = true
            HapticManager.shared.error()
            return
        }
        
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalNotes = trimmedNotes.isEmpty ? nil : trimmedNotes
        let finalCategory = category.isEmpty ? nil : category
        let finalIcon = selectedIcon.isEmpty ? nil : selectedIcon
        
        onSave(trimmedTitle, startTime, endTime, finalNotes, finalCategory, finalIcon)
        
        HapticManager.shared.success()
        dismiss()
    }
    
    private func categoryIcon(for category: String) -> String {
        switch category.lowercased() {
        case "work": return "briefcase.fill"
        case "personal": return "house.fill"
        case "health": return "heart.fill"
        case "learning": return "book.fill"
        case "social": return "person.2.fill"
        default: return "star.fill"
        }
    }
    
    private func categoryGradient(for category: String) -> [Color] {
        switch category.lowercased() {
        case "work": return [Color.premiumBlue, Color.premiumPurple]
        case "personal": return [Color.premiumGreen, Color.premiumTeal]
        case "health": return [Color.premiumGreen, Color.premiumBlue]
        case "learning": return [Color.premiumPurple, Color.premiumBlue]
        case "social": return [Color.premiumTeal, Color.premiumBlue]
        default: return [Color.premiumTextSecondary, Color.premiumTextTertiary]
        }
    }
}

// MARK: - Supporting Views

struct PremiumTextField: View {
    let placeholder: String
    @Binding var text: String
    let icon: String
    var isValid: Bool = true
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Color.premiumBlue)
            
            TextField(placeholder, text: $text)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(.white)
                .tint(Color.premiumBlue)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            isValid ? Color.white.opacity(0.1) : Color.premiumError.opacity(0.5),
                            lineWidth: 1
                        )
                )
        )
    }
}

struct PremiumTextEditor: View {
    let placeholder: String
    @Binding var text: String
    let minHeight: CGFloat
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            if text.isEmpty {
                Text(placeholder)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Color.premiumTextTertiary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
            }
            
            TextEditor(text: $text)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(.white)
                .tint(Color.premiumBlue)
                .scrollContentBackground(.hidden)
                .background(Color.clear)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
        }
        .frame(minHeight: minHeight)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
}

struct PremiumTimePicker: View {
    let title: String
    @Binding var selection: Date
    let icon: String
    let accentColor: Color
    
    var body: some View {
        HStack {
            Label {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.premiumTextSecondary)
            } icon: {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(accentColor)
            }
            
            Spacer()
            
            DatePicker("", selection: $selection, displayedComponents: .hourAndMinute)
                .labelsHidden()
                .tint(accentColor)
                .colorScheme(.dark)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(accentColor.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(accentColor.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

struct PremiumPill: View {
    let title: String
    let isSelected: Bool
    let gradient: [Color]
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(isSelected ? .white : Color.premiumTextSecondary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Group {
                        if isSelected {
                            LinearGradient(colors: gradient, startPoint: .leading, endPoint: .trailing)
                        } else {
                            Color.white.opacity(0.1)
                        }
                    }
                )
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            isSelected ? Color.clear : Color.white.opacity(0.1),
                            lineWidth: 1
                        )
                )
        }
    }
}

struct PremiumCategoryCard: View {
    let title: String
    let isSelected: Bool
    let icon: String
    let gradient: [Color]
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(
                        isSelected ?
                            AnyShapeStyle(LinearGradient(colors: gradient, startPoint: .topLeading, endPoint: .bottomTrailing)) :
                            AnyShapeStyle(Color.premiumTextTertiary)
                    )
                
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(isSelected ? .white : Color.premiumTextSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        isSelected
                        ? AnyShapeStyle(LinearGradient(colors: gradient.map { $0.opacity(0.2) }, startPoint: .topLeading, endPoint: .bottomTrailing))
                        : AnyShapeStyle(Color.white.opacity(0.05))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                isSelected
                                ? AnyShapeStyle(LinearGradient(colors: gradient, startPoint: .topLeading, endPoint: .bottomTrailing))
                                : AnyShapeStyle(Color.white.opacity(0.1)),
                                lineWidth: isSelected ? 2 : 1
                            )
                    )

            )
            .scaleEffect(isSelected ? 1.05 : 1.0)
            .animation(.spring(response: 0.3), value: isSelected)
        }
    }
}

struct ErrorBanner: View {
    let message: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 14, weight: .medium))
            
            Text(message)
                .font(.system(size: 14, weight: .medium))
            
            Spacer()
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            LinearGradient(
                colors: [Color.premiumError, Color.premiumError.opacity(0.8)],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .cornerRadius(12)
    }
}

struct WarningBanner: View {
    let message: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.circle.fill")
                .font(.system(size: 14, weight: .medium))
            
            Text(message)
                .font(.system(size: 14, weight: .medium))
            
            Spacer()
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            LinearGradient(
                colors: [Color.premiumWarning, Color.premiumWarning.opacity(0.8)],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .cornerRadius(12)
    }
}

// MARK: - Preview
#Preview {
    AddTimeBlockView { title, startTime, endTime, notes, category, icon in
        print("Saving: \(title) from \(startTime) to \(endTime)")
    }
    .preferredColorScheme(.dark)
}
