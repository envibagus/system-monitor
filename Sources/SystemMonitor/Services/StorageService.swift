import Foundation

@Observable
final class StorageService: @unchecked Sendable {
    private(set) var storageInfo = StorageInfo()

    private let queue = DispatchQueue(label: "com.systemmonitor.storage", qos: .utility)

    init() {
        // Load basic capacity immediately (fast URL resource lookup)
        let rootURL = URL(fileURLWithPath: "/")
        if let values = try? rootURL.resourceValues(forKeys: [
            .volumeTotalCapacityKey,
            .volumeAvailableCapacityForImportantUsageKey,
            .volumeNameKey
        ]) {
            storageInfo.volumeName = values.volumeName ?? "Macintosh HD"
            storageInfo.totalCapacity = UInt64(values.volumeTotalCapacity ?? 0)
            if let available = values.volumeAvailableCapacityForImportantUsage {
                storageInfo.availableCapacity = UInt64(available)
            }
        }
    }

    func refresh() {
        queue.async { [weak self] in
            guard let self else { return }
            let result = self.readStorageInfo()
            DispatchQueue.main.async {
                self.storageInfo = result
            }
        }
    }

    private func readStorageInfo() -> StorageInfo {
        var info = StorageInfo()

        let rootURL = URL(fileURLWithPath: "/")
        if let values = try? rootURL.resourceValues(forKeys: [
            .volumeTotalCapacityKey,
            .volumeAvailableCapacityForImportantUsageKey,
            .volumeNameKey
        ]) {
            info.volumeName = values.volumeName ?? "Macintosh HD"
            info.totalCapacity = UInt64(values.volumeTotalCapacity ?? 0)
            if let available = values.volumeAvailableCapacityForImportantUsage {
                info.availableCapacity = UInt64(available)
            }
        }

        // Scan categories using a single du call for speed (only TCC-safe paths)
        let home = NSHomeDirectory()
        var scannedCategories: [StorageCategory] = []
        var accountedSize: UInt64 = 0

        // Batch-scan all safe paths at once
        let pathMap: [(id: String, name: String, colorName: String, paths: [String])] = [
            ("applications", "Applications", "storageApps", [
                "/Applications",
                "/System/Applications",
                home + "/Applications"
            ]),
            ("developer", "Developer", "storageDeveloper", [
                home + "/Developer",
                home + "/Library/Developer"
            ]),
            ("documents", "Documents", "storageDocuments", [
                home + "/Documents",
                home + "/Desktop",
                home + "/Downloads"
            ]),
            ("trash", "Trash", "storageTrash", [
                home + "/.Trash"
            ])
        ]

        // Collect all existing paths for a single du call
        let fm = FileManager.default
        var allPaths: [String] = []
        for entry in pathMap {
            for path in entry.paths {
                if fm.fileExists(atPath: path) {
                    allPaths.append(path)
                }
            }
        }

        let sizeResults = batchAllocatedSizes(allPaths)

        for entry in pathMap {
            var totalSize: UInt64 = 0
            for path in entry.paths {
                totalSize += sizeResults[path] ?? 0
            }
            scannedCategories.append(StorageCategory(id: entry.id, name: entry.name, size: totalSize, colorName: entry.colorName))
            accountedSize += totalSize
        }

        // macOS (system) = used - everything else
        let macosSize = info.usedCapacity > accountedSize ? info.usedCapacity - accountedSize : 0
        scannedCategories.append(StorageCategory(id: "macos", name: "macOS", size: macosSize, colorName: "storageMacOS"))

        // Sort by size descending, filter out zero
        info.categories = scannedCategories.filter { $0.size > 0 }.sorted { $0.size > $1.size }
        return info
    }

    /// Batch disk size calculation — single du process for all paths
    private func batchAllocatedSizes(_ paths: [String]) -> [String: UInt64] {
        guard !paths.isEmpty else { return [:] }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/du")
        process.arguments = ["-sk"] + paths

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice

        var results: [String: UInt64] = [:]

        do {
            try process.run()
            process.waitUntilExit()

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                for line in output.components(separatedBy: "\n") where !line.isEmpty {
                    let parts = line.split(separator: "\t", maxSplits: 1)
                    if parts.count == 2,
                       let sizeKB = UInt64(parts[0]) {
                        let path = String(parts[1])
                        results[path] = sizeKB * 1024
                    }
                }
            }
        } catch {
            // Return empty results if du fails
        }
        return results
    }
}
