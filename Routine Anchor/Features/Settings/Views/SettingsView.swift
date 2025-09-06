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
    @Environment(\.premiumManager) private var premiumManager
    @Environment(\.themeManager) private var themeManager
    @EnvironmentObject private var authManager: AuthenticationManager
    
    // MARK: - State
    @State private var viewModel: SettingsViewModel?
    @State private var showingEmailPreferences = false
    @State private var showingPremiumUpgrade = false
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
            ThemedAnimatedBackground()
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
                    
                    premiumStatusSection
                    
                    // Account section
                    if authManager.isEmailCaptured {
                        accountSection
                    }
                    
                    ThemeSettingsRow()
                    
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
                    
                    #if DEBUG
                    simpleDebugSection
                    #endif
                    
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
                        onClearTodaysSchedule: {
                            viewModel?.clearTodaysSchedule()
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
            .environment(\.themeManager, themeManager)
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingPremiumUpgrade) {
            PremiumUpgradeView()
                .environment(\.themeManager, themeManager)
                .environment(\.premiumManager, premiumManager)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingAbout) {
            NavigationStack {
                AboutView()
            }
            .environment(\.themeManager, themeManager)
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingHelp) {
            NavigationStack {
                HelpView()
            }
            .environment(\.themeManager, themeManager)
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingExportData) {
            ExportDataView()
                .modelContainer(modelContext.container)
                .environment(\.themeManager, themeManager)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingImportView) {
            ImportDataView()
                .modelContainer(modelContext.container)
                .environment(\.themeManager, themeManager)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingEmailPreferences) {
            NavigationStack {
                EmailPreferencesView()
                    .environmentObject(authManager)
            }
            .environment(\.themeManager, themeManager)
            .presentationDetents([.large])
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
    
    // MARK: - Premium Status Section
    private var premiumStatusSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Premium")
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundStyle(themeManager?.currentTheme.primaryTextColor ?? Theme.defaultTheme.primaryTextColor)
                
                Spacer()
                
                if premiumManager?.hasPremiumAccess == true {
                    PremiumBadge()
                }
            }
            
            if premiumManager?.hasPremiumAccess == true {
                // Premium user content
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundStyle(themeManager?.currentTheme.colorScheme.warningColor.color ?? Theme.defaultTheme.colorScheme.warningColor.color)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Premium Active")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(themeManager?.currentTheme.primaryTextColor ?? Theme.defaultTheme.primaryTextColor)
                            
                            Text("Thank you for supporting Routine Anchor!")
                                .font(.system(size: 14))
                                .foregroundStyle((themeManager?.currentTheme.primaryTextColor ?? Theme.defaultTheme.primaryTextColor).opacity(0.7))
                        }
                        
                        Spacer()
                    }
                    
                    Button("Manage Subscription") {
                        if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
                            UIApplication.shared.open(url)
                        }
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(themeManager?.currentTheme.colorScheme.workflowPrimary.color ?? Theme.defaultTheme.colorScheme.workflowPrimary.color)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            } else {
                // Free user content
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "star.circle")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(themeManager?.currentTheme.colorScheme.workflowPrimary.color ?? Theme.defaultTheme.colorScheme.workflowPrimary.color)

                        Text("Upgrade to Premium")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(themeManager?.currentTheme.primaryTextColor ?? Theme.defaultTheme.primaryTextColor)

                        Spacer()
                    }

                    Text("Unlock unlimited time blocks, advanced analytics, and premium themes")
                        .font(.system(size: 14))
                        .foregroundStyle((themeManager?.currentTheme.primaryTextColor ?? Theme.defaultTheme.primaryTextColor).opacity(0.7))
                        .frame(maxWidth: .infinity, alignment: .leading)

                    DesignedButton(title: "Upgrade Now", style: .gradient) {
                        HapticManager.shared.anchorSelection()
                        showingPremiumUpgrade = true
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

            }
        }
        .padding(20)
        .themedGlassMorphism(cornerRadius: 20)
    }
    
    // MARK: - Account Section
    private var accountSection: some View {
        VStack(spacing: 16) {
            VStack(spacing: 16) {
                HStack {
                    Text("Account")
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .foregroundStyle(themeManager?.currentTheme.primaryTextColor ?? Theme.defaultTheme.primaryTextColor)
                    
                    Spacer()
                    
                    // Add a verified badge for visual balance
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(themeManager?.currentTheme.colorScheme.actionSuccess.color ?? Theme.defaultTheme.colorScheme.actionSuccess.color)
                        
                        Text("Verified")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(themeManager?.currentTheme.colorScheme.actionSuccess.color ?? Theme.defaultTheme.colorScheme.actionSuccess.color)
                    }
                }
                
                // Email display
                HStack {
                    Image(systemName: "envelope")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(themeManager?.currentTheme.colorScheme.workflowPrimary.color ?? Theme.defaultTheme.colorScheme.workflowPrimary.color)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Email Address")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle((themeManager?.currentTheme.primaryTextColor ?? Theme.defaultTheme.primaryTextColor).opacity(0.7))
                        
                        Text(authManager.userEmail ?? "No email")
                            .font(.system(size: 16))
                            .foregroundStyle(themeManager?.currentTheme.primaryTextColor ?? Theme.defaultTheme.primaryTextColor)
                    }
                    
                    Spacer()
                }
                
                // Divider for visual separation
                Rectangle()
                    .fill((themeManager?.currentTheme.colorScheme.uiElementSecondary.color ?? Theme.defaultTheme.colorScheme.uiElementSecondary.color).opacity(0.3))
                    .frame(height: 1)
                
                // Email preferences button
                HStack {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(themeManager?.currentTheme.colorScheme.workflowPrimary.color ?? Theme.defaultTheme.colorScheme.workflowPrimary.color)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Email Preferences")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(themeManager?.currentTheme.primaryTextColor ?? Theme.defaultTheme.primaryTextColor)
                        
                        Text("Manage notification settings")
                            .font(.system(size: 14))
                            .foregroundStyle((themeManager?.currentTheme.primaryTextColor ?? Theme.defaultTheme.primaryTextColor).opacity(0.7))
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(themeManager?.currentTheme.subtleTextColor ?? Theme.defaultTheme.subtleTextColor)
                }
                .onTapGesture {
                    showingEmailPreferences = true
                }
            }
            .padding(20)
            .themedGlassMorphism(cornerRadius: 20)
        }
    }
    
    #if DEBUG
    private var simpleDebugSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("🧪 Debug")
                    .font(.headline)
                    .foregroundStyle(themeManager?.currentTheme.primaryTextColor ?? Theme.defaultTheme.primaryTextColor)
                
                Spacer()
                
                Button("Toggle Premium") {
                    premiumManager?.toggleDebugPremium()
                    HapticManager.shared.lightImpact()
                }
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.red)
                .foregroundStyle(themeManager?.currentTheme.primaryTextColor ?? Theme.defaultTheme.primaryTextColor)
                .cornerRadius(6)
            }
            
            VStack(spacing: 8) {
                Button("Reset Email Capture") {
                    authManager.resetForTesting()
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.red)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("AUTH DEBUG:")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.yellow)
                
                Text("isEmailCaptured: \(authManager.isEmailCaptured)")
                    .font(.system(size: 10))
                    .foregroundStyle(themeManager?.currentTheme.primaryTextColor ?? Theme.defaultTheme.primaryTextColor)
                
                Text("userEmail: \(authManager.userEmail ?? "nil")")
                    .font(.system(size: 10))
                    .foregroundStyle(themeManager?.currentTheme.primaryTextColor ?? Theme.defaultTheme.primaryTextColor)
                
                Text("shouldShowEmailCapture: \(authManager.shouldShowEmailCapture)")
                    .font(.system(size: 10))
                    .foregroundStyle(themeManager?.currentTheme.primaryTextColor ?? Theme.defaultTheme.primaryTextColor)
            }
            .padding(8)
            .background(Color.black.opacity(0.5))
            .cornerRadius(8)
            
            HStack {
                Text("Status: \(premiumManager?.userIsPremium == true ? "PREMIUM ✅" : "FREE ❌")")
                    .font(.caption)
                    .foregroundStyle((themeManager?.currentTheme.primaryTextColor ?? Theme.defaultTheme.primaryTextColor).opacity(0.7))
                
                Spacer()
                
                Button("1H Premium") {
                    premiumManager?.grantTemporaryPremium(duration: 3600)
                    HapticManager.shared.lightImpact()
                }
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.blue)
                .foregroundStyle(themeManager?.currentTheme.primaryTextColor ?? Theme.defaultTheme.primaryTextColor)
                .cornerRadius(6)
            }
        }
        .padding()
        .background(Color.red.opacity(0.2))
        .cornerRadius(12)
    }
    #endif
}

// MARK: - Preview
#Preview {
    // Create a mock AuthenticationManager with email captured
    let mockAuthManager = AuthenticationManager()
    mockAuthManager.userEmail = "preview@example.com"
    mockAuthManager.isEmailCaptured = true
    
    return SettingsView()
        .modelContainer(for: [TimeBlock.self, DailyProgress.self, RoutineTemplate.self], inMemory: true)
        .environment(\.premiumManager, PremiumManager())
        .environmentObject(mockAuthManager)
}
