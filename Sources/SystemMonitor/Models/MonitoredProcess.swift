import Foundation

struct MonitoredProcess: Identifiable, Sendable {
    let id: pid_t
    let pid: pid_t
    let parentPid: pid_t
    let name: String
    let executablePath: String
    let residentMemory: UInt64
    let cpuUsage: Double
    let isElectron: Bool
    let bundlePath: String?

    /// For Electron grouping: total memory across all child processes
    var groupedMemory: UInt64?
    var childProcesses: [MonitoredProcess]?
}

struct ElectronGroup: Identifiable, Sendable {
    let id: String
    let appName: String
    let bundlePath: String
    let mainPID: pid_t
    let childPIDs: [pid_t]
    let totalResidentMemory: UInt64
    let processCount: Int
}

/// System process category for human-readable grouping
enum SystemProcessCategory: String, CaseIterable, Sendable {
    case kernel = "Kernel & Core"
    case displayUI = "Display & UI"
    case searchIndexing = "Search & Indexing"
    case cloudServices = "Cloud Services"
    case security = "Security & Privacy"
    case networking = "Network Services"
    case audio = "Audio"
    case bluetooth = "Bluetooth"
    case fileSystem = "File Management"
    case daemonServices = "Daemon Services"
    case other = "Uncategorized"

    var sfSymbol: String {
        switch self {
        case .kernel: return "cpu"
        case .displayUI: return "display"
        case .searchIndexing: return "magnifyingglass"
        case .cloudServices: return "icloud"
        case .security: return "lock.shield"
        case .networking: return "network"
        case .audio: return "speaker.wave.2"
        case .bluetooth: return "wave.3.right"
        case .fileSystem: return "folder"
        case .daemonServices: return "gearshape.2"
        case .other: return "questionmark.circle"
        }
    }

    var accentColor: String {
        switch self {
        case .kernel: return "accentPink"
        case .displayUI: return "accentBlue"
        case .searchIndexing: return "accentOrange"
        case .cloudServices: return "accentTeal"
        case .security: return "accentGreen"
        case .networking: return "accentPurple"
        case .audio: return "accentOrange"
        case .bluetooth: return "accentBlue"
        case .fileSystem: return "accentGreen"
        case .daemonServices: return "secondaryText"
        case .other: return "secondaryText"
        }
    }
}

struct SystemProcessGroup: Identifiable, Sendable {
    let id: String
    let category: SystemProcessCategory
    let processes: [MonitoredProcess]
    var totalMemory: UInt64 {
        processes.reduce(0) { $0 + $1.residentMemory }
    }
}
