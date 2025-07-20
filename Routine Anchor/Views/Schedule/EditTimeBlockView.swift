//
//  EditTimeBlockView.swift
//  Routine Anchor
//
//  Created by Christopher Simonson on 7/19/25.
//
import SwiftUI

struct EditTimeBlockView: View {
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Original Data
    let originalTimeBlock: TimeBlock
    
    // MARK: - Form Data
    @State private var title = ""
    @State private var startTime = Date()
    @State private var endTime = Date()
    @State private var notes = ""
    @State private var category = ""
    @State private var selectedIcon = ""
    
    // MARK: - State
    @State private var showingValidationErrors = false
    @State private var validationErrors: [String] = []
    @State private var isFormValid = false
    @State private var hasChanges = false
    @State private var showingDiscardAlert = false
    
    // MARK: - Callback
    let onSave: (TimeBlock) -> Void
    
    // MARK: - Constants
    private let categories = ["Work", "Personal", "Health", "Learning", "Social", "Other"]
    private let icons = ["💼", "🏠", "💪", "📚", "👥", "🎯", "☕", "🍽️", "🧘", "🎵", "📱", "🚗"]
    
    init(timeBlock: TimeBlock, onSave: @escaping (TimeBlock) -> Void) {
        self.originalTimeBlock = timeBlock
        self.onSave = onSave
        
        // Initialize state with existing values
        self._title = State(initialValue: timeBlock.title)
        self._startTime = State(initialValue: timeBlock.startTime)
        self._endTime = State(initialValue: timeBlock.endTime)
        self._notes = State(initialValue: timeBlock.notes ?? "")
        self._category = State(initialValue: timeBlock.category ?? "")
        self._selectedIcon = State(initialValue: timeBlock.icon ?? "")
    }
    
    var body: some View {
        NavigationView {
            Form {
                // Status Section (if block has been started)
                if originalTimeBlock.status != .notStarted {
                    Section {
                        HStack {
                            originalTimeBlock.status.statusIndicator
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Current Status")
                                    .font(TypographyConstants.UI.caption)
                                    .foregroundColor(Color.textSecondary)
                                
                                Text(originalTimeBlock.status.displayName)
                                    .font(TypographyConstants.Body.emphasized)
                                    .foregroundColor(originalTimeBlock.status.color)
                            }
                            
                            Spacer()
                            
                            if originalTimeBlock.status == .inProgress,
                               let remainingMinutes = originalTimeBlock.remainingMinutes {
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text("Time Left")
                                        .font(TypographyConstants.UI.caption)
                                        .foregroundColor(Color.textSecondary)
                                    
                                    Text("\(remainingMinutes)m")
                                        .font(TypographyConstants.UI.timeBlock)
                                        .foregroundColor(Color.warningOrange)
                                        .fontWeight(.medium)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    } header: {
                        Text("Status")
                    } footer: {
                        if originalTimeBlock.status != .notStarted {
                            Text("This time block has been started. Changes will apply to future instances.")
                        }
                    }
                }
                
                // Basic Information Section
                Section {
                    TextField("Time block title", text: $title)
                        .font(TypographyConstants.Body.primary)
                    
                    TextField("Notes (optional)", text: $notes, axis: .vertical)
                        .font(TypographyConstants.Body.secondary)
                        .lineLimit(2...4)
                } header: {
                    Text("Basic Information")
                } footer: {
                    if !title.isEmpty && title.count < 3 {
                        Text("Title should be at least 3 characters")
                            .foregroundColor(Color.errorRed)
                    }
                }
                
                // Time Section
                Section {
                    DatePicker("Start time", selection: $startTime, displayedComponents: .hourAndMinute)
                        .font(TypographyConstants.Body.primary)
                        .disabled(originalTimeBlock.status == .inProgress)
                    
                    DatePicker("End time", selection: $endTime, displayedComponents: .hourAndMinute)
                        .font(TypographyConstants.Body.primary)
                    
                    HStack {
                        Text("Duration")
                            .font(TypographyConstants.Body.primary)
                        
                        Spacer()
                        
                        Text(formattedDuration)
                            .font(TypographyConstants.UI.timeBlock)
                            .foregroundColor(durationColor)
                            .fontWeight(.medium)
                    }
                } header: {
                    Text("Schedule")
                } footer: {
                    if originalTimeBlock.status == .inProgress {
                        Text("Start time cannot be changed for active blocks")
                            .foregroundColor(Color.warningOrange)
                    } else if startTime >= endTime {
                        Text("End time must be after start time")
                            .foregroundColor(Color.errorRed)
                    } else if durationMinutes > 480 {
                        Text("Long time blocks may be hard to complete")
                            .foregroundColor(Color.warningOrange)
                    }
                }
                
                // Category Section
                Section {
                    Picker("Category", selection: $category) {
                        Text("No Category").tag("")
                        ForEach(categories, id: \.self) { cat in
                            Text(cat).tag(cat)
                        }
                    }
                    .pickerStyle(.menu)
                    .font(TypographyConstants.Body.primary)
                } header: {
                    Text("Organization")
                }
                
                // Icon Section
                Section {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            // No icon option
                            Button {
                                selectedIcon = ""
                            } label: {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(selectedIcon.isEmpty ? Color.primaryBlue.opacity(0.2) : Color.clear)
                                    .frame(width: 44, height: 44)
                                    .overlay {
                                        Image(systemName: "minus.circle")
                                            .foregroundColor(selectedIcon.isEmpty ? Color.primaryBlue : Color.textSecondary)
                                    }
                                    .overlay {
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(selectedIcon.isEmpty ? Color.primaryBlue : Color.clear, lineWidth: 2)
                                    }
                            }
                            
                            // Icon options
                            ForEach(icons, id: \.self) { icon in
                                Button {
                                    selectedIcon = icon
                                } label: {
                                    Text(icon)
                                        .font(.system(size: 24))
                                        .frame(width: 44, height: 44)
                                        .background(selectedIcon == icon ? Color.primaryBlue.opacity(0.2) : Color.clear)
                                        .cornerRadius(8)
                                        .overlay {
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(selectedIcon == icon ? Color.primaryBlue : Color.clear, lineWidth: 2)
                                        }
                                }
                            }
                        }
                        .padding(.horizontal, 4)
                    }
                } header: {
                    Text("Icon (Optional)")
                }
                
                // Quick Duration Section (only if not in progress)
                if originalTimeBlock.status != .inProgress {
                    Section {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach([15, 30, 45, 60, 90, 120], id: \.self) { minutes in
                                    Button {
                                        setDuration(minutes: minutes)
                                    } label: {
                                        Text("\(minutes)m")
                                            .font(TypographyConstants.UI.caption)
                                            .fontWeight(.medium)
                                            .foregroundColor(Color.primaryBlue)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(Color.primaryBlue.opacity(0.1))
                                            .cornerRadius(6)
                                    }
                                }
                            }
                            .padding(.horizontal, 4)
                        }
                    } header: {
                        Text("Quick Duration")
                    } footer: {
                        Text("Tap to quickly set common durations")
                    }
                }
                
                // History Section (if block has history)
                if originalTimeBlock.status != .notStarted {
                    Section {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Created")
                                    .font(TypographyConstants.UI.caption)
                                    .foregroundColor(Color.textSecondary)
                                
                                Spacer()
                                
                                Text(originalTimeBlock.createdAt.formatted(date: .abbreviated, time: .shortened))
                                    .font(TypographyConstants.UI.caption)
                                    .foregroundColor(Color.textSecondary)
                            }
                            
                            HStack {
                                Text("Last Updated")
                                    .font(TypographyConstants.UI.caption)
                                    .foregroundColor(Color.textSecondary)
                                
                                Spacer()
                                
                                Text(originalTimeBlock.updatedAt.formatted(date: .abbreviated, time: .shortened))
                                    .font(TypographyConstants.UI.caption)
                                    .foregroundColor(Color.textSecondary)
                            }
                        }
                    } header: {
                        Text("History")
                    }
                }
            }
            .navigationTitle("Edit Time Block")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(hasChanges ? "Cancel" : "Done") {
                        if hasChanges {
                            showingDiscardAlert = true
                        } else {
                            dismiss()
                        }
                    }
                    .foregroundColor(Color.textSecondary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveTimeBlock()
                    }
                    .foregroundColor(isFormValid && hasChanges ? Color.primaryBlue : Color.textSecondary)
                    .fontWeight(.semibold)
                    .disabled(!isFormValid || !hasChanges)
                }
            }
            .onChange(of: title) { _, _ in checkForChanges(); validateForm() }
            .onChange(of: startTime) { _, _ in checkForChanges(); validateForm() }
            .onChange(of: endTime) { _, _ in checkForChanges(); validateForm() }
            .onChange(of: notes) { _, _ in checkForChanges() }
            .onChange(of: category) { _, _ in checkForChanges() }
            .onChange(of: selectedIcon) { _, _ in checkForChanges() }
            .onAppear {
                validateForm()
                checkForChanges()
            }
        }
        .alert("Invalid Time Block", isPresented: $showingValidationErrors) {
            Button("OK") {}
        } message: {
            Text(validationErrors.joined(separator: "\n"))
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
    
    // MARK: - Computed Properties
    
    private var durationMinutes: Int {
        max(0, Int(endTime.timeIntervalSince(startTime) / 60))
    }
    
    private var formattedDuration: String {
        let hours = durationMinutes / 60
        let minutes = durationMinutes % 60
        
        if hours > 0 && minutes > 0 {
            return "\(hours)h \(minutes)m"
        } else if hours > 0 {
            return "\(hours)h"
        } else {
            return "\(minutes)m"
        }
    }
    
    private var durationColor: Color {
        switch durationMinutes {
        case 0:
            return Color.errorRed
        case 1...30:
            return Color.warningOrange
        case 31...120:
            return Color.successGreen
        case 121...240:
            return Color.primaryBlue
        default:
            return Color.warningOrange
        }
    }
    
    // MARK: - Methods
    
    private func checkForChanges() {
        hasChanges = title != originalTimeBlock.title ||
                    startTime != originalTimeBlock.startTime ||
                    endTime != originalTimeBlock.endTime ||
                    notes != (originalTimeBlock.notes ?? "") ||
                    category != (originalTimeBlock.category ?? "") ||
                    selectedIcon != (originalTimeBlock.icon ?? "")
    }
    
    private func validateForm() {
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
        
        if durationMinutes < 1 {
            validationErrors.append("Duration must be at least 1 minute")
        }
        
        if durationMinutes > 24 * 60 {
            validationErrors.append("Duration cannot exceed 24 hours")
        }
        
        isFormValid = validationErrors.isEmpty
    }
    
    private func setDuration(minutes: Int) {
        endTime = Calendar.current.date(byAdding: .minute, value: minutes, to: startTime) ?? endTime
        validateForm()
    }
    
    private func saveTimeBlock() {
        validateForm()
        
        guard isFormValid else {
            showingValidationErrors = true
            return
        }
        
        // Update the time block with new values
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        
        originalTimeBlock.title = trimmedTitle
        originalTimeBlock.startTime = startTime
        originalTimeBlock.endTime = endTime
        originalTimeBlock.notes = trimmedNotes.isEmpty ? nil : trimmedNotes
        originalTimeBlock.category = category.isEmpty ? nil : category
        originalTimeBlock.icon = selectedIcon.isEmpty ? nil : selectedIcon
        
        onSave(originalTimeBlock)
        
        // Add haptic feedback
        HapticManager.shared.success()
        
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
    
    return EditTimeBlockView(timeBlock: sampleBlock) { updatedBlock in
        print("Updated: \(updatedBlock.title)")
    }
}
