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

    // MARK: - Filter Configuration

    /// Initializes any filters for text editing.
    internal func setUpTextFormation() {
        textFilters = []

        let indentationUnit = indentOption.stringValue

        let pairsToHandle: [(String, String)] = [
            ("{", "}"),
            ("[", "]"),
            ("(", ")"),
            ("<", ">")
        ]

        let indenter: TextualIndenter = getTextIndenter()
        let whitespaceProvider = WhitespaceProviders(
            leadingWhitespace: indenter.substitionProvider(indentationUnit: indentationUnit,
                                                           width: tabWidth),
            trailingWhitespace: { _, _ in "" }
        )

        // Filters

        setUpOpenPairFilters(pairs: pairsToHandle, whitespaceProvider: whitespaceProvider)
        setUpNewlineTabFilters(whitespaceProvider: whitespaceProvider,
                               indentOption: indentOption)
        setUpDeletePairFilters(pairs: pairsToHandle)
        setUpDeleteWhitespaceFilter(indentOption: indentOption)
    }

    /// Returns a `TextualIndenter` based on available language configuration.
    private func getTextIndenter() -> TextualIndenter {
        switch language.id {
        case .python:
            return TextualIndenter(patterns: TextualIndenter.pythonPatterns)
        case .ruby:
            return TextualIndenter(patterns: TextualIndenter.rubyPatterns)
        default:
            return TextualIndenter(patterns: TextualIndenter.basicPatterns)
        }
    }

    /// Configures pair filters and adds them to the `textFilters` array.
    /// - Parameters:
    ///   - pairs: The pairs to configure. Eg: `{` and `}`
    ///   - whitespaceProvider: The whitespace providers to use.
    private func setUpOpenPairFilters(pairs: [(String, String)], whitespaceProvider: WhitespaceProviders) {
        for pair in pairs {
            let filter = StandardOpenPairFilter(open: pair.0, close: pair.1, whitespaceProviders: whitespaceProvider)
            textFilters.append(filter)
        }
    }

    /// Configures newline and tab replacement filters.
    /// - Parameters:
    ///   - whitespaceProvider: The whitespace providers to use.
    ///   - indentationUnit: The unit of indentation to use.
    private func setUpNewlineTabFilters(whitespaceProvider: WhitespaceProviders, indentOption: IndentOption) {
        let newlineFilter: Filter = NewlineProcessingFilter(whitespaceProviders: whitespaceProvider)
        let tabReplacementFilter: Filter = TabReplacementFilter(indentOption: indentOption)

        textFilters.append(contentsOf: [newlineFilter, tabReplacementFilter])
    }

    /// Configures delete pair filters.
    private func setUpDeletePairFilters(pairs: [(String, String)]) {
        for pair in pairs {
            let filter = DeleteCloseFilter(open: pair.0, close: pair.1)
            textFilters.append(filter)
        }
    }

    /// Configures up the delete whitespace filter.
    private func setUpDeleteWhitespaceFilter(indentOption: IndentOption) {
        let filter = DeleteWhitespaceFilter(indentOption: indentOption)
        textFilters.append(filter)
    }

    // MARK: - Delegate Methods

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

    /// Determines whether or not a text mutation should be applied.
    /// - Parameters:
    ///   - mutation: The text mutation.
    ///   - textView: The textView to use.
    /// - Returns: Return whether or not the mutation should be applied.
    private func shouldApplyMutation(_ mutation: TextMutation, to textView: STTextView) -> Bool {
        // don't perform any kind of filtering during undo operations
        if textView.undoManager?.isUndoing ?? false || textView.undoManager?.isRedoing ?? false {
            return true
        }

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
}
