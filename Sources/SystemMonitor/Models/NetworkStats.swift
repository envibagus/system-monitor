import Foundation

struct NetworkStats: Sendable {
    var interfaces: [InterfaceStats] = []
    var totalBytesIn: UInt64 = 0
    var totalBytesOut: UInt64 = 0
    var bytesInPerSecond: UInt64 = 0
    var bytesOutPerSecond: UInt64 = 0

    struct InterfaceStats: Identifiable, Sendable {
        let id: String
        let name: String
        let bytesIn: UInt64
        let bytesOut: UInt64
        let bytesInPerSecond: UInt64
        let bytesOutPerSecond: UInt64
        let isActive: Bool
    }
}
