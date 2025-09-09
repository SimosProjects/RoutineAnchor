//
//  SettingsComponents.swift
//  Routine Anchor
//

import SwiftUI
import SwiftData

// MARK: - Settings Section Container

struct SettingsSection<Content: View>: View {
    @Environment(\.themeManager) private var themeManager

    let title: String
    let icon: String
    let color: Color
    let content: Content

    @State private var isVisible = false

    private var theme: AppTheme { themeManager?.currentTheme ?? PredefinedThemes.classic }

    init(title: String, icon: String, color: Color, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.color = color
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section header
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(color)
                    .frame(width: 24, height: 24)

                Text(title)
                    .font(TypographyConstants.Headers.cardTitle)
                    .foregroundStyle(theme.primaryTextColor)

                Spacer()
            }

            // Section content
            content
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(theme.surfaceCardColor.opacity(0.9))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(
                    LinearGradient(colors: [color.opacity(0.30), color.opacity(0.10)],
                                   startPoint: .topLeading, endPoint: .bottomTrailing),
                    lineWidth: 1
                )
        )
        .shadow(color: .black.opacity(0.18), radius: 8, x: 0, y: 4)
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : 20)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
                isVisible = true
            }
        }
    }
}

// MARK: - Toggle Row

struct SettingsToggle: View {
    @Environment(\.themeManager) private var themeManager

    let title: String
    let subtitle: String
    @Binding var isOn: Bool
    let icon: String

    private var theme: AppTheme { themeManager?.currentTheme ?? PredefinedThemes.classic }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(theme.accentPrimaryColor)
                .frame(width: 24, height: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(TypographyConstants.Body.emphasized)
                    .foregroundStyle(theme.primaryTextColor)

                Text(subtitle)
                    .font(TypographyConstants.UI.caption)
                    .foregroundStyle(theme.secondaryTextColor)
            }

            Spacer()

            Toggle("", isOn: $isOn)
                .labelsHidden()
                .toggleStyle(DesignedToggleStyle())
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Custom Toggle Style

struct DesignedToggleStyle: ToggleStyle {
    @Environment(\.themeManager) private var themeManager
    private var theme: AppTheme { themeManager?.currentTheme ?? PredefinedThemes.classic }

    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label

            let onColor  = theme.statusSuccessColor
            let offColor = theme.iconMutedColor

            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(configuration.isOn ? onColor : offColor.opacity(0.6))
                .frame(width: 44, height: 26)
                .overlay(
                    Circle()
                        .fill(theme.primaryTextColor)
                        .frame(width: 22, height: 22)
                        .offset(x: configuration.isOn ? 9 : -9)
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isOn)
                )
                .onTapGesture { configuration.isOn.toggle() }
        }
    }
}

// MARK: - Button Row

struct SettingsButton: View {
    @Environment(\.themeManager) private var themeManager

    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let action: () -> Void

    private var theme: AppTheme { themeManager?.currentTheme ?? PredefinedThemes.classic }

    var body: some View {
        Button {
            HapticManager.shared.lightImpact()
            action()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(color)
                    .frame(width: 24, height: 24)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(TypographyConstants.Body.emphasized)
                        .foregroundStyle(theme.primaryTextColor)

                    Text(subtitle)
                        .font(TypographyConstants.UI.caption)
                        .foregroundStyle(theme.secondaryTextColor)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(theme.secondaryTextColor)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - DatePicker Row

struct SettingsDatePicker: View {
    @Environment(\.themeManager) private var themeManager
    let title: String
    let subtitle: String
    @Binding var selection: Date
    let icon: String

    private var theme: AppTheme { themeManager?.currentTheme ?? PredefinedThemes.classic }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(theme.accentPrimaryColor)
                .frame(width: 24, height: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(TypographyConstants.Body.emphasized)
                    .foregroundStyle(theme.primaryTextColor)

                Text(subtitle)
                    .font(TypographyConstants.UI.caption)
                    .foregroundStyle(theme.secondaryTextColor)
            }

            Spacer()

            DatePicker("", selection: $selection, displayedComponents: .hourAndMinute)
                .labelsHidden()
                .datePickerStyle(.compact)
                .tint(theme.accentPrimaryColor)
        }
    }
}

// MARK: - Picker Row

struct SettingsPicker: View {
    @Environment(\.themeManager) private var themeManager
    let title: String
    let subtitle: String
    let icon: String
    let options: [String]
    @Binding var selection: String

    private var theme: AppTheme { themeManager?.currentTheme ?? PredefinedThemes.classic }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(theme.accentPrimaryColor)
                .frame(width: 24, height: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(TypographyConstants.Body.emphasized)
                    .foregroundStyle(theme.primaryTextColor)

                Text(subtitle)
                    .font(TypographyConstants.UI.caption)
                    .foregroundStyle(theme.secondaryTextColor)
            }

            Spacer()

            Picker("", selection: $selection) {
                ForEach(options, id: \.self) { option in
                    Text(option).tag(option)
                }
            }
            .pickerStyle(.menu)
            .tint(theme.accentPrimaryColor)
        }
    }
}
