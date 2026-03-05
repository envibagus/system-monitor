import Foundation
import Darwin

@Observable
final class CPUService: @unchecked Sendable {
    private(set) var metrics = CPUMetrics()

    private var previousTicks: [(user: UInt64, system: UInt64, idle: UInt64, nice: UInt64)] = []
    private var previousInfoArray: processor_info_array_t?
    private var previousInfoCount: mach_msg_type_number_t = 0

    private let queue = DispatchQueue(label: "com.systemmonitor.cpu", qos: .utility)
    private let performanceCoreCount: Int
    private let efficiencyCoreCount: Int

    init() {
        performanceCoreCount = Self.sysctlInt("hw.perflevel0.physicalcpu") ?? 0
        efficiencyCoreCount = Self.sysctlInt("hw.perflevel1.physicalcpu") ?? 0
    }

    func refresh() {
        queue.async { [weak self] in
            guard let self else { return }
            let result = self.readCPUMetrics()
            DispatchQueue.main.async {
                self.metrics = result
            }
        }
    }

    // MARK: - CPU Metrics Collection

    private func readCPUMetrics() -> CPUMetrics {
        var metrics = CPUMetrics()

        // Per-core usage via host_processor_info
        var numCPUs: natural_t = 0
        var infoArray: processor_info_array_t?
        var infoCount: mach_msg_type_number_t = 0

        let result = host_processor_info(
            mach_host_self(),
            PROCESSOR_CPU_LOAD_INFO,
            &numCPUs,
            &infoArray,
            &infoCount
        )

        guard result == KERN_SUCCESS, let info = infoArray else {
            return metrics
        }

        let cpuLoadInfoSize = Int(CPU_STATE_MAX)
        var coreUsages: [CPUMetrics.CoreUsage] = []
        var totalUser: UInt64 = 0
        var totalSystem: UInt64 = 0
        var totalIdle: UInt64 = 0
        var activeCores = 0

        // Track P-core and E-core indices separately
        var pCoreIndex = 0
        var eCoreIndex = 0

        for i in 0..<Int(numCPUs) {
            let offset = i * cpuLoadInfoSize
            let user = UInt64(info[offset + Int(CPU_STATE_USER)])
            let system = UInt64(info[offset + Int(CPU_STATE_SYSTEM)])
            let idle = UInt64(info[offset + Int(CPU_STATE_IDLE)])
            let nice = UInt64(info[offset + Int(CPU_STATE_NICE)])

            var usage: Double = 0.0

            if i < previousTicks.count {
                let prev = previousTicks[i]
                let deltaUser = user - prev.user
                let deltaSystem = system - prev.system
                let deltaIdle = idle - prev.idle
                let deltaNice = nice - prev.nice
                let totalDelta = deltaUser + deltaSystem + deltaIdle + deltaNice
                if totalDelta > 0 {
                    usage = Double(deltaUser + deltaSystem + deltaNice) / Double(totalDelta)
                }
            }

            totalUser += user
            totalSystem += system
            totalIdle += idle

            let isPerformanceCore = i < performanceCoreCount
            let coreIndex: Int
            if isPerformanceCore {
                coreIndex = pCoreIndex
                pCoreIndex += 1
            } else {
                coreIndex = eCoreIndex
                eCoreIndex += 1
            }

            if usage > 0.01 { activeCores += 1 }

            coreUsages.append(CPUMetrics.CoreUsage(
                id: i,
                coreIndex: coreIndex,
                usage: usage,
                isPerformanceCore: isPerformanceCore
            ))
        }

        // Store current ticks for next delta
        var newTicks: [(user: UInt64, system: UInt64, idle: UInt64, nice: UInt64)] = []
        for i in 0..<Int(numCPUs) {
            let offset = i * cpuLoadInfoSize
            newTicks.append((
                user: UInt64(info[offset + Int(CPU_STATE_USER)]),
                system: UInt64(info[offset + Int(CPU_STATE_SYSTEM)]),
                idle: UInt64(info[offset + Int(CPU_STATE_IDLE)]),
                nice: UInt64(info[offset + Int(CPU_STATE_NICE)])
            ))
        }

        // Deallocate previous buffer to prevent memory leak
        if let prevArray = previousInfoArray {
            vm_deallocate(
                mach_task_self_,
                vm_address_t(bitPattern: prevArray),
                vm_size_t(Int(previousInfoCount) * MemoryLayout<integer_t>.stride)
            )
        }
        previousInfoArray = infoArray
        previousInfoCount = infoCount
        previousTicks = newTicks

        // Total usage
        let totalTicks = totalUser + totalSystem + totalIdle
        if totalTicks > 0 {
            metrics.totalUsage = Double(totalUser + totalSystem) / Double(totalTicks)
            metrics.userUsage = Double(totalUser) / Double(totalTicks)
            metrics.systemUsage = Double(totalSystem) / Double(totalTicks)
            metrics.idleUsage = Double(totalIdle) / Double(totalTicks)
        }

        metrics.coreUsages = coreUsages
        metrics.activeCoreCount = activeCores

        // Load averages
        var loadAvg = [Double](repeating: 0.0, count: 3)
        getloadavg(&loadAvg, 3)
        metrics.loadAverage = (loadAvg[0], loadAvg[1], loadAvg[2])

        // Total process count
        metrics.totalProcessCount = Self.sysctlInt("kern.maxproc") ?? 0

        return metrics
    }

    // MARK: - sysctl Helpers

    private static func sysctlInt(_ name: String) -> Int? {
        var value: Int = 0
        var size = MemoryLayout<Int>.size
        let result = sysctlbyname(name, &value, &size, nil, 0)
        return result == 0 ? value : nil
    }
}
