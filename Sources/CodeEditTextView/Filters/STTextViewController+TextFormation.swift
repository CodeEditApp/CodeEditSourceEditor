//
//  STTextViewController+TextFormation.swift
//  
//
//  Created by Khan Winter on 1/26/23.
//

import AppKit
import STTextView
import TextFormation
import TextStory

extension STTextViewController {

    /// Initializes any filters for text editing.
    internal func setUpTextFormation() {
        let indentationUnit = String(repeating: " ", count: tabWidth)

        // Indentation

        let indenter: TextualIndenter
        switch language.id {
        case .python:
            indenter = TextualIndenter(patterns: TextualIndenter.pythonPatterns)
        case .ruby:
            indenter = TextualIndenter(patterns: TextualIndenter.rubyPatterns)
        default:
            indenter = TextualIndenter(patterns: TextualIndenter.basicPatterns)
        }

        let whitepaceProvider = WhitespaceProviders(
            leadingWhitespace: indenter.substitionProvider(indentationUnit: indentationUnit,
                                                           width: tabWidth),
            trailingWhitespace: { _, _ in "" }
        )

        // Bracket Pairs

        let bracketPairFilter = StandardOpenPairFilter(open: "{", close: "}", whitespaceProviders: whitepaceProvider)
        let bracePairFilter = StandardOpenPairFilter(open: "[", close: "]", whitespaceProviders: whitepaceProvider)
        let parenthesesPairFilter = StandardOpenPairFilter(
            open: "(",
            close: ")",
            whitespaceProviders: whitepaceProvider
        )
        let tagFilter = StandardOpenPairFilter(open: "<", close: ">", whitespaceProviders: whitepaceProvider)

        textFilters.append(contentsOf: [
            bracketPairFilter,
            bracePairFilter,
            parenthesesPairFilter,
            tagFilter
        ])

        // Newline & Tabs

        let newlineFilter = NewlineFilter(whitespaceProviders: whitepaceProvider)

        textFilters.append(newlineFilter)

        let tabReplacementFilter = TabReplacementFilter(indentationUnit: indentationUnit)

        textFilters.append(tabReplacementFilter)

        // Deleting Bracket Pairs

        let deleteBracketFilter = DeleteCloseFilter(open: "{", close: "}")
        let deleteBraceFilter = DeleteCloseFilter(open: "{", close: "}")
        let deleteParenthesesFilter = DeleteCloseFilter(open: "{", close: "}")
        let deleteTagFilter = DeleteCloseFilter(open: "<", close: ">")

        textFilters.append(contentsOf: [
            deleteBracketFilter,
            deleteBraceFilter,
            deleteParenthesesFilter,
            deleteTagFilter
        ])

        let deleteWhitespaceFilter = DeleteWhitespaceFilter(indentationUnit: indentationUnit)

        textFilters.append(deleteWhitespaceFilter)
    }

    /// Determines whether or not a text mutation should be applied.
    /// - Parameters:
    ///   - mutation: The text mutation.
    ///   - textView: The textView to use.
    /// - Returns: Return whether or not the mutation should be applied.
    private func shouldApplyMutation(_ mutation: TextMutation, to textView: STTextView) -> Bool {
        // don't perform any kind of filtering during undo operations
        // TODO: - STTextView.undoActive is private. Need alternative.
//        if textView.undoActive {
//            return true
//        }

        for filter in textFilters {
            let action = filter.processMutation(mutation, in: textView)

            switch action {
            case .none:
                break
            case .stop:
                return true
            case .discard:
                return false
            }
        }

        return true
    }

    public func textView(_ textView: STTextView,
                         shouldChangeTextIn affectedCharRange: NSTextRange,
                         replacementString: String?) -> Bool {
        guard let range = affectedCharRange.nsRange(using: textView.textContentStorage) else {
            return true
        }

        let mutation = TextMutation(string: replacementString ?? "",
                                    range: range,
                                    limit: textView.textContentStorage.length)

        textView.undoManager?.beginUndoGrouping()

        let result = shouldApplyMutation(mutation, to: textView)

        textView.undoManager?.endUndoGrouping()

        return result
    }
}
