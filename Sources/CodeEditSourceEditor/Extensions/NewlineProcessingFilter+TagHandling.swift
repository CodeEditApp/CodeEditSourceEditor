//
//  NewlineProcessingFilter+TagHandling.swift
//  CodeEditSourceEditor
//
//  Created by Roscoe Rubin-Rottenberg on 5/19/24.
//

import Foundation
import TextStory
import TextFormation

extension NewlineProcessingFilter {

    private func handleTags(
        for mutation: TextMutation,
        in interface: TextInterface,
        with indentOption: IndentOption
    ) -> Bool {
        guard let precedingText = interface.substring(
            from: NSRange(
                location: 0,
                length: mutation.range.location
            )
        ) else {
            return false
        }

        guard let followingText = interface.substring(
                from: NSRange(
                    location: mutation.range.location,
                    length: interface.length - mutation.range.location
                )
              ) else {
            return false
        }

        let tagPattern = "<([a-zA-Z][a-zA-Z0-9]*)\\b[^>]*>"

        guard let precedingTagGroups = precedingText.groups(for: tagPattern),
              let precedingTag = precedingTagGroups.first else {
            return false
        }

        guard followingText.range(of: "</\(precedingTag)>", options: .regularExpression) != nil else {
            return false
        }

        let insertionLocation = mutation.range.location
        let newline = "\n"
        let indentedNewline = newline + indentOption.stringValue
        let newRange = NSRange(location: insertionLocation + indentedNewline.count, length: 0)

        // Insert indented newline first
        interface.insertString(indentedNewline, at: insertionLocation)
        // Then insert regular newline after indented newline
        interface.insertString(newline, at: insertionLocation + indentedNewline.count)
        interface.selectedRange = newRange

        return true
    }

    public func processTags(
        for mutation: TextMutation,
        in interface: TextInterface,
        with indentOption: IndentOption
    ) -> FilterAction {
        if handleTags(for: mutation, in: interface, with: indentOption) {
            return .discard
        }
        return .none
    }
}

public extension TextMutation {
    func applyWithTagProcessing(
        in interface: TextInterface,
        using filter: NewlineProcessingFilter,
        with providers: WhitespaceProviders,
        indentOption: IndentOption
    ) -> FilterAction {
        if filter.processTags(for: self, in: interface, with: indentOption) == .discard {
            return .discard
        }

        // Apply the original filter processing
        return filter.processMutation(self, in: interface, with: providers)
    }
}

// Helper extension to extract capture groups
extension String {
    func groups(for regexPattern: String) -> [String]? {
        guard let regex = try? NSRegularExpression(pattern: regexPattern) else { return nil }
        let nsString = self as NSString
        let results = regex.matches(in: self, range: NSRange(location: 0, length: nsString.length))
        return results.first.map { result in
            (1..<result.numberOfRanges).compactMap {
                result.range(at: $0).location != NSNotFound ? nsString.substring(with: result.range(at: $0)) : nil
            }
        }
    }
}
