//
//  MinimapLineFragmentView.swift
//  CodeEditSourceEditor
//
//  Created by Khan Winter on 4/10/25.
//

import AppKit
import CodeEditTextView

/// A custom line fragment view for the minimap.
///
/// Instead of drawing line contents, this view calculates a series of boxes or 'runs' to draw to represent the text
/// in the line fragment.
///
/// Runs are calculated when the view's fragment is set, and cached until invalidated, and all whitespace
/// characters are ignored.
final class MinimapLineFragmentView: LineFragmentView {
    /// A run represents a position, length, and color that we can draw.
    /// ``MinimapLineFragmentView`` class will calculate cache these when a new line fragment is set.
    struct Run {
        let color: NSColor
        let range: NSRange
    }

    private weak var textStorage: NSTextStorage?
    private var drawingRuns: [Run] = []

    init(textStorage: NSTextStorage?) {
        self.textStorage = textStorage
        super.init(frame: .zero)
    }

    @MainActor required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Prepare the view for reuse, clearing cached drawing runs.
    override func prepareForReuse() {
        super.prepareForReuse()
        drawingRuns.removeAll()
    }

    /// Set the new line fragment, and calculate drawing runs for drawing the fragment in the view.
    /// - Parameter newFragment: The new fragment to use.
    override func setLineFragment(_ newFragment: LineFragment) {
        super.setLineFragment(newFragment)
        guard let textStorage else { return }

        // Create the drawing runs using attribute information
        var position = newFragment.documentRange.location

        while position < newFragment.documentRange.max {
            var longestRange: NSRange = .notFound
            defer { position = longestRange.max }

            guard let foregroundColor = textStorage.attribute(
                .foregroundColor,
                at: position,
                longestEffectiveRange: &longestRange,
                in: NSRange(start: position, end: newFragment.documentRange.max)
            ) as? NSColor else {
                continue
            }

            // Now that we have the foreground color for drawing, filter our runs to only include non-whitespace
            // characters
            var range: NSRange = .notFound
            for idx in longestRange.location..<longestRange.max {
                let char = (textStorage.string as NSString).character(at: idx)
                if let scalar = UnicodeScalar(char), CharacterSet.whitespacesAndNewlines.contains(scalar) {
                    // Whitespace
                    if range != .notFound {
                        appendDrawingRun(color: foregroundColor, range: range)
                        range = .notFound
                    }
                } else {
                    // Not whitespace
                    if range == .notFound {
                        range = NSRange(location: idx, length: 1)
                    } else {
                        range = NSRange(start: range.location, end: idx + 1)
                    }
                }
            }

            if range != .notFound {
                appendDrawingRun(color: foregroundColor, range: range)
            }
        }
    }

    /// Appends a new drawing run to the list.
    /// - Parameters:
    ///   - color: The color of the run, will have opacity applied by this method.
    ///   - range: The range, relative to the document. Will be normalized to the fragment by this method.
    private func appendDrawingRun(color: NSColor, range: NSRange) {
        drawingRuns.append(
            Run(
                color: color.withAlphaComponent(0.4),
                range: NSRange(
                    location: range.location - (lineFragment?.documentRange.location ?? 0),
                    length: range.length
                )
            )
        )
    }

    /// Draw our cached drawing runs in the current graphics context.
    override func draw(_ dirtyRect: NSRect) {
        guard let context = NSGraphicsContext.current?.cgContext else { return }

        context.saveGState()
        for run in drawingRuns {
            let rect = CGRect(
                x: 8 + (CGFloat(run.range.location) * 1.5),
                y: 0,
                width: CGFloat(run.range.length) * 1.5,
                height: 2.0
            )
            context.setFillColor(run.color.cgColor)
            context.fill(rect)
        }

        context.restoreGState()
    }
}
