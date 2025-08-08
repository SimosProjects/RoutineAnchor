//
//  PremiumEditTimeBlockView.swift
//  Routine Anchor - Premium Version
//
import SwiftUI

struct PremiumEditTimeBlockView: View {
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Original Data
    let originalTimeBlock: TimeBlock
    
    // MARK: - Form Data
    @State private var formData: TimeBlockFormData
    
    // MARK: - State
    @State private var showingValidationErrors = false
    @State private var showingDiscardAlert = false
    @State private var isVisible = false
    
    // MARK: - Callback
    let onSave: (TimeBlock) -> Void

    init(timeBlock: TimeBlock, onSave: @escaping (TimeBlock) -> Void) {
        self.originalTimeBlock = timeBlock
        self.onSave = onSave
        _formData = State(initialValue: TimeBlockFormData(from: timeBlock))
    }
    
    var body: some View {
        PremiumTimeBlockFormView(
            title: "Edit Time Block",
            icon: "pencil.circle",
            subtitle: "Refine your schedule",
            onDismiss: handleDismiss
        ) {
            VStack(spacing: 24) {
                // Status section (if block has been started)
                if originalTimeBlock.status != .notStarted {
                    statusSection
                }
                
                // Basic Information Section
                basicInfoSection
                
                // Time Section
                timeSection
                
                // Organization Section
                organizationSection
                
                // Icon Section
                iconSection
                
                // Quick Duration Section (only if not in progress)
                if originalTimeBlock.status != .inProgress {
                    quickDurationSection
                }
                
                // History Section (if block has history)
                if originalTimeBlock.status != .notStarted {
                    historySection
                }
                
                // Action Buttons
                actionButtons
            }
        }
        .onAppear {
            formData.validateForm()
            formData.checkForChanges()
            
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.3)) {
                isVisible = true
            }
        }
        .onChange(of: formData.title) { _, _ in
            formData.checkForChanges()
            formData.validateForm()
        }
        .onChange(of: formData.startTime) { _, _ in
            formData.checkForChanges()
            formData.validateForm()
        }
        .onChange(of: formData.endTime) { _, _ in
            formData.checkForChanges()
            formData.validateForm()
        }
        .onChange(of: formData.notes) { _, _ in formData.checkForChanges() }
        .onChange(of: formData.category) { _, _ in formData.checkForChanges() }
        .onChange(of: formData.selectedIcon) { _, _ in formData.checkForChanges() }
        .alert("Invalid Time Block", isPresented: $showingValidationErrors) {
            Button("OK") {}
        } message: {
            Text(formData.validationErrors.joined(separator: "\n"))
        }
        .alert("Discard Changes?", isPresented: $showingDiscardAlert) {
            Button("Discard", role: .destructive) {
                dismiss()
            }
            Button("Keep Editing", role: .cancel) {}
        } message: {
            Text("You have unsaved changes. Are you sure you want to discard them?")
        }
    }
    
    // MARK: - Status Section
    private var statusSection: some View {
        PremiumFormSection(
            title: "Current Status",
            icon: originalTimeBlock.status.iconName,
            color: statusColor
        ) {
            HStack(spacing: 16) {
                // Status indicator
                ZStack {
                    Circle()
                        .fill(statusColor.opacity(0.2))
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: originalTimeBlock.status.iconName)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(statusColor)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(originalTimeBlock.status.displayName)
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                    
                    if originalTimeBlock.status == .inProgress,
                       let remainingMinutes = originalTimeBlock.remainingMinutes {
                        Text("\(remainingMinutes) minutes remaining")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Color.premiumWarning)
                    } else {
                        Text("Status cannot be changed here")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Color.white.opacity(0.6))
                    }
                }
                
                Spacer()
            }
        }
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : 20)
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
    
    private var timeSection: some View {
        PremiumFormSection(
            title: "Schedule",
            icon: "clock",
            color: Color.premiumGreen
        ) {
            VStack(spacing: 16) {
                if originalTimeBlock.status == .inProgress {
                    // Warning for active blocks
                    HStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(Color.premiumWarning)
                        
                        Text("Start time cannot be changed for active blocks")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Color.premiumWarning)
                        
                        Spacer()
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.premiumWarning.opacity(0.15))
                    )
                }
                
                HStack(spacing: 16) {
                    PremiumTimePicker(
                        title: "Start",
                        selection: $formData.startTime,
                        icon: "play.circle",
                        isDisabled: originalTimeBlock.status == .inProgress
                    )
                    
                    PremiumTimePicker(
                        title: "End",
                        selection: $formData.endTime,
                        icon: "stop.circle"
                    )
                }
                
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
    
    private var quickDurationSection: some View {
        PremiumFormSection(
            title: "Quick Duration",
            icon: "timer",
            color: Color.premiumWarning
        ) {
            QuickDurationSelector { minutes in
                formData.setDuration(minutes: minutes)
            }
        }
        .opacity(isVisible ? 1 : 0)
        .offset(x: isVisible ? 0 : 20)
    }
    
    private var historySection: some View {
        PremiumFormSection(
            title: "History",
            icon: "clock.arrow.circlepath",
            color: Color.white.opacity(0.6)
        ) {
            VStack(spacing: 12) {
                HistoryRow(
                    title: "Created",
                    date: originalTimeBlock.createdAt,
                    icon: "plus.circle"
                )
                
                HistoryRow(
                    title: "Last Updated",
                    date: originalTimeBlock.updatedAt,
                    icon: "pencil.circle"
                )
            }
        }
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : 20)
    }
    
    private var actionButtons: some View {
        VStack(spacing: 16) {
            PremiumButton(
                title: formData.hasChanges ? "Save Changes" : "No Changes Made",
                style: .gradient,
                action: saveTimeBlock
            )
            .disabled(!formData.isFormValid || !formData.hasChanges)
            .opacity((formData.isFormValid && formData.hasChanges) ? 1.0 : 0.6)
            
            SecondaryActionButton(
                title: formData.hasChanges ? "Discard Changes" : "Close",
                icon: formData.hasChanges ? "trash" : "xmark",
                action: handleDismiss
            )
        }
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : 20)
    }
    
    // MARK: - Computed Properties
    
    private var statusColor: Color {
        switch originalTimeBlock.status {
        case .completed: return Color.premiumGreen
        case .inProgress: return Color.premiumBlue
        case .notStarted: return Color.premiumPurple
        case .skipped: return Color.premiumError
        }
    }
    
    // MARK: - Actions
    
    private func handleDismiss() {
        if formData.hasChanges {
            showingDiscardAlert = true
        } else {
            dismiss()
        }
    }
    
    private func saveTimeBlock() {
        formData.validateForm()
        
        guard formData.isFormValid else {
            showingValidationErrors = true
            return
        }
        
        // Update the time block with new values
        let (title, notes, category) = formData.prepareForSave()
        
        originalTimeBlock.title = title
        originalTimeBlock.startTime = formData.startTime
        originalTimeBlock.endTime = formData.endTime
        originalTimeBlock.notes = notes
        originalTimeBlock.category = category
        
        onSave(originalTimeBlock)
        
        HapticManager.shared.premiumSuccess()
        dismiss()
    }
}

// MARK: - Preview
#Preview {
    let sampleBlock = TimeBlock(
        title: "Morning Routine",
        startTime: Date(),
        endTime: Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date(),
        notes: "Start the day right",
        category: "Personal"
    )
    sampleBlock.icon = "🌅"
    
    return PremiumEditTimeBlockView(timeBlock: sampleBlock) { updatedBlock in
        print("Updated: \(updatedBlock.title)")
    }
}
