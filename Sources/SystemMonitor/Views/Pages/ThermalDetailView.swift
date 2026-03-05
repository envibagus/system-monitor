import SwiftUI
import Charts

/// Fans & Thermal detail page — fan gauges, temperature readouts, history chart
struct ThermalDetailView: View {
    @Environment(MonitorManager.self) private var monitor
    @Binding var selectedPage: NavigationPage

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                pageHeader(title: "Fans & Thermal", sfSymbol: "thermometer.medium") { selectedPage = .dashboard }

                /* Stat Cards */
                HStack(spacing: 12) {
                    StatCardView(
                        title: "CPU Temp",
                        value: monitor.smcService.cpuTemperature.map { Formatters.temperature($0) } ?? "—",
                        subtitle: "CPU Package",
                        indicatorColor: Theme.temperatureColor(celsius: monitor.smcService.cpuTemperature ?? 0)
                    )
                    StatCardView(
                        title: "GPU Temp",
                        value: monitor.smcService.gpuTemperature.map { Formatters.temperature($0) } ?? "—",
                        subtitle: "GPU",
                        indicatorColor: Theme.temperatureColor(celsius: monitor.smcService.gpuTemperature ?? 0)
                    )
                    if let fan = monitor.smcService.fans.first {
                        StatCardView(
                            title: "Fan Speed",
                            value: Formatters.rpm(fan.currentRPM),
                            subtitle: "of \(Formatters.rpm(fan.maxRPM)) max",
                            indicatorColor: Theme.fanSpeedColor(percentOfMax: fan.percentOfMax)
                        )
                    }
                    StatCardView(
                        title: "Sensors",
                        value: "\(monitor.smcService.temperatures.count)",
                        subtitle: "Active sensors",
                        indicatorColor: Theme.accentTeal
                    )
                }

                /* Fan Gauges */
                if !monitor.smcService.fans.isEmpty {
                    WidgetCardView(title: "Fan Monitoring", sfSymbol: "fan", symbolColor: Theme.accentBlue) {
                        fanGauges
                    }
                }

                /* Temperature History */
                WidgetCardView(title: "Temperature History", sfSymbol: "chart.xyaxis.line", symbolColor: Theme.accentOrange, badge: "60s") {
                    temperatureChart
                }

                /* All Temperature Sensors */
                WidgetCardView(title: "Temperature Sensors", sfSymbol: "thermometer.medium", symbolColor: Theme.accentOrange) {
                    sensorList
                }
            }
            .padding(24)
        }
    }

    // MARK: - Fan Gauges

    private var fanGauges: some View {
        HStack(spacing: 30) {
            ForEach(monitor.smcService.fans) { fan in
                HalfGaugeView(
                    value: fan.currentRPM,
                    maxValue: fan.maxRPM,
                    label: fan.label,
                    valueText: Formatters.rpm(fan.currentRPM),
                    color: Theme.fanSpeedColor(percentOfMax: fan.percentOfMax),
                    size: 120
                )
            }
            Spacer()
        }
        .padding(.vertical, 8)
    }

    // MARK: - Temperature History Chart

    private var temperatureChart: some View {
        VStack(alignment: .leading, spacing: 8) {
            if monitor.cpuTempHistory.data.count >= 2 {
                Chart {
                    ForEach(monitor.cpuTempHistory.data) { point in
                        LineMark(
                            x: .value("Time", point.timestamp),
                            y: .value("Temp", point.value)
                        )
                        .foregroundStyle(Theme.accentOrange)
                        .interpolationMethod(.catmullRom)
                        .lineStyle(StrokeStyle(lineWidth: 2))
                    }

                    ForEach(monitor.gpuTempHistory.data) { point in
                        LineMark(
                            x: .value("Time", point.timestamp),
                            y: .value("Temp", point.value)
                        )
                        .foregroundStyle(Theme.accentPurple)
                        .interpolationMethod(.catmullRom)
                        .lineStyle(StrokeStyle(lineWidth: 2))
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisValueLabel {
                            if let temp = value.as(Double.self) {
                                Text("\(Int(temp))°")
                                    .font(Theme.monoSmallFont)
                                    .foregroundStyle(Theme.secondaryText)
                            }
                        }
                        AxisGridLine().foregroundStyle(Theme.cardBorder)
                    }
                }
                .chartXAxis(.hidden)
                .frame(height: 120)

                /* Legend */
                HStack(spacing: 16) {
                    legendItem("CPU", Theme.accentOrange)
                    legendItem("GPU", Theme.accentPurple)
                }
            } else {
                Text("Collecting temperature data...")
                    .font(Theme.captionFont)
                    .foregroundStyle(Theme.secondaryText)
                    .frame(height: 120)
            }
        }
    }

    private func legendItem(_ label: String, _ color: Color) -> some View {
        HStack(spacing: 5) {
            RoundedRectangle(cornerRadius: 2).fill(color).frame(width: 12, height: 3)
            Text(label).font(Theme.captionFont).foregroundStyle(Theme.secondaryText)
        }
    }

    // MARK: - Sensor List

    private var sensorList: some View {
        VStack(spacing: 0) {
            if monitor.smcService.temperatures.isEmpty {
                Text(monitor.smcService.isConnected ? "No temperature sensors detected" : "SMC not connected")
                    .font(Theme.captionFont)
                    .foregroundStyle(Theme.secondaryText)
                    .padding(.vertical, 12)
            } else {
                ForEach(monitor.smcService.temperatures) { reading in
                    HStack {
                        Text(reading.sensorName)
                            .font(Theme.bodyFont)
                            .foregroundStyle(Theme.primaryText)
                            .lineLimit(1)

                        Text(reading.smcKey)
                            .font(Theme.monoSmallFont)
                            .foregroundStyle(Theme.secondaryText)

                        Spacer()

                        Text(Formatters.temperature(reading.temperature))
                            .font(Theme.monoFont)
                            .foregroundStyle(Theme.temperatureColor(celsius: reading.temperature))
                    }
                    .padding(.vertical, 5)

                    if reading.id != monitor.smcService.temperatures.last?.id {
                        Divider().foregroundStyle(Theme.cardBorder.opacity(0.5))
                    }
                }
            }
        }
    }
}
