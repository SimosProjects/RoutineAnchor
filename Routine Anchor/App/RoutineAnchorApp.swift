//
//  RoutineAnchorApp.swift
//  Routine Anchor
//
//  Main application entry point with migration support
//

import SwiftUI
import SwiftData

@main
struct RoutineAnchorApp: App {
    // MARK: - Properties
    @StateObject private var migrationService = MigrationService.shared
    @State private var modelContainer: ModelContainer?
    @State private var showMigrationView = false
    @State private var initializationError: Error?
    
    // MARK: - App Delegate
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    // MARK: - Body
    var body: some Scene {
        WindowGroup {
            Group {
                if let container = modelContainer {
                    // Main app content
                    ContentView()
                        .modelContainer(container)
                        .environmentObject(migrationService)
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

// MARK: - Migration Progress View
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
                            colors: [Color.premiumBlue, Color.premiumPurple],
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
                        .tint(Color.premiumBlue)
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

// MARK: - App Loading View
struct AppLoadingView: View {
    @State private var pulseScale: CGFloat = 1.0
    @State private var rotationDegrees: Double = 0
    
    var body: some View {
        ZStack {
            // Background gradient
            AnimatedGradientBackground()
                .ignoresSafeArea()
            
            VStack(spacing: 32) {
                // App icon placeholder
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.premiumBlue, Color.premiumPurple],
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

// MARK: - Data Error View
struct DataErrorView: View {
    let error: Error
    let retry: () -> Void
    
    var body: some View {
        ZStack {
            // Background
            AnimatedGradientBackground()
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
                            .background(Color.premiumBlue)
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
