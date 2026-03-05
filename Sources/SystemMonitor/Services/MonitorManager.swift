import Foundation
import SwiftUI

@Observable
final class MonitorManager: @unchecked Sendable {
    let smcService = SMCService()
    let cpuService = CPUService()
    let memoryService = MemoryService()
    let processService = ProcessService()
    let storageService = StorageService()
    let networkService = NetworkService()
    let batteryService = BatteryService()
    let electronDetector = ElectronDetector()

    /// Rolling history for sparkline charts (30 data points)
    var cpuHistory = HistoryBuffer(maxPoints: 30)
    var memoryHistory = HistoryBuffer(maxPoints: 30)
    var networkInHistory = HistoryBuffer(maxPoints: 30)
    var networkOutHistory = HistoryBuffer(maxPoints: 30)
    var cpuTempHistory = HistoryBuffer(maxPoints: 60)
    var gpuTempHistory = HistoryBuffer(maxPoints: 60)

    private var mainTimer: DispatchSourceTimer?
    private var storageTimer: DispatchSourceTimer?
    private var batteryTimer: DispatchSourceTimer?
    private var networkTimer: DispatchSourceTimer?

    private let timerQueue = DispatchQueue(label: "com.systemmonitor.timers", qos: .utility)

    var refreshInterval: TimeInterval = 2.0

    func startMonitoring() {
        electronDetector.scanForElectronApps()

        // Main timer: CPU, Memory, SMC, Process (2s default)
        mainTimer = DispatchSource.makeTimerSource(queue: timerQueue)
        mainTimer?.schedule(deadline: .now(), repeating: refreshInterval)
        mainTimer?.setEventHandler { [weak self] in
            self?.refreshMainServices()
        }
        mainTimer?.resume()

        // Network timer (1s)
        networkTimer = DispatchSource.makeTimerSource(queue: timerQueue)
        networkTimer?.schedule(deadline: .now(), repeating: 1.0)
        networkTimer?.setEventHandler { [weak self] in
            guard let self else { return }
            self.networkService.refresh()
            DispatchQueue.main.async {
                self.networkInHistory.append(Double(self.networkService.stats.bytesInPerSecond))
                self.networkOutHistory.append(Double(self.networkService.stats.bytesOutPerSecond))
            }
        }
        networkTimer?.resume()

        // Battery timer (10s)
        batteryTimer = DispatchSource.makeTimerSource(queue: timerQueue)
        batteryTimer?.schedule(deadline: .now(), repeating: 10.0)
        batteryTimer?.setEventHandler { [weak self] in
            self?.batteryService.refresh()
        }
        batteryTimer?.resume()

        // Storage timer (30s)
        storageTimer = DispatchSource.makeTimerSource(queue: timerQueue)
        storageTimer?.schedule(deadline: .now() + 1.0, repeating: 30.0)
        storageTimer?.setEventHandler { [weak self] in
            self?.storageService.refresh()
        }
        storageTimer?.resume()
    }

    func stopMonitoring() {
        mainTimer?.cancel()
        mainTimer = nil
        networkTimer?.cancel()
        networkTimer = nil
        batteryTimer?.cancel()
        batteryTimer = nil
        storageTimer?.cancel()
        storageTimer = nil
    }

    private func refreshMainServices() {
        cpuService.refresh()
        memoryService.refresh()
        smcService.refresh()
        processService.refresh()

        // Update history buffers on main thread
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.cpuHistory.append(self.cpuService.metrics.totalUsage)
            self.memoryHistory.append(self.memoryService.metrics.usagePercent)

            if let cpuTemp = self.smcService.cpuTemperature {
                self.cpuTempHistory.append(cpuTemp)
            }
            if let gpuTemp = self.smcService.gpuTemperature {
                self.gpuTempHistory.append(gpuTemp)
            }
        }
    }
}
