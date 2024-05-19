//
//  TagFilter.swift
//
//
//  Created by Roscoe Rubin-Rottenberg on 5/18/24.
//

import Foundation
import TextFormation
import TextStory

struct TagFilter: Filter {
    var language: String
    private let newlineFilter = NewlineProcessingFilter()

    func processMutation(
        _ mutation: TextMutation,
        in interface: TextInterface,
        with whitespaceProvider: WhitespaceProviders
    ) -> FilterAction {
        guard isRelevantLanguage() else {
            return .none
        }
        guard let range = Range(mutation.range, in: interface.string) else { return .none }
        let insertedText = mutation.string
        let fullText = interface.string

        // Check if the inserted text is a closing bracket (>)
        if insertedText == ">" {
            let textBeforeCursor = "\(String(fullText[..<range.lowerBound]))\(insertedText)"
            if let lastOpenTag = textBeforeCursor.nearestTag {
                // Check if the tag is not self-closing and there isn't already a closing tag
                if !lastOpenTag.isSelfClosing && !textBeforeCursor.contains("</\(lastOpenTag.name)>") {
                    let closingTag = "</\(lastOpenTag.name)>"
                    let newRange = NSRange(location: mutation.range.location + 1, length: 0)
                    DispatchQueue.main.async {
                        let newMutation = TextMutation(string: closingTag, range: newRange, limit: 50)
                        interface.applyMutation(newMutation)
                        let cursorPosition = NSRange(location: newRange.location, length: 0)
                        interface.selectedRange = cursorPosition
                    }
                }
            }
        }

        return .none
    }
    private func isRelevantLanguage() -> Bool {
        let relevantLanguages = ["html", "javascript", "typescript", "jsx", "tsx"]
        return relevantLanguages.contains(language)
    }
}
private extension String {
    var nearestTag: (name: String, isSelfClosing: Bool)? {
        let regex = try? NSRegularExpression(pattern: "<([a-zA-Z0-9]+)([^>]*)>", options: .caseInsensitive)
        let nsString = self as NSString
        let results = regex?.matches(in: self, options: [], range: NSRange(location: 0, length: nsString.length))

        // Find the nearest tag before the cursor
        guard let lastMatch = results?.last(where: { $0.range.location < nsString.length }) else { return nil }
        let tagNameRange = lastMatch.range(at: 1)
        let attributesRange = lastMatch.range(at: 2)
        let tagName = nsString.substring(with: tagNameRange)
        let attributes = nsString.substring(with: attributesRange)
        let isSelfClosing = attributes.contains("/")

        return (name: tagName, isSelfClosing: isSelfClosing)
    }
}
