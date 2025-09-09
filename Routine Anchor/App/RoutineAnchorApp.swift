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

    // Managers provided via Environment
    @State private var premiumManager = PremiumManager()
    @State private var themeManager: ThemeManager? = nil

    // SwiftData container
    @State private var modelContainer: ModelContainer?

    // UI state
    @State private var showMigrationView = false
    @State private var initializationError: Error?

    // MARK: - App Delegate
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    init() {
        handleUITestReset()
    }

    // MARK: - Body
    var body: some Scene {
        WindowGroup {
            Group {
                if let container = modelContainer {
                    ContentView()
                        .modelContainer(container)
                        .environmentObject(migrationService)
                        .environmentObject(authManager)
                        .environmentObject(adManager)
                        .environment(\.premiumManager, premiumManager)
                        .environment(\.themeManager, themeManager)
                        .onAppear {
                            if themeManager == nil {
                                themeManager = ThemeManager()
                            }
                        }
                        .overlay {
                            if showMigrationView {
                                MigrationProgressView()
                                    .environmentObject(migrationService)
                            }
                        }

                } else if let error = initializationError {
                    DataErrorView(error: error) {
                        Task { await initializeModelContainer() }
                    }

                } else {
                    AppLoadingView()
                }
            }
            .task { await initializeModelContainer() }
            .onChange(of: migrationService.isMigrating) { isMigrating in
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
        let isUITesting =
            ProcessInfo.processInfo.arguments.contains("--uitesting") ||
            ProcessInfo.processInfo.environment["UITEST_MODE"] == "1"

        guard isUITesting else { return }
        print("🧪 UI Test Mode Detected")

        let shouldResetOnboarding =
            ProcessInfo.processInfo.arguments.contains("--reset-onboarding") ||
            ProcessInfo.processInfo.environment["RESET_ONBOARDING"] == "1"

        let shouldResetState =
            ProcessInfo.processInfo.arguments.contains("--reset-state") ||
            ProcessInfo.processInfo.environment["CLEAR_USER_DEFAULTS"] == "1"

        if shouldResetOnboarding || shouldResetState { resetOnboardingState() }
        if shouldResetState {
            clearAllUserDefaults()
            clearSwiftDataIfNeeded()
        }

        if ProcessInfo.processInfo.arguments.contains("--disable-animations") ||
            ProcessInfo.processInfo.environment["DISABLE_ANIMATIONS"] == "1" {
            UIView.setAnimationsEnabled(false)
            print("✅ UI Test: Animations disabled")
        }
        #endif
    }

    private func resetOnboardingState() {
        #if DEBUG
        let keys = [
            "hasCompletedOnboarding",
            "onboardingCompletedAt",
            "notificationsEnabled",
            "notificationSound",
            "hapticsEnabled",
            "autoResetEnabled",
            "dailyReminderTime",
            // PREMIUM RESET
            "userIsPremium",
            "temporaryPremiumUntil"
        ]
        let defaults = UserDefaults.standard
        keys.forEach { defaults.removeObject(forKey: $0) }
        defaults.synchronize()
        print("✅ UI Test: Onboarding state reset")
        #endif
    }

    private func clearAllUserDefaults() {
        #if DEBUG
        if let bundleIdentifier = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: bundleIdentifier)
        }
        let defaults = UserDefaults.standard
        defaults.dictionaryRepresentation().keys.forEach { defaults.removeObject(forKey: $0) }
        defaults.synchronize()
        print("✅ UI Test: All UserDefaults cleared")
        #endif
    }

    private func clearSwiftDataIfNeeded() {
        #if DEBUG
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let storeURL = appSupport.appendingPathComponent("default.store")
        try? FileManager.default.removeItem(at: storeURL)
        print("✅ UI Test: SwiftData store cleared")
        #endif
    }

    // MARK: - Initialization

    /// Initialize the model container with migration support
    @MainActor
    private func initializeModelContainer() async {
        do {
            let container = try migrationService.createModelContainer()
            try await Task.sleep(nanoseconds: 100_000_000) // 0.1s
            withAnimation { self.modelContainer = container }
            print("✅ Model container initialized successfully")
        } catch {
            print("❌ Failed to initialize model container: \(error)")
            self.initializationError = error
        }
    }
}

// MARK: - Migration Progress View
struct MigrationProgressView: View {
    @Environment(\.themeManager) private var themeManager
    @EnvironmentObject var migrationService: MigrationService
    @State private var animationProgress: Double = 0

    private var theme: AppTheme { themeManager?.currentTheme ?? PredefinedThemes.classic }

    var body: some View {
        ZStack {
            // Dim scrim
            Color.black.opacity(0.8).ignoresSafeArea()

            VStack(spacing: 24) {
                Image(systemName: "arrow.triangle.2.circlepath.circle.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [theme.accentPrimaryColor, theme.accentSecondaryColor],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )
                    .rotationEffect(.degrees(animationProgress * 360))
                    .animation(.linear(duration: 2).repeatForever(autoreverses: false), value: animationProgress)

                Text("Updating Your Data")
                    .font(.system(size: 24, weight: .semibold, design: .rounded))
                    .foregroundStyle(theme.primaryTextColor)

                Text("We're migrating your data to the latest format. This will only take a moment.")
                    .font(.system(size: 14))
                    .foregroundStyle(theme.secondaryTextColor)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                VStack(spacing: 8) {
                    ProgressView(value: migrationService.migrationProgress)
                        .tint(theme.accentPrimaryColor)
                        .scaleEffect(y: 2)

                    Text("\(Int(migrationService.migrationProgress * 100))%")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(theme.secondaryTextColor.opacity(0.9))
                }
                .padding(.horizontal)

                if let error = migrationService.migrationError {
                    VStack(spacing: 12) {
                        Text("Migration Issue")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(theme.statusErrorColor)

                        Text(error.localizedDescription)
                            .font(.system(size: 12))
                            .foregroundStyle(theme.secondaryTextColor)
                            .multilineTextAlignment(.center)

                        Button {
                            migrationService.clearError()
                        } label: {
                            Text("Dismiss")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(theme.primaryTextColor)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 8)
                                .background(theme.statusErrorColor.opacity(0.20))
                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        }
                    }
                    .padding()
                    .background(theme.statusErrorColor.opacity(0.10))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }
            .padding(32)
            .background(
                // Glassy card
                ZStack {
                    RoundedRectangle(cornerRadius: 24, style: .continuous).fill(.ultraThinMaterial)
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(theme.borderColor, lineWidth: 1)
                }
            )
            .padding()
        }
        .onAppear { animationProgress = 1 }
    }
}

// MARK: - App Loading View
struct AppLoadingView: View {
    @Environment(\.themeManager) private var themeManager
    @State private var pulseScale: CGFloat = 1.0
    @State private var rotationDegrees: Double = 0

    private var theme: AppTheme { themeManager?.currentTheme ?? PredefinedThemes.classic }

    var body: some View {
        ZStack {
            theme.heroBackground.ignoresSafeArea()

            VStack(spacing: 32) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [theme.accentPrimaryColor, theme.accentSecondaryColor],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 100, height: 100)
                        .scaleEffect(pulseScale)
                        .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: pulseScale)

                    Image(systemName: "clock.fill")
                        .font(.system(size: 50))
                        .foregroundStyle(theme.invertedTextColor)
                        .rotationEffect(.degrees(rotationDegrees))
                        .animation(.linear(duration: 8).repeatForever(autoreverses: false), value: rotationDegrees)
                }

                Text("Routine Anchor")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(colors: [theme.invertedTextColor, theme.primaryTextColor.opacity(0.8)],
                                       startPoint: .top, endPoint: .bottom)
                    )

                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(theme.invertedTextColor)
                    .scaleEffect(1.2)
            }
            .padding()
        }
        .onAppear {
            pulseScale = 1.2
            rotationDegrees = 360
        }
    }
}

// MARK: - Data Error View
struct DataErrorView: View {
    @Environment(\.themeManager) private var themeManager

    let error: Error
    let retry: () -> Void

    private var theme: AppTheme { themeManager?.currentTheme ?? PredefinedThemes.classic }

    var body: some View {
        ZStack {
            theme.heroBackground.ignoresSafeArea()

            VStack(spacing: 24) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(theme.statusWarningColor)

                Text("Unable to Load Data")
                    .font(.system(size: 24, weight: .semibold, design: .rounded))
                    .foregroundStyle(theme.primaryTextColor)

                Text(error.localizedDescription)
                    .font(.system(size: 14))
                    .foregroundStyle(theme.secondaryTextColor)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                VStack(spacing: 12) {
                    Button(action: retry) {
                        Label("Try Again", systemImage: "arrow.clockwise")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(theme.invertedTextColor)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(theme.accentPrimaryColor)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .buttonStyle(.plain)

                    Button {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        Text("Check Settings")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(theme.secondaryTextColor)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 40)
            }
            .padding()
        }
    }
}
