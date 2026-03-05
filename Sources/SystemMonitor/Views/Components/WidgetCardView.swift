import SwiftUI

/// Wrapper card for dashboard widgets (Readout style) — icon, title, optional badge, chevron
struct WidgetCardView<Content: View>: View {
    let title: String
    let sfSymbol: String
    let symbolColor: Color
    var badge: String? = nil
    var destination: NavigationPage? = nil
    @ViewBuilder var content: () -> Content

    @State private var isHovered = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            /* Card Header */
            HStack(spacing: 8) {
                Image(systemName: sfSymbol)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(symbolColor)

                Text(title)
                    .font(Theme.cardHeaderFont)
                    .foregroundStyle(Theme.primaryText)

                if let badge {
                    Text(badge)
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(Theme.secondaryText)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Theme.cardBorder)
                        .clipShape(Capsule())
                }

                Spacer()

                if destination != nil {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(Theme.secondaryText)
                }
            }

            /* Card Content — fills remaining space */
            content()
                .frame(maxHeight: .infinity, alignment: .topLeading)
        }
        .padding(Theme.cardPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
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
