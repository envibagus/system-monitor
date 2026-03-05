import SwiftUI

/// Battery detail page — circular gauge, health stats, charge info
struct BatteryDetailView: View {
    @Environment(MonitorManager.self) private var monitor
    @Binding var selectedPage: NavigationPage

    private var bat: BatteryInfo { monitor.batteryService.batteryInfo }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                pageHeader(title: "Battery", sfSymbol: "battery.75percent") { selectedPage = .dashboard }

                if !bat.isPresent {
                    noBatteryView
                } else {
                    batteryContent
                }
            }
            .padding(24)
        }
    }

    private var batteryContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            /* Stat Cards */
            HStack(spacing: 12) {
                StatCardView(title: "Charge", value: Formatters.percentRaw(bat.chargePercent), subtitle: bat.statusText, indicatorColor: bat.isCharging ? Theme.accentGreen : Theme.accentOrange)
                StatCardView(title: "Health", value: Formatters.percentRaw(bat.healthPercent), subtitle: bat.healthPercent > 80 ? "Normal" : "Service Recommended", indicatorColor: bat.healthPercent > 80 ? Theme.accentGreen : Theme.accentPink)
                StatCardView(title: "Cycles", value: "\(bat.cycleCount)", subtitle: "Charge cycles", indicatorColor: Theme.accentTeal)
                StatCardView(title: "Temperature", value: Formatters.temperature(bat.temperature), subtitle: "Battery temp", indicatorColor: Theme.temperatureColor(celsius: bat.temperature))
            }

            /* Large Circular Gauge */
            WidgetCardView(title: "Charge Level", sfSymbol: "battery.75percent", symbolColor: Theme.accentGreen) {
                HStack(spacing: 40) {
                    circularGauge
                    chargeDetails
                    Spacer()
                }
                .padding(.vertical, 8)
            }

            /* Battery Details */
            WidgetCardView(title: "Battery Details", sfSymbol: "info.circle", symbolColor: Theme.accentBlue) {
                detailsList
            }
        }
    }

    // MARK: - Circular Gauge

    private var circularGauge: some View {
        let fraction = bat.chargePercent / 100.0
        let gaugeColor = fraction > 0.2 ? Theme.accentGreen : Theme.accentPink

        return ZStack {
            /* Background ring */
            Circle()
                .stroke(Theme.cardBorder, lineWidth: 10)
                .frame(width: 120, height: 120)

            /* Value ring */
            Circle()
                .trim(from: 0, to: fraction)
                .stroke(gaugeColor, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                .frame(width: 120, height: 120)
                .rotationEffect(.degrees(-90))
                .animation(Theme.gaugeAnimation, value: fraction)

            /* Center text */
            VStack(spacing: 2) {
                Text(Formatters.percentRaw(bat.chargePercent))
                    .font(.system(size: 24, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Theme.primaryText)
                Text(bat.statusText)
                    .font(Theme.captionFont)
                    .foregroundStyle(Theme.secondaryText)
            }
        }
    }

    private var chargeDetails: some View {
        VStack(alignment: .leading, spacing: 8) {
            detailRow("Status", bat.statusText)
            detailRow("Time Remaining", bat.timeRemainingText)
            detailRow("Power", String(format: "%.1f W", abs(bat.voltage * bat.amperage)))
            detailRow("Voltage", String(format: "%.2f V", bat.voltage))
        }
    }

    // MARK: - Details List

    private var detailsList: some View {
        VStack(spacing: 0) {
            detailListRow("Current Capacity", "\(bat.currentCapacity) mAh")
            Divider().foregroundStyle(Theme.cardBorder.opacity(0.5))
            detailListRow("Maximum Capacity", "\(bat.maxCapacity) mAh")
            Divider().foregroundStyle(Theme.cardBorder.opacity(0.5))
            detailListRow("Design Capacity", "\(bat.designCapacity) mAh")
            Divider().foregroundStyle(Theme.cardBorder.opacity(0.5))
            detailListRow("Cycle Count", "\(bat.cycleCount)")
            Divider().foregroundStyle(Theme.cardBorder.opacity(0.5))
            detailListRow("Health", Formatters.percentRaw(bat.healthPercent))
            Divider().foregroundStyle(Theme.cardBorder.opacity(0.5))
            detailListRow("Temperature", Formatters.temperature(bat.temperature))
        }
    }

    private func detailRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(Theme.captionFont)
                .foregroundStyle(Theme.secondaryText)
            Spacer()
            Text(value)
                .font(Theme.monoSmallFont)
                .foregroundStyle(Theme.primaryText)
        }
    }

    private func detailListRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(Theme.bodyFont)
                .foregroundStyle(Theme.primaryText)
            Spacer()
            Text(value)
                .font(Theme.monoFont)
                .foregroundStyle(Theme.primaryText)
        }
        .padding(.vertical, 6)
    }

    // MARK: - No Battery

    private var noBatteryView: some View {
        VStack(spacing: 12) {
            Image(systemName: "battery.slash")
                .font(.system(size: 40))
                .foregroundStyle(Theme.secondaryText)
            Text("No battery detected")
                .font(Theme.bodyFont)
                .foregroundStyle(Theme.secondaryText)
            Text("This Mac doesn't have a battery, or battery info is unavailable.")
                .font(Theme.captionFont)
                .foregroundStyle(Theme.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(40)
        .background(Theme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: Theme.cardCornerRadius))
        .overlay(RoundedRectangle(cornerRadius: Theme.cardCornerRadius).stroke(Theme.cardBorder, lineWidth: 1))
    }
}
