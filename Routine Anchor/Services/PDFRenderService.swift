//
//  PDFRenderService.swift
//  Routine Anchor
//

import SwiftUI
import UIKit

@MainActor
enum PDFRenderService {
    /// Renders a SwiftUI view to a single-page PDF and returns a file URL in /tmp.
    static func renderSinglePagePDF<Content: View>(
        pageSize: CGSize = CGSize(width: 612, height: 792), // US Letter at 72pt
        @ViewBuilder content: () -> Content
    ) throws -> URL {
        // Build a fixed-size SwiftUI view with a solid background
        let view = content()
            .frame(width: pageSize.width, height: pageSize.height)
            .background(Color.white)

        // Render SwiftUI -> UIImage (offscreen-safe)
        let imageRenderer = ImageRenderer(content: view)
        imageRenderer.isOpaque = true
        imageRenderer.scale = 2 // bump for crisper output

        guard let image = imageRenderer.uiImage else {
            throw NSError(domain: "PDFRenderService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to render image."])
        }

        // Create the PDF
        let bounds = CGRect(origin: .zero, size: pageSize)
        let pdfRenderer = UIGraphicsPDFRenderer(bounds: bounds)

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("RoutineAnchor-Progress-\(UUID().uuidString).pdf")

        try pdfRenderer.writePDF(to: url) { ctx in
            ctx.beginPage()
            image.draw(in: bounds)
        }

        return url
    }
}

