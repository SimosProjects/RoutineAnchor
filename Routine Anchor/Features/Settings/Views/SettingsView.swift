//
//  SettingsView.swift
//  Routine Anchor - Premium Version (iOS 17+ Optimized)
//
import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    // iOS 17+ Pattern: Direct initialization with @State
    @State private var viewModel: SettingsViewModel
    
    // MARK: - State
    @State private var showingAbout = false
    @State private var showingSupport = false
    @State private var showingPrivacy = false
    @State private var showingResetConfirmation = false
    @State private var isAnimating = false
    
    // Settings state - synced with ViewModel
    @State private var notificationsEnabled = false
    @State private var dailyReminderTime = Date()
    @State private var notificationSound = "Default"
    @State private var hapticsEnabled = true
    @State private var autoResetEnabled = false
    
    // MARK: - Initialization
    init() {
        // Initialize with placeholder - will be configured in .task
        let placeholderDataManager = DataManager(modelContext: ModelContext(ModelContainer.shared))
        _viewModel = State(initialValue: SettingsViewModel(dataManager: placeholderDataManager))
    }
    
    var body: some View {
        ZStack {
            // Premium background
            AnimatedGradientBackground()
                .ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Header
                    headerSection
                    
                    // Settings sections
                    notificationSection
                    behaviorSection
                    dataSection
                    aboutSection
                    
                    // Footer
                    footerSection
                }
                .padding(.vertical, 20)
            }
        }
        .navigationBarHidden(true)
        .task {
            await configureViewModel()
            loadSettings()
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                isAnimating = true
            }
        }
        .sheet(isPresented: $showingAbout) {
            AboutView()
        }
        .sheet(isPresented: $showingSupport) {
            SupportView()
        }
        .sheet(isPresented: $showingPrivacy) {
            PrivacyPolicyView()
        }
        .alert("Reset All Data?", isPresented: $showingResetConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Reset", role: .destructive) {
                viewModel.resetAllData()
                HapticManager.shared.error()
            }
        } message: {
            Text("This will permanently delete all your time blocks and progress. This action cannot be undone.")
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 16) {
            HStack {
                Button(action: { dismiss() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Back")
                            .font(.system(size: 16, weight: .medium))
                    }
                    .foregroundStyle(Color.premiumTextSecondary)
                }
                
                Spacer()
            }
            .padding(.horizontal, 24)
            
            Text("Settings")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.white, Color.white.opacity(0.8)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .opacity(isAnimating ? 1 : 0)
                .offset(y: isAnimating ? 0 : 20)
        }
    }
    
    // MARK: - Notification Section
    private var notificationSection: some View {
        VStack(spacing: 16) {
            SectionHeader(title: "Notifications", icon: "bell")
            
            VStack(spacing: 0) {
                // Notifications toggle
                SettingsRow(
                    icon: "bell.badge",
                    title: "Enable Notifications",
                    subtitle: "Get reminders for your time blocks"
                ) {
                    Toggle("", isOn: $notificationsEnabled)
                        .tint(Color.premiumBlue)
                        .onChange(of: notificationsEnabled) { _, newValue in
                            viewModel.notificationsEnabled = newValue
                        }
                }
                
                Divider()
                    .background(Color.white.opacity(0.1))
                    .padding(.leading, 56)
                
                // Daily reminder time
                SettingsRow(
                    icon: "clock",
                    title: "Daily Reminder",
                    subtitle: "Time to review your day"
                ) {
                    DatePicker(
                        "",
                        selection: $dailyReminderTime,
                        displayedComponents: .hourAndMinute
                    )
                    .labelsHidden()
                    .tint(Color.premiumBlue)
                    .onChange(of: dailyReminderTime) { _, newValue in
                        viewModel.dailyReminderTime = newValue
                    }
                }
                .opacity(notificationsEnabled ? 1 : 0.5)
                .disabled(!notificationsEnabled)
                
                Divider()
                    .background(Color.white.opacity(0.1))
                    .padding(.leading, 56)
                
                // Notification sound
                SettingsRow(
                    icon: "speaker.wave.2",
                    title: "Notification Sound",
                    subtitle: notificationSound
                ) {
                    Menu {
                        ForEach(["Default", "Chime", "Bell", "Digital", "None"], id: \.self) { sound in
                            Button(sound) {
                                notificationSound = sound
                                viewModel.notificationSound = sound
                            }
                        }
                    } label: {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14))
                            .foregroundStyle(Color.premiumTextTertiary)
                    }
                }
                .opacity(notificationsEnabled ? 1 : 0.5)
                .disabled(!notificationsEnabled)
            }
            .glassMorphism()
        }
        .padding(.horizontal, 24)
        .opacity(isAnimating ? 1 : 0)
        .offset(y: isAnimating ? 0 : 20)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1), value: isAnimating)
    }
    
    // MARK: - Behavior Section
    private var behaviorSection: some View {
        VStack(spacing: 16) {
            SectionHeader(title: "Behavior", icon: "gearshape.2")
            
            VStack(spacing: 0) {
                // Haptics toggle
                SettingsRow(
                    icon: "hand.tap",
                    title: "Haptic Feedback",
                    subtitle: "Vibrations for interactions"
                ) {
                    Toggle("", isOn: $hapticsEnabled)
                        .tint(Color.premiumBlue)
                        .onChange(of: hapticsEnabled) { _, newValue in
                            viewModel.hapticsEnabled = newValue
                        }
                }
                
                Divider()
                    .background(Color.white.opacity(0.1))
                    .padding(.leading, 56)
                
                // Auto-reset toggle
                SettingsRow(
                    icon: "arrow.clockwise",
                    title: "Auto-Reset at Midnight",
                    subtitle: "Start fresh each day"
                ) {
                    Toggle("", isOn: $autoResetEnabled)
                        .tint(Color.premiumBlue)
                        .onChange(of: autoResetEnabled) { _, newValue in
                            viewModel.autoResetEnabled = newValue
                        }
                }
            }
            .glassMorphism()
        }
        .padding(.horizontal, 24)
        .opacity(isAnimating ? 1 : 0)
        .offset(y: isAnimating ? 0 : 20)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2), value: isAnimating)
    }
    
    // MARK: - Data Section
    private var dataSection: some View {
        VStack(spacing: 16) {
            SectionHeader(title: "Data", icon: "externaldrive")
            
            VStack(spacing: 0) {
                // Export data
                SettingsRow(
                    icon: "square.and.arrow.up",
                    title: "Export Data",
                    subtitle: "Save your progress"
                ) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.premiumTextTertiary)
                }
                .onTapGesture {
                    viewModel.exportData()
                }
                
                Divider()
                    .background(Color.white.opacity(0.1))
                    .padding(.leading, 56)
                
                // Reset data
                SettingsRow(
                    icon: "trash",
                    title: "Reset All Data",
                    subtitle: "Clear everything and start over"
                ) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.red.opacity(0.8))
                }
                .onTapGesture {
                    showingResetConfirmation = true
                }
            }
            .glassMorphism()
        }
        .padding(.horizontal, 24)
        .opacity(isAnimating ? 1 : 0)
        .offset(y: isAnimating ? 0 : 20)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.3), value: isAnimating)
    }
    
    // MARK: - About Section
    private var aboutSection: some View {
        VStack(spacing: 16) {
            SectionHeader(title: "About", icon: "info.circle")
            
            VStack(spacing: 0) {
                // About app
                SettingsRow(
                    icon: "info.circle",
                    title: "About Routine Anchor",
                    subtitle: "Version \(appVersionString)"
                ) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.premiumTextTertiary)
                }
                .onTapGesture {
                    showingAbout = true
                }
                
                Divider()
                    .background(Color.white.opacity(0.1))
                    .padding(.leading, 56)
                
                // Support
                SettingsRow(
                    icon: "questionmark.circle",
                    title: "Support",
                    subtitle: "Get help"
                ) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.premiumTextTertiary)
                }
                .onTapGesture {
                    showingSupport = true
                }
                
                Divider()
                    .background(Color.white.opacity(0.1))
                    .padding(.leading, 56)
                
                // Privacy policy
                SettingsRow(
                    icon: "lock.shield",
                    title: "Privacy Policy",
                    subtitle: "Your data is safe"
                ) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.premiumTextTertiary)
                }
                .onTapGesture {
                    showingPrivacy = true
                }
            }
            .glassMorphism()
        }
        .padding(.horizontal, 24)
        .opacity(isAnimating ? 1 : 0)
        .offset(y: isAnimating ? 0 : 20)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.4), value: isAnimating)
    }
    
    // MARK: - Footer Section
    private var footerSection: some View {
        VStack(spacing: 8) {
            Text("Made with ❤️ in SwiftUI")
                .font(TypographyConstants.UI.footnote)
                .foregroundStyle(Color.premiumTextSecondary)
            
            Text("© 2025 Routine Anchor")
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
    private func configureViewModel() async {
        // Create proper DataManager with current context
        let dataManager = DataManager(modelContext: modelContext)
        
        // Reinitialize ViewModel with proper dependencies
        viewModel = SettingsViewModel(dataManager: dataManager)
    }
    
    private func loadSettings() {
        // Load settings from viewModel
        notificationsEnabled = viewModel.notificationsEnabled
        notificationSound = viewModel.notificationSound
        hapticsEnabled = viewModel.hapticsEnabled
        autoResetEnabled = viewModel.autoResetEnabled
        dailyReminderTime = viewModel.dailyReminderTime
    }
}
