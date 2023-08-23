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
    func layoutManagerYAdjustment(_ yAdjustment: CGFloat)

    var visibleRect: NSRect { get }
}

final class TextLayoutManager: NSObject {
    // MARK: - Public Config

    public weak var delegate: TextLayoutManagerDelegate?
    public var typingAttributes: [NSAttributedString.Key: Any]
    public var lineHeightMultiplier: CGFloat
    public var wrapLines: Bool
    public var detectedLineEnding: LineEnding = .lf
    public var gutterWidth: CGFloat = 20 {
        didSet {
            setNeedsLayout()
        }
    }

    // MARK: - Internal

    private unowned var textStorage: NSTextStorage
    internal var lineStorage: TextLineStorage<TextLine> = TextLineStorage()
    private let viewReuseQueue: ViewReuseQueue<LineFragmentView, UUID> = ViewReuseQueue()
    private var visibleLineIds: Set<TextLine.ID> = []
    /// Used to force a complete re-layout using `setNeedsLayout`
    private var needsLayout: Bool = false
    private var isInTransaction: Bool = false

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

        lineStorage.buildFromTextStorage(textStorage, estimatedLineHeight: estimateLineHeight())
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

    public func textLineForOffset(_ offset: Int) -> TextLineStorage<TextLine>.TextLinePosition? {
        lineStorage.getLine(atIndex: offset)
    }

    public func textOffsetAtPoint(_ point: CGPoint) -> Int? {
        guard let position = lineStorage.getLine(atPosition: point.y),
              let fragmentPosition = position.data.typesetter.lineFragments.getLine(
                atPosition: point.y - position.yPos
              ) else {
            return nil
        }
        let fragment = fragmentPosition.data

        if fragment.width < point.x - gutterWidth {
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
                CGPoint(x: point.x - gutterWidth, y: fragment.height/2)
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
            x: xPos + gutterWidth,
            y: linePosition.yPos + fragmentPosition.yPos
            + (fragmentPosition.data.height - fragmentPosition.data.scaledHeight)/2
        )
    }

    // MARK: - Invalidation

    /// Invalidates layout for the given rect.
    /// - Parameter rect: The rect to invalidate.
    public func invalidateLayoutForRect(_ rect: NSRect) {
        for linePosition in lineStorage.linesStartingAt(rect.minY, until: rect.maxY) {
            linePosition.data.setNeedsLayout()
        }
        layoutLines()
    }

    /// Invalidates layout for the given range of text.
    /// - Parameter range: The range of text to invalidate.
    public func invalidateLayoutForRange(_ range: NSRange) {
        for linePosition in lineStorage.linesInRange(range) {
            linePosition.data.setNeedsLayout()
        }

        layoutLines()
    }

    func setNeedsLayout() {
        needsLayout = true
        visibleLineIds.removeAll(keepingCapacity: true)
    }

    func beginTransaction() {
        isInTransaction = true
    }

    func endTransaction() {
        isInTransaction = false
        setNeedsLayout()
        layoutLines()
    }

    // MARK: - Layout

    /// Lays out all visible lines
    internal func layoutLines() {
        guard let visibleRect = delegate?.visibleRect, !isInTransaction else { return }
        let minY = max(visibleRect.minY, 0)
        let maxY = max(visibleRect.maxY, 0)
        let originalHeight = lineStorage.height
        var usedFragmentIDs = Set<UUID>()
        var forceLayout: Bool = needsLayout
        let maxWidth: CGFloat = wrapLines
            ? (delegate?.textViewSize().width ?? .greatestFiniteMagnitude) - gutterWidth
            : .greatestFiniteMagnitude
        var newVisibleLines: Set<TextLine.ID> = []
        var yContentAdjustment: CGFloat = 0

        // Layout all lines
        for linePosition in lineStorage.linesStartingAt(minY, until: maxY) {
            if forceLayout
                || linePosition.data.needsLayout(maxWidth: maxWidth)
                || !visibleLineIds.contains(linePosition.data.id) {
                let lineSize = layoutLine(
                    linePosition,
                    minY: linePosition.yPos,
                    maxY: maxY,
                    maxWidth: maxWidth,
                    laidOutFragmentIDs: &usedFragmentIDs
                )
                if lineSize.height != linePosition.height {
                    lineStorage.update(
                        atIndex: linePosition.range.location,
                        delta: 0,
                        deltaHeight: lineSize.height - linePosition.height
                    )
                    // If we've updated a line's height, force re-layout for the rest of the pass.
                    forceLayout = true

                    if linePosition.yPos < minY {
                        // Adjust the scroll position by the difference between the new height and old.
                        yContentAdjustment += lineSize.height - linePosition.height
                    }
                }
                if maxLineWidth < lineSize.width {
                    maxLineWidth = lineSize.width
                }
            } else {
                // Make sure the used fragment views aren't dequeued.
                usedFragmentIDs.formUnion(linePosition.data.typesetter.lineFragments.map(\.data.id))
            }
            newVisibleLines.insert(linePosition.data.id)
        }

        // Enqueue any lines not used in this layout pass.
        viewReuseQueue.enqueueViews(notInSet: usedFragmentIDs)

        // Update the visible lines with the new set.
        visibleLineIds = newVisibleLines

        if originalHeight != lineStorage.height || layoutView?.frame.size.height != lineStorage.height {
            delegate?.layoutManagerHeightDidUpdate(newHeight: lineStorage.height)
        }

        if yContentAdjustment != 0 {
            delegate?.layoutManagerYAdjustment(yContentAdjustment)
        }

        needsLayout = false
    }

    /// Lays out a single text line.
    /// - Parameters:
    ///   - position: The line position from storage to use for layout.
    ///   - minY: The minimum Y value to start at.
    ///   - maxY: The maximum Y value to end layout at.
    ///   - laidOutFragmentIDs: Updated by this method as line fragments are laid out.
    /// - Returns: A `CGSize` representing the max width and total height of the laid out portion of the line.
    private func layoutLine(
        _ position: TextLineStorage<TextLine>.TextLinePosition,
        minY: CGFloat,
        maxY: CGFloat,
        maxWidth: CGFloat,
        laidOutFragmentIDs: inout Set<UUID>
    ) -> CGSize {
        let line = position.data
        line.prepareForDisplay(
            maxWidth: maxWidth,
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
        view.frame.origin = CGPoint(x: gutterWidth, y: yPos)
        layoutView?.addSubview(view)
        view.needsDisplay = true
    }

    deinit {
        lineStorage.removeAll()
        layoutView = nil
        delegate = nil
    }
}

// MARK: - Edits

extension TextLayoutManager: NSTextStorageDelegate {
    func textStorage(
        _ textStorage: NSTextStorage,
        didProcessEditing editedMask: NSTextStorageEditActions,
        range editedRange: NSRange,
        changeInLength delta: Int
    ) {
        if editedMask.contains(.editedCharacters) {
            lineStorage.update(atIndex: editedRange.location, delta: delta, deltaHeight: 0)
        }
        invalidateLayoutForRange(editedRange)
    }
}
