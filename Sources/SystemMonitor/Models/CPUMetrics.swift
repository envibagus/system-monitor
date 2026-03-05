import Foundation

struct CPUMetrics: Sendable {
    var totalUsage: Double = 0.0
    var userUsage: Double = 0.0
    var systemUsage: Double = 0.0
    var idleUsage: Double = 1.0
    var coreUsages: [CoreUsage] = []
    var loadAverage: (one: Double, five: Double, fifteen: Double) = (0, 0, 0)
    var activeCoreCount: Int = 0
    var totalProcessCount: Int = 0

    struct CoreUsage: Identifiable, Sendable {
        let id: Int
        let coreIndex: Int
        let usage: Double
        let isPerformanceCore: Bool

        var label: String {
            isPerformanceCore ? "P\(coreIndex)" : "E\(coreIndex)"
        }
    }
}
