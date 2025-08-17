//
//  SettingsView.swift
//  Routine Anchor
//  Swift 6 Compatible Version
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
    @State private var animationTask: Task<Void, Never>?
    
    // MARK: - Settings State
    @State private var notificationsEnabled = true
    @State private var dailyReminderTime = Date()
    @State private var notificationSound = "Default"
    @State private var hapticsEnabled = true
    @State private var autoResetEnabled = true
    @State private var showingClearTodayConfirmation = false
    @State private var animateClear = false
    @State private var showingResetConfirmation = false
    @State private var animateReset = false
    
    // MARK: - Sheet States
    @State private var showingPrivacyPolicy = false
    @State private var showingAbout = false
    @State private var showingHelp = false
    @State private var showingExportData = false
    @State private var showingImportView = false
    @State private var showingDeleteAllConfirmation = false
    
    // MARK: - UI State
    @State private var showingSuccessMessage = false
    @State private var showingErrorMessage = false
    
    var body: some View {
        ZStack {
            // Premium animated background
            AnimatedGradientBackground()
                .ignoresSafeArea()
            
            AnimatedMeshBackground()
                .opacity(0.3)
                .allowsHitTesting(false)
            
            ParticleEffectView()
                .allowsHitTesting(false)
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Header
                    SettingsHeader(
                        onDismiss: { dismiss() },
                        animationPhase: $animationPhase
                    )
                    
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
                    
                    AppVersionView()
                    
                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .task {
            await setupInitialState()
        }
        .onDisappear {
            animationTask?.cancel()
            animationTask = nil
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
            NavigationStack {
                PrivacyPolicyView()
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingAbout) {
            NavigationStack {
                AboutView()
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingHelp) {
            NavigationStack {
                HelpView()
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingExportData) {
            ExportDataView()
                .modelContainer(modelContext.container)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingImportView) {
            ImportDataView()
                .modelContainer(modelContext.container)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
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
            "Clear Today's Schedule",
            isPresented: $showingClearTodayConfirmation,
            titleVisibility: .visible
        ) {
            Button("Clear Schedule", role: .destructive) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    animateClear = true
                }
                viewModel?.clearTodaysSchedule()
                
                // Reset animation after delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    animateClear = false
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete all time blocks for today. This will give you a completely fresh start for the day. This action cannot be undone.")
        }
        .confirmationDialog(
            "Delete All Data",
            isPresented: $showingDeleteAllConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete All Data", role: .destructive) {
                Task { @MainActor in
                    viewModel?.clearAllData()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete all your routines, time blocks, and progress data. This action cannot be undone.")
        }
    }
    
    // MARK: - Computed Properties
    private var appVersionString: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
    
    // MARK: - Helper Methods
    @MainActor
    private func setupInitialState() async {
        await setupViewModel()
        loadSettings()
        startAnimations()
    }
    
    @MainActor
    private func setupViewModel() async {
        guard viewModel == nil else { return }
        
        let dataManager = DataManager(modelContext: modelContext)
        let newViewModel = SettingsViewModel(dataManager: dataManager)
        
        // Ensure ViewModel is properly initialized
        viewModel = newViewModel
        
        // Verify critical properties are accessible
        guard viewModel != nil else {
            print("Error: SettingsViewModel initialization failed")
            return
        }
    }
    
    private func loadSettings() {
        // Load settings from viewModel only - remove UserDefaults fallback
        guard let viewModel = viewModel else { return }
        
        notificationsEnabled = viewModel.notificationsEnabled
        notificationSound = viewModel.notificationSound
        hapticsEnabled = viewModel.hapticsEnabled
        autoResetEnabled = viewModel.autoResetEnabled
        dailyReminderTime = viewModel.dailyReminderTime
    }
    
    private func startAnimations() {
        animationTask?.cancel()
        animationTask = Task { @MainActor in
            while !Task.isCancelled {
                withAnimation(.easeInOut(duration: 2)) {
                    animationPhase = animationPhase == 0 ? 1 : 0
                }
                try? await Task.sleep(nanoseconds: 2_000_000_000)
            }
        }
    }
    
    private func rateApp() {
        viewModel?.rateApp()
    }
    
    private func contactSupport() {
        viewModel?.contactSupport()
    }
}

// MARK: - Preview
#Preview {
    SettingsView()
        .modelContainer(for: [TimeBlock.self, DailyProgress.self], inMemory: true)
}
