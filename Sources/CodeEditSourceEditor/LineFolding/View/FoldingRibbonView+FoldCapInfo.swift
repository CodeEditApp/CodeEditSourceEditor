//
//  FoldCapInfo.swift
//  CodeEditSourceEditor
//
//  Created by Khan Winter on 6/3/25.
//

import AppKit

extension FoldingRibbonView {
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
            let heightDelta: CGFloat = if capTop && capBottom {
                -fold.startLine.height
            } else if capTop || capBottom {
                -(fold.startLine.height / 2.0)
            } else {
                0.0
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
