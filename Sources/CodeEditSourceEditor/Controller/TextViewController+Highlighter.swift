//
//  TextViewController+Highlighter.swift
//  CodeEditSourceEditor
//
//  Created by Khan Winter on 10/14/23.
//

import Foundation
import SwiftTreeSitter

extension TextViewController {
    internal func setUpHighlighter() {
        if let highlighter {
            textView.removeStorageDelegate(highlighter)
            self.highlighter = nil
        }

        let highlighter = Highlighter(
            textView: textView,
            providers: highlightProviders,
            attributeProvider: self,
            language: language
        )
        textView.addStorageDelegate(highlighter)
        self.highlighter = highlighter
    }
}

extension TextViewController: ThemeAttributesProviding {
    public func attributesFor(_ capture: CaptureName?) -> [NSAttributedString.Key: Any] {
        [
            .font: theme.fontFor(for: capture, from: font),
            .foregroundColor: theme.colorFor(capture),
            .kern: textView.kern
        ]
    }
}
