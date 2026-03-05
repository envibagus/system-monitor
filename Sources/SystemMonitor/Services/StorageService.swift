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

        // Match macOS System Settings categories
        let home = NSHomeDirectory()
        var scannedCategories: [StorageCategory] = []
        var accountedSize: UInt64 = 0

        // Applications — app bundles + per-app data (matches macOS System Settings)
        let appsSize = allocatedSize("/Applications")
            + allocatedSize("/System/Applications")
            + allocatedSize(home + "/Applications")
            + allocatedSize(home + "/Library/Application Support")
            + allocatedSize(home + "/Library/Containers")
            + allocatedSize(home + "/Library/Caches")
        scannedCategories.append(StorageCategory(id: "applications", name: "Applications", size: appsSize, colorName: "storageApps"))
        accountedSize += appsSize

        // Developer — ~/Developer + ~/Library/Developer
        let devSize = allocatedSize(home + "/Developer") + allocatedSize(home + "/Library/Developer")
        scannedCategories.append(StorageCategory(id: "developer", name: "Developer", size: devSize, colorName: "storageDeveloper"))
        accountedSize += devSize

        // Documents — ~/Documents + ~/Desktop + ~/Downloads
        let docsSize = allocatedSize(home + "/Documents") + allocatedSize(home + "/Desktop") + allocatedSize(home + "/Downloads")
        scannedCategories.append(StorageCategory(id: "documents", name: "Documents", size: docsSize, colorName: "storageDocuments"))
        accountedSize += docsSize

        // iCloud Drive
        let icloudSize = allocatedSize(home + "/Library/Mobile Documents")
        scannedCategories.append(StorageCategory(id: "icloud", name: "iCloud Drive", size: icloudSize, colorName: "storageICloud"))
        accountedSize += icloudSize

        // Photos
        let photosSize = allocatedSize(home + "/Pictures/Photos Library.photoslibrary")
        scannedCategories.append(StorageCategory(id: "photos", name: "Photos", size: photosSize, colorName: "storagePhotos"))
        accountedSize += photosSize

        // Podcasts
        let podcastDirs = (try? FileManager.default.contentsOfDirectory(atPath: home + "/Library/Group Containers"))?.filter { $0.contains("apple.podcasts") } ?? []
        var podcastSize: UInt64 = 0
        for dir in podcastDirs {
            podcastSize += allocatedSize(home + "/Library/Group Containers/" + dir)
        }
        scannedCategories.append(StorageCategory(id: "podcasts", name: "Podcasts", size: podcastSize, colorName: "storagePodcasts"))
        accountedSize += podcastSize

        // Trash
        let trashSize = allocatedSize(home + "/.Trash")
        scannedCategories.append(StorageCategory(id: "trash", name: "Trash", size: trashSize, colorName: "storageTrash"))
        accountedSize += trashSize

        // macOS (system) = used - everything else
        let macosSize = info.usedCapacity > accountedSize ? info.usedCapacity - accountedSize : 0
        scannedCategories.append(StorageCategory(id: "macos", name: "macOS", size: macosSize, colorName: "storageMacOS"))

        // Sort by size descending, filter out zero
        info.categories = scannedCategories.filter { $0.size > 0 }.sorted { $0.size > $1.size }
        return info
    }

    /// Recursively calculate allocated disk size for a path
    private func allocatedSize(_ path: String) -> UInt64 {
        let fm = FileManager.default
        let url = URL(fileURLWithPath: path)

        // Check if path exists
        var isDir: ObjCBool = false
        guard fm.fileExists(atPath: path, isDirectory: &isDir) else { return 0 }

        // Single file
        if !isDir.boolValue {
            let values = try? url.resourceValues(forKeys: [.totalFileAllocatedSizeKey])
            return UInt64(values?.totalFileAllocatedSize ?? 0)
        }

        // Directory — enumerate all contents (include hidden files for accurate sizing)
        guard let enumerator = fm.enumerator(
            at: url,
            includingPropertiesForKeys: [.totalFileAllocatedSizeKey],
            options: []
        ) else { return 0 }

        var total: UInt64 = 0
        for case let fileURL as URL in enumerator {
            if enumerator.level > 10 {
                enumerator.skipDescendants()
                continue
            }
            if let values = try? fileURL.resourceValues(forKeys: [.totalFileAllocatedSizeKey]),
               let size = values.totalFileAllocatedSize {
                total += UInt64(size)
            }
        }
        return total
    }
}
