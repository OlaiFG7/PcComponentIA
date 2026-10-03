//
//  FlowLayout.swift
//  PcComponentIA
//
//  Created by Olai Fernandez Garcia on 16/07/2026.
//


import SwiftUI

struct FlowLayout: Layout {

    var spacing: CGFloat = 8

    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        let layout = crearLayout(
            subviews: subviews,
            maxWidth: maxWidth
        )

        return CGSize(
            width: layout.width,
            height: layout.height
        )
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) {
        let layout = crearLayout(
            subviews: subviews,
            maxWidth: bounds.width
        )

        for item in layout.items {
            item.subview.place(
                at: CGPoint(
                    x: bounds.minX + item.position.x,
                    y: bounds.minY + item.position.y
                ),
                proposal: ProposedViewSize(item.size)
            )
        }
    }

    private func crearLayout(
        subviews: Subviews,
        maxWidth: CGFloat
    ) -> LayoutResult {
        var items: [LayoutItem] = []

        var x: CGFloat = 0
        var y: CGFloat = 0
        var lineHeight: CGFloat = 0
        var usedWidth: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)

            if x > 0 && x + size.width > maxWidth {
                x = 0
                y += lineHeight + spacing
                lineHeight = 0
            }

            items.append(
                LayoutItem(
                    subview: subview,
                    size: size,
                    position: CGPoint(x: x, y: y)
                )
            )

            x += size.width + spacing
            usedWidth = max(usedWidth, x - spacing)
            lineHeight = max(lineHeight, size.height)
        }

        return LayoutResult(
            items: items,
            width: usedWidth,
            height: y + lineHeight
        )
    }

    private struct LayoutItem {
        let subview: LayoutSubview
        let size: CGSize
        let position: CGPoint
    }

    private struct LayoutResult {
        let items: [LayoutItem]
        let width: CGFloat
        let height: CGFloat
    }
}
