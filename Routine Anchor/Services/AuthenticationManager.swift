//
//  AuthenticationManager.swift
//  Routine Anchor
//
//  Manages user authentication and email collection
//

import Foundation
import SwiftUI

@MainActor
class AuthenticationManager: ObservableObject {
    // MARK: - Published Properties
    @Published var userEmail: String?
    @Published var isEmailCaptured = false
    @Published var shouldShowEmailCapture = false
    @Published var emailCaptureShownCount = 0
    
    // MARK: - Constants
    private let emailCaptureKey = "emailCaptured"
    private let userEmailKey = "userEmail"
    private let emailCaptureShownKey = "emailCaptureShownCount"
    private let firstLaunchKey = "firstLaunchDate"
    
    // MARK: - Initialization
    init() {
        loadUserData()
        checkShouldShowEmailCapture()
    }
    
    // MARK: - Email Capture Logic
    func checkShouldShowEmailCapture() {
        // Don't show if already captured
        guard !isEmailCaptured else {
            shouldShowEmailCapture = false
            return
        }
        
        // Don't show if shown too many times (max 3 attempts)
        guard emailCaptureShownCount < 3 else {
            shouldShowEmailCapture = false
            return
        }
        
        // Check if user has been using the app for at least 3 days
        let daysRequired = 3
        let firstLaunchDate = UserDefaults.standard.object(forKey: firstLaunchKey) as? Date ?? Date()
        let daysSinceFirstLaunch = Calendar.current.dateComponents([.day], from: firstLaunchDate, to: Date()).day ?? 0
        let shouldShow = daysSinceFirstLaunch >= daysRequired
        
        shouldShowEmailCapture = shouldShow
    }
    
    func captureEmail(_ email: String) {
        userEmail = email
        isEmailCaptured = true
        shouldShowEmailCapture = false
        
        // Save to UserDefaults
        UserDefaults.standard.set(email, forKey: userEmailKey)
        UserDefaults.standard.set(true, forKey: emailCaptureKey)
        
        // TODO: Send to Firebase when implemented
        print("📧 Email captured: \(email)")
        
        // Track successful capture
        HapticManager.shared.anchorSuccess()
    }
    
    func incrementEmailCaptureShownCount() {
        emailCaptureShownCount += 1
        UserDefaults.standard.set(emailCaptureShownCount, forKey: emailCaptureShownKey)
    }
    
    func dismissEmailCapture() {
        shouldShowEmailCapture = false
        incrementEmailCaptureShownCount()
    }
    
    // MARK: - User Data Management
    private func loadUserData() {
        userEmail = UserDefaults.standard.string(forKey: userEmailKey)
        isEmailCaptured = UserDefaults.standard.bool(forKey: emailCaptureKey)
        emailCaptureShownCount = UserDefaults.standard.integer(forKey: emailCaptureShownKey)
        
        // Set first launch date if not set
        if UserDefaults.standard.object(forKey: firstLaunchKey) == nil {
            UserDefaults.standard.set(Date(), forKey: firstLaunchKey)
        }
    }
    
    // MARK: - Account Management
    func updateEmailPreferences(marketing: Bool, productUpdates: Bool, courses: Bool) {
        // Store preferences locally for now
        UserDefaults.standard.set(marketing, forKey: "emailPref_marketing")
        UserDefaults.standard.set(productUpdates, forKey: "emailPref_productUpdates")
        UserDefaults.standard.set(courses, forKey: "emailPref_courses")
        
        // TODO: Update Firebase when implemented
        print("Firebase Implementation needed for email preferences update")
    }
    
    func removeAccount() {
        userEmail = nil
        isEmailCaptured = false
        shouldShowEmailCapture = false
        emailCaptureShownCount = 0
        
        // Clear UserDefaults
        UserDefaults.standard.removeObject(forKey: userEmailKey)
        UserDefaults.standard.removeObject(forKey: emailCaptureKey)
        UserDefaults.standard.removeObject(forKey: emailCaptureShownKey)
        UserDefaults.standard.removeObject(forKey: "emailPref_marketing")
        UserDefaults.standard.removeObject(forKey: "emailPref_productUpdates")
        UserDefaults.standard.removeObject(forKey: "emailPref_courses")
    }
    
    // MARK: - Firebase Integration (TODO)
    private func sendEmailToFirebase(_ email: String) {
        // TODO: Implement Firebase integration
        print("Need to implement Firebase integration to send email to Firestore and add user to email marketing list.")
        // This will include:
        // 1. Create user document in Firestore
        // 2. Add to email marketing list
        // 3. Send welcome email
        // 4. Track analytics event
    }
    
    // MARK: - Debug/Testing Functions
    #if DEBUG
    func resetForTesting() {
        // Clear all stored data
        UserDefaults.standard.removeObject(forKey: emailCaptureKey)
        UserDefaults.standard.removeObject(forKey: userEmailKey)
        UserDefaults.standard.removeObject(forKey: emailCaptureShownKey)
        UserDefaults.standard.removeObject(forKey: firstLaunchKey)
        
        // Reset properties
        userEmail = nil
        isEmailCaptured = false
        shouldShowEmailCapture = false
        emailCaptureShownCount = 0
        
        // Set first launch to 3+ days ago for immediate testing
        let threeDaysAgo = Calendar.current.date(byAdding: .day, value: -3, to: Date()) ?? Date()
        UserDefaults.standard.set(threeDaysAgo, forKey: firstLaunchKey)
        
        // Trigger check
        checkShouldShowEmailCapture()
    }

    func forceShowEmailCapture() {
        shouldShowEmailCapture = true
        print("🧪 AUTH: After - shouldShowEmailCapture = \(shouldShowEmailCapture)")
    }
    #endif
}
