//
//  STTextViewController+Highlighter.swift
//
//
//  Created by Khan Winter on 4/21/23.
//

import AppKit
import SwiftTreeSitter

extension STTextViewController {
    /// Configures the `Highlighter` object
    internal func setUpHighlighter() {
        self.highlighter = Highlighter(
            textView: textView,
            highlightProvider: highlightProvider,
            theme: theme,
            attributeProvider: self,
            language: language
        )
    }

    /// Sets the highlight provider and re-highlights all text. This method should be used sparingly.
    internal func setHighlightProvider(_ highlightProvider: HighlightProviding? = nil) {
        var provider: HighlightProviding?

        if let highlightProvider = highlightProvider {
            provider = highlightProvider
        } else {
            let textProvider: ResolvingQueryCursor.TextProvider = { [weak self] range, _ -> String? in
                return self?.textView.textContentStorage?.textStorage?.mutableString.substring(with: range)
            }

            provider = TreeSitterClient(codeLanguage: language, textProvider: textProvider)
        }

        if let provider = provider {
            self.highlightProvider = provider
            highlighter?.setHighlightProvider(provider)
        }
    }

    /// Gets all attributes for the given capture including the line height, background color, and text color.
    /// - Parameter capture: The capture to use for syntax highlighting.
    /// - Returns: All attributes to be applied.
    public func attributesFor(_ capture: CaptureName?) -> [NSAttributedString.Key: Any] {
        return [
            .font: font,
            .foregroundColor: theme.colorFor(capture),
            .baselineOffset: baselineOffset,
            .paragraphStyle: paragraphStyle,
            .kern: kern
        ]
    }
}
