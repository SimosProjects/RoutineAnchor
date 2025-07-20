//
//  HelpView.swift
//  Routine Anchor
//
//  Created by Christopher Simonson on 7/19/25.
//
import SwiftUI

struct HelpView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedSection: HelpSection? = .gettingStarted
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "questionmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.blue)
                        
                        Text("Help & Support")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Spacer()
                    }
                    
                    Text("Learn how to build consistent daily habits with time-blocked routines and gentle accountability.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal)
                .padding(.top, 8)
                
                Divider()
                    .padding(.vertical, 16)
                
                // Content
                ScrollView {
                    LazyVStack(spacing: 20) {
                        ForEach(HelpSection.allCases, id: \.self) { section in
                            HelpSectionView(
                                section: section,
                                isExpanded: selectedSection == section
                            ) {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    selectedSection = selectedSection == section ? nil : section
                                }
                            }
                        }
                        
                        // Contact Support Section
                        ContactSupportView()
                            .padding(.top, 20)
                    }
                    .padding(.horizontal)
                }
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

// MARK: - Help Section Model
enum HelpSection: String, CaseIterable {
    case gettingStarted = "Getting Started"
    case routineBuilder = "Building Your Routine"
    case dailyTracking = "Daily Progress & Check-ins"
    case notifications = "Notifications & Reminders"
    case troubleshooting = "Troubleshooting"
    
    var icon: String {
        switch self {
        case .gettingStarted: return "play.circle"
        case .routineBuilder: return "calendar"
        case .dailyTracking: return "checkmark.circle"
        case .notifications: return "bell.circle"
        case .troubleshooting: return "wrench.and.screwdriver"
        }
    }
    
    var questions: [HelpQuestion] {
        switch self {
        case .gettingStarted:
            return [
                HelpQuestion(
                    question: "What is Routine Anchor?",
                    answer: "Routine Anchor helps you build consistent daily habits using time-blocked routines. Create a structured daily schedule, receive gentle reminders, and track your progress with simple check-ins."
                ),
                HelpQuestion(
                    question: "How do I get started?",
                    answer: "First, create your daily routine by adding time blocks for different activities. Then use the Today view to track your progress throughout the day. You'll receive notifications when each time block begins."
                ),
                HelpQuestion(
                    question: "Do I need an account or internet connection?",
                    answer: "No! Routine Anchor works completely offline. All your data is stored locally on your device, so you can use it anywhere without worrying about internet connectivity or creating accounts."
                )
            ]
        case .routineBuilder:
            return [
                HelpQuestion(
                    question: "How do I create a time block?",
                    answer: "Go to the Schedule Builder, tap 'Add Block', then enter a title and set your start and end times. Give each block a clear, specific name like 'Morning Workout' or 'Deep Work Session'."
                ),
                HelpQuestion(
                    question: "Can I edit or delete time blocks?",
                    answer: "Yes! In the Schedule Builder, tap on any time block to edit it, or swipe left to delete. Remember to save your changes when you're done editing your routine."
                ),
                HelpQuestion(
                    question: "What makes a good time block?",
                    answer: "Effective time blocks are specific, realistic, and focused on one main activity. Aim for 30 minutes to 2 hours per block, and include both work activities and personal care like meals and breaks."
                ),
                HelpQuestion(
                    question: "Can time blocks overlap?",
                    answer: "While the app allows overlapping blocks, it's recommended to avoid them for clarity. If you need flexibility, consider creating broader blocks like 'Morning Routine' rather than multiple overlapping activities."
                )
            ]
        case .dailyTracking:
            return [
                HelpQuestion(
                    question: "How do I mark a time block as complete?",
                    answer: "In the Today view, you'll see 'Done' and 'Skip' buttons for your current time block. Tap 'Done' when you've completed the activity, or 'Skip' if you need to move on to the next block."
                ),
                HelpQuestion(
                    question: "What's the difference between 'Done' and 'Skip'?",
                    answer: "Use 'Done' when you've completed the activity as planned. Use 'Skip' when you choose not to do the activity or need to move on. Both help you stay honest about your progress."
                ),
                HelpQuestion(
                    question: "When can I see my daily summary?",
                    answer: "Your daily summary shows your progress throughout the day. At the end of the day, you'll see a complete breakdown of completed and skipped activities, plus the option to reset for tomorrow."
                ),
                HelpQuestion(
                    question: "What happens when I reset my day?",
                    answer: "Resetting clears all check-ins and sets every time block back to 'not started' for the next day. Your routine structure stays the same, but your progress tracking starts fresh."
                )
            ]
        case .notifications:
            return [
                HelpQuestion(
                    question: "Why am I not receiving notifications?",
                    answer: "Check that you've enabled notifications for Routine Anchor in your iPhone Settings > Notifications. Also ensure you've allowed notifications when the app first asked for permission."
                ),
                HelpQuestion(
                    question: "When do notifications appear?",
                    answer: "You'll receive a notification when each time block is scheduled to begin. This helps you transition smoothly between activities and stay on track with your routine."
                ),
                HelpQuestion(
                    question: "Can I turn off notifications?",
                    answer: "Yes! Go to Settings in the app and toggle off 'Enable Reminders', or adjust notification settings in your iPhone's main Settings app under Routine Anchor."
                ),
                HelpQuestion(
                    question: "Can I customize notification sounds?",
                    answer: "Currently, notifications use the default system sound. You can change this in your iPhone Settings > Notifications > Routine Anchor > Sounds."
                )
            ]
        case .troubleshooting:
            return [
                HelpQuestion(
                    question: "My time blocks aren't showing the right status",
                    answer: "Try refreshing the Today view by pulling down to reload. If problems persist, go to Settings and tap 'Reset Progress' to clear any stuck states."
                ),
                HelpQuestion(
                    question: "The app seems slow or unresponsive",
                    answer: "Close and reopen the app by double-tapping the home button and swiping up on Routine Anchor. If issues continue, restart your iPhone or check for app updates in the App Store."
                ),
                HelpQuestion(
                    question: "I accidentally deleted my routine",
                    answer: "Unfortunately, deleted routines cannot be recovered since all data is stored locally. You'll need to recreate your routine using the Schedule Builder. Consider writing down your routine as a backup."
                ),
                HelpQuestion(
                    question: "My progress reset unexpectedly",
                    answer: "Progress automatically resets each day to give you a fresh start. If it reset during the day, check that your device's date and time settings are correct in iPhone Settings > General > Date & Time."
                )
            ]
        }
    }
}

// MARK: - Help Question Model
struct HelpQuestion {
    let question: String
    let answer: String
}

// MARK: - Help Section View
struct HelpSectionView: View {
    let section: HelpSection
    let isExpanded: Bool
    let onTap: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Section Header
            Button(action: onTap) {
                HStack {
                    Image(systemName: section.icon)
                        .font(.title3)
                        .foregroundStyle(.blue)
                        .frame(width: 24)
                    
                    Text(section.rawValue)
                        .font(.headline)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.leading)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                        .animation(.easeInOut(duration: 0.2), value: isExpanded)
                }
                .padding(.vertical, 16)
                .padding(.horizontal, 16)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Expanded Content
            if isExpanded {
                VStack(spacing: 12) {
                    ForEach(Array(section.questions.enumerated()), id: \.offset) { index, question in
                        HelpQuestionView(question: question)
                        
                        if index < section.questions.count - 1 {
                            Divider()
                                .padding(.horizontal, 16)
                        }
                    }
                }
                .padding(.bottom, 16)
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .move(edge: .top)),
                    removal: .opacity
                ))
            }
        }
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Help Question View
struct HelpQuestionView: View {
    let question: HelpQuestion
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(question.question)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.primary)
            
            Text(question.answer)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
    }
}

// MARK: - Contact Support View
struct ContactSupportView: View {
    var body: some View {
        VStack(spacing: 16) {
            VStack(spacing: 8) {
                Image(systemName: "envelope.circle.fill")
                    .font(.title)
                    .foregroundStyle(.blue)
                
                Text("Still need help?")
                    .font(.headline)
                    .fontWeight(.medium)
                
                Text("Contact our support team for assistance with Routine Anchor or to share feedback about your experience.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 12) {
                Button("Send Feedback") {
                    // Handle feedback action
                    if let url = URL(string: "mailto:support@routineanchor.com?subject=Routine%20Anchor%20Feedback") {
                        UIApplication.shared.open(url)
                    }
                }
                .buttonStyle(.borderedProminent)
                
                Button("Visit Support Website") {
                    // Handle support website action
                    if let url = URL(string: "https://routineanchor.com/support") {
                        UIApplication.shared.open(url)
                    }
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(20)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Preview
#Preview {
    HelpView()
}
