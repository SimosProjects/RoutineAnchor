//
//  PrivacyPolicyView.swift
//  Routine Anchor
//
//  Created by Christopher Simonson on 7/19/25.
//
import SwiftUI

struct PrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Privacy Policy")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundStyle(.primary)
                        
                        Text("Last updated: January 2025")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // Introduction
                    PrivacySection(
                        title: "Our Commitment to Privacy",
                        content: "Routine Anchor is designed with privacy at its core. We believe your personal routine data should remain exactly that - personal. This privacy policy explains how we handle your information when you use our app."
                    )
                    
                    // Data Collection
                    PrivacySection(
                        title: "Information We Collect",
                        content: "Routine Anchor stores your daily routine data locally on your device. We do not collect, transmit, or have access to any of your personal information. The app works completely offline and does not require user accounts or internet connectivity."
                    )
                    
                    // Data Storage
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Data Storage")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundStyle(.primary)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            PrivacyBulletPoint(
                                title: "Local Storage Only",
                                description: "All your routine data, time blocks, and progress tracking information is stored exclusively on your device using iOS's secure local storage."
                            )
                            
                            PrivacyBulletPoint(
                                title: "No Cloud Sync",
                                description: "We do not sync your data to any cloud services or external servers. Your information never leaves your device."
                            )
                            
                            PrivacyBulletPoint(
                                title: "No User Accounts",
                                description: "Routine Anchor does not require user registration, login credentials, or any form of account creation."
                            )
                            
                            PrivacyBulletPoint(
                                title: "No Analytics or Tracking",
                                description: "We do not use analytics services, crash reporting tools, or any tracking mechanisms that would collect usage data."
                            )
                        }
                    }
                    
                    // Notifications
                    PrivacySection(
                        title: "Notifications",
                        content: "Routine Anchor uses local notifications to remind you when time blocks begin. These notifications are generated and processed entirely on your device. No notification data is sent to external services or our servers."
                    )
                    
                    // Data Security
                    PrivacySection(
                        title: "Data Security",
                        content: "Your routine data is protected by iOS's built-in security features, including device encryption and app sandboxing. Since all data remains on your device, it benefits from the same security protections as your other personal information."
                    )
                    
                    // Data Deletion
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Data Control and Deletion")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundStyle(.primary)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            PrivacyBulletPoint(
                                title: "Complete Control",
                                description: "You have full control over your routine data at all times since it's stored locally on your device."
                            )
                            
                            PrivacyBulletPoint(
                                title: "Easy Deletion",
                                description: "You can delete all app data by uninstalling Routine Anchor from your device, or by using the 'Clear All Data' option in Settings."
                            )
                            
                            PrivacyBulletPoint(
                                title: "No Recovery Required",
                                description: "Since we don't store your data externally, there are no accounts to delete or data recovery processes needed."
                            )
                        }
                    }
                    
                    // iOS Permissions
                    PrivacySection(
                        title: "iOS Permissions",
                        content: "Routine Anchor only requests permission to send local notifications. This permission is used exclusively to remind you when time blocks begin. We do not access your contacts, location, camera, microphone, or any other device features."
                    )
                    
                    // Third-Party Services
                    PrivacySection(
                        title: "Third-Party Services",
                        content: "Routine Anchor does not integrate with or share data with any third-party services, analytics platforms, advertising networks, or social media platforms. The app operates in complete isolation from external services."
                    )
                    
                    // Children's Privacy
                    PrivacySection(
                        title: "Children's Privacy",
                        content: "Since Routine Anchor does not collect any personal information and operates entirely offline, it is safe for users of all ages. We do not knowingly collect personal information from children under 13 or any other age group."
                    )
                    
                    // Changes to Policy
                    PrivacySection(
                        title: "Changes to This Privacy Policy",
                        content: "If we make changes to this privacy policy, we will update the 'Last updated' date at the top of this policy. Since the app operates offline, policy updates will be included in app updates distributed through the App Store."
                    )
                    
                    // Contact Information
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Contact Us")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundStyle(.primary)
                        
                        Text("If you have questions about this privacy policy or our privacy practices, please contact us:")
                            .font(.body)
                            .foregroundStyle(.secondary)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Button("Email: support@routineanchor.com") {
                                if let url = URL(string: "mailto:support@routineanchor.com?subject=Privacy%20Policy%20Question") {
                                    UIApplication.shared.open(url)
                                }
                            }
                            .foregroundStyle(.blue)
                            .font(.body)
                            
                            Button("Website: routineanchor.com/privacy") {
                                if let url = URL(string: "https://routineanchor.com/privacy") {
                                    UIApplication.shared.open(url)
                                }
                            }
                            .foregroundStyle(.blue)
                            .font(.body)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    
                    // Summary Box
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "checkmark.shield.fill")
                                .foregroundStyle(.green)
                                .font(.title3)
                            
                            Text("Privacy Summary")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundStyle(.primary)
                        }
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text("• All data stays on your device")
                            Text("• No user accounts or registration")
                            Text("• No internet connectivity required")
                            Text("• No analytics or tracking")
                            Text("• No data sharing with third parties")
                        }
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    }
                    .padding(16)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.medium)
                }
            }
        }
    }
}

// MARK: - Privacy Section Component
struct PrivacySection: View {
    let title: String
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
            
            Text(content)
                .font(.body)
                .foregroundStyle(.secondary)
                .lineLimit(nil)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Privacy Bullet Point Component
struct PrivacyBulletPoint: View {
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "circle.fill")
                .font(.caption2)
                .foregroundStyle(.blue)
                .padding(.top, 6)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

// MARK: - Preview
#Preview {
    PrivacyPolicyView()
}
