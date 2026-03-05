import Foundation

enum SystemProcessCategorizer {
    /// Map of known system process names to their category
    static let processMap: [String: SystemProcessCategory] = [
        // Kernel & Core
        "kernel_task": .kernel,
        "launchd": .daemonServices,

        // Display & UI
        "WindowServer": .displayUI,
        "Dock": .displayUI,
        "SystemUIServer": .displayUI,
        "ControlCenter": .displayUI,
        "NotificationCenter": .displayUI,
        "Finder": .displayUI,
        "AXVisualSupportAgent": .displayUI,
        "universalAccessd": .displayUI,

        // Search & Indexing
        "mds": .searchIndexing,
        "mds_stores": .searchIndexing,
        "mdworker": .searchIndexing,
        "mdworker_shared": .searchIndexing,
        "corespotlightd": .searchIndexing,

        // Cloud Services
        "cloudd": .cloudServices,
        "nsurlsessiond": .cloudServices,
        "bird": .cloudServices,
        "CloudKeychainProxy": .cloudServices,
        "callservicesd": .cloudServices,
        "iCloudNotificationAgent": .cloudServices,
        "photolibraryd": .cloudServices,

        // Security & Privacy
        "trustd": .security,
        "secd": .security,
        "keybagd": .security,
        "securityd": .security,
        "opendirectoryd": .security,
        "loginwindow": .security,
        "authd": .security,
        "endpointsecurityd": .security,

        // Network Services
        "mDNSResponder": .networking,
        "networkd": .networking,
        "WiFiAgent": .networking,
        "rapportd": .networking,
        "symptomsd": .networking,
        "airportd": .networking,
        "configd": .networking,
        "netbiosd": .networking,

        // Audio
        "coreaudiod": .audio,
        "audiomxd": .audio,

        // Bluetooth
        "bluetoothd": .bluetooth,
        "BTServer": .bluetooth,

        // File System
        "fseventsd": .fileSystem,
        "fileproviderd": .fileSystem,
        "revisiond": .fileSystem,
        "lsd": .fileSystem,
        "diskarbitrationd": .fileSystem,
        "fsck_apfs": .fileSystem,

        // Daemon Services
        "cfprefsd": .daemonServices,
        "distnoted": .daemonServices,
        "logd": .daemonServices,
        "powerd": .daemonServices,
        "UserEventAgent": .daemonServices,
        "coreservicesd": .daemonServices,
        "syslogd": .daemonServices,
        "watchdogd": .daemonServices,
        "thermald": .daemonServices,
        "containermanagerd": .daemonServices,
    ]

    /// Categorize a process by its name
    static func categorize(_ processName: String) -> SystemProcessCategory {
        // Direct match
        if let category = processMap[processName] {
            return category
        }

        // Pattern-based matching for common prefixes
        if processName.hasPrefix("mdworker") { return .searchIndexing }
        if processName.hasPrefix("cloud") || processName.hasPrefix("Cloud") { return .cloudServices }
        if processName.hasPrefix("com.apple.") { return .daemonServices }
        if processName.hasSuffix("d") && processName.count < 20 { return .daemonServices }

        return .other
    }

    /// Group processes into system process groups
    static func groupProcesses(_ processes: [MonitoredProcess]) -> [SystemProcessGroup] {
        var grouped: [SystemProcessCategory: [MonitoredProcess]] = [:]

        for process in processes {
            let category = categorize(process.name)
            grouped[category, default: []].append(process)
        }

        return grouped.map { (category, procs) in
            SystemProcessGroup(
                id: category.rawValue,
                category: category,
                processes: procs.sorted { $0.residentMemory > $1.residentMemory }
            )
        }.sorted { $0.totalMemory > $1.totalMemory }
    }
}
