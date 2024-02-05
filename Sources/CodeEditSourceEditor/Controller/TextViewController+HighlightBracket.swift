//
//  TextViewController+HighlightRange.swift
//  CodeEditSourceEditor
//
//  Created by Khan Winter on 4/26/23.
//

import AppKit

extension TextViewController {
    /// Highlights bracket pairs using the current selection.
    internal func highlightSelectionPairs() {
        guard bracketPairHighlight != nil else { return }
        removeHighlightLayers()
        for range in textView.selectionManager.textSelections.map({ $0.range }) {
            if range.isEmpty,
               range.location > 0, // Range is not the beginning of the document
               let precedingCharacter = textView.textStorage.substring(
                from: NSRange(location: range.location - 1, length: 1) // The preceding character exists
               ) {
                for pair in BracketPairs.highlightValues {
                    if precedingCharacter == pair.0 {
                        // Walk forwards
                        if let characterIndex = findClosingPair(
                            pair.0,
                            pair.1,
                            from: range.location,
                            limit: min(NSMaxRange(textView.visibleTextRange ?? .zero) + 4096,
                                       NSMaxRange(textView.documentRange)),
                            reverse: false
                        ) {
                            highlightCharacter(characterIndex)
                            if bracketPairHighlight?.highlightsSourceBracket ?? false {
                                highlightCharacter(range.location - 1)
                            }
                        }
                    } else if precedingCharacter == pair.1 && range.location - 1 > 0 {
                        // Walk backwards
                        if let characterIndex = findClosingPair(
                            pair.1,
                            pair.0,
                            from: range.location - 1,
                            limit: max((textView.visibleTextRange?.location ?? 0) - 4096,
                                       textView.documentRange.location),
                            reverse: true
                        ) {
                            highlightCharacter(characterIndex)
                            if bracketPairHighlight?.highlightsSourceBracket ?? false {
                                highlightCharacter(range.location - 1)
                            }
                        }
                    }
                }
            }
        }
    }

    /// # Dev Note
    /// It's interesting to note that this problem could trivially be turned into a monoid, and the locations of each
    /// pair start/end location determined when the view is loaded. It could then be parallelized for initial speed
    /// and this lookup would be much faster.

    /// Finds a closing character given a pair of characters, ignores pairs inside the given pair.
    ///
    /// ```pseudocode
    /// { -- Start
    ///   {
    ///   } -- A naive algorithm may find this character as the closing pair, which would be incorrect.
    /// } -- Found
    /// ```
    ///
    /// - Parameters:
    ///   - open: The opening pair to look for.
    ///   - close: The closing pair to look for.
    ///   - from: The index to start from. This should not include the start character. Eg given `"{ }"` looking forward
    ///           the index should be `1`
    ///   - limit: A limiting index to stop at. When `reverse` is `true`, this is the minimum index. When `false` this
    ///            is the maximum index.
    ///   - reverse: Set to `true` to walk backwards from `from`.
    /// - Returns: The index of the found closing pair, if any.
    internal func findClosingPair(_ close: String, _ open: String, from: Int, limit: Int, reverse: Bool) -> Int? {
        // Walk the text, counting each close. When we find an open that makes closeCount < 0, return that index.
        var options: NSString.EnumerationOptions = .byCaretPositions
        if reverse {
            options = options.union(.reverse)
        }
        var closeCount = 0
        var index: Int?
        textView.textStorage.mutableString.enumerateSubstrings(
            in: reverse ?
                NSRange(location: limit, length: from - limit) :
                NSRange(location: from, length: limit - from),
            options: options,
            using: { substring, range, _, stop in
                if substring == close {
                    closeCount += 1
                } else if substring == open {
                    closeCount -= 1
                }

                if closeCount < 0 {
                    index = range.location
                    stop.pointee = true
                }
            }
        )
        return index
    }

    /// Adds a temporary highlight effect to the character at the given location.
    /// - Parameters:
    ///   - location: The location of the character to highlight
    ///   - scrollToRange: Set to true to scroll to the given range when highlighting. Defaults to `false`.
    private func highlightCharacter(_ location: Int, scrollToRange: Bool = false) {
        guard let bracketPairHighlight = bracketPairHighlight,
              var rectToHighlight = textView.layoutManager.rectForOffset(location) else {
            return
        }
        let layer = CAShapeLayer()

        switch bracketPairHighlight {
        case .flash:
            rectToHighlight.size.width += 4
            rectToHighlight.origin.x -= 2

            layer.cornerRadius = 3.0
            layer.backgroundColor = NSColor(hex: 0xFEFA80, alpha: 1.0).cgColor
            layer.shadowColor = .black
            layer.shadowOpacity = 0.3
            layer.shadowOffset = CGSize(width: 0, height: 1)
            layer.shadowRadius = 3.0
            layer.opacity = 0.0
        case .bordered(let borderColor):
            layer.borderColor = borderColor.cgColor
            layer.cornerRadius = 2.5
            layer.borderWidth = 0.5
            layer.opacity = 1.0
        case .underline(let underlineColor):
            layer.lineWidth = 1.0
            layer.lineCap = .round
            layer.strokeColor = underlineColor.cgColor
            layer.opacity = 1.0
        }

        switch bracketPairHighlight {
        case .flash, .bordered:
            layer.frame = rectToHighlight
        case .underline:
            let path = CGMutablePath()
            let pathY = rectToHighlight.maxY - (rectToHighlight.height * (lineHeightMultiple - 1))/4
            path.move(to: CGPoint(x: rectToHighlight.minX, y: pathY))
            path.addLine(to: CGPoint(x: rectToHighlight.maxX, y: pathY))
            layer.path = path
        }

        // Insert above selection but below text
        textView.layer?.insertSublayer(layer, at: 1)

        if bracketPairHighlight == .flash {
            addFlashAnimation(to: layer, rectToHighlight: rectToHighlight)
        }

        highlightLayers.append(layer)

        // Scroll the last rect into view, makes a small assumption that the last rect is the lowest visually.
        if scrollToRange {
            textView.scrollToVisible(rectToHighlight)
        }
    }

    /// Adds a flash animation to the given layer.
    /// - Parameters:
    ///   - layer: The layer to add the animation to.
    ///   - rectToHighlight: The layer's bounding rect to animate.
    private func addFlashAnimation(to layer: CALayer, rectToHighlight: CGRect) {
        CATransaction.begin()
        CATransaction.setCompletionBlock { [weak self] in
            if let index = self?.highlightLayers.firstIndex(of: layer) {
                self?.highlightLayers.remove(at: index)
            }
            layer.removeFromSuperlayer()
        }
        let duration = 0.75
        let group = CAAnimationGroup()
        group.duration = duration

        let opacityAnim = CAKeyframeAnimation(keyPath: "opacity")
        opacityAnim.duration = duration
        opacityAnim.values = [1.0, 1.0, 0.0]
        opacityAnim.keyTimes = [0.1, 0.8, 0.9]

        let positionAnim = CAKeyframeAnimation(keyPath: "position")
        positionAnim.keyTimes = [0.0, 0.05, 0.1]
        positionAnim.values = [
            NSPoint(x: rectToHighlight.origin.x, y: rectToHighlight.origin.y),
            NSPoint(x: rectToHighlight.origin.x - 2, y: rectToHighlight.origin.y - 2),
            NSPoint(x: rectToHighlight.origin.x, y: rectToHighlight.origin.y)
        ]
        positionAnim.duration = duration

        var betweenSize = rectToHighlight
        betweenSize.size.width += 4
        betweenSize.size.height += 4
        let boundsAnim = CAKeyframeAnimation(keyPath: "bounds")
        boundsAnim.keyTimes = [0.0, 0.05, 0.1]
        boundsAnim.values = [rectToHighlight, betweenSize, rectToHighlight]
        boundsAnim.duration = duration

        group.animations = [opacityAnim, boundsAnim]
        layer.add(group, forKey: nil)
        CATransaction.commit()
    }

    /// Safely removes all highlight layers.
    internal func removeHighlightLayers() {
        highlightLayers.forEach { layer in
            layer.removeFromSuperlayer()
        }
        highlightLayers.removeAll()
    }
}
