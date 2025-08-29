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
    
    // MARK: - State
    @State private var marketingEmails = true
    @State private var productUpdates = true
    @State private var coursesAndTips = true
    @State private var showingUnsubscribeConfirmation = false
    @State private var isLoading = false
    @State private var showingSuccess = false
    
    var body: some View {
        ZStack {
            // Background
            ThemedAnimatedBackground()
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 32) {
                    // Header
                    headerSection
                    
                    // Email Display
                    emailDisplaySection
                    
                    // Preferences
                    preferencesSection
                    
                    // Actions
                    actionsSection
                    
                    // Unsubscribe
                    unsubscribeSection
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 32)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    dismiss()
                }
                .foregroundStyle(themeManager?.currentTheme.textPrimaryColor ?? Theme.defaultTheme.textPrimaryColor)
            }
        }
        .onAppear {
            loadPreferences()
        }
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
            Button("Unsubscribe", role: .destructive) {
                unsubscribeFromAll()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will remove your email from all communications. You can always re-subscribe later in Settings.")
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "envelope.badge")
                .font(.system(size: 50, weight: .medium))
                .foregroundStyle(
                    LinearGradient(
                        colors: [themeManager?.currentTheme.colorScheme.blue.color ?? Theme.defaultTheme.colorScheme.blue.color, themeManager?.currentTheme.colorScheme.purple.color ?? Theme.defaultTheme.colorScheme.purple.color],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            VStack(spacing: 8) {
                Text("Email Preferences")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(themeManager?.currentTheme.textPrimaryColor ?? Theme.defaultTheme.textPrimaryColor)
                
                Text("Choose what you'd like to receive from us")
                    .font(.system(size: 16))
                    .foregroundStyle((themeManager?.currentTheme.textPrimaryColor ?? Theme.defaultTheme.textPrimaryColor).opacity(0.8))
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    // MARK: - Email Display Section
    private var emailDisplaySection: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "person.circle")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(themeManager?.currentTheme.colorScheme.blue.color ?? Theme.defaultTheme.colorScheme.blue.color)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Email Address")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle((themeManager?.currentTheme.textPrimaryColor ?? Theme.defaultTheme.textPrimaryColor).opacity(0.7))
                    
                    Text(authManager.userEmail ?? "No email")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(themeManager?.currentTheme.textPrimaryColor ?? Theme.defaultTheme.textPrimaryColor)
                }
                
                Spacer()
                
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(themeManager?.currentTheme.colorScheme.green.color ?? Theme.defaultTheme.colorScheme.green.color)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(themeManager?.currentTheme.colorScheme.blue.color ?? Theme.defaultTheme.colorScheme.blue.color.opacity(0.3), lineWidth: 1)
                    )
            )
        }
    }
    
    // MARK: - Preferences Section
    private var preferencesSection: some View {
        VStack(spacing: 20) {
            Text("Email Types")
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .foregroundStyle(themeManager?.currentTheme.textPrimaryColor ?? Theme.defaultTheme.textPrimaryColor)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 16) {
                EmailPreferenceToggle(
                    icon: "lightbulb.fill",
                    title: "Productivity Tips",
                    description: "Weekly productivity insights",
                    isOn: $coursesAndTips,
                    color: themeManager?.currentTheme.colorScheme.warning.color ?? Theme.defaultTheme.colorScheme.warning.color
                )
                
                EmailPreferenceToggle(
                    icon: "app.badge",
                    title: "Product Updates",
                    description: "New features and announcements",
                    isOn: $productUpdates,
                    color: themeManager?.currentTheme.colorScheme.blue.color ?? Theme.defaultTheme.colorScheme.blue.color
                )
                
                EmailPreferenceToggle(
                    icon: "graduationcap.fill",
                    title: "Development Courses",
                    description: "iOS app building tutorials",
                    isOn: $marketingEmails,
                    color: themeManager?.currentTheme.colorScheme.green.color ?? Theme.defaultTheme.colorScheme.green.color
                )
            }
        }
    }
    
    // MARK: - Actions Section
    private var actionsSection: some View {
        VStack(spacing: 16) {
            Button(action: savePreferences) {
                HStack {
                    if isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                            .foregroundStyle(themeManager?.currentTheme.textPrimaryColor ?? Theme.defaultTheme.textPrimaryColor)
                    } else {
                        Text("Save Preferences")
                            .font(.system(size: 16, weight: .semibold))
                    }
                }
                .foregroundStyle(themeManager?.currentTheme.textPrimaryColor ?? Theme.defaultTheme.textPrimaryColor)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    LinearGradient(
                        colors: [themeManager?.currentTheme.colorScheme.blue.color ?? Theme.defaultTheme.colorScheme.blue.color, themeManager?.currentTheme.colorScheme.purple.color ?? Theme.defaultTheme.colorScheme.purple.color],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
                .disabled(isLoading)
            }
            
            Text("We respect your privacy and will never spam you. You can change these preferences anytime.")
                .font(.system(size: 12))
                .foregroundStyle((themeManager?.currentTheme.textSecondaryColor ?? Theme.defaultTheme.textSecondaryColor).opacity(0.85))
                .multilineTextAlignment(.center)
        }
    }
    
    // MARK: - Unsubscribe Section
    private var unsubscribeSection: some View {
        VStack(spacing: 16) {
            Divider()
                .background((themeManager?.currentTheme.colorScheme.surfaceSecondary.color ?? Theme.defaultTheme.colorScheme.surfaceSecondary.color))
            
            VStack(spacing: 12) {
                Text("Don't want any emails?")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle((themeManager?.currentTheme.textPrimaryColor ?? Theme.defaultTheme.textPrimaryColor).opacity(0.8))
                
                Button("Unsubscribe from All") {
                    showingUnsubscribeConfirmation = true
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(themeManager?.currentTheme.colorScheme.warning.color ?? Theme.defaultTheme.colorScheme.warning.color)
            }
        }
    }
    
    // MARK: - Actions
    private func loadPreferences() {
        marketingEmails = UserDefaults.standard.bool(forKey: "emailPref_marketing")
        productUpdates = UserDefaults.standard.bool(forKey: "emailPref_productUpdates")
        coursesAndTips = UserDefaults.standard.bool(forKey: "emailPref_courses")
        
        // Default to true if never set
        if !UserDefaults.standard.objectExists(forKey: "emailPref_marketing") {
            marketingEmails = true
        }
        if !UserDefaults.standard.objectExists(forKey: "emailPref_productUpdates") {
            productUpdates = true
        }
        if !UserDefaults.standard.objectExists(forKey: "emailPref_courses") {
            coursesAndTips = true
        }
    }
    
    private func savePreferences() {
        isLoading = true
        
        // Simulate API call delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            authManager.updateEmailPreferences(
                marketing: marketingEmails,
                productUpdates: productUpdates,
                courses: coursesAndTips
            )
            
            isLoading = false
            HapticManager.shared.anchorSuccess()
            
            // Dismiss after successful save
            dismiss()
        }
    }
    
    private func unsubscribeFromAll() {
        marketingEmails = false
        productUpdates = false
        coursesAndTips = false
        
        savePreferences()
    }
}

// MARK: - Email Preference Toggle
struct EmailPreferenceToggle: View {
    @Environment(\.themeManager) private var themeManager
    let icon: String
    let title: String
    let description: String
    @Binding var isOn: Bool
    let color: Color
    
    var body: some View {
        VStack(spacing: 0) {
            // Header row with title and toggle
            HStack(spacing: 12) {
                // Icon
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(color)
                }
                
                // Title - allow it to expand and shrink as needed
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(themeManager?.currentTheme.textPrimaryColor ?? Theme.defaultTheme.textPrimaryColor)
                    .lineLimit(1)
                    .layoutPriority(1) // Give title priority over spacer
                    .minimumScaleFactor(0.8) // Allow slight text scaling if needed
                
                Spacer(minLength: 20) // Ensure minimum space between title and toggle
                
                // Toggle
                Toggle("", isOn: $isOn)
                    .toggleStyle(SwitchToggleStyle(tint: color))
                    .fixedSize() // Prevent toggle from being compressed
            }
            
            // Description row (separate, full width) - THIS WAS MISSING
            if !description.isEmpty {
                HStack {
                    Text(description)
                        .font(.system(size: 13))
                        .foregroundStyle((themeManager?.currentTheme.textSecondaryColor ?? Theme.defaultTheme.textSecondaryColor).opacity(0.85))
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    Spacer()
                }
                .padding(.top, 8)
                .padding(.leading, 48) // Align with title text (icon width + spacing)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            isOn ? color.opacity(0.3) : Color(themeManager?.currentTheme.colorScheme.surfacePrimary.color ?? Theme.defaultTheme.colorScheme.surfacePrimary.color),
                            lineWidth: 1
                        )
                )
        )
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isOn)
    }
}

// MARK: - UserDefaults Helper Extension
extension UserDefaults {
    func objectExists(forKey defaultName: String) -> Bool {
        return object(forKey: defaultName) != nil
    }
}

#Preview {
    NavigationStack {
        EmailPreferencesView()
            .environmentObject(AuthenticationManager())
    }
}
