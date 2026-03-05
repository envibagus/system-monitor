import SwiftUI

/// Half-circle gauge with animated arc and center value
struct HalfGaugeView: View {
    let value: Double
    let maxValue: Double
    let label: String
    let valueText: String
    let color: Color
    var size: CGFloat = 100

    private var normalizedValue: Double {
        guard maxValue > 0 else { return 0 }
        return min(value / maxValue, 1.0)
    }

    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                /* Background arc */
                HalfArc()
                    .stroke(Theme.cardBorder, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: size, height: size / 2)

                /* Value arc */
                HalfArc()
                    .trim(from: 0, to: normalizedValue)
                    .stroke(color, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: size, height: size / 2)
                    .animation(Theme.gaugeAnimation, value: normalizedValue)

                /* Center value */
                Text(valueText)
                    .font(.system(size: size * 0.18, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Theme.primaryText)
                    .offset(y: size * 0.05)
            }
            .frame(height: size / 2 + 8)

            /* Label */
            Text(label)
                .font(Theme.captionFont)
                .foregroundStyle(Theme.secondaryText)
        }
    }
}

/// Half-circle arc shape (180 degrees, bottom half)
private struct HalfArc: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addArc(
            center: CGPoint(x: rect.midX, y: rect.maxY),
            radius: rect.width / 2,
            startAngle: .degrees(180),
            endAngle: .degrees(0),
            clockwise: false
        )
        return path
    }
}
