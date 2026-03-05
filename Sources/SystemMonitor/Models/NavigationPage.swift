import SwiftUI

enum NavigationSection: String, CaseIterable {
    case overview = "OVERVIEW"
    case monitor = "MONITOR"
    case system = "SYSTEM"
}

enum NavigationPage: String, Identifiable, CaseIterable {
    case dashboard
    case cpu
    case memory
    case storage
    case thermal
    case network
    case battery
    case startupItems
    case settings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .dashboard: return "Dashboard"
        case .cpu: return "CPU"
        case .memory: return "Memory"
        case .storage: return "Storage"
        case .thermal: return "Fans & Thermal"
        case .network: return "Network"
        case .battery: return "Battery"
        case .startupItems: return "Startup Items"
        case .settings: return "Settings"
        }
    }

    var sfSymbol: String {
        switch self {
        case .dashboard: return "square.grid.2x2"
        case .cpu: return "cpu"
        case .memory: return "memorychip"
        case .storage: return "internaldrive"
        case .thermal: return "thermometer.medium"
        case .network: return "network"
        case .battery: return "battery.75percent"
        case .startupItems: return "power"
        case .settings: return "gearshape"
        }
    }

    var section: NavigationSection {
        switch self {
        case .dashboard: return .overview
        case .cpu, .memory, .storage, .thermal, .network: return .monitor
        case .battery, .startupItems, .settings: return .system
        }
    }

    static func pages(for section: NavigationSection) -> [NavigationPage] {
        allCases.filter { $0.section == section }
    }
}
