import SwiftUI

enum AlertLevel {
    case warning
    case critical
    case info

    var color: Color {
        switch self {
        case .warning: return Theme.accentOrange
        case .critical: return Theme.accentPink
        case .info: return Theme.accentBlue
        }
    }

    var sfSymbol: String {
        switch self {
        case .warning: return "exclamationmark.triangle.fill"
        case .critical: return "exclamationmark.circle.fill"
        case .info: return "info.circle.fill"
        }
    }
}

/// Full-width alert banner with tinted background (Readout style)
struct AlertBannerView: View {
    let message: String
    let level: AlertLevel
    var action: (() -> Void)? = nil

    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: level.sfSymbol)
                .font(.system(size: 13))
                .foregroundStyle(level.color)

            Text(message)
                .font(Theme.bodyFont)
                .foregroundStyle(Theme.primaryText)

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(Theme.secondaryText)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(level.color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(level.color.opacity(0.2), lineWidth: 1)
        )
        .onHover { hovering in
            withAnimation(Theme.hoverAnimation) { isHovered = hovering }
        }
        .onTapGesture { action?() }
    }
}
