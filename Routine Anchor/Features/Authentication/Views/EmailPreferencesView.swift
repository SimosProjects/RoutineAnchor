//
//  EmailPreferencesView.swift
//  Routine Anchor
//
//  Email preferences and subscription management
//

import SwiftUI

struct EmailPreferencesView: View {
    @Environment(\.themeManager) private var themeManager
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authManager: AuthenticationManager

    // Theme shortcut (falls back to Classic)
    private var theme: AppTheme { themeManager?.currentTheme ?? PredefinedThemes.classic }

    // MARK: - State
    @State private var marketingEmails = true
    @State private var productUpdates = true
    @State private var coursesAndTips = true
    @State private var showingUnsubscribeConfirmation = false
    @State private var isLoading = false
    @State private var showingSuccess = false

    var body: some View {
        ZStack {
            // Screen background from theme (hero gradient + vignette)
            theme.heroBackground.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 32) {
                    headerSection
                    emailDisplaySection
                    preferencesSection
                    actionsSection
                    unsubscribeSection
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 32)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") { dismiss() }
                    .foregroundStyle(theme.primaryTextColor)
                    .buttonStyle(.plain)
            }
        }
        .onAppear(perform: loadPreferences)
        .alert("Preferences Saved", isPresented: $showingSuccess) {
            Button("OK") { dismiss() }
        } message: {
            Text("Your email preferences have been updated successfully.")
        }
        .confirmationDialog(
            "Unsubscribe from All",
            isPresented: $showingUnsubscribeConfirmation,
            titleVisibility: .visible
        ) {
            Button("Unsubscribe", role: .destructive, action: unsubscribeFromAll)
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will remove your email from all communications. You can always re-subscribe later in Settings.")
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "envelope.badge")
                .font(.system(size: 50, weight: .medium))
                .foregroundStyle(
                    LinearGradient(colors: [theme.accentPrimaryColor, theme.accentSecondaryColor],
                                   startPoint: .topLeading, endPoint: .bottomTrailing)
                )

            VStack(spacing: 8) {
                Text("Email Preferences")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(theme.primaryTextColor)

                Text("Choose what you'd like to receive from us")
                    .font(.system(size: 16))
                    .foregroundStyle(theme.secondaryTextColor.opacity(0.8))
                    .multilineTextAlignment(.center)
            }
        }
    }

    // MARK: - Email Display

    private var emailDisplaySection: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "person.circle")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(theme.accentPrimaryColor)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Email Address")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(theme.secondaryTextColor.opacity(0.7))

                    Text(authManager.userEmail ?? "No email")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(theme.primaryTextColor)
                }

                Spacer()

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(theme.statusSuccessColor)
            }
            .padding(16)
            .background(
                // Glassy card with subtle border
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous).fill(.ultraThinMaterial)
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(theme.borderColor, lineWidth: 1)
                }
            )
        }
    }

    // MARK: - Preferences

    private var preferencesSection: some View {
        VStack(spacing: 20) {
            Text("Email Types")
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .foregroundStyle(theme.primaryTextColor)
                .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: 16) {
                EmailPreferenceToggle(
                    icon: "lightbulb.fill",
                    title: "Productivity Tips",
                    description: "Weekly productivity insights",
                    isOn: $coursesAndTips,
                    color: theme.statusWarningColor   // semantic: guidance/tips
                )
                EmailPreferenceToggle(
                    icon: "app.badge",
                    title: "Product Updates",
                    description: "New features and announcements",
                    isOn: $productUpdates,
                    color: theme.accentPrimaryColor   // semantic: main accent
                )
                EmailPreferenceToggle(
                    icon: "graduationcap.fill",
                    title: "Development Courses",
                    description: "iOS app building tutorials",
                    isOn: $marketingEmails,
                    color: theme.statusSuccessColor   // semantic: positive/education
                )
            }
        }
    }

    // MARK: - Actions

    private var actionsSection: some View {
        VStack(spacing: 16) {
            Button(action: savePreferences) {
                HStack {
                    if isLoading {
                        ProgressView().scaleEffect(0.8)
                    } else {
                        Text("Save Preferences")
                            .font(.system(size: 16, weight: .semibold))
                    }
                }
                .foregroundStyle(theme.invertedTextColor)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    LinearGradient(colors: [theme.accentPrimaryColor, theme.accentSecondaryColor],
                                   startPoint: .leading, endPoint: .trailing)
                )
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .shadow(color: theme.accentPrimaryColor.opacity(0.25), radius: 10, x: 0, y: 5)
            }
            .buttonStyle(.plain)
            .disabled(isLoading)

            Text("We respect your privacy and will never spam you. You can change these preferences anytime.")
                .font(.system(size: 12))
                .foregroundStyle(theme.secondaryTextColor.opacity(0.85))
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Unsubscribe

    private var unsubscribeSection: some View {
        VStack(spacing: 16) {
            Divider().background(theme.borderColor)

            VStack(spacing: 12) {
                Text("Don't want any emails?")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(theme.primaryTextColor.opacity(0.8))

                Button("Unsubscribe from All") {
                    showingUnsubscribeConfirmation = true
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(theme.statusWarningColor)
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Logic

    /// Loads persisted user preferences (defaults to `true` if never set).
    private func loadPreferences() {
        let d = UserDefaults.standard

        // Read booleans (default to true if the key doesn't exist)
        marketingEmails = d.objectExists(forKey: "emailPref_marketing") ? d.bool(forKey: "emailPref_marketing") : true
        productUpdates = d.objectExists(forKey: "emailPref_productUpdates") ? d.bool(forKey: "emailPref_productUpdates") : true
        coursesAndTips = d.objectExists(forKey: "emailPref_courses") ? d.bool(forKey: "emailPref_courses") : true
    }

    private func savePreferences() {
        isLoading = true

        // Simulate API write with a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            authManager.updateEmailPreferences(
                marketing: marketingEmails,
                productUpdates: productUpdates,
                courses: coursesAndTips
            )

            isLoading = false
            HapticManager.shared.anchorSuccess()
            showingSuccess = true
        }
    }

    private func unsubscribeFromAll() {
        marketingEmails = false
        productUpdates = false
        coursesAndTips = false
        savePreferences()
    }
}

// MARK: - Email Preference Toggle Row

/// Compact, glassy toggle row used in the preferences list.
struct EmailPreferenceToggle: View {
    @Environment(\.themeManager) private var themeManager
    let icon: String
    let title: String
    let description: String
    @Binding var isOn: Bool
    let color: Color

    private var theme: AppTheme { themeManager?.currentTheme ?? PredefinedThemes.classic }

    var body: some View {
        VStack(spacing: 0) {
            // Title row
            HStack(spacing: 12) {
                ZStack {
                    Circle().fill(color.opacity(0.15)).frame(width: 36, height: 36)
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(color)
                }

                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(theme.primaryTextColor)
                    .lineLimit(1)
                    .layoutPriority(1)
                    .minimumScaleFactor(0.8)

                Spacer(minLength: 20)

                Toggle("", isOn: $isOn)
                    .toggleStyle(SwitchToggleStyle(tint: color))
                    .fixedSize()
            }

            // Description row
            if !description.isEmpty {
                HStack {
                    Text(description)
                        .font(.system(size: 13))
                        .foregroundStyle(theme.secondaryTextColor.opacity(0.85))
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                    Spacer()
                }
                .padding(.top, 8)
                .padding(.leading, 48) // aligns under title (icon 36 + 12 spacing)
            }
        }
        .padding(16)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous).fill(.ultraThinMaterial)
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(isOn ? color.opacity(0.30) : theme.borderColor, lineWidth: 1)
            }
        )
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isOn)
    }
}

// MARK: - UserDefaults small helper

extension UserDefaults {
    func objectExists(forKey defaultName: String) -> Bool {
        object(forKey: defaultName) != nil
    }
}

#Preview {
    NavigationStack {
        EmailPreferencesView()
            .environment(\.themeManager, ThemeManager.preview())
            .environmentObject(AuthenticationManager())
    }
}
