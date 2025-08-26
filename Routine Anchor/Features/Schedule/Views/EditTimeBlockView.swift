//
//  EditTimeBlockView.swift
//  Routine Anchor
//
import SwiftUI

struct EditTimeBlockView: View {
    @Environment(\.themeManager) private var themeManager
    @Environment(\.dismiss) private var dismiss
    @State private var formData: TimeBlockFormData
    @State private var showingValidationErrors = false
    @State private var isVisible = false
    @State private var showingDiscardConfirmation = false
    @State private var selectedDuration: Int? = nil
    
    // MARK: - Properties
    let originalTimeBlock: TimeBlock
    let existingTimeBlocks: [TimeBlock]
    let onSave: (TimeBlock) -> Void
    
    init(
        timeBlock: TimeBlock,
        existingTimeBlocks: [TimeBlock],
        onSave: @escaping (TimeBlock) -> Void
    ) {
        self.originalTimeBlock = timeBlock
        self.existingTimeBlocks = existingTimeBlocks
        self.onSave = onSave
        self._formData = State(initialValue: TimeBlockFormData(from: timeBlock))
    }
    
    var body: some View {
        TimeBlockFormView(
            title: "Edit Time Block",
            icon: "pencil.circle",
            subtitle: "Update your schedule",
            onDismiss: handleDismiss
        ) {
            VStack(spacing: 24) {
                // Status indicator if active
                if originalTimeBlock.status == .inProgress {
                    activeBlockWarning
                }
                
                // Basic Information Section
                basicInfoSection
                
                // Time Section with Quick Duration integrated
                timeAndDurationSection
                
                // Organization Section
                organizationSection
                
                // Icon Section
                iconSection
                
                // History Section (if applicable)
                if originalTimeBlock.createdAt != Date.distantPast {
                    historySection
                }
                
                // Action Buttons
                actionButtons
            }
        }
        .onAppear {
            formData.setExistingTimeBlocks(
                existingTimeBlocks,
                excluding: originalTimeBlock.id
            )
            formData.validateForm()
            formData.checkForChanges()
            
            // Calculate initial duration to see if it matches a preset
            let duration = Int(formData.endTime.timeIntervalSince(formData.startTime) / 60)
            if [15, 30, 45, 60, 90, 120].contains(duration) {
                selectedDuration = duration
            }
            
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.3)) {
                isVisible = true
            }
        }
        .onChange(of: formData.title) { _, _ in
            formData.validateForm()
            formData.checkForChanges()
        }
        .onChange(of: formData.startTime) { _, _ in
            formData.validateForm()
            formData.checkForChanges()
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
            formData.checkForChanges()
            // Clear selected duration if times were manually changed
            if selectedDuration != nil {
                let currentDuration = Int(formData.endTime.timeIntervalSince(formData.startTime) / 60)
                if currentDuration != selectedDuration {
                    selectedDuration = nil
                }
            }
        }
        .onChange(of: formData.notes) { _, _ in formData.checkForChanges() }
        .onChange(of: formData.category) { _, _ in formData.checkForChanges() }
        .onChange(of: formData.selectedIcon) { _, _ in formData.checkForChanges() }
        .alert("Invalid Time Block", isPresented: $showingValidationErrors) {
            Button("OK") {}
        } message: {
            Text(formData.validationErrors.joined(separator: "\n"))
        }
        .confirmationDialog(
            "Discard Changes?",
            isPresented: $showingDiscardConfirmation,
            titleVisibility: .visible
        ) {
            Button("Discard", role: .destructive) {
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("You have unsaved changes. Are you sure you want to discard them?")
        }
    }
    
    // MARK: - Form Sections
    
    private var activeBlockWarning: some View {
        HStack(spacing: 12) {
            Image(systemName: "clock.badge.exclamationmark")
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(Color.anchorBlue)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Currently Active")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(themeManager?.currentTheme.textPrimaryColor ?? Theme.defaultTheme.textPrimaryColor)
                
                Text("This time block is in progress")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.7))
            }
            
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.anchorBlue.opacity(0.15))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.anchorBlue.opacity(0.3), lineWidth: 1)
        )
        .padding(.horizontal, 24)
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : -20)
    }
    
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
                if originalTimeBlock.status == .inProgress {
                    // Warning for active blocks
                    HStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(Color.anchorWarning)
                        
                        Text("Start time cannot be changed for active blocks")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Color.anchorWarning)
                        
                        Spacer()
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.anchorWarning.opacity(0.15))
                    )
                }
                
                // Time pickers
                HStack(spacing: 16) {
                    TimePicker(
                        title: "Start",
                        selection: $formData.startTime,
                        icon: "play.circle",
                        isDisabled: originalTimeBlock.status == .inProgress
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
                            .foregroundStyle(Color.white.opacity(0.8))
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
    
    private var historySection: some View {
        FormSection(
            title: "History",
            icon: "clock.arrow.circlepath",
            color: Color.white.opacity(0.6)
        ) {
            VStack(spacing: 12) {
                // Safely handle dates
                if originalTimeBlock.createdAt != Date.distantPast {
                    HistoryRow(
                        title: "Created",
                        date: originalTimeBlock.createdAt,
                        icon: "plus.circle"
                    )
                }
                
                if originalTimeBlock.updatedAt != originalTimeBlock.createdAt {
                    HistoryRow(
                        title: "Last Updated",
                        date: originalTimeBlock.updatedAt,
                        icon: "pencil.circle"
                    )
                }
                
                if originalTimeBlock.createdAt == Date.distantPast {
                    Text("No history available")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.5))
                }
            }
        }
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : 20)
    }
    
    private var actionButtons: some View {
        VStack(spacing: 16) {
            DesignedButton(
                title: formData.hasChanges ? "Save Changes" : "No Changes",
                style: formData.hasChanges ? .gradient : .secondary,
                action: saveChanges
            )
            .disabled(!formData.isFormValid || !formData.hasChanges)
            .opacity(formData.isFormValid && formData.hasChanges ? 1.0 : 0.6)
            
            SecondaryActionButton(
                title: "Cancel",
                icon: "xmark",
                action: handleDismiss
            )
        }
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : 20)
    }
    
    // MARK: - Actions
    
    private func handleDismiss() {
        if formData.hasChanges {
            showingDiscardConfirmation = true
        } else {
            dismiss()
        }
    }
    
    private func saveChanges() {
        formData.validateForm()
        
        guard formData.isFormValid else {
            showingValidationErrors = true
            return
        }
        
        // Create updated time block
        let updatedBlock = originalTimeBlock
        
        let (title, notes, category) = formData.prepareForSave()
        updatedBlock.title = title
        updatedBlock.startTime = formData.startTime
        updatedBlock.endTime = formData.endTime
        updatedBlock.notes = notes
        updatedBlock.category = category
        updatedBlock.icon = formData.selectedIcon.isEmpty ? nil : formData.selectedIcon
        updatedBlock.updatedAt = Date()
        
        onSave(updatedBlock)
        
        HapticManager.shared.anchorSuccess()
        dismiss()
    }
}

// MARK: - Preview
#Preview {
    let sampleBlock = TimeBlock(
        title: "Morning Routine",
        startTime: Date(),
        endTime: Date().addingTimeInterval(3600),
        notes: "Exercise, shower, breakfast",
        category: "Personal"
    )
    
    // Create some sample existing blocks to test conflict detection
    let existingBlocks = [
        TimeBlock(
            title: "Early Meeting",
            startTime: Date().addingTimeInterval(-1800), // 30 min before
            endTime: Date().addingTimeInterval(-600)     // 10 min before
        ),
        TimeBlock(
            title: "Lunch Break",
            startTime: Date().addingTimeInterval(7200),  // 2 hours after
            endTime: Date().addingTimeInterval(10800)    // 3 hours after
        ),
        TimeBlock(
            title: "Conflicting Block",
            startTime: Date().addingTimeInterval(1800),  // 30 min after (overlaps!)
            endTime: Date().addingTimeInterval(5400)     // 90 min after
        )
    ]
    
    return EditTimeBlockView(
        timeBlock: sampleBlock,
        existingTimeBlocks: existingBlocks // ← Add this parameter!
    ) { updatedBlock in
        print("Updated: \(updatedBlock.title)")
    }
}

// Alternative: Simple preview without conflicts
#Preview("No Conflicts") {
    let sampleBlock = TimeBlock(
        title: "Morning Routine",
        startTime: Date(),
        endTime: Date().addingTimeInterval(3600),
        notes: "Exercise, shower, breakfast",
        category: "Personal"
    )
    
    return EditTimeBlockView(
        timeBlock: sampleBlock,
        existingTimeBlocks: [] // ← Empty array = no conflicts
    ) { updatedBlock in
        print("Updated: \(updatedBlock.title)")
    }
}

// Preview for AddTimeBlockView too:
#Preview("Add Time Block") {
    let existingBlocks = [
        TimeBlock(
            title: "Existing Block",
            startTime: Date().addingTimeInterval(3600),
            endTime: Date().addingTimeInterval(7200)
        )
    ]
    
    AddTimeBlockView(
        existingTimeBlocks: existingBlocks
    ) { title, startTime, endTime, notes, category in
        print("Saving: \(title) from \(startTime) to \(endTime)")
    }
}
