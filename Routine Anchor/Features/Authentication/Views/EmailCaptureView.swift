//
//  EmailCaptureView.swift
//  Routine Anchor
//
//  Email capture modal for building user list
//
import SwiftUI

struct EmailCaptureView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.themeManager) private var themeManager
    @State private var email = ""
    @State private var isLoading = false
    @State private var showThankYou = false
    @State private var errorMessage: String?
    
    private var themeSecondaryText: Color {
        themeManager?.currentTheme.secondaryTextColor ?? Theme.defaultTheme.secondaryTextColor
    }

    private var themeTertiaryText: Color {
        themeManager?.currentTheme.subtleTextColor ?? Theme.defaultTheme.subtleTextColor
    }
    
    let onEmailCaptured: (String) -> Void
    
    var body: some View {
        ZStack {
            // Background
            ThemedAnimatedBackground()
                .ignoresSafeArea()
            
            VStack(spacing: 32) {
                if showThankYou {
                    thankYouContent
                } else {
                    emailCaptureContent
                }
            }
            .padding(.horizontal, 24)
        }
        .navigationBarHidden(true)
    }
    
    // MARK: - Email Capture Content
    private var emailCaptureContent: some View {
        VStack(spacing: 32) {
            // Close button
            HStack {
                Spacer()
                Button(action: {
                    // Close button - just dismiss normally
                    dismiss()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle((themeManager?.currentTheme.primaryTextColor ?? Theme.defaultTheme.primaryTextColor).opacity(0.7))
                }
            }
            
            // Header
            VStack(spacing: 16) {
                Image(systemName: "envelope.badge")
                    .font(.system(size: 60, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [themeManager?.currentTheme.colorScheme.normal.color ?? Theme.defaultTheme.colorScheme.normal.color, themeManager?.currentTheme.colorScheme.primaryAccent.color ?? Theme.defaultTheme.colorScheme.primaryAccent.color],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                Text("Stay in the Loop")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(themeManager?.currentTheme.primaryTextColor ?? Theme.defaultTheme.primaryTextColor)
                    .multilineTextAlignment(.center)
                
                Text("Get productivity tips, app updates, and early access to new features")
                    .font(.system(size: 16))
                    .foregroundStyle((themeManager?.currentTheme.primaryTextColor ?? Theme.defaultTheme.primaryTextColor).opacity(0.8))
                    .multilineTextAlignment(.center)
            }
            
            // Benefits
            VStack(spacing: 16) {
                benefitRow(icon: "lightbulb", text: "Weekly productivity insights")
                benefitRow(icon: "star", text: "Early access to new features")
                benefitRow(icon: "bell", text: "App updates and announcements")
                benefitRow(icon: "gift", text: "Exclusive tips and guides")
            }
            .padding(.vertical, 16)
            
            // Email input
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    TextField("Enter your email", text: $email)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .onSubmit {
                            submitEmail()
                        }
                    
                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
                
                Button(action: submitEmail) {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                                .foregroundStyle(themeManager?.currentTheme.primaryTextColor ?? Theme.defaultTheme.primaryTextColor)
                        } else {
                            Text("Stay Updated")
                                .font(.system(size: 16, weight: .semibold))
                        }
                    }
                    .foregroundStyle(themeManager?.currentTheme.primaryTextColor ?? Theme.defaultTheme.primaryTextColor)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(
                        LinearGradient(
                            colors: [themeManager?.currentTheme.colorScheme.success.color ?? Theme.defaultTheme.colorScheme.success.color, themeManager?.currentTheme.colorScheme.secondaryUIElement.color ?? Theme.defaultTheme.colorScheme.secondaryUIElement.color],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                    .disabled(isLoading || email.isEmpty)
                }
                
                Button("Maybe Later") {
                    // "Maybe Later" - just dismiss normally
                    dismiss()
                }
                .font(.system(size: 14))
                .foregroundStyle((themeManager?.currentTheme.primaryTextColor ?? Theme.defaultTheme.primaryTextColor).opacity(0.7))
            }
            
            Text("We respect your privacy. Unsubscribe anytime.")
                .font(.system(size: 12))
                .foregroundStyle(themeTertiaryText)
                .multilineTextAlignment(.center)
        }
    }
    
    // MARK: - Thank You Content
    private var thankYouContent: some View {
        VStack(spacing: 32) {
            Spacer()
            
            VStack(spacing: 24) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80, weight: .medium))
                    .foregroundStyle(themeManager?.currentTheme.colorScheme.success.color ?? Theme.defaultTheme.colorScheme.success.color)
                
                VStack(spacing: 16) {
                    Text("Thank You!")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(themeManager?.currentTheme.primaryTextColor ?? Theme.defaultTheme.primaryTextColor)
                    
                    Text("Check your email for a welcome message with productivity tips to get started.")
                        .font(.system(size: 16))
                        .foregroundStyle((themeManager?.currentTheme.primaryTextColor ?? Theme.defaultTheme.primaryTextColor).opacity(0.8))
                        .multilineTextAlignment(.center)
                }
            }
            
            Spacer()
            
            Button("Continue") {
                dismiss()
            }
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(themeManager?.currentTheme.primaryTextColor ?? Theme.defaultTheme.primaryTextColor)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(themeManager?.currentTheme.colorScheme.success.color ?? Theme.defaultTheme.colorScheme.success.color)
            .cornerRadius(12)
        }
    }
    
    // MARK: - Helper Views
    private func benefitRow(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(themeManager?.currentTheme.colorScheme.success.color ?? Theme.defaultTheme.colorScheme.success.color)
                .frame(width: 20)
            
            Text(text)
                .font(.system(size: 14))
                .foregroundStyle(themeSecondaryText)
            
            Spacer()
        }
    }
    
    // MARK: - Actions
    private func submitEmail() {
        guard isValidEmail(email) else {
            errorMessage = "Please enter a valid email address"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        // Simulate API call
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            isLoading = false
            onEmailCaptured(email)
            
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                showThankYou = true
            }
            
            // Auto dismiss after showing thank you
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                dismiss()
            }
        }
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
}

#Preview {
    EmailCaptureView { email in
        print("Captured email: \(email)")
    }
}
