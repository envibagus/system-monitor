import Foundation
import IOKit

@Observable
final class BatteryService: @unchecked Sendable {
    private(set) var batteryInfo = BatteryInfo()

    private let queue = DispatchQueue(label: "com.systemmonitor.battery", qos: .utility)

    func refresh() {
        queue.async { [weak self] in
            guard let self else { return }
            let result = self.readBatteryInfo()
            DispatchQueue.main.async {
                self.batteryInfo = result
            }
        }
    }

    private func readBatteryInfo() -> BatteryInfo {
        var info = BatteryInfo()

        let service = IOServiceGetMatchingService(
            kIOMainPortDefault,
            IOServiceMatching("AppleSmartBattery")
        )
        guard service != 0 else {
            info.isPresent = false
            return info
        }
        defer { IOObjectRelease(service) }

        info.isPresent = true

        // Read battery properties from IORegistry
        if let props = getServiceProperties(service) {
            info.currentCapacity = props["CurrentCapacity"] as? Int ?? 0
            info.maxCapacity = props["MaxCapacity"] as? Int ?? 0
            info.designCapacity = props["DesignCapacity"] as? Int ?? 0
            info.cycleCount = props["CycleCount"] as? Int ?? 0
            info.isCharging = props["IsCharging"] as? Bool ?? false
            info.isPluggedIn = props["ExternalConnected"] as? Bool ?? false

            // Temperature in centidegrees
            if let temp = props["Temperature"] as? Int {
                info.temperature = Double(temp) / 100.0
            }

            // Time remaining in minutes
            info.timeRemaining = props["TimeRemaining"] as? Int ?? -1

            // Voltage in mV
            if let voltage = props["Voltage"] as? Int {
                info.voltage = Double(voltage) / 1000.0
            }

            // Amperage in mA
            if let amperage = props["Amperage"] as? Int {
                info.amperage = Double(amperage) / 1000.0
            }
        }

        return info
    }

    private func getServiceProperties(_ service: io_service_t) -> [String: Any]? {
        var propsRef: Unmanaged<CFMutableDictionary>?
        let result = IORegistryEntryCreateCFProperties(service, &propsRef, kCFAllocatorDefault, 0)
        guard result == kIOReturnSuccess, let props = propsRef?.takeRetainedValue() else {
            return nil
        }
        return props as? [String: Any]
    }
}
