import SwiftUI

/// Top stat card — large value with colored dot indicator and subtitle (Readout style)
struct StatCardView: View {
    let title: String
    let value: String
    let subtitle: String
    let indicatorColor: Color
    var sfSymbol: String? = nil

    @State private var isHovered = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            /* Value */
            Text(value)
                .font(.system(size: 28, weight: .semibold, design: .monospaced))
                .foregroundStyle(Theme.primaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.6)

            /* Indicator dot + subtitle */
            HStack(spacing: 6) {
                Circle()
                    .fill(indicatorColor)
                    .frame(width: 7, height: 7)

                Text(subtitle)
                    .font(Theme.captionFont)
                    .foregroundStyle(Theme.secondaryText)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Theme.cardPadding)
        .background(Theme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: Theme.cardCornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cardCornerRadius)
                .stroke(isHovered ? Theme.cardBorderHover : Theme.cardBorder, lineWidth: 1)
        )
        .onHover { hovering in
            withAnimation(Theme.hoverAnimation) {
                isHovered = hovering
            }
        }
    }
}
