//
//  TextLayoutManager.swift
//  
//
//  Created by Khan Winter on 6/21/23.
//

import Foundation
import AppKit

protocol TextLayoutManagerDelegate: AnyObject {
    func maxWidthDidChange(newWidth: CGFloat)
    func textViewportSize() -> CGSize
    func textLayoutSetNeedsDisplay()
}

class TextLayoutManager: NSObject {
    // MARK: - Public Config

    public weak var delegate: TextLayoutManagerDelegate?
    public var typingAttributes: [NSAttributedString.Key: Any]
    public var lineHeightMultiplier: CGFloat
    public var wrapLines: Bool

    // MARK: - Internal

    private unowned var textStorage: NSTextStorage
    private var lineStorage: TextLineStorage

    private var maxLineWidth: CGFloat = 0 {
        didSet {
            delegate?.maxWidthDidChange(newWidth: maxLineWidth)
        }
    }

    // MARK: - Init

    /// Initialize a text layout manager and prepare it for use.
    /// - Parameters:
    ///   - textStorage: The text storage object to use as a data source.
    ///   - typingAttributes: The attributes to use while typing.
    init(
        textStorage: NSTextStorage,
        typingAttributes: [NSAttributedString.Key: Any],
        lineHeightMultiplier: CGFloat,
        wrapLines: Bool
    ) {
        self.textStorage = textStorage
        self.lineStorage = TextLineStorage()
        self.typingAttributes = typingAttributes
        self.lineHeightMultiplier = lineHeightMultiplier
        self.wrapLines = wrapLines
        super.init()
        textStorage.addAttributes(typingAttributes, range: NSRange(location: 0, length: textStorage.length))
        prepareTextLines()
    }

    /// Prepares the layout manager for use.
    /// Parses the text storage object into lines and builds the `lineStorage` object from those lines.
    private func prepareTextLines() {
        guard lineStorage.count == 0 else { return }
#if DEBUG
        var info = mach_timebase_info()
        guard mach_timebase_info(&info) == KERN_SUCCESS else { return }
        let start = mach_absolute_time()
#endif

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

        var index = 0
        var lines: [(TextLine, Int)] = []
        while let range = getNextLine(startingAt: index) {
            lines.append((
                TextLine(stringRef: textStorage, range: NSRange(location: index, length: NSMaxRange(range) - index)),
                NSMaxRange(range) - index
            ))
            index = NSMaxRange(range)
        }
        // Create the last line
        if textStorage.length - index > 0 {
            lines.append((
                TextLine(stringRef: textStorage, range: NSRange(location: index, length: textStorage.length - index)),
                index
            ))
        }

        // Use a more efficient tree building algorithm than adding lines as calculated in the above loop.
        lineStorage.build(from: lines, estimatedLineHeight: estimateLineHeight())

#if DEBUG
        let end = mach_absolute_time()
        let elapsed = end - start
        let nanos = elapsed * UInt64(info.numer) / UInt64(info.denom)
        print("Layout Manager built in: ", TimeInterval(nanos) / TimeInterval(NSEC_PER_MSEC), "ms")
#endif
    }

    private func estimateLineHeight() -> CGFloat {
        let string = NSAttributedString(string: "0", attributes: typingAttributes)
        let typesetter = CTTypesetterCreateWithAttributedString(string)
        let ctLine = CTTypesetterCreateLine(typesetter, CFRangeMake(0, 1))
        var ascent: CGFloat = 0
        var descent: CGFloat = 0
        var leading: CGFloat = 0
        CTLineGetTypographicBounds(ctLine, &ascent, &descent, &leading)
        return (ascent + descent + leading) * lineHeightMultiplier
    }

    // MARK: - Public Convenience Methods

    public func estimatedHeight() -> CGFloat {
        guard let position = lineStorage.getLine(atIndex: lineStorage.length - 1) else {
            return 0.0
        }
        return position.node.height + position.height
    }

    public func estimatedWidth() -> CGFloat {
        maxLineWidth
    }

    public func textLineForPosition(_ posY: CGFloat) -> TextLine? {
        lineStorage.getLine(atPosition: posY)?.node.line
    }

    public func enumerateLines(startingAt posY: CGFloat, completion: ((TextLine, Int, CGFloat) -> Bool)) {
        for position in lineStorage.linesStartingAt(posY, until: .greatestFiniteMagnitude) {
            guard completion(position.node.line, position.offset, position.height) else {
                break
            }
        }
    }

    // MARK: - Rendering

    public func invalidateLayoutForRect(_ rect: NSRect) {
        // Get all lines in rect and discard their line fragment data
        for position in lineStorage.linesStartingAt(rect.minY, until: rect.maxY) {
            position.node.line.typesetter.lineFragments.removeAll(keepingCapacity: true)
        }
    }

    public func invalidateLayoutForRange(_ range: NSRange) {
        for position in lineStorage.linesInRange(range) {
            position.node.line.typesetter.lineFragments.removeAll(keepingCapacity: true)
        }
    }

    internal func draw(inRect rect: CGRect, context: CGContext) {
        // Get all lines in rect & draw!
        for position in lineStorage.linesStartingAt(rect.minY, until: rect.maxY) {
            let lineSize = drawLine(
                line: position.node.line,
                offsetHeight: position.height,
                minY: rect.minY,
                maxY: rect.maxY,
                context: context
            )
            if lineSize.height != position.node.height {
                lineStorage.update(
                    atIndex: position.offset,
                    delta: 0,
                    deltaHeight: lineSize.height - position.node.height
                )
            }
            if maxLineWidth < lineSize.width {
                maxLineWidth = lineSize.width
            }
        }
    }

    /// Draws a `TextLine` into the current graphics context up to a maximum y position.
    /// - Parameters:
    ///   - line: The line to draw.
    ///   - offsetHeight: The initial offset of the line.
    ///   - minY: The minimum Y position to begin drawing from.
    ///   - maxY: The maximum Y position to draw to.
    /// - Returns: The size of the rendered line.
    private func drawLine(
        line: TextLine,
        offsetHeight: CGFloat,
        minY: CGFloat,
        maxY: CGFloat,
        context: CGContext
    ) -> CGSize {
        if line.typesetter.lineFragments.isEmpty {
            line.prepareForDisplay(
                maxWidth: wrapLines
                ? delegate?.textViewportSize().width ?? .greatestFiniteMagnitude
                : .greatestFiniteMagnitude
            )
        }
        var height = offsetHeight
        var maxWidth: CGFloat = 0
        for lineFragment in line.typesetter.lineFragments {
            if height + (lineFragment.height * lineHeightMultiplier) >= minY {
                // The fragment is within the valid region
                context.saveGState()
                context.textMatrix = .init(scaleX: 1, y: -1)
                context.translateBy(x: 0, y: lineFragment.height)
                context.textPosition = CGPoint(x: 0, y: height)
                CTLineDraw(lineFragment.ctLine, context)
                context.restoreGState()
            }
            maxWidth = max(lineFragment.width, maxWidth)
            height += lineFragment.height * lineHeightMultiplier
        }
        return CGSize(width: maxWidth, height: height - offsetHeight)
    }
}

extension TextLayoutManager: NSTextStorageDelegate {
    func textStorage(
        _ textStorage: NSTextStorage,
        didProcessEditing editedMask: NSTextStorageEditActions,
        range editedRange: NSRange,
        changeInLength delta: Int
    ) {
        invalidateLayoutForRange(editedRange)
        delegate?.textLayoutSetNeedsDisplay()
    }
}
