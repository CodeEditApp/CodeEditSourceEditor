//
//  TextLine.swift
//  
//
//  Created by Khan Winter on 6/21/23.
//

import Foundation
import AppKit

/// Represents a displayable line of text.
public final class TextLine: Identifiable, Equatable {
    public let id: UUID = UUID()
    private var needsLayout: Bool = true
    var maxWidth: CGFloat?
    private(set) var typesetter: Typesetter = Typesetter()

    /// The line fragments contained by this text line.
    public var lineFragments: TextLineStorage<LineFragment> {
        typesetter.lineFragments
    }

    /// Marks this line as needing layout and clears all typesetting data.
    public func setNeedsLayout() {
        needsLayout = true
        typesetter = Typesetter()
    }

    /// Determines if the line needs to be laid out again.
    /// - Parameter maxWidth: The new max width to check.
    /// - Returns: True, if this line has been marked as needing layout using ``TextLine/setNeedsLayout()`` or if the
    ///            line needs to find new line breaks due to a new constraining width.
    func needsLayout(maxWidth: CGFloat) -> Bool {
        needsLayout || maxWidth != self.maxWidth
    }

    /// Prepares the line for display, generating all potential line breaks and calculating the real height of the line.
    /// - Parameters:
    ///   - displayData: Information required to display a text line.
    ///   - range: The range this text range represents in the entire document.
    ///   - stringRef: A reference to the string storage for the document.
    ///   - markedRanges: Any marked ranges in the line.
    ///   - breakStrategy: Determines how line breaks are calculated.
    func prepareForDisplay(
        displayData: DisplayData,
        range: NSRange,
        stringRef: NSTextStorage,
        markedRanges: MarkedTextManager.MarkedRanges?,
        breakStrategy: LineBreakStrategy
    ) {
        let string = stringRef.attributedSubstring(from: range)
        self.maxWidth = displayData.maxWidth
        typesetter.typeset(
            string,
            displayData: displayData,
            breakStrategy: breakStrategy,
            markedRanges: markedRanges
        )
        needsLayout = false
    }

    public static func == (lhs: TextLine, rhs: TextLine) -> Bool {
        lhs.id == rhs.id
    }

    /// Contains all required data to perform a typeset and layout operation on a text line.
    struct DisplayData {
        let maxWidth: CGFloat
        let lineHeightMultiplier: CGFloat
        let estimatedLineHeight: CGFloat
    }
}
