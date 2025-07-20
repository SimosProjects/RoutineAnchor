//
//  SettingsView.swift
//  Routine Anchor
//
//  Created by Christopher Simonson on 7/19/25.
//
import SwiftUI
import SwiftData
import UserNotifications

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: SettingsViewModel?
    
    // MARK: - State
    @State private var showingPrivacyPolicy = false
    @State private var showingAbout = false
    @State private var showingResetConfirmation = false
    @State private var showingExportData = false
    @State private var notificationsEnabled = true
    @State private var notificationSound = "Default"
    @State private var dailyReminderTime = Date()
    
    var body: some View {
        NavigationView {
            List {
                // MARK: - Routine Section
                Section {
                    NavigationLink(destination: ScheduleBuilderView()) {
                        SettingsRowView(
                            icon: "clock",
                            title: "Edit Daily Routine",
                            subtitle: "Modify your time blocks",
                            iconColor: Color.primaryBlue
                        )
                    }
                    
                    Button {
                        viewModel?.resetTodaysProgress()
                    } label: {
                        SettingsRowView(
                            icon: "arrow.clockwise",
                            title: "Reset Today's Progress",
                            subtitle: "Start today over",
                            iconColor: Color.warningOrange
                        )
                    }
                    
                    Button {
                        showingResetConfirmation = true
                    } label: {
                        SettingsRowView(
                            icon: "trash",
                            title: "Clear All Data",
                            subtitle: "Delete all routines and progress",
                            iconColor: Color.errorRed
                        )
                    }
                } header: {
                    Text("Routine")
                }
                
                // MARK: - Notifications Section
                Section {
                    HStack {
                        SettingsRowView(
                            icon: "bell",
                            title: "Enable Reminders",
                            subtitle: "Get notified when blocks start",
                            iconColor: Color.primaryBlue
                        )
                        
                        Spacer()
                        
                        Toggle("", isOn: $notificationsEnabled)
                            .tint(Color.primaryBlue)
                    }
                    
                    if notificationsEnabled {
                        NavigationLink(destination: NotificationSoundView(selectedSound: $notificationSound)) {
                            SettingsRowView(
                                icon: "speaker.wave.2",
                                title: "Notification Sound",
                                subtitle: notificationSound,
                                iconColor: Color.successGreen
                            )
                        }
                        
                        DatePicker("Daily Reminder", selection: $dailyReminderTime, displayedComponents: .hourAndMinute)
                            .foregroundColor(Color.textPrimary)
                    }
                } header: {
                    Text("Notifications")
                } footer: {
                    if !notificationsEnabled {
                        Text("Enable notifications to get reminders when your time blocks start.")
                    }
                }
                
                // MARK: - Data & Privacy Section
                Section {
                    Button {
                        showingExportData = true
                    } label: {
                        SettingsRowView(
                            icon: "square.and.arrow.up",
                            title: "Export Data",
                            subtitle: "Save your routines and progress",
                            iconColor: Color.primaryBlue
                        )
                    }
                    
                    Button {
                        showingPrivacyPolicy = true
                    } label: {
                        SettingsRowView(
                            icon: "hand.raised",
                            title: "Privacy Policy",
                            subtitle: "How we handle your data",
                            iconColor: Color.successGreen
                        )
                    }
                } header: {
                    Text("Data & Privacy")
                } footer: {
                    Text("All data is stored locally on your device. We don't collect or share any personal information.")
                }
                
                // MARK: - Support Section
                Section {
                    NavigationLink(destination: HelpView()) {
                        SettingsRowView(
                            icon: "questionmark.circle",
                            title: "Help & FAQ",
                            subtitle: "Get answers to common questions",
                            iconColor: Color.primaryBlue
                        )
                    }
                    
                    Button {
                        sendFeedback()
                    } label: {
                        SettingsRowView(
                            icon: "envelope",
                            title: "Send Feedback",
                            subtitle: "Help us improve the app",
                            iconColor: Color.warningOrange
                        )
                    }
                    
                    Button {
                        shareApp()
                    } label: {
                        SettingsRowView(
                            icon: "square.and.arrow.up",
                            title: "Share App",
                            subtitle: "Tell friends about Routine Anchor",
                            iconColor: Color.successGreen
                        )
                    }
                } header: {
                    Text("Support")
                }
                
                // MARK: - About Section
                Section {
                    Button {
                        showingAbout = true
                    } label: {
                        SettingsRowView(
                            icon: "info.circle",
                            title: "About",
                            subtitle: "Version \(appVersion)",
                            iconColor: Color.textSecondary
                        )
                    }
                    
                    Button {
                        rateApp()
                    } label: {
                        SettingsRowView(
                            icon: "star",
                            title: "Rate App",
                            subtitle: "Leave a review on the App Store",
                            iconColor: Color.warningOrange
                        )
                    }
                } header: {
                    Text("About")
                }
                
                // MARK: - Debug Section (only in debug builds)
                #if DEBUG
                Section {
                    Button {
                        viewModel?.addSampleData()
                    } label: {
                        SettingsRowView(
                            icon: "hammer",
                            title: "Add Sample Data",
                            subtitle: "For testing purposes",
                            iconColor: Color.primaryBlue
                        )
                    }
                    
                    Button {
                        viewModel?.clearAllNotifications()
                    } label: {
                        SettingsRowView(
                            icon: "bell.slash",
                            title: "Clear Notifications",
                            subtitle: "Remove all pending notifications",
                            iconColor: Color.errorRed
                        )
                    }
                } header: {
                    Text("Debug")
                }
                #endif
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(Color.primaryBlue)
                }
            }
            .onAppear {
                setupViewModel()
                loadSettings()
            }
            .onChange(of: notificationsEnabled) { _, newValue in
                updateNotificationSettings(enabled: newValue)
            }
            .onChange(of: dailyReminderTime) { _, newTime in
                scheduleDailyReminder(at: newTime)
            }
        }
        .sheet(isPresented: $showingPrivacyPolicy) {
            //PrivacyPolicyView()
        }
        .sheet(isPresented: $showingAbout) {
            //AboutView()
        }
        .sheet(isPresented: $showingExportData) {
            //ExportDataView()
        }
        .confirmationDialog(
            "Clear All Data",
            isPresented: $showingResetConfirmation,
            titleVisibility: .visible
        ) {
            Button("Clear All Data", role: .destructive) {
                viewModel?.clearAllData()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete all your routines, time blocks, and progress data. This action cannot be undone.")
        }
    }
    
    // MARK: - Computed Properties
    
    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
    
    // MARK: - Helper Methods
    
    private func setupViewModel() {
        let dataManager = DataManager(modelContext: modelContext)
        viewModel = SettingsViewModel(dataManager: dataManager)
    }
    
    private func loadSettings() {
        // Load notification settings from UserDefaults
        notificationsEnabled = UserDefaults.standard.bool(forKey: "notificationsEnabled")
        notificationSound = UserDefaults.standard.string(forKey: "notificationSound") ?? "Default"
        
        if let reminderData = UserDefaults.standard.object(forKey: "dailyReminderTime") as? Data,
           let reminderTime = try? JSONDecoder().decode(Date.self, from: reminderData) {
            dailyReminderTime = reminderTime
        }
    }
    
    private func updateNotificationSettings(enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: "notificationsEnabled")
        
        if enabled {
            requestNotificationPermission()
        } else {
            UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        }
    }
    
    private func requestNotificationPermission() {
        Task {
            do {
                let granted = try await UNUserNotificationCenter.current()
                    .requestAuthorization(options: [.alert, .badge, .sound])
                
                if !granted {
                    await MainActor.run {
                        notificationsEnabled = false
                    }
                }
            } catch {
                print("Error requesting notification permission: \(error)")
            }
        }
    }
    
    private func scheduleDailyReminder(at time: Date) {
        // Save the time
        if let timeData = try? JSONEncoder().encode(time) {
            UserDefaults.standard.set(timeData, forKey: "dailyReminderTime")
        }
        
        // Schedule the reminder
        viewModel?.scheduleDailyReminder(at: time)
    }
    
    private func sendFeedback() {
        guard let url = URL(string: "mailto:feedback@routineanchor.app?subject=Routine%20Anchor%20Feedback") else { return }
        
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }
    
    private func shareApp() {
        let appURL = "https://apps.apple.com/app/routine-anchor/id123456789" // Replace with actual App Store URL
        let activityVC = UIActivityViewController(
            activityItems: [
                "Check out Routine Anchor - the best app for building daily habits with time-blocked routines!",
                URL(string: appURL)!
            ],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(activityVC, animated: true)
        }
    }
    
    private func rateApp() {
        guard let url = URL(string: "https://apps.apple.com/app/routine-anchor/id123456789?action=write-review") else { return }
        UIApplication.shared.open(url)
    }
}

// MARK: - Settings Row View
struct SettingsRowView: View {
    let icon: String
    let title: String
    let subtitle: String
    let iconColor: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(iconColor)
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(TypographyConstants.Body.emphasized)
                    .foregroundColor(Color.textPrimary)
                
                Text(subtitle)
                    .font(TypographyConstants.UI.caption)
                    .foregroundColor(Color.textSecondary)
            }
            
            Spacer()
        }
        .contentShape(Rectangle())
    }
}

// MARK: - Notification Sound View
struct NotificationSoundView: View {
    @Binding var selectedSound: String
    @Environment(\.dismiss) private var dismiss
    
    private let sounds = ["Default", "Chime", "Bell", "Ping", "Pop", "Gentle"]
    
    var body: some View {
        List {
            ForEach(sounds, id: \.self) { sound in
                Button {
                    selectedSound = sound
                    UserDefaults.standard.set(sound, forKey: "notificationSound")
                    dismiss()
                } label: {
                    HStack {
                        Text(sound)
                            .foregroundColor(Color.textPrimary)
                        
                        Spacer()
                        
                        if selectedSound == sound {
                            Image(systemName: "checkmark")
                                .foregroundColor(Color.primaryBlue)
                        }
                    }
                }
            }
        }
        .navigationTitle("Notification Sound")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Previews
#Preview("Settings View") {
    SettingsView()
        .modelContainer(for: [TimeBlock.self, DailyProgress.self], inMemory: true)
}

#Preview("Settings Row") {
    SettingsRowView(
        icon: "clock",
        title: "Edit Daily Routine",
        subtitle: "Modify your time blocks",
        iconColor: Color.primaryBlue
    )
    .padding()
}
