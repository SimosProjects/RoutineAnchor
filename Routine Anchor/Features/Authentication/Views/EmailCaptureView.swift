//
//  EmailCaptureView.swift
//  Routine Anchor
//
//  Email capture modal for building the user list.
//

import SwiftUI

struct EmailCaptureView: View {
    // Env
    @Environment(\.dismiss) private var dismiss
    @Environment(\.themeManager) private var themeManager

    // Local state
    @State private var email = ""
    @State private var isLoading = false
    @State private var showThankYou = false
    @State private var errorMessage: String?

    /// Callback when a valid email is submitted
    let onEmailCaptured: (String) -> Void

    // Theme sugar
    private var theme: AppTheme { themeManager?.currentTheme ?? PredefinedThemes.classic }

    var body: some View {
        ZStack {
            // Hero background (replaces ThemedAnimatedBackground)
            theme.heroBackground.ignoresSafeArea()

            VStack(spacing: 32) {
                if showThankYou {
                    thankYouSection
                } else {
                    captureSection
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    // MARK: - Capture UI

    private var captureSection: some View {
        VStack(spacing: 32) {
            // Close
            HStack {
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(theme.primaryTextColor.opacity(0.7))
                }
                .buttonStyle(.plain)
            }

            // Header
            VStack(spacing: 16) {
                Image(systemName: "envelope.badge")
                    .font(.system(size: 60, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [theme.accentPrimaryColor, theme.accentSecondaryColor],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )

                Text("Stay in the Loop")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(theme.primaryTextColor)
                    .multilineTextAlignment(.center)

                Text("Get productivity tips, app updates, and early access to new features")
                    .font(.system(size: 16))
                    .foregroundStyle(theme.secondaryTextColor.opacity(0.85))
                    .multilineTextAlignment(.center)
            }

            // Benefits
            VStack(spacing: 16) {
                benefitRow(icon: "lightbulb", text: "Weekly productivity insights")
                benefitRow(icon: "star",      text: "Early access to new features")
                benefitRow(icon: "bell",      text: "App updates and announcements")
                benefitRow(icon: "gift",      text: "Exclusive tips and guides")
            }
            .padding(.vertical, 4)

            // Email input + actions
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    // Styled TextField to match theme
                    TextField("Enter your email", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                        .foregroundStyle(theme.primaryTextColor)
                        .padding(14)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(theme.surfaceCardColor.opacity(0.35))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(errorMessage == nil ? theme.borderColor.opacity(0.7) : theme.statusErrorColor, lineWidth: 1)
                        )
                        .onSubmit { submitEmail() }

                    if let error = errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(theme.statusErrorColor)
                    }
                }

                // Primary action
                DesignedButton(
                    title: isLoading ? "Submitting..." : "Stay Updated",
                    style: .gradient,
                    size: .medium,
                    fullWidth: true,
                    isEnabled: isValidEmail(email),
                    isLoading: isLoading,
                    action: { submitEmail() }
                )

                // Secondary
                Button("Maybe Later") { dismiss() }
                    .font(.system(size: 14))
                    .foregroundStyle(theme.primaryTextColor.opacity(0.75))
                    .buttonStyle(.plain)
            }

            Text("We respect your privacy. Unsubscribe anytime.")
                .font(.system(size: 12))
                .foregroundStyle(theme.subtleTextColor)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Thank You UI

    private var thankYouSection: some View {
        VStack(spacing: 32) {
            Spacer(minLength: 8)

            VStack(spacing: 24) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80, weight: .medium))
                    .foregroundStyle(theme.statusSuccessColor)

                VStack(spacing: 16) {
                    Text("Thank You!")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(theme.primaryTextColor)

                    Text("Check your email for a welcome message with productivity tips to get started.")
                        .font(.system(size: 16))
                        .foregroundStyle(theme.secondaryTextColor.opacity(0.9))
                        .multilineTextAlignment(.center)
                }
            }

            Spacer(minLength: 8)

            DesignedButton(
                title: "Continue",
                style: .gradient,
                size: .medium,
                fullWidth: true
            ) {
                dismiss()
            }
        }
    }

    // MARK: - Benefit Row

    private func benefitRow(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(theme.statusSuccessColor)
                .frame(width: 20)

            Text(text)
                .font(.system(size: 14))
                .foregroundStyle(theme.secondaryTextColor)

            Spacer()
        }
    }

    // MARK: - Actions

    private func submitEmail() {
        guard isValidEmail(email) else {
            errorMessage = "Please enter a valid email address"
            return
        }
        errorMessage = nil
        isLoading = true

        // Simulated API call
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            isLoading = false
            onEmailCaptured(email)

            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                showThankYou = true
            }

            // Auto-dismiss shortly after showing the thank-you
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                dismiss()
            }
        }
    }

    private func isValidEmail(_ email: String) -> Bool {
        let regex = #"[A-Z0-9a-z._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,64}"#
        return NSPredicate(format: "SELF MATCHES %@", regex).evaluate(with: email)
    }
}

#Preview {
    EmailCaptureView { email in
        print("Captured email: \(email)")
    }
    .environment(\.themeManager, ThemeManager.preview())
    .preferredColorScheme(.dark)
}
