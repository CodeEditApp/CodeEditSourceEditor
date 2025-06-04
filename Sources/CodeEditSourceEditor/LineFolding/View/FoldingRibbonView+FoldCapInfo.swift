//
//  FoldCapInfo.swift
//  CodeEditSourceEditor
//
//  Created by Khan Winter on 6/3/25.
//

import AppKit

extension FoldingRibbonView {
    /// A helper type that determines if a fold should be drawn with a cap on the top or bottom if
    /// there's an adjacent fold on the same text line. It also provides a helper method
    struct FoldCapInfo {
        let startIndices: Set<Int>
        let endIndices: Set<Int>

        init(_ folds: [DrawingFoldInfo]) {
            self.startIndices = folds.reduce(into: Set<Int>(), { $0.insert($1.startLine.index) })
            self.endIndices = folds.reduce(into: Set<Int>(), { $0.insert($1.endLine.index) })
        }

        func foldNeedsTopCap(_ fold: DrawingFoldInfo) -> Bool {
            endIndices.contains(fold.startLine.index)
        }

        func foldNeedsBottomCap(_ fold: DrawingFoldInfo) -> Bool {
            startIndices.contains(fold.endLine.index)
        }

        func adjustFoldRect(
            using fold: DrawingFoldInfo,
            rect: NSRect
        ) -> NSRect {
            let capTop = foldNeedsTopCap(fold)
            let capBottom = foldNeedsBottomCap(fold)
            let yDelta = capTop ? fold.startLine.height / 2.0 : 0.0

            var heightDelta: CGFloat = 0.0
            if capTop {
                heightDelta -= fold.startLine.height / 2.0
            }
            if capBottom {
                heightDelta -= fold.endLine.height / 2.0
            }

            return NSRect(
                x: rect.origin.x,
                y: rect.origin.y + yDelta,
                width: rect.size.width,
                height: rect.size.height + heightDelta
            )
        }
    }
}
