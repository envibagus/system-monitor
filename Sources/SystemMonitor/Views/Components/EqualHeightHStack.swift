import SwiftUI

/// HStack that forces all children to the same height (tallest child wins)
struct EqualHeightHStack: Layout {
    var spacing: CGFloat = 12

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        guard !subviews.isEmpty else { return .zero }

        let width = proposal.width ?? 0
        let count = CGFloat(subviews.count)
        let totalSpacing = spacing * (count - 1)
        let childWidth = (width - totalSpacing) / count

        let childProposal = ProposedViewSize(width: childWidth, height: proposal.height)

        // Find the tallest child
        let maxHeight = subviews.map { $0.sizeThatFits(childProposal).height }.max() ?? 0

        return CGSize(width: width, height: maxHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        guard !subviews.isEmpty else { return }

        let count = CGFloat(subviews.count)
        let totalSpacing = spacing * (count - 1)
        let childWidth = (bounds.width - totalSpacing) / count

        // All children get the full row height
        let childProposal = ProposedViewSize(width: childWidth, height: bounds.height)

        var x = bounds.minX
        for subview in subviews {
            subview.place(
                at: CGPoint(x: x, y: bounds.minY),
                proposal: childProposal
            )
            x += childWidth + spacing
        }
    }
}
