import SwiftUI

/// Single process row with name, memory bar, and value
struct ProcessRowView: View {
    let name: String
    let memory: UInt64
    let maxMemory: UInt64
    let isElectron: Bool

    private var fraction: Double {
        guard maxMemory > 0 else { return 0 }
        return Double(memory) / Double(maxMemory)
    }

    var body: some View {
        HStack(spacing: 10) {
            /* Process name */
            Text(name)
                .font(Theme.bodyFont)
                .foregroundStyle(Theme.primaryText)
                .lineLimit(1)
                .frame(maxWidth: 140, alignment: .leading)

            /* Electron badge */
            if isElectron {
                Text("Electron")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(Theme.accentPurple)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Theme.accentPurple.opacity(0.15))
                    .clipShape(Capsule())
            }

            /* Progress bar */
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Theme.cardBorder)
                        .frame(height: 6)

                    RoundedRectangle(cornerRadius: 3)
                        .fill(Theme.accentBlue)
                        .frame(width: max(fraction * geo.size.width, 2), height: 6)
                }
                .frame(height: geo.size.height)
            }
            .frame(height: 6)

            /* Memory value */
            Text(Formatters.bytes(memory))
                .font(Theme.monoSmallFont)
                .foregroundStyle(Theme.secondaryText)
                .frame(width: 65, alignment: .trailing)
        }
    }
}
