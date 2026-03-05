import SwiftUI

/// Storage detail page — overview, segmented bar, category breakdown
struct StorageDetailView: View {
    @Environment(MonitorManager.self) private var monitor
    @Binding var selectedPage: NavigationPage

    private var info: StorageInfo { monitor.storageService.storageInfo }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                pageHeader(title: "Storage", sfSymbol: "internaldrive") { selectedPage = .dashboard }

                /* Stat Cards */
                HStack(spacing: 12) {
                    StatCardView(title: "Volume", value: info.volumeName.isEmpty ? "—" : info.volumeName, subtitle: "Boot volume", indicatorColor: Theme.accentPurple)
                    StatCardView(title: "Used", value: Formatters.gigabytes(info.usedCapacity), subtitle: "of \(Formatters.gigabytes(info.totalCapacity))", indicatorColor: Theme.accentPurple)
                    StatCardView(title: "Free", value: Formatters.gigabytes(info.availableCapacity), subtitle: Formatters.percentRaw(100 - info.usagePercent * 100) + " free", indicatorColor: Theme.accentGreen)
                }

                /* Storage Composition Bar */
                WidgetCardView(title: "Disk Usage", sfSymbol: "chart.bar.fill", symbolColor: Theme.accentPurple) {
                    storageBar
                }

                /* Category Breakdown */
                WidgetCardView(title: "Category Breakdown", sfSymbol: "folder.fill", symbolColor: Theme.accentBlue) {
                    categoryList
                }
            }
            .padding(24)
        }
    }

    private var storageBar: some View {
        let segments: [(label: String, value: Double, color: Color)] = info.categories.map { cat in
            (label: cat.name, value: Double(cat.size), color: colorForCategory(cat.colorName))
        }
        return SegmentedBarView(segments: segments, height: 28)
    }

    private var categoryList: some View {
        VStack(spacing: 0) {
            ForEach(info.categories.sorted(by: { $0.size > $1.size })) { cat in
                HStack(spacing: 12) {
                    Circle()
                        .fill(colorForCategory(cat.colorName))
                        .frame(width: 10, height: 10)

                    Text(cat.name)
                        .font(Theme.bodyFont)
                        .foregroundStyle(Theme.primaryText)

                    Spacer()

                    /* Proportion bar */
                    let fraction = info.usedCapacity > 0 ? Double(cat.size) / Double(info.usedCapacity) : 0
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Theme.cardBorder)
                                .frame(height: 6)
                            RoundedRectangle(cornerRadius: 3)
                                .fill(colorForCategory(cat.colorName))
                                .frame(width: max(fraction * geo.size.width, 2), height: 6)
                        }
                        .frame(height: geo.size.height)
                    }
                    .frame(width: 120, height: 6)

                    Text(Formatters.bytes(cat.size))
                        .font(Theme.monoSmallFont)
                        .foregroundStyle(Theme.secondaryText)
                        .frame(width: 80, alignment: .trailing)
                }
                .padding(.vertical, 8)

                if cat.id != info.categories.last?.id {
                    Divider().foregroundStyle(Theme.cardBorder.opacity(0.5))
                }
            }
        }
    }

    private func colorForCategory(_ name: String) -> Color {
        Theme.storageColor(for: name)
    }
}
