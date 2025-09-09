//
//  AddTimeBlockView.swift
//  Routine Anchor
//
//  New-block sheet.
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

    private var theme: AppTheme { themeManager?.currentTheme ?? PredefinedThemes.classic }

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

                basicInfoSection
                timeAndDurationSection
                organizationSection
                iconSection
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
        .onChange(of: formData.startTime) { _, _ in handleManualTimeChange() }
        .onChange(of: formData.endTime) { _, _ in handleManualTimeChange() }
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
                HStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(theme.statusWarningColor)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Time Conflict")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(theme.primaryTextColor)

                        if conflicts.count == 1 {
                            Text("Overlaps with '\(conflicts.first!.title)'")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(theme.secondaryTextColor)
                        } else {
                            Text("Overlaps with \(conflicts.count) time blocks")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(theme.secondaryTextColor)
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
                    .foregroundStyle(theme.accentPrimaryColor)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(theme.surfaceCardColor.opacity(0.65))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(theme.borderColor.opacity(0.8), lineWidth: 1)
                            )
                    )
                }
                .buttonStyle(.plain)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(theme.surfaceCardColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                LinearGradient(
                                    colors: [theme.statusWarningColor.opacity(0.6),
                                             theme.statusWarningColor.opacity(0.2)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                    )
            )
            .shadow(color: theme.statusWarningColor.opacity(0.18), radius: 8, x: 0, y: 4)
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
                HStack(spacing: 16) {
                    TimePicker(title: "Start", selection: $formData.startTime, icon: "play.circle")
                    TimePicker(title: "End",   selection: $formData.endTime,   icon: "stop.circle")
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

    private var actionButtons: some View {
        VStack(spacing: 16) {
            DesignedButton(
                title: "Create Time Block",
                style: .gradient,
                action: saveTimeBlock
            )
            .disabled(!formData.isFormValid)
            .opacity(formData.isFormValid ? 1.0 : 0.6)

            SecondaryActionButton(title: "Cancel", icon: "xmark") { dismiss() }
        }
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : 20)
    }

    // MARK: - Actions

    private func handleManualTimeChange() {
        formData.validateForm()
        if selectedDuration != nil {
            let currentDuration = Int(formData.endTime.timeIntervalSince(formData.startTime) / 60)
            if currentDuration != selectedDuration { selectedDuration = nil }
        }
    }

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

#Preview {
    AddTimeBlockView { title, start, end, notes, category in
        print("Saving: \(title) from \(start) to \(end)")
    }
}
