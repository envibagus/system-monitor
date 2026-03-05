import Foundation
import Darwin

@Observable
final class MemoryService: @unchecked Sendable {
    private(set) var metrics = MemoryMetrics()

    private let queue = DispatchQueue(label: "com.systemmonitor.memory", qos: .utility)
    private let totalPhysical: UInt64

    init() {
        var memSize: UInt64 = 0
        var size = MemoryLayout<UInt64>.size
        sysctlbyname("hw.memsize", &memSize, &size, nil, 0)
        totalPhysical = memSize
    }

    func refresh() {
        queue.async { [weak self] in
            guard let self else { return }
            let result = self.readMemoryMetrics()
            DispatchQueue.main.async {
                self.metrics = result
            }
        }
    }

    private func readMemoryMetrics() -> MemoryMetrics {
        var metrics = MemoryMetrics()
        metrics.totalPhysical = totalPhysical

        // VM statistics
        var vmStats = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64>.size / MemoryLayout<integer_t>.size)

        let result = withUnsafeMutablePointer(to: &vmStats) { ptr in
            ptr.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { intPtr in
                host_statistics64(mach_host_self(), HOST_VM_INFO64, intPtr, &count)
            }
        }

        guard result == KERN_SUCCESS else { return metrics }

        let pageSize = UInt64(getpagesize())

        let active = UInt64(vmStats.active_count) * pageSize
        let inactive = UInt64(vmStats.inactive_count) * pageSize
        let wired = UInt64(vmStats.wire_count) * pageSize
        let compressed = UInt64(vmStats.compressor_page_count) * pageSize
        let free = UInt64(vmStats.free_count) * pageSize
        let purgeable = UInt64(vmStats.purgeable_count) * pageSize
        let speculative = UInt64(vmStats.speculative_count) * pageSize

        let internal_ = UInt64(vmStats.internal_page_count) * pageSize
        metrics.appMemory = internal_ > purgeable ? internal_ - purgeable : 0
        metrics.wired = wired
        metrics.compressed = compressed
        metrics.cached = purgeable + speculative
        metrics.free = free

        // Memory pressure level
        var pressureLevel: Int32 = 0
        var pressureSize = MemoryLayout<Int32>.size
        let pressureResult = sysctlbyname("kern.memorystatus_vm_pressure_level", &pressureLevel, &pressureSize, nil, 0)
        if pressureResult == 0 {
            metrics.pressureLevel = Int(pressureLevel)
        }

        return metrics
    }
}
