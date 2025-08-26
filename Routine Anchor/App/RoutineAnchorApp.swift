//
//  RoutineAnchorApp.swift
//  Routine Anchor
//
//  Main application entry point with migration support and premium integration
//
import SwiftUI
import SwiftData

@main
struct RoutineAnchorApp: App {
    // MARK: - Properties
    @StateObject private var migrationService = MigrationService.shared
    @StateObject private var authManager = AuthenticationManager()
    @StateObject private var adManager = AdManager()
    @State private var premiumManager = PremiumManager()
    @State private var themeManager: ThemeManager?
    @State private var modelContainer: ModelContainer?
    @State private var showMigrationView = false
    @State private var initializationError: Error?
    
    // MARK: - App Delegate
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    init() {
        // Handle UI test reset flags
        handleUITestReset()
    }
    
    // MARK: - Body
    var body: some Scene {
        WindowGroup {
            Group {
                if let container = modelContainer {
                    // Main app content with premium manager
                    ContentView()
                        .modelContainer(container)
                        .environmentObject(migrationService)
                        .premiumEnvironment(premiumManager)
                        .environmentObject(authManager)
                        .environmentObject(adManager)
                        .environment(\.themeManager, themeManager)
                        .onAppear {
                            if themeManager == nil {
                                themeManager = ThemeManager(premiumManager: premiumManager)
                            }
                        }
                        .overlay {
                            if showMigrationView {
                                MigrationProgressView()
                                    .environmentObject(migrationService)
                            }
                        }
                } else if let error = initializationError {
                    // Error state
                    DataErrorView(error: error) {
                        Task {
                            await initializeModelContainer()
                        }
                    }
                } else {
                    // Loading state
                    AppLoadingView()
                }
            }
            .task {
                await initializeModelContainer()
            }
            .onChange(of: migrationService.isMigrating) { _, isMigrating in
                withAnimation(.easeInOut(duration: 0.3)) {
                    showMigrationView = isMigrating
                }
            }
        }
    }
    
    // MARK: - UI Test Support
    
    /// Handle UI test launch arguments and environment variables
    private func handleUITestReset() {
        #if DEBUG
        // Check if we're in UI test mode
        let isUITesting = ProcessInfo.processInfo.arguments.contains("--uitesting") ||
                         ProcessInfo.processInfo.environment["UITEST_MODE"] == "1"
        
        guard isUITesting else { return }
        
        print("🧪 UI Test Mode Detected")
        
        // Check for reset flags
        let shouldResetOnboarding = ProcessInfo.processInfo.arguments.contains("--reset-onboarding") ||
                                   ProcessInfo.processInfo.environment["RESET_ONBOARDING"] == "1"
        
        let shouldResetState = ProcessInfo.processInfo.arguments.contains("--reset-state") ||
                              ProcessInfo.processInfo.environment["CLEAR_USER_DEFAULTS"] == "1"
        
        if shouldResetOnboarding || shouldResetState {
            resetOnboardingState()
        }
        
        if shouldResetState {
            clearAllUserDefaults()
            clearSwiftDataIfNeeded()
        }
        
        // Disable animations for UI tests
        if ProcessInfo.processInfo.arguments.contains("--disable-animations") ||
           ProcessInfo.processInfo.environment["DISABLE_ANIMATIONS"] == "1" {
            UIView.setAnimationsEnabled(false)
            print("✅ UI Test: Animations disabled")
        }
        #endif
    }
    
    /// Reset onboarding-related UserDefaults
    private func resetOnboardingState() {
        #if DEBUG
        UserDefaults.standard.removeObject(forKey: "hasCompletedOnboarding")
        UserDefaults.standard.removeObject(forKey: "onboardingCompletedAt")
        UserDefaults.standard.removeObject(forKey: "notificationsEnabled")
        UserDefaults.standard.removeObject(forKey: "notificationSound")
        UserDefaults.standard.removeObject(forKey: "hapticsEnabled")
        UserDefaults.standard.removeObject(forKey: "autoResetEnabled")
        UserDefaults.standard.removeObject(forKey: "dailyReminderTime")
        // PREMIUM RESET
        UserDefaults.standard.removeObject(forKey: "userIsPremium")
        UserDefaults.standard.removeObject(forKey: "temporaryPremiumUntil")
        UserDefaults.standard.synchronize()
        
        print("✅ UI Test: Onboarding state reset")
        #endif
    }
    
    /// Clear all UserDefaults (for complete reset)
    private func clearAllUserDefaults() {
        #if DEBUG
        if let bundleIdentifier = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: bundleIdentifier)
        }
        
        // Also clear standard UserDefaults
        let defaults = UserDefaults.standard
        let dictionary = defaults.dictionaryRepresentation()
        dictionary.keys.forEach { key in
            defaults.removeObject(forKey: key)
        }
        
        defaults.synchronize()
        print("✅ UI Test: All UserDefaults cleared")
        #endif
    }
    
    /// Clear SwiftData store if needed
    private func clearSwiftDataIfNeeded() {
        #if DEBUG
        // Get the URL for the SwiftData store
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory,
                                                  in: .userDomainMask).first!
        let storeURL = appSupport.appendingPathComponent("default.store")
        
        // Remove the store file if it exists
        try? FileManager.default.removeItem(at: storeURL)
        
        print("✅ UI Test: SwiftData store cleared")
        #endif
    }
    
    // MARK: - Initialization
    
    /// Initialize the model container with migration support
    @MainActor
    private func initializeModelContainer() async {
        do {
            // Create container with migration support
            let container = try migrationService.createModelContainer()
            
            // Small delay to ensure proper initialization
            try await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
            
            withAnimation {
                self.modelContainer = container
            }
            
            print("✅ Model container initialized successfully")
            
        } catch {
            print("❌ Failed to initialize model container: \(error)")
            self.initializationError = error
        }
    }
}

// MARK: - Migration Progress View (unchanged)
struct MigrationProgressView: View {
    @EnvironmentObject var migrationService: MigrationService
    @State private var animationProgress: Double = 0
    
    var body: some View {
        ZStack {
            // Full screen background
            Color.black.opacity(0.8)
                .ignoresSafeArea()
            
            // Migration card
            VStack(spacing: 24) {
                // Icon
                Image(systemName: "arrow.triangle.2.circlepath.circle.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.anchorBlue, Color.anchorPurple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .rotationEffect(.degrees(animationProgress * 360))
                    .animation(
                        .linear(duration: 2).repeatForever(autoreverses: false),
                        value: animationProgress
                    )
                
                // Title
                Text("Updating Your Data")
                    .font(.system(size: 24, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                
                // Description
                Text("We're migrating your data to the latest format. This will only take a moment.")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                // Progress bar
                VStack(spacing: 8) {
                    ProgressView(value: migrationService.migrationProgress)
                        .progressViewStyle(LinearProgressViewStyle())
                        .tint(Color.anchorBlue)
                        .scaleEffect(y: 2)
                    
                    Text("\(Int(migrationService.migrationProgress * 100))%")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                }
                .padding(.horizontal)
                
                // Error message if any
                if let error = migrationService.migrationError {
                    VStack(spacing: 12) {
                        Text("Migration Issue")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.red)
                        
                        Text(error.localizedDescription)
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                        
                        Button(action: {
                            migrationService.clearError()
                        }) {
                            Text("Dismiss")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 8)
                                .background(Color.red.opacity(0.2))
                                .cornerRadius(8)
                        }
                    }
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(12)
                }
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.2),
                                        Color.white.opacity(0.1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            )
            .padding()
        }
        .onAppear {
            animationProgress = 1
        }
    }
}

// MARK: - App Loading View (unchanged)
struct AppLoadingView: View {
    @State private var pulseScale: CGFloat = 1.0
    @State private var rotationDegrees: Double = 0
    
    var body: some View {
        ZStack {
            // Background gradient
            ThemedAnimatedBackground()
                .ignoresSafeArea()
            
            VStack(spacing: 32) {
                // App icon placeholder
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.anchorBlue, Color.anchorPurple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 100, height: 100)
                        .scaleEffect(pulseScale)
                        .animation(
                            .easeInOut(duration: 1.5).repeatForever(autoreverses: true),
                            value: pulseScale
                        )
                    
                    Image(systemName: "clock.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.white)
                        .rotationEffect(.degrees(rotationDegrees))
                        .animation(
                            .linear(duration: 8).repeatForever(autoreverses: false),
                            value: rotationDegrees
                        )
                }
                
                Text("Routine Anchor")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, .white.opacity(0.8)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.2)
            }
        }
        .onAppear {
            pulseScale = 1.2
            rotationDegrees = 360
        }
    }
}

// MARK: - Data Error View (unchanged)
struct DataErrorView: View {
    let error: Error
    let retry: () -> Void
    
    var body: some View {
        ZStack {
            // Background
            ThemedAnimatedBackground()
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Error icon
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.yellow)
                
                // Title
                Text("Unable to Load Data")
                    .font(.system(size: 24, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                
                // Error message
                Text(error.localizedDescription)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                // Actions
                VStack(spacing: 12) {
                    Button(action: retry) {
                        Label("Try Again", systemImage: "arrow.clockwise")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.anchorBlue)
                            .cornerRadius(12)
                    }
                    
                    Button(action: {
                        // Open settings to check storage
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        Text("Check Settings")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                .padding(.horizontal, 40)
            }
            .padding()
        }
    }
}
