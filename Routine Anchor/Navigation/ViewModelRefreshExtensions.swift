//
//  ViewModelRefreshExtensions.swift
//  Routine Anchor (iOS 17+ Optimized)
//
//  Extensions to add refresh capability to ViewModels without timers
//

import SwiftUI
import Combine

// MARK: - TodayViewModel Extension

extension TodayViewModel {
    func setupRefreshObserver() {
        NotificationCenter.default.addObserver(
            forName: .refreshTodayView,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.refreshData()
            }
        }
    }
    
    func removeRefreshObserver() {
        NotificationCenter.default.removeObserver(self, name: .refreshTodayView, object: nil)
    }
}

// MARK: - ScheduleBuilderViewModel Extension

extension ScheduleBuilderViewModel {
    func setupRefreshObserver() {
        NotificationCenter.default.addObserver(
            forName: .refreshScheduleView,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.loadTimeBlocks()
            }
        }
    }
    
    func removeRefreshObserver() {
        NotificationCenter.default.removeObserver(self, name: .refreshScheduleView, object: nil)
    }
}

// MARK: - DailySummaryViewModel Extension

extension DailySummaryViewModel {
    func setupRefreshObserver() {
        NotificationCenter.default.addObserver(
            forName: .refreshSummaryView,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.refreshData()
            }
        }
    }
    
    func removeRefreshObserver() {
        NotificationCenter.default.removeObserver(self, name: .refreshSummaryView, object: nil)
    }
}

// MARK: - View Modifier for Time-Based Updates

struct TimeBasedRefreshModifier: ViewModifier {
    let interval: TimeInterval
    let action: () async -> Void
    
    @State private var refreshTask: Task<Void, Never>?
    
    func body(content: Content) -> some View {
        content
            .task {
                // Initial refresh
                await action()
                
                // Schedule periodic updates
                refreshTask = Task {
                    while !Task.isCancelled {
                        try? await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
                        
                        if !Task.isCancelled {
                            await action()
                        }
                    }
                }
            }
            .onDisappear {
                refreshTask?.cancel()
                refreshTask = nil
            }
    }
}

extension View {
    /// Add time-based refresh to a view
    /// This properly manages the refresh task lifecycle
    func refreshPeriodically(
        every interval: TimeInterval,
        action: @escaping () async -> Void
    ) -> some View {
        modifier(TimeBasedRefreshModifier(interval: interval, action: action))
    }
}

// MARK: - Enhanced Refresh Modifiers

extension View {
    /// Refresh TodayView on tab change with proper lifecycle management
    func autoRefreshToday(viewModel: TodayViewModel) -> some View {
        self
            .task {
                viewModel.setupRefreshObserver()
                viewModel.refreshData()
            }
            .onDisappear {
                viewModel.removeRefreshObserver()
            }
            .refreshPeriodically(every: 60) {
                viewModel.refreshData()
            }
    }
    
    /// Refresh ScheduleView on tab change
    func autoRefreshSchedule(viewModel: ScheduleBuilderViewModel) -> some View {
        self
            .task {
                viewModel.setupRefreshObserver()
                viewModel.loadTimeBlocks()
            }
            .onDisappear {
                viewModel.removeRefreshObserver()
            }
    }
    
    /// Refresh SummaryView on tab change
    func autoRefreshSummary(viewModel: DailySummaryViewModel) -> some View {
        self
            .task {
                viewModel.setupRefreshObserver()
                viewModel.refreshData()
            }
            .onDisappear {
                viewModel.removeRefreshObserver()
            }
    }
}
