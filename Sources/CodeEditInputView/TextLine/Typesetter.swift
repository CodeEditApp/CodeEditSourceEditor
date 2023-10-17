//
//  Typesetter.swift
//  
//
//  Created by Khan Winter on 6/21/23.
//

import Foundation
import CoreText

final class Typesetter {
    var typesetter: CTTypesetter?
    var string: NSAttributedString!
    var lineFragments = TextLineStorage<LineFragment>()

    // MARK: - Init & Prepare

    init() { }

    func prepareToTypeset(
        _ string: NSAttributedString,
        maxWidth: CGFloat,
        lineHeightMultiplier: CGFloat,
        estimatedLineHeight: CGFloat
    ) {
        lineFragments.removeAll()
        self.typesetter = CTTypesetterCreateWithAttributedString(string)
        self.string = string
        generateLines(
            maxWidth: maxWidth,
            lineHeightMultiplier: lineHeightMultiplier,
            estimatedLineHeight: estimatedLineHeight
        )
    }

    // MARK: - Generate lines
    
    /// Generate line fragments.
    /// - Parameters:
    ///   - maxWidth: The maximum width the line can be.
    ///   - lineHeightMultiplier: The multiplier to apply to an empty line's height.
    ///   - estimatedLineHeight: The estimated height of an empty line.
    private func generateLines(maxWidth: CGFloat, lineHeightMultiplier: CGFloat, estimatedLineHeight: CGFloat) {
        guard let typesetter else { return }
        var lines: [TextLineStorage<LineFragment>.BuildItem] = []
        var height: CGFloat = 0
        if string.length == 0 {
            // Insert an empty fragment
            let ctLine = CTTypesetterCreateLine(typesetter, CFRangeMake(0, 0))
            let fragment = LineFragment(
                ctLine: ctLine,
                width: 0,
                height: estimatedLineHeight,
                descent: 0,
                lineHeightMultiplier: lineHeightMultiplier
            )
            lines = [.init(data: fragment, length: 0, height: fragment.scaledHeight)]
        } else {
            var startIndex = 0
            while startIndex < string.length {
                let lineBreak = suggestLineBreak(
                    using: typesetter,
                    strategy: .word, // TODO: Make this configurable
                    startingOffset: startIndex,
                    constrainingWidth: maxWidth
                )
                let lineFragment = typesetLine(
                    range: NSRange(location: startIndex, length: lineBreak - startIndex),
                    lineHeightMultiplier: lineHeightMultiplier
                )
                lines.append(.init(data: lineFragment, length: lineBreak - startIndex, height: lineFragment.scaledHeight))
                startIndex = lineBreak
                height = lineFragment.scaledHeight
            }
        }
        // Use an efficient tree building algorithm rather than adding lines sequentially
        lineFragments.build(from: lines, estimatedLineHeight: height)
    }
    
    /// Typeset a new fragment.
    /// - Parameters:
    ///   - range: The range of the fragment.
    ///   - lineHeightMultiplier: The multiplier to apply to the line's height.
    /// - Returns: A new line fragment.
    private func typesetLine(range: NSRange, lineHeightMultiplier: CGFloat) -> LineFragment {
        let ctLine = CTTypesetterCreateLine(typesetter!, CFRangeMake(range.location, range.length))
        var ascent: CGFloat = 0
        var descent: CGFloat = 0
        var leading: CGFloat = 0
        let width = CGFloat(CTLineGetTypographicBounds(ctLine, &ascent, &descent, &leading))
        let height = ascent + descent + leading
        return LineFragment(
            ctLine: ctLine,
            width: width,
            height: height,
            descent: descent,
            lineHeightMultiplier: lineHeightMultiplier
        )
    }

    // MARK: - Line Breaks

    /// Suggest a line break for the given line break strategy.
    /// - Parameters:
    ///   - typesetter: The typesetter to use.
    ///   - strategy: The strategy that determines a valid line break.
    ///   - startingOffset: Where to start breaking.
    ///   - constrainingWidth: The available space for the line.
    /// - Returns: An offset relative to the entire string indicating where to break.
    private func suggestLineBreak(
        using typesetter: CTTypesetter,
        strategy: LineBreakStrategy,
        startingOffset: Int,
        constrainingWidth: CGFloat
    ) -> Int {
        switch strategy {
        case .character:
            return suggestLineBreakForCharacter(
                using: typesetter,
                startingOffset: startingOffset,
                constrainingWidth: constrainingWidth
            )
        case .word:
            return suggestLineBreakForWord(
                using: typesetter,
                startingOffset: startingOffset,
                constrainingWidth: constrainingWidth
            )
        }
    }

    /// Suggest a line break for the character break strategy.
    /// - Parameters:
    ///   - typesetter: The typesetter to use.
    ///   - startingOffset: Where to start breaking.
    ///   - constrainingWidth: The available space for the line.
    /// - Returns: An offset relative to the entire string indicating where to break.
    private func suggestLineBreakForCharacter(
        using typesetter: CTTypesetter,
        startingOffset: Int,
        constrainingWidth: CGFloat
    ) -> Int {
        var breakIndex: Int
        breakIndex = startingOffset + CTTypesetterSuggestClusterBreak(typesetter, startingOffset, constrainingWidth)
        guard breakIndex < string.length else {
            return breakIndex
        }
        let substring = string.attributedSubstring(from: NSRange(location: breakIndex - 1, length: 2)).string
        if substring == LineEnding.carriageReturnLineFeed.rawValue {
            // Breaking in the middle of the clrf line ending
            return breakIndex + 1
        }
        return breakIndex
    }

    /// Suggest a line break for the word break strategy.
    /// - Parameters:
    ///   - typesetter: The typesetter to use.
    ///   - startingOffset: Where to start breaking.
    ///   - constrainingWidth: The available space for the line.
    /// - Returns: An offset relative to the entire string indicating where to break.
    private func suggestLineBreakForWord(
        using typesetter: CTTypesetter,
        startingOffset: Int,
        constrainingWidth: CGFloat
    ) -> Int {
        let breakIndex = startingOffset + CTTypesetterSuggestClusterBreak(typesetter, startingOffset, constrainingWidth)
        if breakIndex >= string.length || (breakIndex - 1 > 0 && ensureCharacterCanBreakLine(at: breakIndex - 1)) {
            // Breaking either at the end of the string, or on a whitespace.
            return breakIndex
        } else if breakIndex - 1 > 0 {
            // Try to walk backwards until we hit a whitespace or punctuation
            var index = breakIndex - 1

            while breakIndex - index < 100 && index > startingOffset {
                if ensureCharacterCanBreakLine(at: index) {
                    return index + 1
                }
                index -= 1
            }
        }

        return breakIndex
    }
    
    /// Ensures the character at the given index can break a line.
    /// - Parameter index: The index to check at.
    /// - Returns: True, if the character is a whitespace or punctuation character.
    private func ensureCharacterCanBreakLine(at index: Int) -> Bool {
        let set = CharacterSet(
            charactersIn: string.attributedSubstring(from: NSRange(location: index, length: 1)).string
        )
        return set.isSubset(of: .whitespaces) || set.isSubset(of: .punctuationCharacters)
    }

    deinit {
        lineFragments.removeAll()
    }
}
