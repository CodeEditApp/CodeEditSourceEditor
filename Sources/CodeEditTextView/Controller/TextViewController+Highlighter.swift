//
//  TextViewController+Highlighter.swift
//  
//
//  Created by Khan Winter on 10/14/23.
//

import Foundation
import SwiftTreeSitter

extension TextViewController {
    internal func setUpHighlighter() {
        self.highlighter = Highlighter(
            textView: textView,
            highlightProvider: highlightProvider,
            theme: theme,
            attributeProvider: self,
            language: language
        )
        storageDelegate.addDelegate(highlighter!)
        setHighlightProvider(self.highlightProvider)
    }

    internal func setHighlightProvider(_ highlightProvider: HighlightProviding? = nil) {
        var provider: HighlightProviding?

        if let highlightProvider = highlightProvider {
            provider = highlightProvider
        } else {
            let textProvider: ResolvingQueryCursor.TextProvider = { [weak self] range, _ -> String? in
                return self?.textView.textStorage.mutableString.substring(with: range)
            }

            provider = TreeSitterClient(textProvider: textProvider)
        }

        if let provider = provider {
            self.highlightProvider = provider
            highlighter?.setHighlightProvider(provider)
        }
    }
}

extension TextViewController: ThemeAttributesProviding {
    public func attributesFor(_ capture: CaptureName?) -> [NSAttributedString.Key: Any] {
        [
            .font: font,
            .foregroundColor: theme.colorFor(capture),
            .kern: textView.kern
        ]
    }
}
