import SwiftUI
import AppKit

enum Theme {
    // MARK: - Adaptive Color Helper
    /// Creates a SwiftUI Color that adapts between dark and light appearance
    private static func adaptive(dark: UInt32, light: UInt32) -> Color {
        Color(nsColor: NSColor(name: nil, dynamicProvider: { appearance in
            let isDark = appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            let hex = isDark ? dark : light
            let r = CGFloat((hex >> 16) & 0xFF) / 255.0
            let g = CGFloat((hex >> 8) & 0xFF) / 255.0
            let b = CGFloat(hex & 0xFF) / 255.0
            return NSColor(red: r, green: g, blue: b, alpha: 1.0)
        }))
    }

    // MARK: - Backgrounds
    static let windowBackground = adaptive(dark: 0x0F1219, light: 0xF2F4F7)
    static let sidebarBackground = adaptive(dark: 0x111622, light: 0xE8EBF0)
    static let cardBackground = adaptive(dark: 0x141825, light: 0xFFFFFF)
    static let cardBorder = adaptive(dark: 0x1E2433, light: 0xD4D8E0)
    static let cardBorderHover = adaptive(dark: 0x2A3548, light: 0xB8BEC8)

    // MARK: - Text
    static let primaryText = adaptive(dark: 0xE8ECF4, light: 0x1A1D26)
    static let secondaryText = adaptive(dark: 0x6B7A90, light: 0x5A6478)

    // MARK: - Sidebar
    static let sidebarSelectedText = adaptive(dark: 0xFFFFFF, light: 0x1A3A6B)
    static let sidebarHover = adaptive(dark: 0xFFFFFF, light: 0x000000)

    // MARK: - Accents (darkened in light mode for WCAG contrast)
    static let accentBlue = adaptive(dark: 0x5E9EFF, light: 0x2B6CB0)
    static let accentOrange = adaptive(dark: 0xFFB84D, light: 0xC07A12)
    static let accentGreen = adaptive(dark: 0x7BEB7B, light: 0x1A8A3E)
    static let accentPink = adaptive(dark: 0xFF6B8A, light: 0xD43D56)
    static let accentPurple = adaptive(dark: 0xC084FC, light: 0x8B3DC7)
    static let accentTeal = adaptive(dark: 0x38BDF8, light: 0x0B7AAD)

    // MARK: - Memory Composition Colors
    static let memoryApp = accentBlue
    static let memorySystem = accentPurple
    static let memoryWired = accentOrange
    static let memoryCompressed = accentTeal
    static let memoryCached = accentGreen
    static let memoryFree = adaptive(dark: 0x1A1F2E, light: 0xE4E7ED)

    // MARK: - Storage Category Colors (matching macOS System Settings)
    static let storageApps = adaptive(dark: 0xE45650, light: 0xCC3E38)
    static let storageTrash = adaptive(dark: 0xE8943A, light: 0xC87A28)
    static let storageDeveloper = adaptive(dark: 0xE5C444, light: 0xB89A20)
    static let storageDocuments = adaptive(dark: 0x64B5F6, light: 0x2B7CC9)
    static let storageICloud = adaptive(dark: 0x42A5F5, light: 0x1E75C9)
    static let storagePhotos = adaptive(dark: 0xEC407A, light: 0xC22258)
    static let storagePodcasts = adaptive(dark: 0xAB47BC, light: 0x8A2F9C)
    static let storageMacOS = adaptive(dark: 0x8E8E93, light: 0x6E6E73)
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
