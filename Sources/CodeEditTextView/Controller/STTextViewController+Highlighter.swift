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
}
