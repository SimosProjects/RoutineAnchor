//
//  SettingsView.swift
//  Routine Anchor
//
//  Created by Christopher Simonson on 7/21/25.
//
import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    // MARK: - State
    @State private var viewModel: SettingsViewModel?
    @State private var animationPhase = 0
    @State private var particleSystem = ParticleSystem()
    
    // MARK: - Settings State
    @State private var notificationsEnabled = true
    @State private var dailyReminderTime = Date()
    @State private var notificationSound = "Default"
    @State private var hapticsEnabled = true
    @State private var autoResetEnabled = true
    
    // MARK: - Sheet States
    @State private var showingPrivacyPolicy = false
    @State private var showingAbout = false
    @State private var showingHelp = false
    @State private var showingExportData = false
    @State private var showingImportView = false
    @State private var showingResetConfirmation = false
    @State private var showingDeleteAllConfirmation = false
    
    // MARK: - UI State
    @State private var showingSuccessMessage = false
    @State private var showingErrorMessage = false
    
    var body: some View {
        ZStack {
            // Premium animated background
            AnimatedGradientBackground()
            AnimatedMeshBackground()
                .opacity(0.3)
                .allowsHitTesting(false)
            ParticleEffectView(system: particleSystem)
                .allowsHitTesting(false)
            
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection
                    
                    // Settings sections
                    
                    NotificationSettingsSection(
                        notificationsEnabled: $notificationsEnabled,
                        dailyReminderTime: $dailyReminderTime,
                        notificationSound: $notificationSound
                    )
                    
                    // Use the new AppPreferencesSection component
                    AppPreferencesSection(
                        hapticsEnabled: $hapticsEnabled,
                        autoResetEnabled: $autoResetEnabled,
                        onResetProgress: {
                            showingResetConfirmation = true
                        }
                    )
                    
                    SupportInfoSection(
                        onShowHelp: {
                            showingHelp = true
                        },
                        onShowAbout: {
                            showingAbout = true
                        },
                        onRateApp: {
                            rateApp()
                        },
                        onContactSupport: {
                            contactSupport()
                        }
                    )
                    
                    DataManagementSection(
                        onExportData: {
                            showingExportData = true
                        },
                        onImportData: {
                            showingImportView = true
                        },
                        onShowPrivacyPolicy: {
                            showingPrivacyPolicy = true
                        },
                        onDeleteAllData: {
                            showingDeleteAllConfirmation = true
                        }
                    )
                    
                    appVersion
                    
                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            setupViewModel()
            loadSettings()
            particleSystem.startEmitting()
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                animationPhase += 1
            }
        }
        .onChange(of: notificationsEnabled) { _, newValue in
            viewModel?.notificationsEnabled = newValue
        }
        .onChange(of: dailyReminderTime) { _, newTime in
            viewModel?.dailyReminderTime = newTime
        }
        .onChange(of: notificationSound) { _, newValue in
            viewModel?.notificationSound = newValue
        }
        .onChange(of: hapticsEnabled) { _, newValue in
            viewModel?.hapticsEnabled = newValue
        }
        .onChange(of: autoResetEnabled) { _, newValue in
            viewModel?.autoResetEnabled = newValue
        }
        .sheet(isPresented: $showingPrivacyPolicy) {
            PrivacyPolicyView()
        }
        .sheet(isPresented: $showingAbout) {
            AboutView()
        }
        .sheet(isPresented: $showingHelp) {
            HelpView()
        }
        .sheet(isPresented: $showingExportData) {
            ExportDataView()
        }
        .sheet(isPresented: $showingImportView) {
            ImportDataView()
        }
        .overlay(alignment: .top) {
            // Success/Error message overlay
            if let viewModel = viewModel {
                if let successMessage = viewModel.successMessage {
                    MessageBanner(message: successMessage, type: .success)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: viewModel.successMessage)
                }
                
                if let errorMessage = viewModel.errorMessage {
                    MessageBanner(message: errorMessage, type: .error)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: viewModel.errorMessage)
                }
            }
        }
        .confirmationDialog(
            "Reset Today's Progress",
            isPresented: $showingResetConfirmation,
            titleVisibility: .visible
        ) {
            Button("Reset Progress", role: .destructive) {
                viewModel?.resetTodaysProgress()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will reset all time blocks back to 'Not Started' for today. This action cannot be undone.")
        }
        .confirmationDialog(
            "Delete All Data",
            isPresented: $showingDeleteAllConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete All Data", role: .destructive) {
                viewModel?.clearAllData()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete all your routines, time blocks, and progress data. This action cannot be undone.")
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 16) {
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.8))
                        .frame(width: 32, height: 32)
                        .background(
                            Circle()
                                .fill(.ultraThinMaterial)
                                .background(
                                    Circle().fill(Color.white.opacity(0.1))
                                )
                        )
                }
                
                Spacer()
            }
            
            VStack(spacing: 12) {
                Image(systemName: "gear")
                    .font(.system(size: 48, weight: .light))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.premiumBlue, Color.premiumPurple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .scaleEffect(animationPhase == 0 ? 1.0 : 1.1)
                    .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: animationPhase)
                
                Text("Settings")
                    .font(TypographyConstants.Headers.welcome)
                    .foregroundStyle(Color.premiumTextPrimary)
                
                Text("Customize your experience")
                    .font(TypographyConstants.Body.secondary)
                    .foregroundStyle(Color.premiumTextSecondary)
            }
        }
    }
    
    // MARK: - App Version
    private var appVersion: some View {
        VStack(spacing: 8) {
            Text("Routine Anchor")
                .font(TypographyConstants.Body.emphasized)
                .foregroundStyle(Color.premiumTextPrimary)
            
            Text("Version \(appVersionString)")
                .font(TypographyConstants.UI.caption)
                .foregroundStyle(Color.premiumTextSecondary)
            
            Text("© 2025 Simo's Media & Tech, LLC.")
                .font(TypographyConstants.UI.caption)
                .foregroundStyle(Color.premiumTextTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .glassMorphism()
    }
    
    // MARK: - Computed Properties
    private var appVersionString: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
    
    // MARK: - Helper Methods
    private func setupViewModel() {
        let dataManager = DataManager(modelContext: modelContext)
        viewModel = SettingsViewModel(dataManager: dataManager)
    }
    
    private func loadSettings() {
        // Load settings from viewModel if available, otherwise use defaults
        if let viewModel = viewModel {
            notificationsEnabled = viewModel.notificationsEnabled
            notificationSound = viewModel.notificationSound
            hapticsEnabled = viewModel.hapticsEnabled
            autoResetEnabled = viewModel.autoResetEnabled
            dailyReminderTime = viewModel.dailyReminderTime
        } else {
            // Fallback to UserDefaults
            notificationsEnabled = UserDefaults.standard.bool(forKey: "notificationsEnabled")
            notificationSound = UserDefaults.standard.string(forKey: "notificationSound") ?? "Default"
            hapticsEnabled = HapticManager.shared.isHapticsEnabled
            autoResetEnabled = UserDefaults.standard.bool(forKey: "autoResetEnabled")
            
            if let reminderData = UserDefaults.standard.object(forKey: "dailyReminderTime") as? Data,
               let reminderTime = try? JSONDecoder().decode(Date.self, from: reminderData) {
                dailyReminderTime = reminderTime
            }
        }
    }
    
    // Remove the old update functions since they're now handled by the viewModel
    private func rateApp() {
        viewModel?.rateApp()
    }
    
    private func contactSupport() {
        viewModel?.contactSupport()
    }
}

// MARK: - Settings Components

struct SettingsSection<Content: View>: View {
    let title: String
    let icon: String
    let color: Color
    let content: Content
    
    @State private var isVisible = false
    
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
                    .foregroundStyle(Color.premiumTextPrimary)
                
                Spacer()
            }
            
            // Section content
            content
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.08),
                                    Color.white.opacity(0.04)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    LinearGradient(
                        colors: [
                            color.opacity(0.3),
                            color.opacity(0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: color.opacity(0.2), radius: 8, x: 0, y: 4)
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : 20)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
                isVisible = true
            }
        }
    }
}

// MARK: - Custom Toggle Style
struct PremiumToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label
            
            RoundedRectangle(cornerRadius: 16)
                .fill(configuration.isOn ? Color.premiumGreen : Color.white.opacity(0.2))
                .frame(width: 44, height: 26)
                .overlay(
                    Circle()
                        .fill(.white)
                        .frame(width: 22, height: 22)
                        .offset(x: configuration.isOn ? 9 : -9)
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isOn)
                )
                .onTapGesture {
                    configuration.isOn.toggle()
                }
        }
    }
}

// MARK: - Message Banner
struct MessageBanner: View {
    let message: String
    let type: MessageType
    
    enum MessageType {
        case success, error
        
        var color: Color {
            switch self {
            case .success: return Color.premiumGreen
            case .error: return Color.premiumError
            }
        }
        
        var icon: String {
            switch self {
            case .success: return "checkmark.circle.fill"
            case .error: return "exclamationmark.triangle.fill"
            }
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: type.icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(type.color)
            
            Text(message)
                .font(TypographyConstants.Body.emphasized)
                .foregroundStyle(Color.premiumTextPrimary)
                .lineLimit(2)
            
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(type.color.opacity(0.1))
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(type.color.opacity(0.3), lineWidth: 1)
        )
        .shadow(color: type.color.opacity(0.2), radius: 8, x: 0, y: 4)
        .padding(.horizontal, 24)
        .padding(.top, 8)
    }
}

// MARK: - Preview
#Preview {
    SettingsView()
}
