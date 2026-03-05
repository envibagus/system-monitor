import SwiftUI
import Charts

/// CPU detail page — stat cards, large sparkline, per-core bar grid, top processes table
struct CPUDetailView: View {
    @Environment(MonitorManager.self) private var monitor
    @Binding var selectedPage: NavigationPage
    @State private var showPerCore = true

    private var cpu: CPUMetrics { monitor.cpuService.metrics }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                /* Page Header */
                pageHeader(title: "CPU", sfSymbol: "cpu") { selectedPage = .dashboard }

                /* Stat Cards */
                HStack(spacing: 12) {
                    StatCardView(
                        title: "Usage",
                        value: Formatters.percent(cpu.totalUsage),
                        subtitle: "Total CPU",
                        indicatorColor: Theme.cpuUsageColor(percent: cpu.totalUsage * 100)
                    )
                    StatCardView(
                        title: "Temperature",
                        value: monitor.smcService.cpuTemperature.map { Formatters.temperature($0) } ?? "—",
                        subtitle: "CPU Package",
                        indicatorColor: Theme.temperatureColor(celsius: monitor.smcService.cpuTemperature ?? 0)
                    )
                    StatCardView(
                        title: "Active Cores",
                        value: "\(cpu.activeCoreCount)",
                        subtitle: "of \(cpu.coreUsages.count) cores",
                        indicatorColor: Theme.accentGreen
                    )
                    StatCardView(
                        title: "Load Average",
                        value: String(format: "%.2f", cpu.loadAverage.one),
                        subtitle: String(format: "%.2f / %.2f", cpu.loadAverage.five, cpu.loadAverage.fifteen),
                        indicatorColor: Theme.accentOrange
                    )
                }

                /* Large CPU Sparkline */
                WidgetCardView(title: "CPU Usage", sfSymbol: "chart.xyaxis.line", symbolColor: Theme.accentBlue, badge: "30s") {
                    SparklineView(
                        data: monitor.cpuHistory.data,
                        color: Theme.accentBlue,
                        height: 120
                    )
                }

                /* Per-Core View */
                WidgetCardView(title: "Per-Core Usage", sfSymbol: "square.grid.3x3", symbolColor: Theme.accentBlue) {
                    perCoreGrid
                }

                /* Top CPU Processes */
                WidgetCardView(title: "Top Processes", sfSymbol: "list.number", symbolColor: Theme.accentBlue) {
                    topProcessesTable
                }
            }
            .padding(24)
        }
    }

    // MARK: - Per-Core Grid

    private var perCoreGrid: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: min(cpu.coreUsages.count, 12))

        return LazyVGrid(columns: columns, spacing: 8) {
            ForEach(cpu.coreUsages) { core in
                VStack(spacing: 4) {
                    /* Vertical bar */
                    GeometryReader { geo in
                        ZStack(alignment: .bottom) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Theme.cardBorder)

                            RoundedRectangle(cornerRadius: 3)
                                .fill(core.isPerformanceCore ? Theme.accentBlue : Theme.accentGreen)
                                .frame(height: max(geo.size.height * core.usage, 2))
                        }
                    }
                    .frame(height: 60)

                    /* Core label */
                    Text(core.label)
                        .font(.system(size: 9, weight: .medium, design: .monospaced))
                        .foregroundStyle(Theme.secondaryText)

                    /* Percentage */
                    Text(Formatters.percent(core.usage))
                        .font(.system(size: 9, weight: .medium, design: .monospaced))
                        .foregroundStyle(core.usage > 0.7 ? Theme.accentPink : Theme.primaryText)
                }
            }
        }
        .animation(Theme.gaugeAnimation, value: cpu.coreUsages.map(\.usage))
    }

    // MARK: - Top Processes Table

    private var topProcessesTable: some View {
        VStack(spacing: 0) {
            /* Table Header */
            HStack {
                Text("Process")
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("PID")
                    .frame(width: 60, alignment: .trailing)
                Text("CPU %")
                    .frame(width: 70, alignment: .trailing)
                Text("Memory")
                    .frame(width: 80, alignment: .trailing)
            }
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(Theme.secondaryText)
            .padding(.bottom, 6)

            Divider().foregroundStyle(Theme.cardBorder)

            /* Rows */
            let top10 = Array(monitor.processService.processes.prefix(10))
            ForEach(top10) { proc in
                HStack {
                    Text(proc.name)
                        .font(Theme.bodyFont)
                        .foregroundStyle(Theme.primaryText)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text("\(proc.pid)")
                        .font(Theme.monoSmallFont)
                        .foregroundStyle(Theme.secondaryText)
                        .frame(width: 60, alignment: .trailing)

                    Text("—")
                        .font(Theme.monoSmallFont)
                        .foregroundStyle(Theme.secondaryText)
                        .frame(width: 70, alignment: .trailing)

                    Text(Formatters.bytes(proc.residentMemory))
                        .font(Theme.monoSmallFont)
                        .foregroundStyle(Theme.primaryText)
                        .frame(width: 80, alignment: .trailing)
                }
                .padding(.vertical, 5)

                if proc.id != top10.last?.id {
                    Divider().foregroundStyle(Theme.cardBorder.opacity(0.5))
                }
            }
        }
    }
}

/// Reusable page header with optional back button
func pageHeader(title: String, sfSymbol: String, onBack: (() -> Void)? = nil) -> some View {
    HStack(spacing: 12) {
        if let onBack {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Theme.accentBlue)
            }
            .buttonStyle(.plain)
        }

        Image(systemName: sfSymbol)
            .font(.system(size: 20))
            .foregroundStyle(Theme.accentBlue)
        Text(title)
            .font(Theme.titleFont)
            .foregroundStyle(Theme.primaryText)
        Spacer()
    }
    .padding(.bottom, 4)
}
