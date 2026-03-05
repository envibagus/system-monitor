import SwiftUI
import Charts

/// Dashboard home page (Readout style) — health header, stat cards, widget grid, alerts, summary row
struct DashboardView: View {
    @Environment(MonitorManager.self) private var monitor
    @Binding var selectedPage: NavigationPage

    private var isHealthy: Bool {
        let cpuTemp = monitor.smcService.cpuTemperature ?? 0
        let ramPercent = monitor.memoryService.metrics.usagePercent * 100
        let storagePercent = monitor.storageService.storageInfo.usagePercent * 100
        return !(cpuTemp > 90 || ramPercent > 85 || storagePercent > 90)
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        let name = NSFullUserName().components(separatedBy: " ").first ?? "there"
        let timeGreeting: String
        switch hour {
        case 5..<12: timeGreeting = "Good morning"
        case 12..<17: timeGreeting = "Good afternoon"
        case 17..<22: timeGreeting = "Good evening"
        default: timeGreeting = "Burning the midnight oil"
        }
        return "\(timeGreeting), \(name)"
    }

    private var healthSummary: String {
        let cpu = monitor.cpuService.metrics.totalUsage
        let mem = monitor.memoryService.metrics
        let procs = monitor.processService.totalProcessCount

        if !isHealthy {
            var issues: [String] = []
            let ramPercent = mem.usagePercent * 100
            if ramPercent > 85 { issues.append("memory is running tight at \(Formatters.percentRaw(ramPercent))") }
            let cpuTemp = monitor.smcService.cpuTemperature ?? 0
            if cpuTemp > 90 { issues.append("CPU is running hot at \(Formatters.temperature(cpuTemp))") }
            let storagePercent = monitor.storageService.storageInfo.usagePercent * 100
            if storagePercent > 90 { issues.append("disk space is low") }
            return "Heads up — \(issues.joined(separator: " and ")). \(procs) processes active."
        }

        // Healthy state — friendly summary
        let cpuDesc: String
        if cpu < 0.15 { cpuDesc = "Your Mac is cruising along nicely" }
        else if cpu < 0.5 { cpuDesc = "Things are humming along smoothly" }
        else if cpu < 0.7 { cpuDesc = "Your Mac is working steadily" }
        else { cpuDesc = "Your Mac is working hard right now" }

        return "\(cpuDesc) — \(Formatters.gigabytes(mem.used)) of \(Formatters.gigabytes(mem.totalPhysical)) RAM in use, \(procs) processes."
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                /* System Health Header */
                healthHeader

                /* Top Stat Cards (4-up) */
                statCardsRow

                /* Widget Grid (2-column) */
                widgetGrid

                /* Alert Banners */
                alertBanners

                /* Bottom Summary Row */
                summaryRow
            }
            .padding(24)
        }
    }

    // MARK: - Health Header

    private var healthHeader: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Text("\(greeting)!")
                    .font(Theme.titleFont)
                    .foregroundStyle(Theme.primaryText)

                if isHealthy {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Theme.accentGreen)
                        .font(.system(size: 16))
                } else {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(Theme.accentOrange)
                        .font(.system(size: 16))
                }
            }

            Text(healthSummary)
                .font(Theme.bodyFont)
                .foregroundStyle(Theme.secondaryText)

            Text("Up \(uptimeString) · Apple Silicon · macOS 26")
                .font(Theme.captionFont)
                .foregroundStyle(Theme.secondaryText.opacity(0.7))
        }
        .padding(.bottom, 4)
    }

    private var uptimeString: String {
        var boottime = timeval()
        var size = MemoryLayout<timeval>.stride
        let mib: [Int32] = [CTL_KERN, KERN_BOOTTIME]
        let result = mib.withUnsafeBufferPointer { ptr in
            sysctl(UnsafeMutablePointer(mutating: ptr.baseAddress!), 2, &boottime, &size, nil, 0)
        }
        guard result == 0 else { return "—" }
        let elapsed = Date().timeIntervalSince1970 - Double(boottime.tv_sec)
        return Formatters.uptime(elapsed)
    }

    // MARK: - Stat Cards

    private var statCardsRow: some View {
        HStack(spacing: 12) {
            /* CPU */
            StatCardView(
                title: "CPU",
                value: Formatters.percent(monitor.cpuService.metrics.totalUsage),
                subtitle: "CPU Usage",
                indicatorColor: Theme.cpuUsageColor(percent: monitor.cpuService.metrics.totalUsage * 100)
            )
            .onTapGesture { selectedPage = .cpu }

            /* RAM */
            let mem = monitor.memoryService.metrics
            StatCardView(
                title: "RAM",
                value: Formatters.gigabytes(mem.used),
                subtitle: "of \(Formatters.gigabytes(mem.totalPhysical))",
                indicatorColor: Theme.memoryUsageColor(percent: mem.usagePercent * 100)
            )
            .onTapGesture { selectedPage = .memory }

            /* Processes */
            StatCardView(
                title: "Processes",
                value: "\(monitor.processService.totalProcessCount)",
                subtitle: "\(monitor.cpuService.metrics.activeCoreCount) active cores",
                indicatorColor: Theme.accentGreen
            )
            .onTapGesture { selectedPage = .cpu }

            /* Storage */
            let stor = monitor.storageService.storageInfo
            StatCardView(
                title: "Storage",
                value: Formatters.gigabytes(stor.usedCapacity),
                subtitle: "of \(Formatters.gigabytes(stor.totalCapacity))",
                indicatorColor: Theme.accentPurple
            )
            .onTapGesture { selectedPage = .storage }
        }
    }

    // MARK: - Widget Grid

    private var widgetGrid: some View {
        VStack(spacing: 16) {
            /* Row 1: CPU + Memory sparklines (equal height) */
            EqualHeightHStack(spacing: 12) {
                WidgetCardView(title: "CPU Usage", sfSymbol: "cpu", symbolColor: Theme.accentBlue, badge: "30s", destination: .cpu) {
                    SparklineView(data: monitor.cpuHistory.data, color: Theme.accentBlue, height: 80)
                }
                .onTapGesture { selectedPage = .cpu }

                WidgetCardView(title: "Memory Pressure", sfSymbol: "memorychip", symbolColor: Theme.accentOrange, badge: "30s", destination: .memory) {
                    SparklineView(data: monitor.memoryHistory.data, color: Theme.accentOrange, height: 80)
                }
                .onTapGesture { selectedPage = .memory }
            }

            /* Row 2: Top Memory Users + Thermal (equal height) */
            EqualHeightHStack(spacing: 12) {
                WidgetCardView(title: "Top Memory Users", sfSymbol: "arrow.up.circle", symbolColor: Theme.accentPurple, destination: .memory) {
                    topMemoryUsers
                }
                .onTapGesture { selectedPage = .memory }

                WidgetCardView(title: "Thermal", sfSymbol: "thermometer.medium", symbolColor: Theme.accentOrange, destination: .thermal) {
                    thermalGauges
                }
                .onTapGesture { selectedPage = .thermal }
            }

            /* Row 3: Storage (full width) */
            WidgetCardView(title: "Storage", sfSymbol: "internaldrive", symbolColor: Theme.accentPurple, destination: .storage) {
                storageBar
            }
            .onTapGesture { selectedPage = .storage }
        }
    }

    // MARK: - Widget Content

    private var topMemoryUsers: some View {
        let top5 = Array(monitor.processService.processes.prefix(5))
        let maxMem = top5.first?.residentMemory ?? 1

        return VStack(spacing: 6) {
            if top5.isEmpty {
                Text("Loading processes...")
                    .font(Theme.captionFont)
                    .foregroundStyle(Theme.secondaryText)
            } else {
                ForEach(top5) { proc in
                    ProcessRowView(
                        name: proc.name,
                        memory: proc.residentMemory,
                        maxMemory: maxMem,
                        isElectron: monitor.electronDetector.isElectronProcess(proc)
                    )
                }
            }
        }
    }

    private var thermalGauges: some View {
        HStack(spacing: 20) {
            let cpuTemp = monitor.smcService.cpuTemperature ?? 0
            let gpuTemp = monitor.smcService.gpuTemperature ?? 0

            HalfGaugeView(
                value: cpuTemp,
                maxValue: 110,
                label: "CPU",
                valueText: cpuTemp > 0 ? Formatters.temperature(cpuTemp) : "—",
                color: Theme.temperatureColor(celsius: cpuTemp),
                size: 90
            )

            HalfGaugeView(
                value: gpuTemp,
                maxValue: 110,
                label: "GPU",
                valueText: gpuTemp > 0 ? Formatters.temperature(gpuTemp) : "—",
                color: Theme.temperatureColor(celsius: gpuTemp),
                size: 90
            )

            Spacer()
        }
    }

    private var storageBar: some View {
        let info = monitor.storageService.storageInfo
        let segments: [(label: String, value: Double, color: Color)] = info.categories.map { cat in
            (label: cat.name, value: Double(cat.size), color: Theme.storageColor(for: cat.colorName))
        }
        return SegmentedBarView(segments: segments)
    }

    // MARK: - Alert Banners

    @ViewBuilder
    private var alertBanners: some View {
        let cpuTemp = monitor.smcService.cpuTemperature ?? 0
        let ramPercent = monitor.memoryService.metrics.usagePercent * 100
        let storagePercent = monitor.storageService.storageInfo.usagePercent * 100

        if cpuTemp > 85 {
            AlertBannerView(
                message: "CPU temperature at \(Formatters.temperature(cpuTemp)). Consider closing intensive apps.",
                level: cpuTemp > 95 ? .critical : .warning
            ) { selectedPage = .thermal }
        }

        if ramPercent > 80 {
            AlertBannerView(
                message: "Memory at \(Formatters.percentRaw(ramPercent)). \(topMemoryAppName) is using the most.",
                level: ramPercent > 90 ? .critical : .warning
            ) { selectedPage = .memory }
        }

        if storagePercent > 90 {
            let free = monitor.storageService.storageInfo.availableCapacity
            AlertBannerView(
                message: "Disk has only \(Formatters.bytes(free)) free.",
                level: .warning
            ) { selectedPage = .storage }
        }
    }

    private var topMemoryAppName: String {
        monitor.processService.processes.first?.name ?? "Unknown"
    }

    // MARK: - Summary Row

    private var summaryRow: some View {
        HStack(spacing: 12) {
            /* Fans */
            summaryCard(
                icon: "fan",
                title: "Fans",
                value: monitor.smcService.fans.first.map { Formatters.rpm($0.currentRPM) } ?? "—",
                color: Theme.accentBlue
            )

            /* Network */
            summaryCard(
                icon: "arrow.down.circle",
                title: "Network",
                value: "\(Formatters.networkSpeed(monitor.networkService.stats.bytesInPerSecond)) ↓",
                color: Theme.accentGreen
            )

            /* Battery */
            let bat = monitor.batteryService.batteryInfo
            summaryCard(
                icon: "battery.75percent",
                title: "Battery",
                value: bat.isPresent ? Formatters.percentRaw(bat.chargePercent) : "No Battery",
                color: bat.isCharging ? Theme.accentGreen : Theme.accentOrange
            )

            /* Uptime */
            summaryCard(
                icon: "clock",
                title: "Uptime",
                value: uptimeString,
                color: Theme.accentTeal
            )
        }
    }

    private func summaryCard(icon: String, title: String, value: String, color: Color) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(color)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(Theme.captionFont)
                    .foregroundStyle(Theme.secondaryText)
                Text(value)
                    .font(Theme.monoSmallFont)
                    .foregroundStyle(Theme.primaryText)
                    .lineLimit(1)
            }

            Spacer()
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(Theme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: Theme.cardCornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cardCornerRadius)
                .stroke(Theme.cardBorder, lineWidth: 1)
        )
    }
}
