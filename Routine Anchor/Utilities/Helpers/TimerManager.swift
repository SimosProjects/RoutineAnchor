//
//  TimerManager.swift
//  Routine Anchor
//
//  Created to centralize timer lifecycle management and prevent memory leaks
//
import Foundation
import SwiftUI

/// A centralized manager for handling timers with automatic cleanup
@MainActor
class TimerManager: ObservableObject {
    // MARK: - Types
    
    /// Timer configuration
    struct TimerConfiguration {
        let identifier: String
        let interval: TimeInterval
        let repeats: Bool
        let action: @MainActor () -> Void
    }
    
    // MARK: - Properties
    
    /// Active timers mapped by identifier
    private var activeTimers: [String: Timer] = [:]
    
    /// Queue for thread-safe timer operations
    private let timerQueue = DispatchQueue(label: "com.routineanchor.timermanager", attributes: .concurrent)
    
    // MARK: - Singleton (Optional)
    static let shared = TimerManager()
    
    // MARK: - Initialization
    
    init() {
        // Setup notification observers for app lifecycle
        setupLifecycleObservers()
    }
    
    func shutdown() {
        for timer in activeTimers.values {
            timer.invalidate()
        }
        activeTimers.removeAll()
    }
    
    // MARK: - Public Methods
    
    /// Schedule a new timer with automatic management
    /// - Parameters:
    ///   - identifier: Unique identifier for the timer
    ///   - interval: Time interval in seconds
    ///   - repeats: Whether the timer should repeat
    ///   - action: The action to perform when timer fires
    func scheduleTimer(
        identifier: String,
        interval: TimeInterval,
        repeats: Bool = true,
        action: @escaping @MainActor () -> Void
    ) {
        // Cancel any existing timer with the same identifier
        invalidateTimer(identifier: identifier)
        
        // Create new timer with weak self reference
        let timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: repeats) { [weak self] _ in
            Task { @MainActor in
                action()
                
                // Auto-cleanup non-repeating timers
                if !repeats {
                    self?.invalidateTimer(identifier: identifier)
                }
            }
        }
        
        // Store the timer
        activeTimers[identifier] = timer
    }
    
    /// Invalidate a specific timer
    /// - Parameter identifier: The identifier of the timer to invalidate
    func invalidateTimer(identifier: String) {
        if let timer = activeTimers[identifier] {
            timer.invalidate()
            activeTimers.removeValue(forKey: identifier)
        }
    }
    
    /// Invalidate all active timers
    func invalidateAllTimers() {
        for (_, timer) in activeTimers {
            timer.invalidate()
        }
        activeTimers.removeAll()
    }
    
    /// Pause a specific timer
    /// - Parameter identifier: The identifier of the timer to pause
    func pauseTimer(identifier: String) {
        timerQueue.sync {
            activeTimers[identifier]?.fireDate = .distantFuture
        }
    }
    
    /// Resume a paused timer
    /// - Parameter identifier: The identifier of the timer to resume
    func resumeTimer(identifier: String) {
        timerQueue.sync {
            activeTimers[identifier]?.fireDate = Date()
        }
    }
    
    /// Check if a timer is active
    /// - Parameter identifier: The identifier to check
    /// - Returns: Whether the timer is currently active
    func isTimerActive(identifier: String) -> Bool {
        timerQueue.sync {
            return activeTimers[identifier]?.isValid ?? false
        }
    }
    
    // MARK: - Private Methods
    
    /// Setup app lifecycle observers
    private func setupLifecycleObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }
    
    @objc private func handleAppDidEnterBackground() {
        Task { @MainActor in
            for identifier in activeTimers.keys {
                pauseTimer(identifier: identifier)
            }
        }
    }
    
    @objc private func handleAppWillEnterForeground() {
        Task { @MainActor in
            for identifier in activeTimers.keys {
                resumeTimer(identifier: identifier)
            }
        }
    }
}

// MARK: - View Extension for Easy Timer Management

extension View {
    /// Schedule a managed timer that automatically cleans up
    /// - Parameters:
    ///   - identifier: Unique identifier for the timer
    ///   - interval: Time interval in seconds
    ///   - repeats: Whether the timer should repeat
    ///   - isActive: Binding to control timer state
    ///   - action: The action to perform when timer fires
    func managedTimer(
        identifier: String,
        interval: TimeInterval,
        repeats: Bool = true,
        isActive: Binding<Bool>,
        action: @Sendable @escaping () -> Void
    ) -> some View {
        self
            .onAppear {
                if isActive.wrappedValue {
                    TimerManager.shared.scheduleTimer(
                        identifier: identifier,
                        interval: interval,
                        repeats: repeats,
                        action: action
                    )
                }
            }
            .onDisappear {
                TimerManager.shared.invalidateTimer(identifier: identifier)
            }
            .onChange(of: isActive.wrappedValue) { _, newValue in
                if newValue {
                    TimerManager.shared.scheduleTimer(
                        identifier: identifier,
                        interval: interval,
                        repeats: repeats,
                        action: action
                    )
                } else {
                    TimerManager.shared.invalidateTimer(identifier: identifier)
                }
            }
    }
}

// MARK: - Timer Identifiers

/// Common timer identifiers used throughout the app
enum TimerIdentifiers {
    static let todayViewRefresh = "todayView.refresh"
    static let scheduleAutoSave = "schedule.autoSave"
    static let summaryDataRefresh = "summary.dataRefresh"
    static let notificationScheduler = "notification.scheduler"
    static let midnightReset = "settings.midnightReset"
}
