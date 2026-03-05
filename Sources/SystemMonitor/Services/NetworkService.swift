import Foundation
import Darwin

@Observable
final class NetworkService: @unchecked Sendable {
    private(set) var stats = NetworkStats()

    private var previousCounters: [String: (bytesIn: UInt64, bytesOut: UInt64)] = [:]
    private var lastSampleTime: Date?
    private let queue = DispatchQueue(label: "com.systemmonitor.network", qos: .utility)

    func refresh() {
        queue.async { [weak self] in
            guard let self else { return }
            let result = self.readNetworkStats()
            DispatchQueue.main.async {
                self.stats = result
            }
        }
    }

    private func readNetworkStats() -> NetworkStats {
        var stats = NetworkStats()
        var ifaddrsPtr: UnsafeMutablePointer<ifaddrs>?

        guard getifaddrs(&ifaddrsPtr) == 0, let firstAddr = ifaddrsPtr else {
            return stats
        }
        defer { freeifaddrs(ifaddrsPtr) }

        let now = Date()
        let elapsed = lastSampleTime.map { now.timeIntervalSince($0) } ?? 1.0
        var newCounters: [String: (bytesIn: UInt64, bytesOut: UInt64)] = [:]
        var interfaces: [NetworkStats.InterfaceStats] = []

        var addr = firstAddr
        while true {
            let name = String(cString: addr.pointee.ifa_name)

            // Only process AF_LINK (data link layer) for byte counters
            if addr.pointee.ifa_addr.pointee.sa_family == UInt8(AF_LINK) {
                // Filter to relevant interfaces
                let isRelevant = name.hasPrefix("en") || name.hasPrefix("bridge")

                if isRelevant {
                    let data = unsafeBitCast(addr.pointee.ifa_data, to: UnsafeMutablePointer<if_data>.self)
                    let bytesIn = UInt64(data.pointee.ifi_ibytes)
                    let bytesOut = UInt64(data.pointee.ifi_obytes)

                    newCounters[name] = (bytesIn: bytesIn, bytesOut: bytesOut)

                    var bytesInPerSec: UInt64 = 0
                    var bytesOutPerSec: UInt64 = 0

                    if let prev = previousCounters[name], elapsed > 0 {
                        let deltaIn = bytesIn >= prev.bytesIn ? bytesIn - prev.bytesIn : 0
                        let deltaOut = bytesOut >= prev.bytesOut ? bytesOut - prev.bytesOut : 0
                        bytesInPerSec = UInt64(Double(deltaIn) / elapsed)
                        bytesOutPerSec = UInt64(Double(deltaOut) / elapsed)
                    }

                    let isActive = bytesIn > 0 || bytesOut > 0

                    interfaces.append(NetworkStats.InterfaceStats(
                        id: name,
                        name: name,
                        bytesIn: bytesIn,
                        bytesOut: bytesOut,
                        bytesInPerSecond: bytesInPerSec,
                        bytesOutPerSecond: bytesOutPerSec,
                        isActive: isActive
                    ))

                    stats.totalBytesIn += bytesIn
                    stats.bytesInPerSecond += bytesInPerSec
                    stats.totalBytesOut += bytesOut
                    stats.bytesOutPerSecond += bytesOutPerSec
                }
            }

            guard let next = addr.pointee.ifa_next else { break }
            addr = next
        }

        previousCounters = newCounters
        lastSampleTime = now
        stats.interfaces = interfaces

        return stats
    }
}
