import Foundation

struct StorageInfo: Sendable {
    var volumeName: String = ""
    var totalCapacity: UInt64 = 0
    var availableCapacity: UInt64 = 0
    var categories: [StorageCategory] = []

    var usedCapacity: UInt64 {
        totalCapacity - availableCapacity
    }

    var usagePercent: Double {
        guard totalCapacity > 0 else { return 0 }
        return Double(usedCapacity) / Double(totalCapacity)
    }
}

struct StorageCategory: Identifiable, Sendable {
    let id: String
    let name: String
    let size: UInt64
    let colorName: String

    static let applications = "Applications"
    static let documents = "Documents"
    static let media = "Media"
    static let developer = "Developer"
    static let systemData = "System Data"
    static let other = "Other"
}
