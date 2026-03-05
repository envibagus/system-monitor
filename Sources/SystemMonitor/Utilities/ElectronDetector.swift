import Foundation

final class ElectronDetector: @unchecked Sendable {
    private var electronBundles: Set<String> = []
    private var bundleCache: [String: Bool] = [:]
    private var lastScanPIDs: Set<pid_t> = []
    private let queue = DispatchQueue(label: "com.systemmonitor.electron", qos: .utility)

    /// Scan application directories for Electron bundles
    func scanForElectronApps() {
        let searchPaths = [
            "/Applications",
            NSHomeDirectory() + "/Applications"
        ]

        var found = Set<String>()
        let fm = FileManager.default

        for searchPath in searchPaths {
            guard let contents = try? fm.contentsOfDirectory(atPath: searchPath) else { continue }

            for item in contents where item.hasSuffix(".app") {
                let bundlePath = (searchPath as NSString).appendingPathComponent(item)
                let electronFramework = (bundlePath as NSString)
                    .appendingPathComponent("Contents/Frameworks/Electron Framework.framework")

                if fm.fileExists(atPath: electronFramework) {
                    found.insert(bundlePath)
                    bundleCache[bundlePath] = true
                }
            }
        }

        electronBundles = found
    }

    /// Check if a process belongs to an Electron app
    func isElectronProcess(_ process: MonitoredProcess) -> Bool {
        let path = process.executablePath

        // Check if executable is inside a known Electron bundle
        for bundle in electronBundles {
            if path.hasPrefix(bundle) {
                return true
            }
        }

        // Fallback: check for " Helper" suffix pattern common in Electron apps
        if process.name.contains(" Helper") || process.name.contains("Helper (") {
            return true
        }

        return false
    }

    /// Group processes by their Electron app bundle
    func groupElectronProcesses(_ processes: [MonitoredProcess]) -> [ElectronGroup] {
        var groups: [String: (name: String, path: String, pids: [pid_t], memory: UInt64)] = [:]

        // Check if PIDs changed and rescan if needed
        let currentPIDs = Set(processes.map(\.pid))
        if currentPIDs != lastScanPIDs {
            scanForElectronApps()
            lastScanPIDs = currentPIDs
        }

        for process in processes {
            guard isElectronProcess(process) else { continue }

            // Find which bundle this process belongs to
            var matchedBundle: String?
            var appName: String?

            for bundle in electronBundles {
                if process.executablePath.hasPrefix(bundle) {
                    matchedBundle = bundle
                    appName = ((bundle as NSString).lastPathComponent as NSString)
                        .deletingPathExtension
                    break
                }
            }

            // Fallback: group by parent process name pattern
            if matchedBundle == nil {
                let baseName = process.name
                    .replacingOccurrences(of: " Helper", with: "")
                    .replacingOccurrences(of: " (Renderer)", with: "")
                    .replacingOccurrences(of: " (GPU)", with: "")
                    .replacingOccurrences(of: " (Plugin)", with: "")
                matchedBundle = "fallback:\(baseName)"
                appName = baseName
            }

            let key = matchedBundle ?? process.name
            if groups[key] == nil {
                groups[key] = (name: appName ?? process.name, path: matchedBundle ?? "", pids: [], memory: 0)
            }
            groups[key]!.pids.append(process.pid)
            groups[key]!.memory += process.residentMemory
        }

        return groups.map { (key, value) in
            ElectronGroup(
                id: key,
                appName: value.name,
                bundlePath: value.path,
                mainPID: value.pids.first ?? 0,
                childPIDs: Array(value.pids.dropFirst()),
                totalResidentMemory: value.memory,
                processCount: value.pids.count
            )
        }.sorted { $0.totalResidentMemory > $1.totalResidentMemory }
    }
}
