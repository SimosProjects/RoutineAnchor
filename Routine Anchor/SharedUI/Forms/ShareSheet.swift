//
//  ShareSheet.swift
//  Routine Anchor
//
//  Minimal SwiftUI wrapper around UIActivityViewController.
//

import SwiftUI
import UIKit

@MainActor
struct ShareSheet: UIViewControllerRepresentable {
    /// Items to share (URL, String, UIImage, Data, etc.)
    var items: [Any]

    /// Activities to hide (optional).
    var excludedActivityTypes: [UIActivity.ActivityType] = []

    /// Subject for Mail share (optional).
    var subject: String? = nil

    /// Called when the sheet finishes (completed = user shared something).
    var completion: ((Bool) -> Void)? = nil

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        controller.excludedActivityTypes = excludedActivityTypes

        // Set subject for mail share targets
        if let subject {
            controller.setValue(subject, forKey: "subject")
        }

        controller.completionWithItemsHandler = { _, completed, _, _ in
            completion?(completed)
        }
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // Nothing to update while presented
    }
}
