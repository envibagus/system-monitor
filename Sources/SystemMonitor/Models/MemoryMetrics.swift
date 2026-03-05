import Foundation

struct MemoryMetrics: Sendable {
    var totalPhysical: UInt64 = 0
    var appMemory: UInt64 = 0
    var wired: UInt64 = 0
    var compressed: UInt64 = 0
    var cached: UInt64 = 0
    var free: UInt64 = 0

    var used: UInt64 {
        appMemory + wired + compressed
    }

    var usagePercent: Double {
        guard totalPhysical > 0 else { return 0 }
        return Double(used) / Double(totalPhysical)
    }

    /// Memory pressure level: 0 = normal, 1 = warn, 2 = critical
    var pressureLevel: Int = 0
}
