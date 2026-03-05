import SwiftUI
import Charts

/// Network detail page — up/down sparklines, interface list, connection info
struct NetworkDetailView: View {
    @Environment(MonitorManager.self) private var monitor
    @Binding var selectedPage: NavigationPage

    private var net: NetworkStats { monitor.networkService.stats }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                pageHeader(title: "Network", sfSymbol: "network") { selectedPage = .dashboard }

                /* Stat Cards */
                HStack(spacing: 12) {
                    StatCardView(
                        title: "Download",
                        value: Formatters.networkSpeed(net.bytesInPerSecond),
                        subtitle: "Receiving",
                        indicatorColor: Theme.accentGreen
                    )
                    StatCardView(
                        title: "Upload",
                        value: Formatters.networkSpeed(net.bytesOutPerSecond),
                        subtitle: "Sending",
                        indicatorColor: Theme.accentBlue
                    )
                    StatCardView(
                        title: "Interfaces",
                        value: "\(net.interfaces.filter(\.isActive).count)",
                        subtitle: "Active",
                        indicatorColor: Theme.accentTeal
                    )
                }

                /* Download Sparkline */
                WidgetCardView(title: "Download", sfSymbol: "arrow.down.circle.fill", symbolColor: Theme.accentGreen, badge: "30s") {
                    SparklineView(
                        data: monitor.networkInHistory.data,
                        color: Theme.accentGreen,
                        height: 80
                    )
                }

                /* Upload Sparkline */
                WidgetCardView(title: "Upload", sfSymbol: "arrow.up.circle.fill", symbolColor: Theme.accentBlue, badge: "30s") {
                    SparklineView(
                        data: monitor.networkOutHistory.data,
                        color: Theme.accentBlue,
                        height: 80
                    )
                }

                /* Interface List */
                WidgetCardView(title: "Interfaces", sfSymbol: "antenna.radiowaves.left.and.right", symbolColor: Theme.accentTeal) {
                    interfaceList
                }
            }
            .padding(24)
        }
    }

    private var interfaceList: some View {
        VStack(spacing: 0) {
            /* Header */
            HStack {
                Text("Interface")
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("Download")
                    .frame(width: 100, alignment: .trailing)
                Text("Upload")
                    .frame(width: 100, alignment: .trailing)
                Text("Total In")
                    .frame(width: 80, alignment: .trailing)
            }
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(Theme.secondaryText)
            .padding(.bottom, 6)

            Divider().foregroundStyle(Theme.cardBorder)

            ForEach(net.interfaces) { iface in
                HStack {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(iface.isActive ? Theme.accentGreen : Theme.secondaryText)
                            .frame(width: 6, height: 6)
                        Text(iface.name)
                            .font(Theme.bodyFont)
                            .foregroundStyle(Theme.primaryText)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Text(Formatters.networkSpeed(iface.bytesInPerSecond))
                        .font(Theme.monoSmallFont)
                        .foregroundStyle(Theme.accentGreen)
                        .frame(width: 100, alignment: .trailing)

                    Text(Formatters.networkSpeed(iface.bytesOutPerSecond))
                        .font(Theme.monoSmallFont)
                        .foregroundStyle(Theme.accentBlue)
                        .frame(width: 100, alignment: .trailing)

                    Text(Formatters.bytes(iface.bytesIn))
                        .font(Theme.monoSmallFont)
                        .foregroundStyle(Theme.secondaryText)
                        .frame(width: 80, alignment: .trailing)
                }
                .padding(.vertical, 5)

                if iface.id != net.interfaces.last?.id {
                    Divider().foregroundStyle(Theme.cardBorder.opacity(0.5))
                }
            }
        }
    }
}
