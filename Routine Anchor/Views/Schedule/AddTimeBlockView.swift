//
//  AddTimeBlockView.swift
//  Routine Anchor
//
//  Created by Christopher Simonson on 7/19/25.
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
    
    // MARK: - State
    @State private var showingValidationErrors = false
    @State private var validationErrors: [String] = []
    @State private var isFormValid = false
    
    // MARK: - Callback
    let onSave: (String, Date, Date, String?, String?) -> Void
    
    // MARK: - Constants
    private let categories = ["Work", "Personal", "Health", "Learning", "Social", "Other"]
    private let icons = ["💼", "🏠", "💪", "📚", "👥", "🎯", "☕", "🍽️", "🧘", "🎵", "📱", "🚗"]
    
    init(onSave: @escaping (String, Date, Date, String?, String?) -> Void) {
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
            Form {
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
                    if startTime >= endTime {
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
                } footer: {
                    Text("Choose an icon to help identify this time block")
                }
                
                // Quick Duration Section
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
            .navigationTitle("New Time Block")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(Color.textSecondary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveTimeBlock()
                    }
                    .foregroundColor(isFormValid ? Color.primaryBlue : Color.textSecondary)
                    .fontWeight(.semibold)
                    .disabled(!isFormValid)
                }
            }
            .onChange(of: title) { _, _ in validateForm() }
            .onChange(of: startTime) { _, _ in validateForm() }
            .onChange(of: endTime) { _, _ in validateForm() }
            .onAppear {
                validateForm()
            }
        }
        .alert("Invalid Time Block", isPresented: $showingValidationErrors) {
            Button("OK") {}
        } message: {
            Text(validationErrors.joined(separator: "\n"))
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
        
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalNotes = trimmedNotes.isEmpty ? nil : trimmedNotes
        let finalCategory = category.isEmpty ? nil : category
        
        onSave(trimmedTitle, startTime, endTime, finalNotes, finalCategory)
        
        // Add haptic feedback
        HapticManager.shared.success()
        
        dismiss()
    }
}

// MARK: - Preview
#Preview {
    AddTimeBlockView { title, startTime, endTime, notes, category in
        print("Saving: \(title) from \(startTime) to \(endTime)")
    }
}
