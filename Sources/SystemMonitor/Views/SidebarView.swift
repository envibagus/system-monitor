import SwiftUI

/// Grouped sidebar navigation (Readout style) — uppercase section labels, SF Symbols, active highlight
struct SidebarView: View {
    @Binding var selectedPage: NavigationPage

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(NavigationSection.allCases, id: \.self) { section in
                /* Section label */
                Text(section.rawValue)
                    .font(Theme.sidebarSectionFont)
                    .foregroundStyle(Theme.secondaryText)
                    .padding(.horizontal, 16)
                    .padding(.top, section == .overview ? 8 : 20)
                    .padding(.bottom, 6)

                /* Section items */
                ForEach(NavigationPage.pages(for: section)) { page in
                    SidebarItemView(
                        page: page,
                        isSelected: selectedPage == page
                    ) {
                        selectedPage = page
                    }
                }
            }

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}

/// Single sidebar item row
private struct SidebarItemView: View {
    let page: NavigationPage
    let isSelected: Bool
    let onTap: () -> Void

    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: page.sfSymbol)
                .font(.system(size: 14))
                .foregroundStyle(isSelected ? Theme.sidebarSelectedText : Theme.secondaryText)
                .frame(width: 20)

            Text(page.title)
                .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                .foregroundStyle(isSelected ? Theme.sidebarSelectedText : Theme.primaryText)

            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background {
            if isSelected {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Theme.accentBlue.opacity(0.25))
            } else if isHovered {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Theme.sidebarHover.opacity(0.05))
            }
        }
        .padding(.horizontal, 8)
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
        .onHover { hovering in
            withAnimation(Theme.hoverAnimation) {
                isHovered = hovering
            }
        }
    }
}
