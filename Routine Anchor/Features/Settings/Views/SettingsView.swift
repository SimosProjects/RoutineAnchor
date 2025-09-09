//
//  SettingsView.swift
//  Routine Anchor
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.themeManager) private var themeManager
    @Environment(\.premiumManager) private var premiumManager

    // Theme sugar
    private var theme: AppTheme { themeManager?.currentTheme ?? PredefinedThemes.classic }

    // Local preferences
    @State private var notificationsEnabled = true
    @State private var dailyReminderTime = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date()
    @State private var hapticsEnabled = true

    // Sheets / flows
    @State private var showThemePicker = false
    @State private var showAbout = false
    @State private var showHelp = false
    @State private var showPrivacy = false
    @State private var showImport = false
    @State private var showExport = false
    @State private var showPremiumSheet = false

    // Debug
    #if DEBUG
    @State private var debugPremiumOverride = UserDefaults.standard.bool(forKey: "premiumDebugOverride")
    #endif

    var body: some View {
        NavigationStack {
            ZStack {
                theme.heroBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        header

                        premiumCard
                        appearanceCard
                        notificationsCard
                        preferencesCard
                        dataCard
                        supportCard

                        #if DEBUG
                        debugCard
                        #endif

                        versionFooter
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(theme.primaryTextColor)
                }
            }
            // Sheets
            .sheet(isPresented: $showThemePicker) {
                ThemeSelectionView()
                    .environment(\.themeManager, themeManager)
                    .preferredColorScheme(.dark)
            }
            .sheet(isPresented: $showAbout) {
                NavigationStack { AboutView() }
                    .environment(\.themeManager, themeManager)
            }
            .sheet(isPresented: $showHelp) {
                NavigationStack { HelpView() }
                    .environment(\.themeManager, themeManager)
            }
            .sheet(isPresented: $showPrivacy) {
                NavigationStack { PrivacyPolicyView() }
                    .environment(\.themeManager, themeManager)
            }
            .sheet(isPresented: $showImport) {
                NavigationStack { ImportDataView() }
                    .environment(\.themeManager, themeManager)
            }
            .sheet(isPresented: $showExport) {
                NavigationStack { ExportDataView() }
                    .environment(\.themeManager, themeManager)
            }
            .sheet(isPresented: $showPremiumSheet) {
                NavigationStack { PremiumUpgradeView() }
                    .environment(\.themeManager, themeManager)
                    .environment(\.premiumManager, premiumManager)
            }
        }
    }

    // MARK: - Sections

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Customize your experience")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(theme.primaryTextColor)
            Text("Appearance, notifications, data, premium, and more.")
                .font(.system(size: 15))
                .foregroundStyle(theme.secondaryTextColor)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var premiumCard: some View {
        SectionCard(corner: theme.cardCornerRadius) {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 10) {
                    Image(systemName: "crown.fill")
                        .foregroundStyle(theme.statusWarningColor)
                        .font(.system(size: 18, weight: .semibold))
                    Text("Premium")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(theme.primaryTextColor)
                    Spacer()
                }

                if premiumManager?.userIsPremium == true {
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundStyle(theme.statusSuccessColor)
                        Text("You’re Premium — thanks for supporting!")
                            .foregroundStyle(theme.primaryTextColor)
                            .font(.system(size: 15, weight: .medium))
                        Spacer()
                        Button {
                            HapticManager.shared.lightImpact()
                            showPremiumSheet = true
                        } label: {
                            Text("Manage")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(theme.invertedTextColor)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(theme.accentPrimaryColor)
                                .clipShape(Capsule())
                        }
                    }
                } else {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Unlock premium themes, analytics, unlimited templates, and more.")
                            .font(.system(size: 14))
                            .foregroundStyle(theme.secondaryTextColor)

                        Button {
                            HapticManager.shared.mediumImpact()
                            showPremiumSheet = true
                        } label: {
                            Text("Upgrade to Premium")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(theme.invertedTextColor)
                                .frame(maxWidth: .infinity)
                                .frame(height: 48)
                                .background(theme.actionPrimaryGradient)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                .shadow(color: theme.accentPrimaryColor.opacity(0.25), radius: 10, x: 0, y: 5)
                        }
                        .buttonStyle(.plain)

                        Button("Restore Purchases") {
                            HapticManager.shared.lightImpact()
                            Task { await premiumManager?.restorePurchases() }
                        }
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(theme.secondaryTextColor)
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var appearanceCard: some View {
        SectionCard(corner: theme.cardCornerRadius) {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 10) {
                    Image(systemName: "paintbrush.fill")
                        .foregroundStyle(theme.accentPrimaryColor)
                        .font(.system(size: 18, weight: .semibold))
                    Text("Appearance")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(theme.primaryTextColor)
                    Spacer()
                }

                // Current theme preview
                HStack(spacing: 12) {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(
                            LinearGradient(colors: [theme.gradient.heroTop, theme.gradient.heroBottom],
                                           startPoint: .top, endPoint: .bottom)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(theme.glassMaterialOverlay)
                        )
                        .frame(width: 64, height: 64)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(theme.borderColor.opacity(0.8), lineWidth: 1)
                        )

                    VStack(alignment: .leading, spacing: 4) {
                        Text(theme.name)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(theme.primaryTextColor)
                        Text(theme.description)
                            .font(.system(size: 13))
                            .foregroundStyle(theme.secondaryTextColor)
                            .lineLimit(2)
                    }

                    Spacer()

                    Button {
                        HapticManager.shared.lightImpact()
                        showThemePicker = true
                    } label: {
                        Text("Choose")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(theme.invertedTextColor)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(theme.actionPrimaryGradient)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var notificationsCard: some View {
        SectionCard(corner: theme.cardCornerRadius) {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 10) {
                    Image(systemName: "bell.fill")
                        .foregroundStyle(theme.accentSecondaryColor)
                        .font(.system(size: 18, weight: .semibold))
                    Text("Notifications")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(theme.primaryTextColor)
                    Spacer()
                }

                Toggle(isOn: $notificationsEnabled) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Enable Notifications")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(theme.primaryTextColor)
                        Text("Reminders for time blocks and daily review")
                            .font(.system(size: 12))
                            .foregroundStyle(theme.subtleTextColor)
                    }
                }
                .tint(theme.accentPrimaryColor)

                HStack {
                    Text("Daily Reminder")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(theme.primaryTextColor)
                    Spacer()
                    DatePicker("", selection: $dailyReminderTime, displayedComponents: .hourAndMinute)
                        .labelsHidden()
                        .colorMultiply(theme.primaryTextColor)
                }
                .opacity(notificationsEnabled ? 1.0 : 0.5)
            }
        }
    }

    private var preferencesCard: some View {
        SectionCard(corner: theme.cardCornerRadius) {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 10) {
                    Image(systemName: "gearshape.fill")
                        .foregroundStyle(theme.accentPrimaryColor)
                        .font(.system(size: 18, weight: .semibold))
                    Text("Preferences")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(theme.primaryTextColor)
                    Spacer()
                }

                Toggle(isOn: $hapticsEnabled) {
                    Text("Enable Haptics")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(theme.primaryTextColor)
                }
                .tint(theme.accentPrimaryColor)

                RowButton(title: "Email Preferences", icon: "envelope") {
                    HapticManager.shared.lightImpact()
                    // Present inline to keep navigation consistent with other sheets
                    if let window = UIApplication.shared.connectedScenes
                        .compactMap({ $0 as? UIWindowScene })
                        .first?.windows.first,
                       let root = window.rootViewController {
                        let host = UIHostingController(rootView: NavigationStack {
                            EmailPreferencesView()
                                .environment(\.themeManager, themeManager)
                                .navigationBarTitleDisplayMode(.inline)
                        })
                        root.present(host, animated: true)
                    }
                }
            }
        }
    }

    private var dataCard: some View {
        SectionCard(corner: theme.cardCornerRadius) {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 10) {
                    Image(systemName: "externaldrive.fill")
                        .foregroundStyle(theme.statusSuccessColor)
                        .font(.system(size: 18, weight: .semibold))
                    Text("Data")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(theme.primaryTextColor)
                    Spacer()
                }

                RowButton(title: "Import Data", icon: "square.and.arrow.down") {
                    HapticManager.shared.lightImpact()
                    showImport = true
                }

                RowButton(title: "Export Data", icon: "square.and.arrow.up") {
                    HapticManager.shared.lightImpact()
                    showExport = true
                }
            }
        }
    }

    private var supportCard: some View {
        SectionCard(corner: theme.cardCornerRadius) {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 10) {
                    Image(systemName: "questionmark.circle.fill")
                        .foregroundStyle(theme.statusInfoColor)
                        .font(.system(size: 18, weight: .semibold))
                    Text("Support")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(theme.primaryTextColor)
                    Spacer()
                }

                VStack(spacing: 10) {
                    RowButton(title: "Help & Support", icon: "questionmark.circle") {
                        HapticManager.shared.lightImpact()
                        showHelp = true
                    }
                    RowButton(title: "About", icon: "info.circle") {
                        HapticManager.shared.lightImpact()
                        showAbout = true
                    }
                    RowButton(title: "Privacy Policy", icon: "shield") {
                        HapticManager.shared.lightImpact()
                        showPrivacy = true
                    }
                    RowButton(title: "Rate the App", icon: "star") {
                        HapticManager.shared.lightImpact()
                        if let url = URL(string: "https://apps.apple.com/app/id0000000000?action=write-review") {
                            UIApplication.shared.open(url)
                        }
                    }
                }
            }
        }
    }

    #if DEBUG
    private var debugCard: some View {
        SectionCard(corner: theme.cardCornerRadius) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 10) {
                    Image(systemName: "wrench.and.screwdriver.fill")
                        .foregroundStyle(theme.accentSecondaryColor)
                        .font(.system(size: 18, weight: .semibold))
                    Text("Debug")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(theme.primaryTextColor)
                    Spacer()
                }

                Toggle(isOn: $debugPremiumOverride) {
                    Text("Simulate Premium (Debug)")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(theme.primaryTextColor)
                }
                .tint(theme.accentPrimaryColor)
                .onChange(of: debugPremiumOverride) { _, enabled in
                    // Persist the override so it survives relaunches
                    UserDefaults.standard.set(enabled, forKey: "premiumDebugOverride")
                    // Tell the PremiumManager (and anyone else) to react
                    NotificationCenter.default.post(
                        name: .premiumDebugOverrideChanged,
                        object: nil,
                        userInfo: ["enabled": enabled]
                    )
                }

                Text("Use this to test premium features without a purchase. Only visible in DEBUG builds.")
                    .font(.system(size: 12))
                    .foregroundStyle(theme.secondaryTextColor)
            }
        }
    }
    #endif

    private var versionFooter: some View {
        VStack(spacing: 4) {
            Text("Routine Anchor")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(theme.secondaryTextColor)
            Text("Version \(appVersion)")
                .font(.system(size: 12))
                .foregroundStyle(theme.subtleTextColor)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    // MARK: - Helpers

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
}

// MARK: - Small local building blocks

private struct SectionCard<Content: View>: View {
    @Environment(\.themeManager) private var themeManager
    private var theme: AppTheme { themeManager?.currentTheme ?? PredefinedThemes.classic }

    let corner: CGFloat
    let content: () -> Content

    init(corner: CGFloat = 16, @ViewBuilder content: @escaping () -> Content) {
        self.corner = corner
        self.content = content
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            content()
                .padding(16)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            // Glassy + tinted card surface using theme tokens
            ZStack {
                RoundedRectangle(cornerRadius: corner, style: .continuous).fill(.ultraThinMaterial)
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .fill(theme.glassMaterialOverlay)
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .fill(theme.color.surface.card.opacity(0.35))
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: corner, style: .continuous)
                .stroke(theme.borderColor.opacity(0.9), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(theme.shadowOpacity * 0.5), radius: 10, x: 0, y: 6)
    }
}

private struct RowButton: View {
    @Environment(\.themeManager) private var themeManager
    private var theme: AppTheme { themeManager?.currentTheme ?? PredefinedThemes.classic }

    let title: String
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(theme.accentPrimaryColor)

                Text(title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(theme.primaryTextColor)

                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(theme.subtleTextColor)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 8)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(theme.color.surface.card.opacity(0.30))
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Debug Notification

extension Notification.Name {
    static let premiumDebugOverrideChanged = Notification.Name("premiumDebugOverrideChanged")
}

#Preview {
    SettingsView()
        .environment(\.themeManager, ThemeManager.preview())
        .environment(\.premiumManager, PremiumManager())
        .preferredColorScheme(.dark)
}
