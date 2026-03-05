import SwiftUI

enum Theme {
    // MARK: - Backgrounds
    static let windowBackground = Color(hex: 0x0F1219)
    static let sidebarBackground = Color(hex: 0x111622)
    static let cardBackground = Color(hex: 0x141825)
    static let cardBorder = Color(hex: 0x1E2433)
    static let cardBorderHover = Color(hex: 0x2A3548)

    // MARK: - Text
    static let primaryText = Color(hex: 0xE8ECF4)
    static let secondaryText = Color(hex: 0x6B7A90)

    // MARK: - Accents
    static let accentBlue = Color(hex: 0x5E9EFF)
    static let accentOrange = Color(hex: 0xFFB84D)
    static let accentGreen = Color(hex: 0x7BEB7B)
    static let accentPink = Color(hex: 0xFF6B8A)
    static let accentPurple = Color(hex: 0xC084FC)
    static let accentTeal = Color(hex: 0x38BDF8)

    // MARK: - Memory Composition Colors
    static let memoryApp = accentBlue
    static let memorySystem = accentPurple
    static let memoryWired = accentOrange
    static let memoryCompressed = accentTeal
    static let memoryCached = accentGreen
    static let memoryFree = Color(hex: 0x1A1F2E)

    // MARK: - Storage Category Colors (matching macOS System Settings)
    static let storageApps = Color(hex: 0xE45650)        // Red — Applications
    static let storageTrash = Color(hex: 0xE8943A)       // Orange — Trash
    static let storageDeveloper = Color(hex: 0xE5C444)   // Yellow — Developer
    static let storageDocuments = Color(hex: 0x64B5F6)   // Light Blue — Documents
    static let storageICloud = Color(hex: 0x42A5F5)      // Blue — iCloud Drive
    static let storagePhotos = Color(hex: 0xEC407A)      // Pink — Photos
    static let storagePodcasts = Color(hex: 0xAB47BC)    // Purple — Podcasts
    static let storageMacOS = Color(hex: 0x8E8E93)       // Gray — macOS
    static let storageOther = secondaryText

    /// Resolve storage color from category color name
    static func storageColor(for name: String) -> Color {
        switch name {
        case "storageApps": return storageApps
        case "storageTrash": return storageTrash
        case "storageDeveloper": return storageDeveloper
        case "storageDocuments": return storageDocuments
        case "storageICloud": return storageICloud
        case "storagePhotos": return storagePhotos
        case "storagePodcasts": return storagePodcasts
        case "storageMacOS": return storageMacOS
        default: return storageOther
        }
    }

    // MARK: - Typography
    static let titleFont = Font.system(size: 22, weight: .semibold)
    static let cardHeaderFont = Font.system(size: 13, weight: .semibold)
    static let bodyFont = Font.system(size: 13, weight: .regular)
    static let captionFont = Font.system(size: 11, weight: .regular)
    static let sidebarSectionFont = Font.system(size: 11, weight: .medium)
    static let monoFont = Font.system(size: 13, weight: .medium, design: .monospaced)
    static let monoLargeFont = Font.system(size: 22, weight: .semibold, design: .monospaced)
    static let monoSmallFont = Font.system(size: 11, weight: .regular, design: .monospaced)

    // MARK: - Layout
    static let cardCornerRadius: CGFloat = 12
    static let cardPadding: CGFloat = 18
    static let windowMinWidth: CGFloat = 900
    static let windowMinHeight: CGFloat = 600

    // MARK: - Animation
    static let pageTransition = Animation.easeInOut(duration: 0.3)
    static let gaugeAnimation = Animation.easeOut(duration: 0.8)
    static let sparklineAnimation = Animation.easeInOut(duration: 0.5)
    static let hoverAnimation = Animation.easeInOut(duration: 0.15)

    // MARK: - Temperature Thresholds
    static func temperatureColor(celsius: Double) -> Color {
        if celsius < 70 { return accentGreen }
        if celsius < 85 { return accentOrange }
        return accentPink
    }

    static func cpuUsageColor(percent: Double) -> Color {
        if percent < 70 { return accentBlue }
        return accentPink
    }

    static func memoryUsageColor(percent: Double) -> Color {
        if percent < 80 { return accentOrange }
        return accentPink
    }

    static func fanSpeedColor(percentOfMax: Double) -> Color {
        if percentOfMax < 0.4 { return accentBlue }
        if percentOfMax < 0.7 { return accentOrange }
        return accentPink
    }
}

extension Color {
    init(hex: UInt32) {
        let r = Double((hex >> 16) & 0xFF) / 255.0
        let g = Double((hex >> 8) & 0xFF) / 255.0
        let b = Double(hex & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b)
    }
}
