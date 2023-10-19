//
//  TextLayoutManager.swift
//  
//
//  Created by Khan Winter on 6/21/23.
//

import Foundation
import AppKit
import Common

public protocol TextLayoutManagerDelegate: AnyObject {
    func layoutManagerHeightDidUpdate(newHeight: CGFloat)
    func layoutManagerMaxWidthDidChange(newWidth: CGFloat)
    func textViewSize() -> CGSize
    func textLayoutSetNeedsDisplay()
    func layoutManagerYAdjustment(_ yAdjustment: CGFloat)

    var visibleRect: NSRect { get }
}

public class TextLayoutManager: NSObject {
    // MARK: - Public Properties

    public weak var delegate: TextLayoutManagerDelegate?
    public var typingAttributes: [NSAttributedString.Key: Any] {
        didSet {
            _estimateLineHeight = nil
        }
    }
    public var lineHeightMultiplier: CGFloat {
        didSet {
            setNeedsLayout()
        }
    }
    public var wrapLines: Bool {
        didSet {
            setNeedsLayout()
        }
    }
    public var detectedLineEnding: LineEnding = .lineFeed
    /// The edge insets to inset all text layout with.
    public var edgeInsets: HorizontalEdgeInsets = .zero {
        didSet {
            delegate?.layoutManagerMaxWidthDidChange(newWidth: maxLineWidth + edgeInsets.horizontal)
            setNeedsLayout()
        }
    }

    /// The number of lines in the document
    public var lineCount: Int {
        lineStorage.count
    }

    // MARK: - Internal

    internal unowned var textStorage: NSTextStorage
    internal var lineStorage: TextLineStorage<TextLine> = TextLineStorage()
    private let viewReuseQueue: ViewReuseQueue<LineFragmentView, UUID> = ViewReuseQueue()
    private var visibleLineIds: Set<TextLine.ID> = []
    /// Used to force a complete re-layout using `setNeedsLayout`
    private var needsLayout: Bool = false
    private(set) public var isInTransaction: Bool = false

    weak internal var layoutView: NSView?

    internal var maxLineWidth: CGFloat = 0 {
        didSet {
            delegate?.layoutManagerMaxWidthDidChange(newWidth: maxLineWidth + edgeInsets.horizontal)
        }
    }
    private var maxLineLayoutWidth: CGFloat {
        wrapLines ? (delegate?.textViewSize().width ?? .greatestFiniteMagnitude) - edgeInsets.horizontal
        : .greatestFiniteMagnitude
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
        var info = mach_timebase_info()
        guard mach_timebase_info(&info) == KERN_SUCCESS else { return }
        let start = mach_absolute_time()

        lineStorage.buildFromTextStorage(textStorage, estimatedLineHeight: estimateLineHeight())
        detectedLineEnding = LineEnding.detectLineEnding(lineStorage: lineStorage, textStorage: textStorage)

        let end = mach_absolute_time()
        let elapsed = end - start
        let nanos = elapsed * UInt64(info.numer) / UInt64(info.denom)
        print("Text Layout Manager built in: ", TimeInterval(nanos) / TimeInterval(NSEC_PER_MSEC), "ms")
    }

    /// Estimates the line height for the current typing attributes.
    /// Takes into account ``TextLayoutManager/lineHeightMultiplier``.
    /// - Returns: The estimated line height.
    public func estimateLineHeight() -> CGFloat {
        if let _estimateLineHeight {
            return _estimateLineHeight
        } else {
            let string = NSAttributedString(string: "0", attributes: typingAttributes)
            let typesetter = CTTypesetterCreateWithAttributedString(string)
            let ctLine = CTTypesetterCreateLine(typesetter, CFRangeMake(0, 1))
            var ascent: CGFloat = 0
            var descent: CGFloat = 0
            var leading: CGFloat = 0
            CTLineGetTypographicBounds(ctLine, &ascent, &descent, &leading)
            _estimateLineHeight = (ascent + descent + leading) * lineHeightMultiplier
            return _estimateLineHeight!
        }
    }

    /// The last known line height estimate. If  set to `nil`, will be recalculated the next time
    /// ``TextLayoutManager/estimateLineHeight()`` is called.
    private var _estimateLineHeight: CGFloat?

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

    public func setNeedsLayout() {
        needsLayout = true
        visibleLineIds.removeAll(keepingCapacity: true)
    }

    /// Begins a transaction, preventing the layout manager from performing layout until the `endTransaction` is called.
    /// Useful for grouping attribute modifications into one layout pass rather than laying out every update.
    public func beginTransaction() {
        isInTransaction = true
    }

    /// Ends a transaction. When called, the layout manager will layout any necessary lines.
    public func endTransaction() {
        isInTransaction = false
        setNeedsLayout()
        layoutLines()
    }

    // MARK: - Layout

    /// Lays out all visible lines
    internal func layoutLines() { // swiftlint:disable:this function_body_length
        guard let visibleRect = delegate?.visibleRect, !isInTransaction else { return }
        let minY = max(visibleRect.minY, 0)
        let maxY = max(visibleRect.maxY, 0)
        let originalHeight = lineStorage.height
        var usedFragmentIDs = Set<UUID>()
        var forceLayout: Bool = needsLayout
        var newVisibleLines: Set<TextLine.ID> = []
        var yContentAdjustment: CGFloat = 0
        var maxFoundLineWidth = maxLineWidth

        // Layout all lines
        for linePosition in lineStorage.linesStartingAt(minY, until: maxY) {
            // Updating height in the loop may cause the iterator to be wrong
            guard linePosition.yPos < maxY else { break }

            if forceLayout
                || linePosition.data.needsLayout(maxWidth: maxLineLayoutWidth)
                || !visibleLineIds.contains(linePosition.data.id) {
                let lineSize = layoutLine(
                    linePosition,
                    minY: linePosition.yPos,
                    maxY: maxY,
                    maxWidth: maxLineLayoutWidth,
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
                if maxFoundLineWidth < lineSize.width {
                    maxFoundLineWidth = lineSize.width
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

        if maxFoundLineWidth > maxLineWidth {
            maxLineWidth = maxFoundLineWidth
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
            estimatedLineHeight: estimateLineHeight(),
            range: position.range,
            stringRef: textStorage
        )

        if position.range.isEmpty {
            return CGSize(width: 0, height: estimateLineHeight())
        }

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
        view.frame.origin = CGPoint(x: edgeInsets.left, y: yPos)
        layoutView?.addSubview(view)
        view.needsDisplay = true
    }

    deinit {
        lineStorage.removeAll()
        layoutView = nil
        delegate = nil
    }
}
