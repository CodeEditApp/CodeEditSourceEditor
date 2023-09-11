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

    func prepareToTypeset(_ string: NSAttributedString, maxWidth: CGFloat, lineHeightMultiplier: CGFloat) {
        lineFragments.removeAll()
        self.typesetter = CTTypesetterCreateWithAttributedString(string)
        self.string = string
        generateLines(maxWidth: maxWidth, lineHeightMultiplier: lineHeightMultiplier)
    }

    // MARK: - Generate lines

    private func generateLines(maxWidth: CGFloat, lineHeightMultiplier: CGFloat) {
        guard let typesetter else { return }
        var startIndex = 0
        while startIndex < string.length {
            let lineBreak = suggestLineBreak(using: typesetter, startingOffset: startIndex, constrainingWidth: maxWidth)
            let lineFragment = typesetLine(
                range: NSRange(location: startIndex, length: lineBreak - startIndex),
                lineHeightMultiplier: lineHeightMultiplier
            )
            lineFragments.insert(
                line: lineFragment,
                atIndex: startIndex,
                length: lineBreak - startIndex,
                height: lineFragment.scaledHeight
            )
            startIndex = lineBreak
        }
    }

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

    private func suggestLineBreak(
        using typesetter: CTTypesetter,
        startingOffset: Int,
        constrainingWidth: CGFloat
    ) -> Int {
        var breakIndex: Int
        breakIndex = startingOffset + CTTypesetterSuggestClusterBreak(typesetter, startingOffset, constrainingWidth)
        // Ensure we're breaking at a whitespace, CT can sometimes suggest this incorrectly.
        guard breakIndex < string.length && breakIndex - 1 > 0 && ensureCharacterCanBreakLine(at: breakIndex - 1) else {
            // Walk backwards until we find a valid break point. Max out at 100 characters.
            var index = breakIndex - 1
            while index > 0 && breakIndex - index > 100 {
                if ensureCharacterCanBreakLine(at: index) {
                    return index
                } else {
                    index -= 1
                }
            }
            return breakIndex
        }

        return breakIndex
    }

    private func ensureCharacterCanBreakLine(at index: Int) -> Bool {
        let set = CharacterSet(
            charactersIn: string.attributedSubstring(from: NSRange(location: index, length: 1)).string
        )
        return set.isSubset(of: .whitespacesAndNewlines.subtracting(.newlines))
        || set.isSubset(of: .punctuationCharacters)
    }

    deinit {
        lineFragments.removeAll()
    }
}
