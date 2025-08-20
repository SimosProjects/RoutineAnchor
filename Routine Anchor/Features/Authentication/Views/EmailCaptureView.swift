//
//  EmailCaptureView.swift
//  Routine Anchor
//
//  Email capture modal for building user list
//
import SwiftUI

struct EmailCaptureView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var email = ""
    @State private var isLoading = false
    @State private var showThankYou = false
    @State private var errorMessage: String?
    
    let onEmailCaptured: (String) -> Void
    
    var body: some View {
        ZStack {
            // Background
            AnimatedGradientBackground()
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
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
            
            // Header
            VStack(spacing: 16) {
                Image(systemName: "envelope.badge")
                    .font(.system(size: 60, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.anchorBlue, Color.anchorPurple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                Text("Stay in the Loop")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                
                Text("Get notified about new features, productivity tips, and exclusive app development courses")
                    .font(.system(size: 16))
                    .foregroundStyle(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
            }
            
            // Email input
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "envelope")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(Color.anchorBlue)
                        
                        TextField("Enter your email", text: $email)
                            .font(.system(size: 16))
                            .foregroundStyle(.white)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .autocorrectionDisabled()
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.ultraThinMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.anchorBlue.opacity(0.3), lineWidth: 1)
                            )
                    )
                }
                
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .font(.system(size: 14))
                        .foregroundStyle(Color.anchorWarning)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            
            // Benefits
            VStack(spacing: 12) {
                benefitRow(icon: "star", text: "Early access to new features")
                benefitRow(icon: "lightbulb", text: "Productivity tips and insights")
                benefitRow(icon: "graduationcap", text: "Exclusive app development courses")
                benefitRow(icon: "gift", text: "Special offers and discounts")
            }
            
            Spacer()
            
            // Action buttons
            VStack(spacing: 12) {
                Button(action: submitEmail) {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                                .foregroundStyle(.white)
                        } else {
                            Text("Join the Community")
                                .font(.system(size: 16, weight: .semibold))
                        }
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(
                        LinearGradient(
                            colors: [Color.anchorBlue, Color.anchorPurple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                    .disabled(email.isEmpty || isLoading)
                    .opacity(email.isEmpty ? 0.6 : 1.0)
                }
                
                Button("Maybe Later") {
                    dismiss()
                }
                .font(.system(size: 14))
                .foregroundStyle(.white.opacity(0.7))
            }
            
            // Privacy note
            Text("We respect your privacy. No spam, unsubscribe anytime.")
                .font(.system(size: 12))
                .foregroundStyle(.white.opacity(0.6))
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
                    .foregroundStyle(Color.anchorGreen)
                
                VStack(spacing: 12) {
                    Text("Welcome Aboard!")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    
                    Text("Check your email for a welcome message with productivity tips to get started.")
                        .font(.system(size: 16))
                        .foregroundStyle(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                }
            }
            
            Spacer()
            
            Button("Continue") {
                dismiss()
            }
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(Color.anchorGreen)
            .cornerRadius(12)
        }
    }
    
    // MARK: - Helper Views
    private func benefitRow(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.anchorGreen)
                .frame(width: 20)
            
            Text(text)
                .font(.system(size: 14))
                .foregroundStyle(.white.opacity(0.9))
            
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
