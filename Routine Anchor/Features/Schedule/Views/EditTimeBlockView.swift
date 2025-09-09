//
//  EditTimeBlockView.swift
//  Routine Anchor
//
//  Edit-block sheet.
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

    // MARK: - Props
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

    private var theme: AppTheme { themeManager?.currentTheme ?? PredefinedThemes.classic }

    var body: some View {
        TimeBlockFormView(
            title: "Edit Time Block",
            icon: "pencil.circle",
            subtitle: "Update your schedule",
            onDismiss: handleDismiss
        ) {
            VStack(spacing: 24) {
                if originalTimeBlock.status == .inProgress {
                    activeBlockWarning
                }

                basicInfoSection
                timeAndDurationSection
                organizationSection
                iconSection

                if originalTimeBlock.createdAt != Date.distantPast {
                    historySection
                }

                actionButtons
            }
        }
        .onAppear {
            formData.setExistingTimeBlocks(existingTimeBlocks, excluding: originalTimeBlock.id)
            formData.validateForm()
            formData.checkForChanges()

            // Seed quick-duration if exact match
            let duration = Int(formData.endTime.timeIntervalSince(formData.startTime) / 60)
            if [15, 30, 45, 60, 90, 120].contains(duration) { selectedDuration = duration }

            withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.3)) {
                isVisible = true
            }
        }
        .onChange(of: formData.title) { _, _ in formData.validateForm(); formData.checkForChanges() }
        .onChange(of: formData.notes) { _, _ in formData.checkForChanges() }
        .onChange(of: formData.category) { _, _ in formData.checkForChanges() }
        .onChange(of: formData.selectedIcon) { _, _ in formData.checkForChanges() }
        .onChange(of: formData.startTime) { _, _ in onTimesChanged() }
        .onChange(of: formData.endTime) { _, _ in onTimesChanged() }
        .alert("Invalid Time Block", isPresented: $showingValidationErrors) {
            Button("OK") {}
        } message: {
            Text(formData.validationErrors.joined(separator: "\n"))
        }
        .confirmationDialog("Discard Changes?",
                            isPresented: $showingDiscardConfirmation,
                            titleVisibility: .visible) {
            Button("Discard", role: .destructive) { dismiss() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("You have unsaved changes. Are you sure you want to discard them?")
        }
    }

    // MARK: - Sections

    private var activeBlockWarning: some View {
        HStack(spacing: 12) {
            Image(systemName: "clock.badge.exclamationmark")
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(theme.accentPrimaryColor)

            VStack(alignment: .leading, spacing: 4) {
                Text("Currently Active")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(theme.primaryTextColor)

                Text("This time block is in progress")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(theme.secondaryTextColor)
            }
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(theme.accentPrimaryColor.opacity(0.15))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(theme.accentPrimaryColor.opacity(0.3), lineWidth: 1)
        )
        .padding(.horizontal, 24)
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : -20)
    }

    private var basicInfoSection: some View {
        FormSection(
            title: "Basic Information",
            icon: "doc.text",
            color: theme.accentPrimaryColor
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
            color: theme.statusSuccessColor
        ) {
            VStack(spacing: 20) {
                if originalTimeBlock.status == .inProgress {
                    HStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(theme.statusWarningColor)

                        Text("Start time cannot be changed for active blocks")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(theme.statusWarningColor)
                        Spacer()
                    }
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 10).fill(theme.statusWarningColor.opacity(0.15)))
                }

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

                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 8) {
                        Image(systemName: "timer")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(theme.statusWarningColor)
                        Text("Quick Duration")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(theme.primaryTextColor.opacity(0.8))
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

                let duration = Int(formData.endTime.timeIntervalSince(formData.startTime) / 60)
                DurationCard(minutes: duration, color: color(for: duration))
            }
        }
        .opacity(isVisible ? 1 : 0)
        .offset(x: isVisible ? 0 : 20)
    }

    private func color(for minutes: Int) -> Color {
        switch minutes {
        case ..<15: return theme.statusErrorColor
        case ..<60: return theme.statusWarningColor
        default:    return theme.statusSuccessColor
        }
    }

    private var organizationSection: some View {
        FormSection(
            title: "Organization",
            icon: "folder",
            color: theme.accentSecondaryColor
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
            color: theme.accentSecondaryColor
        ) {
            IconSelector(icons: formData.icons, selectedIcon: $formData.selectedIcon)
        }
        .opacity(isVisible ? 1 : 0)
        .offset(x: isVisible ? 0 : -20)
    }

    private var historySection: some View {
        FormSection(
            title: "History",
            icon: "clock.arrow.circlepath",
            color: theme.secondaryTextColor.opacity(0.85)
        ) {
            VStack(spacing: 12) {
                if originalTimeBlock.createdAt != Date.distantPast {
                    HistoryRow(title: "Created", date: originalTimeBlock.createdAt, icon: "plus.circle")
                }
                if originalTimeBlock.updatedAt != originalTimeBlock.createdAt {
                    HistoryRow(title: "Last Updated", date: originalTimeBlock.updatedAt, icon: "pencil.circle")
                }
                if originalTimeBlock.createdAt == Date.distantPast {
                    Text("No history available")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(theme.subtleTextColor)
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
                style: formData.hasChanges ? .gradient : .surface,
                isEnabled: formData.hasChanges,
                action: saveChanges
            )
            .disabled(!formData.isFormValid || !formData.hasChanges)
            .opacity(formData.isFormValid && formData.hasChanges ? 1.0 : 0.6)

            SecondaryActionButton(title: "Cancel", icon: "xmark", action: handleDismiss)
        }
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : 20)
    }

    // MARK: - Actions

    private func onTimesChanged() {
        formData.validateForm(); formData.checkForChanges()
        if selectedDuration != nil {
            let currentDuration = Int(formData.endTime.timeIntervalSince(formData.startTime) / 60)
            if currentDuration != selectedDuration { selectedDuration = nil }
        }
    }

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

#Preview {
    let sample = TimeBlock(title: "Morning Routine",
                           startTime: Date(),
                           endTime: Date().addingTimeInterval(3600),
                           notes: "Exercise, shower, breakfast",
                           category: "Personal")

    return EditTimeBlockView(timeBlock: sample, existingTimeBlocks: []) { _ in }
}
