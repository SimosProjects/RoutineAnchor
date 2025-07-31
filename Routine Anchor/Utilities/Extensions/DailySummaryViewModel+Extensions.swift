//
//  DailySummaryViewModel+Extension.swift
//  Routine Anchor
//
//  Extension to add missing methods for DailySummaryView
//
import Foundation

extension DailySummaryViewModel {
    /// Generate insights (wrapper for getPersonalizedInsights)
    func generateInsights() -> [String]? {
        let insights = getPersonalizedInsights()
        return insights.isEmpty ? nil : insights
    }
}
