//
//  MinimapLineRenderer.swift
//  CodeEditSourceEditor
//
//  Created by Khan Winter on 4/10/25.
//

import AppKit
import CodeEditTextView

final class MinimapLineRenderer: TextLayoutManagerRenderDelegate {
    weak var textView: TextView?

    init(textView: TextView) {
        self.textView = textView
    }

    func prepareForDisplay( // swiftlint:disable:this function_parameter_count
        textLine: TextLine,
        displayData: TextLine.DisplayData,
        range: NSRange,
        stringRef: NSTextStorage,
        markedRanges: MarkedRanges?,
        breakStrategy: LineBreakStrategy
    ) {
        let maxWidth: CGFloat = if let textView, textView.wrapLines {
            textView.layoutManager.maxLineLayoutWidth
        } else {
            .infinity
        }

        textLine.prepareForDisplay(
            displayData: TextLine.DisplayData(maxWidth: maxWidth, lineHeightMultiplier: 1.0, estimatedLineHeight: 3.0),
            range: range,
            stringRef: stringRef,
            markedRanges: markedRanges,
            breakStrategy: breakStrategy
        )

        // Make all fragments 2px tall
        textLine.lineFragments.forEach { fragmentPosition in
            let remainingHeight = fragmentPosition.height - 3.0
            if remainingHeight != 0 {
                textLine.lineFragments.update(
                    atOffset: fragmentPosition.range.location,
                    delta: 0,
                    deltaHeight: -remainingHeight
                )
            }
            fragmentPosition.data.height = 2.0
            fragmentPosition.data.scaledHeight = 3.0
        }
    }

    func estimatedLineHeight() -> CGFloat? {
        3.0
    }

    func lineFragmentView(for lineFragment: LineFragment) -> LineFragmentView {
        MinimapLineFragmentView(textStorage: textView?.textStorage)
    }

    func characterXPosition(in lineFragment: LineFragment, for offset: Int) -> CGFloat {
        8 + (CGFloat(offset) * 1.5)
    }
}
