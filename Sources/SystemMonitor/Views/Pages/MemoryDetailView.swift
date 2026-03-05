import SwiftUI
import Charts

/// Memory detail page — composition bar, pressure chart, tabbed Apps/System view
struct MemoryDetailView: View {
    @Environment(MonitorManager.self) private var monitor
    @Binding var selectedPage: NavigationPage
    @State private var selectedTab: MemoryTab = .apps

    private var mem: MemoryMetrics { monitor.memoryService.metrics }

    enum MemoryTab: String, CaseIterable {
        case apps = "Apps"
        case system = "System"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                pageHeader(title: "Memory", sfSymbol: "memorychip") { selectedPage = .dashboard }

                /* Stat Cards */
                HStack(spacing: 12) {
                    StatCardView(title: "Used", value: Formatters.gigabytes(mem.used), subtitle: "of \(Formatters.gigabytes(mem.totalPhysical))", indicatorColor: Theme.memoryUsageColor(percent: mem.usagePercent * 100))
                    StatCardView(title: "App Memory", value: Formatters.gigabytes(mem.appMemory), subtitle: "Active apps", indicatorColor: Theme.accentBlue)
                    StatCardView(title: "Wired", value: Formatters.gigabytes(mem.wired), subtitle: "Kernel-locked", indicatorColor: Theme.accentOrange)
                    StatCardView(title: "Compressed", value: Formatters.gigabytes(mem.compressed), subtitle: "Compressed", indicatorColor: Theme.accentTeal)
                }

                /* Memory Composition Bar */
                WidgetCardView(title: "Memory Composition", sfSymbol: "chart.bar.fill", symbolColor: Theme.accentBlue) {
                    compositionBar
                }

                /* Memory Pressure Chart */
                WidgetCardView(title: "Memory Pressure", sfSymbol: "gauge.with.dots.needle.33percent", symbolColor: pressureColor, badge: "30s") {
                    SparklineView(
                        data: monitor.memoryHistory.data,
                        color: pressureColor,
                        height: 80
                    )
                }

                /* Summary bar */
                summaryBar

                /* Tabbed View: Apps / System */
                Picker("View", selection: $selectedTab) {
                    ForEach(MemoryTab.allCases, id: \.self) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 200)

                switch selectedTab {
                case .apps:
                    appsTab
                case .system:
                    systemTab
                }
            }
            .padding(24)
        }
    }

    private var pressureColor: Color {
        switch mem.pressureLevel {
        case 0: return Theme.accentGreen
        case 1: return Theme.accentOrange
        default: return Theme.accentPink
        }
    }

    // MARK: - Composition Bar

    private var compositionBar: some View {
        SegmentedBarView(segments: [
            (label: "App Memory", value: Double(mem.appMemory), color: Theme.memoryApp),
            (label: "Wired", value: Double(mem.wired), color: Theme.memoryWired),
            (label: "Compressed", value: Double(mem.compressed), color: Theme.memoryCompressed),
            (label: "Cached", value: Double(mem.cached), color: Theme.memoryCached),
            (label: "Free", value: Double(mem.free), color: Theme.memoryFree),
        ], height: 24)
    }

    // MARK: - Summary Bar

    private var summaryBar: some View {
        HStack(spacing: 20) {
            summaryItem("Apps", Formatters.gigabytes(mem.appMemory), Theme.accentBlue)
            Text("·").foregroundStyle(Theme.secondaryText)
            summaryItem("System", Formatters.gigabytes(mem.wired), Theme.accentPurple)
            Text("·").foregroundStyle(Theme.secondaryText)
            summaryItem("Free", Formatters.gigabytes(mem.free), Theme.accentGreen)
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(Theme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.cardBorder, lineWidth: 1))
    }

    private func summaryItem(_ label: String, _ value: String, _ color: Color) -> some View {
        HStack(spacing: 6) {
            Circle().fill(color).frame(width: 7, height: 7)
            Text("\(label): ")
                .font(Theme.bodyFont)
                .foregroundStyle(Theme.secondaryText)
            + Text(value)
                .font(Theme.monoFont)
                .foregroundStyle(Theme.primaryText)
        }
    }

    // MARK: - Apps Tab

    private var appsTab: some View {
        VStack(spacing: 0) {
            let procs = Array(monitor.processService.processes.prefix(20))
            let maxMem = procs.first?.residentMemory ?? 1

            ForEach(procs) { proc in
                HStack(spacing: 10) {
                    Text(proc.name)
                        .font(Theme.bodyFont)
                        .foregroundStyle(Theme.primaryText)
                        .lineLimit(1)
                        .frame(maxWidth: 180, alignment: .leading)

                    if monitor.electronDetector.isElectronProcess(proc) {
                        Text("Electron")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(Theme.accentPurple)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Theme.accentPurple.opacity(0.15))
                            .clipShape(Capsule())
                    }

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 3).fill(Theme.cardBorder).frame(height: 6)
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Theme.accentBlue)
                                .frame(width: max(Double(proc.residentMemory) / Double(maxMem) * geo.size.width, 2), height: 6)
                        }
                        .frame(height: geo.size.height)
                    }
                    .frame(height: 6)

                    Text(Formatters.bytes(proc.residentMemory))
                        .font(Theme.monoSmallFont)
                        .foregroundStyle(Theme.secondaryText)
                        .frame(width: 70, alignment: .trailing)
                }
                .padding(.vertical, 6)
                .padding(.horizontal, Theme.cardPadding)

                Divider().foregroundStyle(Theme.cardBorder.opacity(0.5)).padding(.horizontal, Theme.cardPadding)
            }
        }
        .background(Theme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: Theme.cardCornerRadius))
        .overlay(RoundedRectangle(cornerRadius: Theme.cardCornerRadius).stroke(Theme.cardBorder, lineWidth: 1))
    }

    // MARK: - System Tab

    private var systemTab: some View {
        let systemProcs = monitor.processService.processes.filter { proc in
            proc.executablePath.hasPrefix("/usr") || proc.executablePath.hasPrefix("/System") || proc.executablePath.hasPrefix("/sbin") || proc.name == "kernel_task"
        }
        let groups = SystemProcessCategorizer.groupProcesses(systemProcs)

        return VStack(spacing: 8) {
            ForEach(groups) { group in
                DisclosureGroup {
                    ForEach(group.processes) { proc in
                        HStack {
                            Text(proc.name)
                                .font(Theme.captionFont)
                                .foregroundStyle(Theme.primaryText)
                                .lineLimit(1)
                            Spacer()
                            Text("\(proc.pid)")
                                .font(Theme.monoSmallFont)
                                .foregroundStyle(Theme.secondaryText)
                            Text(Formatters.bytes(proc.residentMemory))
                                .font(Theme.monoSmallFont)
                                .foregroundStyle(Theme.primaryText)
                                .frame(width: 70, alignment: .trailing)
                        }
                        .padding(.vertical, 2)
                    }
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: group.category.sfSymbol)
                            .font(.system(size: 13))
                            .foregroundStyle(Theme.accentBlue)
                            .frame(width: 20)
                        Text(group.category.rawValue)
                            .font(Theme.cardHeaderFont)
                            .foregroundStyle(Theme.primaryText)

                        Text("\(group.processes.count) processes")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(Theme.secondaryText)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Theme.cardBorder)
                            .clipShape(Capsule())

                        Spacer()

                        Text(Formatters.bytes(group.totalMemory))
                            .font(Theme.monoFont)
                            .foregroundStyle(Theme.primaryText)
                    }
                }
                .padding(12)
                .background(Theme.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: Theme.cardCornerRadius))
                .overlay(RoundedRectangle(cornerRadius: Theme.cardCornerRadius).stroke(Theme.cardBorder, lineWidth: 1))
            }
        }
    }
}
