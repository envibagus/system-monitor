import Foundation

struct BatteryInfo: Sendable {
    var isPresent: Bool = false
    var currentCapacity: Int = 0
    var maxCapacity: Int = 0
    var designCapacity: Int = 0
    var cycleCount: Int = 0
    var isCharging: Bool = false
    var isPluggedIn: Bool = false
    var temperature: Double = 0.0
    var timeRemaining: Int = -1
    var voltage: Double = 0.0
    var amperage: Double = 0.0

    var chargePercent: Double {
        guard maxCapacity > 0 else { return 0 }
        return Double(currentCapacity) / Double(maxCapacity) * 100
    }

    var healthPercent: Double {
        guard designCapacity > 0 else { return 0 }
        return Double(maxCapacity) / Double(designCapacity) * 100
    }

    var statusText: String {
        if !isPresent { return "No Battery" }
        if isCharging { return "Charging" }
        if isPluggedIn { return "Full" }
        return "On Battery"
    }

    var timeRemainingText: String {
        guard timeRemaining > 0 else { return "Calculating..." }
        let hours = timeRemaining / 60
        let minutes = timeRemaining % 60
        return "\(hours)h \(minutes)m"
    }
}
