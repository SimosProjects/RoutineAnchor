//
//  ThemeColorSwathsPreview.swift
//  Routine Anchor
//
//  Created by Christopher Simonson on 9/11/25.
//

#if DEBUG
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Theme Color Swatches (Preview-only)

/// Visualizes a ThemeColorScheme in labeled swatches.
/// This view is preview-only (file is wrapped in `#if DEBUG`).
struct ThemeColorSchemeSwatchesView: View {
    let scheme: ThemeColorScheme

    private let columns = [
        GridItem(.flexible(minimum: 120), spacing: 12),
        GridItem(.flexible(minimum: 120), spacing: 12),
        GridItem(.flexible(minimum: 120), spacing: 12)
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                // Backgrounds
                SectionBlock("Backgrounds") {
                    SwatchTile("Primary Background", color: scheme.primaryBackground.color)
                    SwatchTile("Secondary Background", color: scheme.secondaryBackground.color)
                    SwatchTile("Elevated Background", color: scheme.elevatedBackground.color)
                    GradientTile("Background Gradient", colors: scheme.backgroundColors.map { $0.color })
                }

                // Text
                SectionBlock("Text") {
                    SwatchTile("Primary Text", color: scheme.primaryText.color)
                    SwatchTile("Secondary Text", color: scheme.secondaryText.color)
                    SwatchTile("Subtle Text", color: scheme.subtleText.color)
                    SwatchTile("Inverted Text", color: scheme.invertedText.color)
                }

                // Accents
                SectionBlock("Accents") {
                    SwatchTile("Primary Accent", color: scheme.primaryAccent.color)
                    SwatchTile("Secondary Accent", color: scheme.secondaryAccent.color)
                }

                // Buttons
                SectionBlock("Buttons") {
                    SwatchTile("Primary Button", color: scheme.primaryButton.color)
                    SwatchTile("Secondary Button", color: scheme.secondaryButton.color)
                    SwatchTile("Button Accent", color: scheme.buttonAccent.color)
                    GradientTile("Button Gradient", colors: scheme.buttonGradient.map { $0.color })
                }

                // Icons
                SectionBlock("Icons") {
                    SwatchTile("Icon Normal", color: scheme.normal.color)
                    SwatchTile("Icon Muted", color: scheme.muted.color)
                }

                // Status
                SectionBlock("Status") {
                    SwatchTile("Success", color: scheme.success.color)
                    SwatchTile("Warning", color: scheme.warning.color)
                    SwatchTile("Error", color: scheme.error.color)
                    SwatchTile("Info", color: scheme.info.color)
                }

                // Lines & Focus
                SectionBlock("Lines & Focus") {
                    SwatchTile("Divider", color: scheme.divider.color)
                    SwatchTile("Border", color: scheme.border.color)
                    SwatchTile("Focus Ring", color: scheme.focusRing.color)
                }

                // Progress & Rings
                SectionBlock("Progress & Rings") {
                    SwatchTile("Track", color: scheme.progressTrack.color)
                    GradientTile("Fill (Start → End)", colors: [scheme.progressFillStart.color, scheme.progressFillEnd.color])
                    InfoTile(
                        title: "Ring Alphas",
                        subtitle: String(format: "Outer %.2f  |  Inner %.2f → %.2f",
                                         scheme.ringOuterAlpha,
                                         scheme.ringInnerStartAlpha,
                                         scheme.ringInnerEndAlpha)
                    )
                }

                // Glass & Glow
                SectionBlock("Glass & Glow") {
                    SwatchTile("Glass Tint", color: scheme.glassTint.color)
                    InfoTile(title: "Glass Opacity", subtitle: String(format: "%.2f", scheme.glassOpacity))
                    InfoTile(title: "Glow Intensity",
                             subtitle: "Primary \(pct(scheme.glowIntensityPrimary))  •  Secondary \(pct(scheme.glowIntensitySecondary))")
                    InfoTile(title: "Glow Radii",
                             subtitle: "Blur \(Int(scheme.glowBlurRadius)) • Inner \(Int(scheme.glowRadiusInner)) • Outer \(Int(scheme.glowRadiusOuter))")
                }

                // Charts
                SectionBlock("Charts") {
                    ForEach(Array(scheme.chartPalette.enumerated()), id: \.offset) { idx, hex in
                        SwatchTile("Palette \(idx + 1)", color: hex.color)
                    }
                    SwatchTile("Grid", color: scheme.chartGrid.color)
                    SwatchTile("Label", color: scheme.chartLabel.color)
                }

                // Additional UI
                SectionBlock("Additional UI") {
                    SwatchTile("Primary UI Element", color: scheme.primaryUIElement.color)
                    SwatchTile("Secondary UI Element", color: scheme.secondaryUIElement.color)
                }
            }
            .padding(20)
        }
        .navigationTitle("Theme Swatches")
        .background(Color(.systemBackground))
    }

    private func pct(_ v: Double) -> String {
        String(format: "%.0f%%", v * 100.0)
    }
}

// MARK: - Building Blocks

private struct SectionBlock<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content

    init(_ title: String, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.content = content
    }

    private let columns = [
        GridItem(.flexible(minimum: 120), spacing: 12),
        GridItem(.flexible(minimum: 120), spacing: 12),
        GridItem(.flexible(minimum: 120), spacing: 12)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.secondary)
                .padding(.bottom, 4)
            LazyVGrid(columns: columns, spacing: 16) {
                content()
            }
        }
    }
}

private struct SwatchTile: View {
    let title: String
    let color: Color

    init(_ title: String, color: Color) {
        self.title = title
        self.color = color
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            RoundedRectangle(cornerRadius: 12)
                .fill(color)
                .frame(height: 64)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.black.opacity(0.06), lineWidth: 1)
                )
            Text(title)
                .font(.system(size: 12, weight: .medium))
            Text(color.toHexString() ?? "")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
    }
}

private struct GradientTile: View {
    let title: String
    let colors: [Color]

    init(_ title: String, colors: [Color]) {
        self.title = title
        self.colors = colors
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .frame(height: 64)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.black.opacity(0.06), lineWidth: 1)
                )
            Text(title)
                .font(.system(size: 12, weight: .medium))
            Text(colors.compactMap { $0.toHexString() }.joined(separator: " → "))
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .truncationMode(.middle)
        }
    }
}

private struct InfoTile: View {
    let title: String
    let subtitle: String
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .frame(height: 64)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.black.opacity(0.06), lineWidth: 1)
                )
            Text(title)
                .font(.system(size: 12, weight: .medium))
            Text(subtitle)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Color → Hex helper

private extension Color {
    /// Hex string in #RRGGBB or #AARRGGBB if includeAlpha == true (iOS only)
    func toHexString(includeAlpha: Bool = false) -> String? {
        #if canImport(UIKit)
        let ui = UIColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 1
        guard ui.getRed(&r, green: &g, blue: &b, alpha: &a) else { return nil }
        if includeAlpha {
            let A = Int(round(a * 255)), R = Int(round(r * 255)), G = Int(round(g * 255)), B = Int(round(b * 255))
            return String(format: "#%02X%02X%02X%02X", A, R, G, B)
        } else {
            let R = Int(round(r * 255)), G = Int(round(g * 255)), B = Int(round(b * 255))
            return String(format: "#%02X%02X%02X", R, G, B)
        }
        #else
        return nil
        #endif
    }
}

// MARK: - Previews

#Preview("All Themes (Tabbed)") {
    TabView {
        ForEach(Theme.allAvailable, id: \.id) { theme in
            NavigationStack {
                ThemeColorSchemeSwatchesView(scheme: theme.colorScheme)
                    .navigationTitle(theme.name)
            }
            .tabItem { Label(theme.name, systemImage: theme.isPremium ? "sparkles" : "paintbrush") }
            .preferredColorScheme(theme.colorScheme.primaryBackground.color.isLight ? .light : .dark)
        }
    }
    .tabViewStyle(.automatic)
}

#endif
