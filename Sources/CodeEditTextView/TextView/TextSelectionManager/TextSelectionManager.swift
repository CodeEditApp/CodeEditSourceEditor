//
//  TextSelectionManager.swift
//  
//
//  Created by Khan Winter on 7/17/23.
//

import AppKit
import TextStory

protocol TextSelectionManagerDelegate: AnyObject {
    var font: NSFont { get }

    func setNeedsDisplay()
    func estimatedLineHeight() -> CGFloat
}

/// Manages an array of text selections representing cursors (0-length ranges) and selections (>0-length ranges).
///
/// Draws selections using a draw method similar to the `TextLayoutManager` class, and adds cursor views when
/// appropriate.
class TextSelectionManager {
    struct MarkedText {
        let range: NSRange
        let attributedString: NSAttributedString
    }

    class TextSelection {
        var range: NSRange
        weak var view: CursorView?

        init(range: NSRange, view: CursorView? = nil) {
            self.range = range
            self.view = view
        }

        var isCursor: Bool {
            range.length == 0
        }

        func didInsertText(length: Int, retainLength: Bool = false) {
            if !retainLength {
                range.length = 0
            }
            range.location += length
        }
    }

    enum Destination {
        case character
        case word
        case line
        /// Eg: Bottom of screen
        case container
        case document
    }

    enum Direction {
        case up
        case down
        case forward
        case backward
    }

    class var selectionChangedNotification: Notification.Name {
        Notification.Name("TextSelectionManager.TextSelectionChangedNotification")
    }

    public var selectedLineBackgroundColor: NSColor = NSColor.selectedTextBackgroundColor.withSystemEffect(.disabled)

    private(set) var markedText: [MarkedText] = []
    private(set) var textSelections: [TextSelection] = []
    private weak var layoutManager: TextLayoutManager?
    private weak var textStorage: NSTextStorage?
    private weak var layoutView: NSView?
    private weak var delegate: TextSelectionManagerDelegate?

    init(
        layoutManager: TextLayoutManager,
        textStorage: NSTextStorage,
        layoutView: NSView?,
        delegate: TextSelectionManagerDelegate?
    ) {
        self.layoutManager = layoutManager
        self.textStorage = textStorage
        self.layoutView = layoutView
        self.delegate = delegate
        textSelections = []
        updateSelectionViews()
    }

    public func setSelectedRange(_ range: NSRange) {
        textSelections.forEach { $0.view?.removeFromSuperview() }
        textSelections = [TextSelection(range: range)]
        updateSelectionViews()
    }

    public func setSelectedRanges(_ ranges: [NSRange]) {
        textSelections.forEach { $0.view?.removeFromSuperview() }
        textSelections = ranges.map { TextSelection(range: $0) }
        updateSelectionViews()
    }

    internal func updateSelectionViews() {
        textSelections.forEach { $0.view?.removeFromSuperview() }
        for textSelection in textSelections where textSelection.range.isEmpty {
            textSelection.view?.removeFromSuperview()
            let lineFragment = layoutManager?
                .textLineForOffset(textSelection.range.location)?
                .data
                .typesetter
                .lineFragments
                .first

            let cursorView = CursorView()
            cursorView.frame.origin = (layoutManager?.rectForOffset(textSelection.range.location) ?? .zero).origin

            cursorView.frame.size.height = lineFragment?.data.scaledHeight ?? 0
            layoutView?.addSubview(cursorView)
            textSelection.view = cursorView
        }
        delegate?.setNeedsDisplay()
        NotificationCenter.default.post(Notification(name: Self.selectionChangedNotification))
    }

    /// Notifies the selection manager of an edit and updates all selections accordingly.
    /// - Parameters:
    ///   - delta: The change in length of the document
    ///   - retainLength: Set to `true` if selections should keep their lengths after the edit.
    ///                   By default all selection lengths are set to 0 after any edit.
    func updateSelections(delta: Int, retainLength: Bool = false) {
        textSelections.forEach { $0.didInsertText(length: delta, retainLength: retainLength) }
    }

    internal func removeCursors() {
        for textSelection in textSelections {
            textSelection.view?.removeFromSuperview()
        }
    }

    /// Draws line backgrounds and selection rects for each selection in the given rect.
    /// - Parameter rect: The rect to draw in.
    internal func drawSelections(in rect: NSRect) {
        guard let context = NSGraphicsContext.current?.cgContext else { return }
        context.saveGState()
        // For each selection in the rect
        for textSelection in textSelections {
            if textSelection.range.isEmpty {
                // Highlight the line
                guard let linePosition = layoutManager?.textLineForOffset(textSelection.range.location) else {
                    continue
                }
                let selectionRect = CGRect(
                    x: rect.minX,
                    y: layoutManager?.rectForOffset(linePosition.range.location)?.minY ?? linePosition.yPos,
                    width: rect.width,
                    height: linePosition.height
                )
                if selectionRect.intersects(rect) {
                    context.setFillColor(selectedLineBackgroundColor.cgColor)
                    context.fill(selectionRect)
                }
            } else {
                // TODO: Highlight Selection Ranges

//                guard let selectionPointMin = layoutManager.pointForOffset(selection.range.location),
//                      let selectionPointMax = layoutManager.pointForOffset(selection.range.max) else {
//                    continue
//                }
//                let selectionRect = NSRect(
//                    x: selectionPointMin.x,
//                    y: selectionPointMin.y,
//                    width: selectionPointMax.x - selectionPointMin.x,
//                    height: selectionPointMax.y - selectionPointMin.y
//                )
//                if selectionRect.intersects(rect) {
//                    // This selection has some portion in the visible rect, draw it.
//                    for linePosition in layoutManager.lineStorage.linesInRange(selection.range) {
//
//                    }
//                }
            }
        }
        context.restoreGState()
    }

    // MARK: - Selection Manipulation

    public func rangeOfSelection(from offset: Int, direction: Direction, destination: Destination) -> NSRange {
        switch direction {
        case .backward:
            return extendSelection(from: offset, destination: destination, delta: -1)
        case .forward:
            return NSRange(location: offset, length: 0)
        case .up: // TODO: up
            return NSRange(location: offset, length: 0)
        case .down: // TODO: down
            return NSRange(location: offset, length: 0)
        }
    }

    /// Extends a selection from the given offset determining the length by the destination.
    ///
    /// Returns a new range that needs to be merged with an existing selection range using `NSRange.formUnion`
    ///
    /// - Parameters:
    ///   - offset: The location to start extending the selection from.
    ///   - destination: Determines how far the selection is extended.
    ///   - delta: The direction the selection should be extended. `1` for forwards, `-1` for backwards.
    /// - Returns: A new range to merge with a selection.
    private func extendSelection(from offset: Int, destination: Destination, delta: Int) -> NSRange {
        guard let string = textStorage?.string as NSString? else { return NSRange(location: offset, length: 0) }

        switch destination {
        case .character:
            return extendSelectionCharacter(string: string, from: offset, delta: delta)
        case .word:
            return extendSelectionWord(string: string, from: offset, delta: delta)
        case .line:
            return extendSelectionLine(string: string, from: offset, delta: delta)
        case .container:
            return extendSelectionContainer(from: offset, delta: delta)
        case .document:
            if delta > 0 {
                return NSRange(location: offset, length: string.length - offset)
            } else {
                return NSRange(location: 0, length: offset)
            }
        }
    }

    /// Extends the selection by a single character.
    ///
    /// The range returned from this method can be longer than `1` character if the character in the extended direction
    /// is a member of a grapheme cluster.
    ///
    /// - Parameters:
    ///   - string: The reference string to use.
    ///   - offset: The location to start extending the selection from.
    ///   - delta: The direction the selection should be extended. `1` for forwards, `-1` for backwards.
    /// - Returns: The range of the extended selection.
    private func extendSelectionCharacter(string: NSString, from offset: Int, delta: Int) -> NSRange {
        if delta > 0 {
            return string.rangeOfComposedCharacterSequences(for: NSRange(location: offset, length: 1))
        } else {
            return string.rangeOfComposedCharacterSequences(for: NSRange(location: offset - 1, length: 1))
        }
    }

    /// Extends the selection by one "word".
    ///
    /// Words in this case begin after encountering an alphanumeric character, and extend until either a whitespace
    /// or punctuation character.
    /// 
    /// - Parameters:
    ///   - string: The reference string to use.
    ///   - offset: The location to start extending the selection from.
    ///   - delta: The direction the selection should be extended. `1` for forwards, `-1` for backwards.
    /// - Returns: The range of the extended selection.
    private func extendSelectionWord(string: NSString, from offset: Int, delta: Int) -> NSRange {
        var enumerationOptions: NSString.EnumerationOptions = .byCaretPositions
        if delta < 0 {
            enumerationOptions.formUnion(.reverse)
        }
        guard let line = layoutManager?.textLineForOffset(offset),
              let lineFragment = line.data.typesetter.lineFragments.getLine(atIndex: offset - line.range.location)
        else {
            return NSRange(location: offset, length: 0)
        }
        let lineStart = line.range.location + lineFragment.range.location
        let lineEnd = line.range.location + lineFragment.range.max
        var rangeToDelete = NSRange(location: offset, length: 0)

        var hasFoundValidWordChar = false
        string.enumerateSubstrings(
            in: NSRange(
                location: delta > 0 ? offset : lineStart,
                length: delta > 0 ? lineEnd - offset : offset - lineStart
            ),
            options: enumerationOptions
        ) { substring, _, _, stop in
            guard let substring = substring else {
                stop.pointee = true
                return
            }

            if hasFoundValidWordChar && CharacterSet
                .whitespacesWithoutNewlines
                .union(.punctuationCharacters)
                .isSuperset(of: CharacterSet(charactersIn: substring)) {
                stop.pointee = true
                return
            } else if CharacterSet.alphanumerics.isSuperset(of: CharacterSet(charactersIn: substring)) {
                hasFoundValidWordChar = true
            }
            rangeToDelete.length += substring.count

            if delta < 0 {
                rangeToDelete.location -= substring.count
            }
        }

        return rangeToDelete
    }

    /// Extends the selection by one line in the direction specified.
    ///
    /// If extending backwards, this method will return the beginning of the leading non-whitespace characters
    /// in the line. If the offset is located in the leading whitespace it will return the real line beginning.
    /// For Example
    /// ```
    /// ^ = offset, ^--^ = returned range
    /// Line:
    ///      Loren Ipsum
    ///            ^
    /// Extend 1st Call:
    ///      Loren Ipsum
    ///      ^-----^
    /// Extend 2nd Call:
    ///      Loren Ipsum
    /// ^----^
    /// ```
    ///
    /// - Parameters:
    ///   - string: The reference string to use.
    ///   - offset: The location to start extending the selection from.
    ///   - delta: The direction the selection should be extended. `1` for forwards, `-1` for backwards.
    /// - Returns: The range of the extended selection.
    private func extendSelectionLine(string: NSString, from offset: Int, delta: Int) -> NSRange {
        guard let line = layoutManager?.textLineForOffset(offset),
              let lineFragment = line.data.typesetter.lineFragments.getLine(atIndex: offset - line.range.location)
        else {
            return NSRange(location: offset, length: 0)
        }
        print(line.range, lineFragment.range)
        let lineBound = delta > 0
        ? line.range.location + lineFragment.range.max
        : line.range.location + lineFragment.range.location

        var foundRange = NSRange(
            location: min(lineBound, offset),
            length: max(lineBound, offset) - min(lineBound, offset)
        )
        let originalFoundRange = foundRange

        // Only do this if we're going backwards.
        if delta < 0 {
            string.enumerateSubstrings(in: foundRange, options: .byCaretPositions) { substring, _, _, stop in
                if let substring = substring as String? {
                    if CharacterSet.whitespacesWithoutNewlines.isSuperset(of: CharacterSet(charactersIn: substring)) {
                        foundRange.location += 1
                        foundRange.length -= 1
                    } else {
                        stop.pointee = true
                    }
                } else {
                    stop.pointee = true
                }
            }
        }

        return foundRange.length == 0 ? originalFoundRange : foundRange
    }

    /// Extends a selection one "container" long.
    /// - Parameters:
    ///   - offset: The location to start extending the selection from.
    ///   - delta: The direction the selection should be extended. `1` for forwards, `-1` for backwards.
    /// - Returns: The range of the extended selection.
    private func extendSelectionContainer(from offset: Int, delta: Int) -> NSRange {
        guard let layoutView, let endOffset = layoutManager?.textOffsetAtPoint(
            CGPoint(
                x: delta > 0 ? layoutView.frame.maxX : layoutView.frame.minX,
                y: delta > 0 ? layoutView.frame.maxY : layoutView.frame.minY
            )
        ) else {
            return NSRange(location: offset, length: 0)
        }
        return endOffset > offset
        ? NSRange(location: offset, length: endOffset - offset)
        : NSRange(location: endOffset, length: offset - endOffset)
    }
}
