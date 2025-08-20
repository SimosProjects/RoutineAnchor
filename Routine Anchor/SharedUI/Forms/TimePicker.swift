//
//  TimePicker.swift
//  Routine Anchor
//
//  Created by Christopher Simonson on 7/23/25.
//
import SwiftUI

struct TimePicker: View {
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
                    .foregroundStyle(isDisabled ? Color.white.opacity(0.4) : Color.anchorGreen)

                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(isDisabled ? Color.white.opacity(0.4) : .white)
            }

            DatePicker("", selection: $selection, displayedComponents: .hourAndMinute)
                .datePickerStyle(.compact)
                .labelsHidden()
                .accentColor(Color.anchorGreen)
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

