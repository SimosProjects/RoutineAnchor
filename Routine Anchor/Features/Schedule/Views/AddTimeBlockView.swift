//
//  AddTimeBlockView.swift
//  Routine Anchor
//
import SwiftUI
import Foundation

struct AddTimeBlockView: View {
    @Environment(\.themeManager) private var themeManager
    @Environment(\.dismiss) private var dismiss
    @State private var formData = TimeBlockFormData()
    
    // MARK: - State
    @State private var showingValidationErrors = false
    @State private var isVisible = false
    @State private var selectedDuration: Int? = nil
    
    let existingTimeBlocks: [TimeBlock]
    let onSave: (String, Date, Date, String?, String?) -> Void
    
    init(
        existingTimeBlocks: [TimeBlock] = [],
        onSave: @escaping (String, Date, Date, String?, String?) -> Void
    ) {
        self.existingTimeBlocks = existingTimeBlocks
        self.onSave = onSave
    }
    
    var body: some View {
        TimeBlockFormView(
            title: "New Time Block",
            icon: "plus.circle",
            subtitle: "Add structure to your day",
            onDismiss: { dismiss() }
        ) {
            VStack(spacing: 24) {
                if !formData.getConflictingBlocks().isEmpty {
                    conflictWarningView
                }
                
                // Basic Information Section
                basicInfoSection
                
                // Time Section with Quick Duration integrated
                timeAndDurationSection
                
                // Organization Section
                organizationSection
                
                // Icon Section
                iconSection
                
                // Action Buttons
                actionButtons
            }
        }
        .onAppear {
            formData.setExistingTimeBlocks(existingTimeBlocks)
            formData.setToNextAvailableSlot()
            formData.validateForm()
            
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.3)) {
                isVisible = true
            }
        }
        .onChange(of: formData.title) { _, _ in formData.validateForm() }
        .onChange(of: formData.startTime) { _, _ in
            formData.validateForm()
            // Clear selected duration if times were manually changed
            if selectedDuration != nil {
                let currentDuration = Int(formData.endTime.timeIntervalSince(formData.startTime) / 60)
                if currentDuration != selectedDuration {
                    selectedDuration = nil
                }
            }
        }
        .onChange(of: formData.endTime) { _, _ in
            formData.validateForm()
            // Clear selected duration if times were manually changed
            if selectedDuration != nil {
                let currentDuration = Int(formData.endTime.timeIntervalSince(formData.startTime) / 60)
                if currentDuration != selectedDuration {
                    selectedDuration = nil
                }
            }
        }
        .alert("Invalid Time Block", isPresented: $showingValidationErrors) {
            Button("OK") {}
        } message: {
            Text(formData.validationErrors.joined(separator: "\n"))
        }
    }
    
    // MARK: - Conflict Warning
    
    @ViewBuilder
    private var conflictWarningView: some View {
        let conflicts = formData.getConflictingBlocks()
        
        if !conflicts.isEmpty {
            VStack(spacing: 12) {
                // Main warning content
                HStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(Color.anchorWarning)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Time Conflict")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Color.anchorTextPrimary)
                        
                        if conflicts.count == 1 {
                            Text("Overlaps with '\(conflicts.first!.title)'")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(Color.anchorTextSecondary)
                        } else {
                            Text("Overlaps with \(conflicts.count) time blocks")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(Color.anchorTextSecondary)
                        }
                    }
                    
                    Spacer()
                }
                
                Button(action: {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                        formData.setToNextAvailableSlot()
                    }
                    HapticManager.shared.lightImpact()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 13, weight: .medium))
                        Text("Find Next Available Time")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundStyle(Color.anchorBlue)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(themeManager?.currentTheme.colorScheme.surfacePrimary.color ?? Theme.defaultTheme.colorScheme.surfacePrimary.color))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.anchorBlue.opacity(0.3), lineWidth: 1)
                            )
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.cardBackground) // Your app's card background
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.anchorWarning.opacity(0.6),
                                        Color.anchorWarning.opacity(0.2)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                    )
            )
            .shadow(color: Color.anchorWarning.opacity(0.2), radius: 8, x: 0, y: 4)
            .padding(.horizontal, 24)
            .transition(.asymmetric(
                insertion: .scale(scale: 0.95).combined(with: .opacity),
                removal: .scale(scale: 0.9).combined(with: .opacity)
            ))
        }
    }
    
    // MARK: - Form Sections
    
    private var basicInfoSection: some View {
        FormSection(
            title: "Basic Information",
            icon: "doc.text",
            color: Color.anchorBlue
        ) {
            VStack(spacing: 16) {
                DesignedTextField(
                    title: "Title",
                    text: $formData.title,
                    placeholder: "What will you be doing?",
                    icon: "textformat"
                )
                
                DesignedTextField(
                    title: "Notes",
                    text: $formData.notes,
                    placeholder: "Add details or reminders (optional)",
                    icon: "note.text",
                    isMultiline: true
                )
            }
        }
        .opacity(isVisible ? 1 : 0)
        .offset(x: isVisible ? 0 : -20)
    }
    
    private var timeAndDurationSection: some View {
        FormSection(
            title: "Schedule",
            icon: "clock",
            color: Color.anchorGreen
        ) {
            VStack(spacing: 20) {
                // Time pickers
                HStack(spacing: 16) {
                    TimePicker(
                        title: "Start",
                        selection: $formData.startTime,
                        icon: "play.circle"
                    )
                    
                    TimePicker(
                        title: "End",
                        selection: $formData.endTime,
                        icon: "stop.circle"
                    )
                }
                
                // Quick duration selector - RIGHT UNDER TIME PICKERS
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 8) {
                        Image(systemName: "timer")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Color.anchorWarning)
                        
                        Text("Quick Duration")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color(themeManager?.currentTheme.textPrimaryColor ?? Theme.defaultTheme.textPrimaryColor).opacity(0.8))
                    }
                    
                    QuickDurationSelector(
                        selectedDuration: $selectedDuration,
                        onSelect: { minutes in
                            selectedDuration = minutes
                            formData.setDuration(minutes: minutes)
                            HapticManager.shared.anchorSelection()
                        }
                    )
                }
                
                // Duration display card
                let duration = Int(formData.endTime.timeIntervalSince(formData.startTime) / 60)
                DurationCard(
                    minutes: duration,
                    color: color(for: duration)
                )
            }
        }
        .opacity(isVisible ? 1 : 0)
        .offset(x: isVisible ? 0 : 20)
    }
    
    private func color(for minutes: Int) -> Color {
        switch minutes {
        case ..<15:
            return .anchorError
        case ..<30:
            return .anchorWarning
        case ..<60:
            return .anchorWarning
        default:
            return .anchorGreen
        }
    }
    
    private var organizationSection: some View {
        FormSection(
            title: "Organization",
            icon: "folder",
            color: Color.anchorPurple
        ) {
            CategorySelector(
                categories: formData.categories,
                selectedCategory: $formData.category
            )
        }
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : 20)
    }
    
    private var iconSection: some View {
        FormSection(
            title: "Icon",
            icon: "face.smiling",
            color: Color.anchorTeal
        ) {
            IconSelector(
                icons: formData.icons,
                selectedIcon: $formData.selectedIcon
            )
        }
        .opacity(isVisible ? 1 : 0)
        .offset(x: isVisible ? 0 : -20)
    }
    
    private var actionButtons: some View {
        VStack(spacing: 16) {
            DesignedButton(
                title: "Create Time Block",
                style: .gradient,
                action: saveTimeBlock
            )
            .disabled(!formData.isFormValid)
            .opacity(formData.isFormValid ? 1.0 : 0.6)
            
            SecondaryActionButton(
                title: "Cancel",
                icon: "xmark",
                action: { dismiss() }
            )
        }
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : 20)
    }
    
    // MARK: - Actions
    
    private func saveTimeBlock() {
        formData.validateForm()
        
        guard formData.isFormValid else {
            showingValidationErrors = true
            return
        }
        
        let (title, notes, category) = formData.prepareForSave()
        
        onSave(title, formData.startTime, formData.endTime, notes, category)
        
        HapticManager.shared.anchorSuccess()
        dismiss()
    }
}

extension TimeBlockFormData {
    /// Find the next available time slot that doesn't conflict
    func findNextAvailableTimeSlot(duration: TimeInterval = 3600) -> (start: Date, end: Date)? {
        let calendar = Calendar.current
        let now = Date()
        
        // Start from the next hour
        let startOfNextHour = calendar.dateInterval(of: .hour, for: now)?.end ?? now
        var candidateStart = startOfNextHour
        
        // Try up to 24 hours ahead
        for _ in 0..<24 {
            let candidateEnd = candidateStart.addingTimeInterval(duration)
            
            // Create test block
            let testBlock = TimeBlock(
                title: "Test",
                startTime: candidateStart,
                endTime: candidateEnd
            )
            
            // Check if this slot is free
            let conflicts = testBlock.conflictsWith(existingTimeBlocks)
            if conflicts.isEmpty {
                return (start: candidateStart, end: candidateEnd)
            }
            
            // Move to next hour
            candidateStart = calendar.date(byAdding: .hour, value: 1, to: candidateStart) ?? candidateStart
        }
        
        return nil // No available slot found in next 24 hours
    }
    
    /// Set the form to the next available time slot
    func setToNextAvailableSlot() {
        if let nextSlot = findNextAvailableTimeSlot() {
            self.startTime = nextSlot.start
            self.endTime = nextSlot.end
            validateForm()
        }
    }
}

// MARK: - Preview
#Preview {
    AddTimeBlockView { title, startTime, endTime, notes, category in
        print("Saving: \(title) from \(startTime) to \(endTime)")
    }
}
