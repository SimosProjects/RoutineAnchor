//
//  PremiumAddTimeBlockView.swift
//  Routine Anchor - Premium Version (Improved Duration Selection)
//
import SwiftUI

struct PremiumAddTimeBlockView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var formData = TimeBlockFormData()
    
    // MARK: - State
    @State private var showingValidationErrors = false
    @State private var isVisible = false
    @State private var selectedDuration: Int? = nil // Track selected duration
    
    // MARK: - Callback
    let onSave: (String, Date, Date, String?, String?) -> Void
    
    var body: some View {
        PremiumTimeBlockFormView(
            title: "New Time Block",
            icon: "plus.circle",
            subtitle: "Add structure to your day",
            onDismiss: { dismiss() }
        ) {
            VStack(spacing: 24) {
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
    
    // MARK: - Form Sections
    
    private var basicInfoSection: some View {
        PremiumFormSection(
            title: "Basic Information",
            icon: "doc.text",
            color: Color.premiumBlue
        ) {
            VStack(spacing: 16) {
                PremiumTextField(
                    title: "Title",
                    text: $formData.title,
                    placeholder: "What will you be doing?",
                    icon: "textformat"
                )
                
                PremiumTextField(
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
        PremiumFormSection(
            title: "Schedule",
            icon: "clock",
            color: Color.premiumGreen
        ) {
            VStack(spacing: 20) {
                // Time pickers
                HStack(spacing: 16) {
                    PremiumTimePicker(
                        title: "Start",
                        selection: $formData.startTime,
                        icon: "play.circle"
                    )
                    
                    PremiumTimePicker(
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
                            .foregroundStyle(Color.premiumWarning)
                        
                        Text("Quick Duration")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color.white.opacity(0.8))
                    }
                    
                    QuickDurationSelector(
                        selectedDuration: $selectedDuration,
                        onSelect: { minutes in
                            selectedDuration = minutes
                            formData.setDuration(minutes: minutes)
                            HapticManager.shared.premiumSelection()
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
            return .premiumError
        case ..<30:
            return .premiumWarning
        case ..<60:
            return .premiumWarning
        default:
            return .premiumGreen
        }
    }
    
    private var organizationSection: some View {
        PremiumFormSection(
            title: "Organization",
            icon: "folder",
            color: Color.premiumPurple
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
        PremiumFormSection(
            title: "Icon",
            icon: "face.smiling",
            color: Color.premiumTeal
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
            PremiumButton(
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
        
        HapticManager.shared.premiumSuccess()
        dismiss()
    }
}

// MARK: - Preview
#Preview {
    PremiumAddTimeBlockView { title, startTime, endTime, notes, category in
        print("Saving: \(title) from \(startTime) to \(endTime)")
    }
}
