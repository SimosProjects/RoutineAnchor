//
//  ViewModelRefreshExtensions.swift
//  Routine Anchor
//
//  Extensions to add refresh capability to ViewModels
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
                await self?.refreshData()
            }
        }
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
                await self?.refreshData()
            }
        }
    }
}

// MARK: - View Extension for Auto-Refresh

extension View {
    /// Auto-refresh TodayView on tab change
    func autoRefreshToday(viewModel: TodayViewModel?) -> some View {
        self.onAppear {
            viewModel?.setupRefreshObserver()
        }
        .task {
            await viewModel?.refreshData()
        }
    }
    
    /// Auto-refresh ScheduleView on tab change
    func autoRefreshSchedule(viewModel: ScheduleBuilderViewModel?) -> some View {
        self.onAppear {
            viewModel?.setupRefreshObserver()
        }
        .task {
            viewModel?.loadTimeBlocks()
        }
    }
    
    /// Auto-refresh SummaryView on tab change
    func autoRefreshSummary(viewModel: DailySummaryViewModel?) -> some View {
        self.onAppear {
            viewModel?.setupRefreshObserver()
        }
        .task {
            await viewModel?.refreshData()
        }
    }
}
