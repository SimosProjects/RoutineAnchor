//
//  AboutView.swift
//  Routine Anchor
//
//  Created by Christopher Simonson on 7/19/25.
//
import SwiftUI

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // App Icon and Title Section
                    VStack(spacing: 16) {
                        Image(systemName: "target")
                            .font(.system(size: 80, weight: .thin))
                            .foregroundStyle(.blue)
                            .symbolRenderingMode(.hierarchical)
                        
                        VStack(spacing: 8) {
                            Text("Routine Anchor")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundStyle(.primary)
                            
                            Text("Version 1.0.0")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.top, 20)
                    
                    // App Description
                    VStack(alignment: .leading, spacing: 16) {
                        Text("About")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundStyle(.primary)
                        
                        Text("Routine Anchor helps you build consistent daily habits with time-blocked routines and gentle accountability. Create structured daily schedules, receive timely reminders, and track your progress with simple, honest check-ins.")
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .lineLimit(nil)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // Key Features
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Key Features")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundStyle(.primary)
                        
                        VStack(spacing: 12) {
                            FeatureRow(
                                icon: "calendar",
                                title: "Time-Blocked Scheduling",
                                description: "Create and manage daily routines using structured time blocks"
                            )
                            
                            FeatureRow(
                                icon: "bell",
                                title: "Smart Reminders",
                                description: "Get notified when each time block begins to stay on track"
                            )
                            
                            FeatureRow(
                                icon: "checkmark.circle",
                                title: "Simple Check-ins",
                                description: "Mark tasks as completed or skipped with honest progress tracking"
                            )
                            
                            FeatureRow(
                                icon: "chart.bar",
                                title: "Daily Progress",
                                description: "View your productivity at a glance with clear daily summaries"
                            )
                            
                            FeatureRow(
                                icon: "lock.shield",
                                title: "Privacy First",
                                description: "All data stays on your device - no accounts or cloud sync required"
                            )
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // Developer Information
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Developer")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundStyle(.primary)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Built with care for iOS users who value productivity and personal accountability.")
                                .font(.body)
                                .foregroundStyle(.secondary)
                            
                            Text("Routine Anchor is designed to work completely offline, ensuring your personal routine data remains private and secure on your device.")
                                .font(.body)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // Contact and Support Links
                    VStack(spacing: 16) {
                        VStack(spacing: 12) {
                            Button("Send Feedback") {
                                if let url = URL(string: "mailto:support@routineanchor.com?subject=Routine%20Anchor%20Feedback") {
                                    UIApplication.shared.open(url)
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            
                            Button("Visit Website") {
                                if let url = URL(string: "https://routineanchor.com") {
                                    UIApplication.shared.open(url)
                                }
                            }
                            .buttonStyle(.bordered)
                        }
                        
                        // Legal Links
                        HStack(spacing: 20) {
                            Button("Privacy Policy") {
                                // Navigate to privacy policy
                            }
                            .font(.footnote)
                            .foregroundStyle(.blue)
                            
                            Button("Terms of Service") {
                                if let url = URL(string: "https://routineanchor.com/terms") {
                                    UIApplication.shared.open(url)
                                }
                            }
                            .font(.footnote)
                            .foregroundStyle(.blue)
                        }
                    }
                    
                    // Copyright
                    Text("© 2025 Routine Anchor. All rights reserved.")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .padding(.top, 8)
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

// MARK: - Preview
#Preview {
    AboutView()
}
