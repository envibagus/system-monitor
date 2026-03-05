import SwiftUI
import Charts

/// Sparkline chart with optional area fill (Readout style)
struct SparklineView: View {
    let data: [DataPoint]
    let color: Color
    var showArea: Bool = true
    var height: CGFloat = 60

    var body: some View {
        if data.count < 2 {
            /* Placeholder when no data yet */
            RoundedRectangle(cornerRadius: 4)
                .fill(Theme.cardBorder.opacity(0.3))
                .frame(height: height)
                .overlay {
                    Text("Collecting data...")
                        .font(Theme.captionFont)
                        .foregroundStyle(Theme.secondaryText)
                }
        } else {
            Chart(data) { point in
                LineMark(
                    x: .value("Time", point.timestamp),
                    y: .value("Value", point.value)
                )
                .foregroundStyle(color)
                .interpolationMethod(.catmullRom)
                .lineStyle(StrokeStyle(lineWidth: 2))

                if showArea {
                    AreaMark(
                        x: .value("Time", point.timestamp),
                        y: .value("Value", point.value)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [color.opacity(0.2), color.opacity(0.02)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)
                }
            }
            .chartXAxis(.hidden)
            .chartYAxis(.hidden)
            .chartYScale(domain: 0...1.0)
            .frame(height: height)
            .animation(Theme.sparklineAnimation, value: data.count)
        }
    }
}
