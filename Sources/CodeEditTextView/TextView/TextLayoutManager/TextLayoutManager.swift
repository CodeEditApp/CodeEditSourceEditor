//
//  TextLayoutManager.swift
//  
//
//  Created by Khan Winter on 6/21/23.
//

import Foundation
import AppKit

protocol TextLayoutManagerDelegate: AnyObject { }

class TextLayoutManager: NSObject {
    private unowned var textStorage: NSTextStorage
    private var lineStorage: TextLineStorage
    public var typingAttributes: [NSAttributedString.Key: Any] = [
        .font: NSFont.monospacedSystemFont(ofSize: 12, weight: .regular),
        .paragraphStyle: NSParagraphStyle.default.copy()
    ]

    // MARK: - Init

    /// Initialize a text layout manager and prepare it for use.
    /// - Parameters:
    ///   - textStorage: The text storage object to use as a data source.
    ///   - typingAttributes: The attributes to use while typing.
    init(textStorage: NSTextStorage, typingAttributes: [NSAttributedString.Key: Any]) {
        self.textStorage = textStorage
        self.lineStorage = TextLineStorage()
        self.typingAttributes = typingAttributes
        super.init()
        textStorage.addAttributes(typingAttributes, range: NSRange(location: 0, length: textStorage.length))
        prepareTextLines()
    }

    /// Prepares the layout manager for use.
    /// Parses the text storage object into lines and builds the `lineStorage` object from those lines.
    private func prepareTextLines() {
        guard lineStorage.count == 0 else { return }
        var info = mach_timebase_info()
        guard mach_timebase_info(&info) == KERN_SUCCESS else { return }
        let start = mach_absolute_time()

        func getNextLine(startingAt location: Int) -> NSRange? {
            let range = NSRange(location: location, length: 0)
            var end: Int = NSNotFound
            var contentsEnd: Int = NSNotFound
            (textStorage.string as NSString).getLineStart(nil, end: &end, contentsEnd: &contentsEnd, for: range)
            if end != NSNotFound && contentsEnd != NSNotFound && end != contentsEnd {
                return NSRange(location: contentsEnd, length: end - contentsEnd)
            } else {
                return nil
            }
        }

        let estimatedLineHeight = NSAttributedString(string: " ", attributes: typingAttributes).boundingRect(
            with: NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        ).height

        var index = 0
        var lines: [(TextLine, Int)] = []
        while let range = getNextLine(startingAt: index) {
            lines.append((
                TextLine(stringRef: textStorage, range: NSRange(location: index, length: NSMaxRange(range) - index)),
                NSMaxRange(range) - index
            ))
            index = NSMaxRange(range)
        }
        // Get the last line
        if textStorage.length - index > 0 {
            lines.append((
                TextLine(stringRef: textStorage, range: NSRange(location: index, length: textStorage.length - index)),
                index
            ))
        }

        lineStorage.build(from: lines, estimatedLineHeight: estimatedLineHeight)

        let end = mach_absolute_time()
        let elapsed = end - start
        let nanos = elapsed * UInt64(info.numer) / UInt64(info.denom)
        print("Layout Manager built in: ", TimeInterval(nanos) / TimeInterval(NSEC_PER_MSEC), "ms")
    }

    // MARK: - API

    func estimatedHeight() -> CGFloat {
        guard let position = lineStorage.getLine(atIndex: lineStorage.length - 1) else {
            return 0.0
        }
        return position.node.height + position.height
    }
    func estimatedWidth() -> CGFloat { 0 }

    func textLineForPosition(_ posY: CGFloat) -> TextLine? {
        lineStorage.getLine(atPosition: posY)?.node.line
    }

    // MARK: - Rendering

    func draw(inRect rect: CGRect, context: CGContext) {
        // Get all lines in rect & draw!
        var currentPosition = lineStorage.getLine(atPosition: rect.minY)
        while let position = currentPosition, position.height < rect.maxY {
            let lineHeight = drawLine(
                line: position.node.line,
                offsetHeight: position.height,
                minY: rect.minY,
                maxY: rect.maxY,
                context: context
            )
            if lineHeight != position.node.height {
                lineStorage.update(atIndex: position.offset, delta: 0, deltaHeight: lineHeight - position.node.height)
            }
            currentPosition = lineStorage.getLine(atIndex: position.offset + position.node.length)
        }
    }

    /// Draws a `TextLine` into the current graphics context up to a maximum y position.
    /// - Parameters:
    ///   - line: The line to draw.
    ///   - offsetHeight: The initial offset of the line.
    ///   - minY: The minimum Y position to begin drawing from.
    ///   - maxY: The maximum Y position to draw to.
    private func drawLine(
        line: TextLine,
        offsetHeight: CGFloat,
        minY: CGFloat,
        maxY: CGFloat,
        context: CGContext
    ) -> CGFloat {
        if line.typesetter.lineFragments.isEmpty {
            line.prepareForDisplay(maxWidth: .greatestFiniteMagnitude)
        }
        var height = offsetHeight
        for lineFragment in line.typesetter.lineFragments {
            if height + lineFragment.height >= minY {
                // The fragment is within the valid region
                context.saveGState()
                context.textMatrix = .init(scaleX: 1, y: -1)
                context.translateBy(x: 0, y: lineFragment.height)
                context.textPosition = CGPoint(x: 0, y: height)
                CTLineDraw(lineFragment.ctLine, context)
                context.restoreGState()
            }
            height += lineFragment.height
        }
        return height - offsetHeight
    }
}

extension TextLayoutManager: NSTextStorageDelegate {
    func textStorage(
        _ textStorage: NSTextStorage,
        didProcessEditing editedMask: NSTextStorageEditActions,
        range editedRange: NSRange,
        changeInLength delta: Int
    ) {
        
    }
}
