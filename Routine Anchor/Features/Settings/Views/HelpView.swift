//
//  HelpView.swift
//  Routine Anchor
//  Swift 6 Compatible Version
//
//  Created by Christopher Simonson on 7/21/25.
//
import SwiftUI

struct HelpView: View {
    @Environment(\.themeManager) private var themeManager
    @Environment(\.dismiss) private var dismiss
    @State private var animationPhase = 0
    @State private var searchText = ""
    @State private var animationTask: Task<Void, Never>?
    @State private var selectedCategory: HelpCategory = .gettingStarted
    
    // Helper function to get color for category
    private func categoryColor(for category: HelpCategory) -> Color {
        guard let theme = themeManager?.currentTheme else {
            return defaultCategoryColor(for: category)
        }
        
        switch category {
        case .all: return theme.colorScheme.blue.color
        case .gettingStarted: return theme.colorScheme.green.color
        case .timeBlocks: return theme.colorScheme.purple.color
        case .notifications: return theme.colorScheme.warning.color
        case .settings: return theme.colorScheme.teal.color
        case .troubleshooting: return theme.colorScheme.error.color
        }
    }
    
    private func defaultCategoryColor(for category: HelpCategory) -> Color {
        let defaultTheme = Theme.defaultTheme
        switch category {
        case .all: return defaultTheme.colorScheme.blue.color
        case .gettingStarted: return defaultTheme.colorScheme.green.color
        case .timeBlocks: return defaultTheme.colorScheme.purple.color
        case .notifications: return defaultTheme.colorScheme.warning.color
        case .settings: return defaultTheme.colorScheme.teal.color
        case .troubleshooting: return defaultTheme.colorScheme.error.color
        }
    }
    
    var body: some View {
        ZStack {
            ThemedAnimatedBackground()
            AnimatedMeshBackground()
                .opacity(0.3)
                .allowsHitTesting(false)

            ParticleEffectView()
                .allowsHitTesting(false)
            
            VStack(spacing: 0) {
                // Header
                headerSection
                
                // Search bar
                searchSection
                
                // Category picker
                categoryPicker
                
                // Help content
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(filteredHelpItems, id: \.id) { item in
                            HelpItemView(item: item, categoryColor: categoryColor(for: item.category))
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
                .background(Color.clear)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            animationTask = Task { @MainActor in
                 while !Task.isCancelled {
                     withAnimation(.easeInOut(duration: 2)) {
                         animationPhase = 1
                     }
                     try? await Task.sleep(nanoseconds: 2_000_000_000)
                 }
             }
        }
        .onDisappear {
            animationTask?.cancel()
            animationTask = nil
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 16) {
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle((themeManager?.currentTheme.textPrimaryColor ?? Theme.defaultTheme.textPrimaryColor).opacity(0.8))
                        .frame(width: 32, height: 32)
                        .background(
                            Circle()
                                .fill(.ultraThinMaterial)
                                .background(
                                    Circle().fill(themeManager?.currentTheme.colorScheme.surfacePrimary.color ?? Theme.defaultTheme.colorScheme.surfacePrimary.color)
                                )
                        )
                }
                
                Spacer()
                
                Button(action: contactSupport) {
                    HStack(spacing: 6) {
                        Image(systemName: "envelope")
                            .font(.system(size: 14, weight: .medium))
                        Text("Support")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundStyle(themeManager?.currentTheme.colorScheme.blue.color ?? Theme.defaultTheme.colorScheme.blue.color)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(themeManager?.currentTheme.colorScheme.surfaceSecondary.color ?? Theme.defaultTheme.colorScheme.surfaceSecondary.color)
                    .cornerRadius(8)
                }
            }
            
            VStack(spacing: 12) {
                Image(systemName: "questionmark.circle")
                    .font(.system(size: 48, weight: .light))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                themeManager?.currentTheme.colorScheme.blue.color ?? Theme.defaultTheme.colorScheme.blue.color,
                                themeManager?.currentTheme.colorScheme.purple.color ?? Theme.defaultTheme.colorScheme.purple.color
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .scaleEffect(animationPhase == 0 ? 1.0 : 1.1)
                    .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: animationPhase)
                
                Text("Help & Support")
                    .font(TypographyConstants.Headers.welcome)
                    .foregroundStyle(themeManager?.currentTheme.textPrimaryColor ?? Theme.defaultTheme.textPrimaryColor)
                    .multilineTextAlignment(.center)
                
                Text("Find answers and get the most out of Routine Anchor")
                    .font(TypographyConstants.Body.secondary)
                    .foregroundStyle(themeManager?.currentTheme.textSecondaryColor ?? Theme.defaultTheme.textSecondaryColor)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 20)
    }
    
    // MARK: - Search Section
    private var searchSection: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(themeManager?.currentTheme.textSecondaryColor ?? Theme.defaultTheme.textSecondaryColor)
            
            TextField("Search help topics...", text: $searchText)
                .font(TypographyConstants.Body.primary)
                .foregroundStyle(themeManager?.currentTheme.textPrimaryColor ?? Theme.defaultTheme.textPrimaryColor)
                .textFieldStyle(PlainTextFieldStyle())
            
            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(themeManager?.currentTheme.textSecondaryColor ?? Theme.defaultTheme.textSecondaryColor)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill((themeManager?.currentTheme.colorScheme.surfacePrimary.color ?? Theme.defaultTheme.colorScheme.surfacePrimary.color).opacity(0.5))
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(themeManager?.currentTheme.colorScheme.surfaceSecondary.color ?? Theme.defaultTheme.colorScheme.surfaceSecondary.color, lineWidth: 1)
        )
        .padding(.horizontal, 24)
        .padding(.top, 16)
    }
    
    // MARK: - Category Picker
    private var categoryPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(HelpCategory.allCases, id: \.self) { category in
                    HelpCategoryChip(
                        category: category,
                        categoryColor: categoryColor(for: category),
                        isSelected: selectedCategory == category,
                        action: { selectedCategory = category }
                    )
                }
            }
            .padding(.horizontal, 24)
        }
        .padding(.top, 16)
    }
    
    // MARK: - Computed Properties
    private var filteredHelpItems: [HelpItem] {
        let categoryItems = helpItems.filter { item in
            selectedCategory == .all || item.category == selectedCategory
        }
        
        if searchText.isEmpty {
            return categoryItems
        } else {
            return categoryItems.filter { item in
                item.title.localizedCaseInsensitiveContains(searchText) ||
                item.content.localizedCaseInsensitiveContains(searchText) ||
                item.keywords.contains { $0.localizedCaseInsensitiveContains(searchText) }
            }
        }
    }
    
    // MARK: - Actions
    private func contactSupport() {
        HapticManager.shared.lightImpact()
        
        if let url = URL(string: "mailto:support@routineanchor.com?subject=Help%20Request") {
            UIApplication.shared.open(url)
        }
    }
}

struct HelpCategoryChip: View {
    @Environment(\.themeManager) private var themeManager
    let category: HelpCategory
    let categoryColor: Color
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            HapticManager.shared.lightImpact()
            action()
        }) {
            HStack(spacing: 6) {
                Image(systemName: category.icon)
                    .font(.system(size: 14, weight: .medium))
                
                Text(category.title)
                    .font(.system(size: 14, weight: .medium))
            }
            .foregroundStyle(
                isSelected ? (themeManager?.currentTheme.textPrimaryColor ?? Theme.defaultTheme.textPrimaryColor) :
                (themeManager?.currentTheme.textSecondaryColor ?? Theme.defaultTheme.textSecondaryColor)
            )
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? categoryColor : (themeManager?.currentTheme.colorScheme.surfacePrimary.color ?? Theme.defaultTheme.colorScheme.surfacePrimary.color))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(
                        isSelected ? Color.clear : (themeManager?.currentTheme.colorScheme.surfaceSecondary.color ?? Theme.defaultTheme.colorScheme.surfaceSecondary.color),
                        lineWidth: 1
                    )
            )
        }
        .scaleEffect(isSelected ? 1.0 : 0.95)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

// MARK: - Help Models
enum HelpCategory: CaseIterable {
    case all
    case gettingStarted
    case timeBlocks
    case notifications
    case settings
    case troubleshooting
    
    var title: String {
        switch self {
        case .all: return "All"
        case .gettingStarted: return "Getting Started"
        case .timeBlocks: return "Time Blocks"
        case .notifications: return "Notifications"
        case .settings: return "Settings"
        case .troubleshooting: return "Troubleshooting"
        }
    }
    
    var icon: String {
        switch self {
        case .all: return "grid.circle"
        case .gettingStarted: return "play.circle"
        case .timeBlocks: return "clock"
        case .notifications: return "bell"
        case .settings: return "gear"
        case .troubleshooting: return "wrench"
        }
    }
    
    // Removed color property - handled in View instead
}

struct HelpItem {
    let id = UUID()
    let category: HelpCategory
    let title: String
    let content: String
    let keywords: [String]
}

// MARK: - Help Content Data
private let helpItems: [HelpItem] = [
    // Getting Started
    HelpItem(
        category: .gettingStarted,
        title: "Welcome to Routine Anchor",
        content: "Routine Anchor helps you build consistent daily routines through time-blocking. Create structured schedules, track your progress, and develop productive habits that stick.\n\nTo get started:\n1. Create your first time block\n2. Set up your daily routine\n3. Start tracking your progress",
        keywords: ["welcome", "intro", "start", "begin", "new"]
    ),
    
    HelpItem(
        category: .gettingStarted,
        title: "Creating Your First Time Block",
        content: "Time blocks are the foundation of your routine. Each block represents a dedicated period for a specific activity.\n\nTo create a time block:\n1. Tap the '+' button in Schedule Builder\n2. Enter a descriptive title\n3. Set your start and end times\n4. Add notes and choose a category\n5. Save your block",
        keywords: ["create", "new", "first", "block", "schedule"]
    ),
    
    HelpItem(
        category: .gettingStarted,
        title: "Building Your Daily Routine",
        content: "A good routine balances work, personal time, and self-care. Start with 3-5 essential time blocks and gradually add more.\n\nTips for success:\n• Be realistic with timing\n• Include buffer time between activities\n• Start small and build consistency\n• Adjust as needed",
        keywords: ["routine", "daily", "schedule", "tips", "success"]
    ),
    
    // Time Blocks
    HelpItem(
        category: .timeBlocks,
        title: "Understanding Time Block Status",
        content: "Each time block has a status that shows your progress:\n\n• Not Started: Upcoming or scheduled\n• In Progress: Currently active\n• Completed: Successfully finished\n• Skipped: Missed or intentionally skipped\n\nYou can manually update status by tapping on blocks.",
        keywords: ["status", "progress", "completed", "skipped", "active"]
    ),
    
    HelpItem(
        category: .timeBlocks,
        title: "Editing and Deleting Time Blocks",
        content: "You can modify your time blocks at any time:\n\nTo edit: Tap on a time block and select 'Edit'\nTo delete: Swipe left on a time block or use the delete button\n\nNote: Changes to active blocks will apply to future instances.",
        keywords: ["edit", "delete", "modify", "change", "remove"]
    ),
    
    HelpItem(
        category: .timeBlocks,
        title: "Time Block Categories and Icons",
        content: "Organize your blocks with categories and visual icons:\n\n• Work: Professional tasks and meetings\n• Personal: Self-care and hobbies\n• Health: Exercise and wellness\n• Learning: Study and skill development\n• Social: Time with others\n\nIcons help you quickly identify different types of activities.",
        keywords: ["category", "organize", "icon", "work", "personal", "health"]
    ),
    
    // Notifications
    HelpItem(
        category: .notifications,
        title: "Setting Up Notifications",
        content: "Routine Anchor can remind you when time blocks are starting:\n\n1. Go to Settings\n2. Enable 'Notifications'\n3. Choose your preferred notification sound\n4. Set up daily reminders if desired\n\nNotifications help you stay on track with your routine.",
        keywords: ["notification", "reminder", "alert", "sound", "enable"]
    ),
    
    HelpItem(
        category: .notifications,
        title: "Managing Notification Permissions",
        content: "If notifications aren't working:\n\n1. Check iOS Settings > Notifications > Routine Anchor\n2. Ensure 'Allow Notifications' is enabled\n3. Check that 'Sounds' and 'Badges' are enabled\n4. Make sure 'Do Not Disturb' isn't blocking notifications",
        keywords: ["permission", "ios", "settings", "allow", "enable", "fix"]
    ),
    
    // Settings
    HelpItem(
        category: .settings,
        title: "Customizing Your Experience",
        content: "Personalize Routine Anchor in Settings:\n\n• Notification preferences\n• Daily reminder times\n• Haptic feedback options\n• Data export and backup\n• Privacy settings\n\nAdjust these settings to match your preferences.",
        keywords: ["customize", "personalize", "preferences", "haptic", "backup"]
    ),
    
    HelpItem(
        category: .settings,
        title: "Data Privacy and Storage",
        content: "Your privacy is our priority:\n\n• All data is stored locally on your device\n• No personal information is collected or transmitted\n• You can export your data anytime\n• Deleting the app removes all data permanently\n\nYour routine data never leaves your device.",
        keywords: ["privacy", "data", "local", "export", "security", "storage"]
    ),
    
    // Troubleshooting
    HelpItem(
        category: .troubleshooting,
        title: "App Performance Issues",
        content: "If the app is running slowly:\n\n1. Close and restart the app\n2. Restart your device\n3. Check for app updates in the App Store\n4. Ensure you have sufficient storage space\n5. Contact support if issues persist",
        keywords: ["slow", "performance", "crash", "fix", "restart", "update"]
    ),
    
    HelpItem(
        category: .troubleshooting,
        title: "Time Blocks Not Saving",
        content: "If your time blocks aren't saving:\n\n1. Check that you have storage space available\n2. Ensure the app has necessary permissions\n3. Try creating a simple block first\n4. Restart the app and try again\n5. Contact support with details about the issue",
        keywords: ["save", "saving", "storage", "permission", "error", "fix"]
    ),
    
    HelpItem(
        category: .troubleshooting,
        title: "Syncing and Backup",
        content: "Routine Anchor stores data locally for privacy. To backup your data:\n\n1. Go to Settings > Export Data\n2. Save the exported file to your preferred location\n3. Use this file to restore data if needed\n\nNote: Data doesn't sync between devices automatically.",
        keywords: ["sync", "backup", "export", "restore", "data", "transfer"]
    )
]

// MARK: - Supporting Views
struct HelpItemView: View {
    @Environment(\.themeManager) private var themeManager
    let item: HelpItem
    let categoryColor: Color
    @State private var isExpanded = false
    @State private var isVisible = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            Button(action: {
                HapticManager.shared.lightImpact()
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    isExpanded.toggle()
                }
            }) {
                HStack(spacing: 12) {
                    Image(systemName: item.category.icon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(categoryColor)
                        .frame(width: 24, height: 24)
                    
                    Text(item.title)
                        .font(TypographyConstants.Headers.cardTitle)
                        .foregroundStyle(themeManager?.currentTheme.textPrimaryColor ?? Theme.defaultTheme.textPrimaryColor)
                        .multilineTextAlignment(.leading)
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(themeManager?.currentTheme.textSecondaryColor ?? Theme.defaultTheme.textSecondaryColor)
                        .rotationEffect(.degrees(isExpanded ? 0 : 0))
                }
                .padding(16)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Content
            if isExpanded {
                VStack(alignment: .leading, spacing: 12) {
                    Divider()
                        .background(themeManager?.currentTheme.colorScheme.surfaceSecondary.color ?? Theme.defaultTheme.colorScheme.surfaceSecondary.color)
                    
                    Text(item.content)
                        .font(TypographyConstants.Body.secondary)
                        .foregroundStyle(themeManager?.currentTheme.textSecondaryColor ?? Theme.defaultTheme.textSecondaryColor)
                        .lineSpacing(2)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)
                }
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .move(edge: .top)),
                    removal: .opacity.combined(with: .move(edge: .top))
                ))
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill((themeManager?.currentTheme.colorScheme.surfacePrimary.color ?? Theme.defaultTheme.colorScheme.surfacePrimary.color).opacity(0.5))
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    LinearGradient(
                        colors: [
                            categoryColor.opacity(0.3),
                            categoryColor.opacity(0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: categoryColor.opacity(0.1), radius: 8, x: 0, y: 4)
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : 20)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
                isVisible = true
            }
        }
    }
}

// MARK: - Preview
#Preview {
    HelpView()
}
