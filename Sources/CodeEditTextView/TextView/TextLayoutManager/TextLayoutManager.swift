//
//  TextLayoutManager.swift
//  
//
//  Created by Khan Winter on 6/21/23.
//

import Foundation
import AppKit

protocol TextLayoutManagerDelegate: AnyObject {
    func layoutManagerHeightDidUpdate(newHeight: CGFloat)
    func layoutManagerMaxWidthDidChange(newWidth: CGFloat)
    func textViewSize() -> CGSize
    func textLayoutSetNeedsDisplay()

    var visibleRect: NSRect { get }
}

final class TextLayoutManager: NSObject {
    // MARK: - Public Config

    public weak var delegate: TextLayoutManagerDelegate?
    public var typingAttributes: [NSAttributedString.Key: Any]
    public var lineHeightMultiplier: CGFloat
    public var wrapLines: Bool
    public var detectedLineEnding: LineEnding = .lf

    // MARK: - Internal

    private unowned var textStorage: NSTextStorage
    private var lineStorage: TextLineStorage<TextLine> = TextLineStorage()
    private let viewReuseQueue: ViewReuseQueue<LineFragmentView, UUID> = ViewReuseQueue()

    weak private var layoutView: NSView?

    private var maxLineWidth: CGFloat = 0 {
        didSet {
            delegate?.layoutManagerMaxWidthDidChange(newWidth: maxLineWidth)
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
        wrapLines: Bool,
        textView: NSView,
        delegate: TextLayoutManagerDelegate?
    ) {
        self.textStorage = textStorage
        self.typingAttributes = typingAttributes
        self.lineHeightMultiplier = lineHeightMultiplier
        self.wrapLines = wrapLines
        self.layoutView = textView
        self.delegate = delegate
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
                TextLine(stringRef: textStorage),
                range.max - index
            ))
            index = NSMaxRange(range)
        }
        // Create the last line
        if textStorage.length - index > 0 {
            lines.append((
                TextLine(stringRef: textStorage),
                textStorage.length - index
            ))
        }

        // Use an efficient tree building algorithm rather than adding lines sequentially
        lineStorage.build(from: lines, estimatedLineHeight: estimateLineHeight())
        detectedLineEnding = LineEnding.detectLineEnding(lineStorage: lineStorage)

#if DEBUG
        let end = mach_absolute_time()
        let elapsed = end - start
        let nanos = elapsed * UInt64(info.numer) / UInt64(info.denom)
        print("Text Layout Manager built in: ", TimeInterval(nanos) / TimeInterval(NSEC_PER_MSEC), "ms")
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

    // MARK: - Public Methods

    public func estimatedHeight() -> CGFloat {
        lineStorage.height
    }

    public func estimatedWidth() -> CGFloat {
        maxLineWidth
    }

    public func textLineForPosition(_ posY: CGFloat) -> TextLineStorage<TextLine>.TextLinePosition? {
        lineStorage.getLine(atPosition: posY)
    }

    public func textOffsetAtPoint(_ point: CGPoint) -> Int? {
        guard let position = lineStorage.getLine(atPosition: point.y),
              let fragmentPosition = position.data.typesetter.lineFragments.getLine(
                atPosition: point.y - position.yPos
              ) else {
            return nil
        }
        let fragment = fragmentPosition.data

        if fragment.width < point.x {
            let fragmentRange = CTLineGetStringRange(fragment.ctLine)
            // Return eol
            return position.range.location + fragmentRange.location + fragmentRange.length - (
                // Before the eol character (insertion point is before the eol)
                fragmentPosition.range.max == position.range.max ?
                1 : detectedLineEnding.length
            )
        } else {
            // Somewhere in the fragment
            let fragmentIndex = CTLineGetStringIndexForPosition(
                fragment.ctLine,
                CGPoint(x: point.x, y: fragment.height/2)
            )
            return position.range.location + fragmentIndex
        }
    }

    /// Find a position for the character at a given offset.
    /// Returns the bottom-left corner of the character.
    /// - Parameter offset: The offset to create the rect for.
    /// - Returns: The found rect for the given offset.
    public func positionForOffset(_ offset: Int) -> CGPoint? {
        guard let linePosition = lineStorage.getLine(atIndex: offset),
              let fragmentPosition = linePosition.data.typesetter.lineFragments.getLine(
                atIndex: offset - linePosition.range.location
              ) else {
            return nil
        }

        let xPos = CTLineGetOffsetForStringIndex(
            fragmentPosition.data.ctLine,
            offset - linePosition.range.location,
            nil
        )

        return CGPoint(
            x: xPos,
            y: linePosition.yPos + fragmentPosition.yPos
            + (fragmentPosition.data.height - fragmentPosition.data.scaledHeight)/2
        )
    }

    // MARK: - Invalidation

    /// Invalidates layout for the given rect.
    /// - Parameter rect: The rect to invalidate.
    public func invalidateLayoutForRect(_ rect: NSRect) {
        guard let visibleRect = delegate?.visibleRect else { return }
        // The new view IDs
        var usedFragmentIDs = Set<UUID>()
        // The IDs that were replaced and need removing.
        var existingFragmentIDs = Set<UUID>()
        let minY = max(max(rect.minY, 0), visibleRect.minY)
        let maxY = min(rect.maxY, visibleRect.maxY)

        for linePosition in lineStorage.linesStartingAt(minY, until: maxY) {
            existingFragmentIDs.formUnion(Set(linePosition.data.typesetter.lineFragments.map(\.data.id)))

            let lineSize = layoutLine(
                linePosition,
                minY: linePosition.yPos,
                maxY: maxY,
                laidOutFragmentIDs: &usedFragmentIDs
            )
            if lineSize.height != linePosition.height {
                // If there's a height change, we need to lay out everything again and enqueue any views already used.
                viewReuseQueue.enqueueViews(in: usedFragmentIDs.union(existingFragmentIDs))
                layoutLines()
                return
            }
            if maxLineWidth < lineSize.width {
                maxLineWidth = lineSize.width
            }
        }

        viewReuseQueue.enqueueViews(in: existingFragmentIDs)
    }

    /// Invalidates layout for the given range of text.
    /// - Parameter range: The range of text to invalidate.
    public func invalidateLayoutForRange(_ range: NSRange) {
        // Determine the min/max Y value for this range and invalidate it
        guard let minPosition = lineStorage.getLine(atIndex: range.location),
              let maxPosition = lineStorage.getLine(atIndex: range.max) else {
            return
        }
        invalidateLayoutForRect(
            NSRect(
                x: 0,
                y: minPosition.yPos,
                width: 0,
                height: maxPosition.yPos + maxPosition.height
            )
        )
    }

    // MARK: - Layout

    /// Lays out all visible lines
    internal func layoutLines() {
        guard let visibleRect = delegate?.visibleRect else { return }
        let minY = max(visibleRect.minY - 200, 0)
        let maxY = visibleRect.maxY + 200
        let originalHeight = lineStorage.height
        var usedFragmentIDs = Set<UUID>()

        // Layout all lines
        for linePosition in lineStorage.linesStartingAt(minY, until: maxY) {
            let lineSize = layoutLine(
                linePosition,
                minY: linePosition.yPos,
                maxY: maxY,
                laidOutFragmentIDs: &usedFragmentIDs
            )
            if lineSize.height != linePosition.height {
                lineStorage.update(
                    atIndex: linePosition.range.location,
                    delta: 0,
                    deltaHeight: lineSize.height - linePosition.height
                )
            }
            if maxLineWidth < lineSize.width {
                maxLineWidth = lineSize.width
            }
        }

        // Enqueue any lines not used in this layout pass.
        viewReuseQueue.enqueueViews(notInSet: usedFragmentIDs)

        if originalHeight != lineStorage.height || layoutView?.frame.size.height != lineStorage.height {
            delegate?.layoutManagerHeightDidUpdate(newHeight: lineStorage.height)
        }
    }

    /// Lays out any lines that should be visible but are not laid out yet.
    /// - Parameter delta: If used a scroll view, the delta between the last y position and the current y position.
    ///                    Used to correctly update the view's height without jumping down in the active scroll.
    internal func updateVisibleLines(delta: CGFloat?) {
        // TODO: re-calculate layout after size change.
        // Get all visible lines and determine if more need to be laid out vertically.
        guard let visibleRect = delegate?.visibleRect else { return }
        let minY = max(visibleRect.minY - 200, 0)
        let maxY = visibleRect.maxY + 200
        let existingFragmentIDs = Set(viewReuseQueue.usedViews.keys)
        var usedFragmentIDs = Set<UUID>()

        for linePosition in lineStorage.linesStartingAt(minY, until: maxY) {
            if linePosition.data.typesetter.lineFragments.isEmpty {
                usedFragmentIDs.forEach { viewId in
                    viewReuseQueue.enqueueView(forKey: viewId)
                }
                layoutLines()
                return
            }
            for lineFragmentPosition in linePosition.data.typesetter.lineFragments {
                let lineFragment = lineFragmentPosition.data
                usedFragmentIDs.insert(lineFragment.id)
                if viewReuseQueue.usedViews[lineFragment.id] == nil {
                    layoutFragmentView(
                        for: lineFragmentPosition,
                        at: linePosition.yPos + lineFragmentPosition.height
                    )
                }
            }
        }

        viewReuseQueue.enqueueViews(in: existingFragmentIDs.subtracting(usedFragmentIDs))
    }

    /// Lays out a single text line.
    /// - Parameters:
    ///   - position: The line position from storage to use for layout.
    ///   - minY: The minimum Y value to start at.
    ///   - maxY: The maximum Y value to end layout at.
    ///   - laidOutFragmentIDs: Updated by this method as line fragments are laid out.
    /// - Returns: A `CGSize` representing the max width and total height of the laid out portion of the line.
    internal func layoutLine(
        _ position: TextLineStorage<TextLine>.TextLinePosition,
        minY: CGFloat,
        maxY: CGFloat,
        laidOutFragmentIDs: inout Set<UUID>
    ) -> CGSize {
        let line = position.data
        line.prepareForDisplay(
            maxWidth: wrapLines
            ? delegate?.textViewSize().width ?? .greatestFiniteMagnitude
            : .greatestFiniteMagnitude,
            lineHeightMultiplier: lineHeightMultiplier,
            range: position.range
        )

        var height: CGFloat = 0
        var width: CGFloat = 0

        // TODO: Lay out only fragments in min/max Y
        for lineFragmentPosition in line.typesetter.lineFragments {
            let lineFragment = lineFragmentPosition.data

            layoutFragmentView(for: lineFragmentPosition, at: minY + lineFragmentPosition.yPos)

            width = max(width, lineFragment.width)
            height += lineFragment.scaledHeight
            laidOutFragmentIDs.insert(lineFragment.id)
        }

        return CGSize(width: width, height: height)
    }

    /// Lays out a line fragment view for the given line fragment at the specified y value.
    /// - Parameters:
    ///   - lineFragment: The line fragment position to lay out a view for.
    ///   - yPos: The y value at which the line should begin.
    private func layoutFragmentView(
        for lineFragment: TextLineStorage<LineFragment>.TextLinePosition,
        at yPos: CGFloat
    ) {
        let view = viewReuseQueue.getOrCreateView(forKey: lineFragment.data.id)
        view.setLineFragment(lineFragment.data)
        view.frame.origin = CGPoint(x: 0, y: yPos)
        layoutView?.addSubview(view)
        view.needsDisplay = true
    }

    deinit {
        lineStorage.removeAll()
        layoutView = nil
        delegate = nil
    }
}

extension TextLayoutManager: NSTextStorageDelegate {
    func textStorage(
        _ textStorage: NSTextStorage,
        didProcessEditing editedMask: NSTextStorageEditActions,
        range editedRange: NSRange,
        changeInLength delta: Int
    ) {
        if editedMask.contains(.editedCharacters) {
            lineStorage.update(atIndex: editedRange.location, delta: delta, deltaHeight: 0)
            layoutLines()
        } else {
            invalidateLayoutForRange(editedRange)
            delegate?.textLayoutSetNeedsDisplay()
        }
    }
}
