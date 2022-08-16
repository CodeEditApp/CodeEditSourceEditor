//
//  STTextViewController+TreeSitter.swift
//  CodeEditTextView
//
//  Created by Lukas Pistrol on 28.05.22.
//

import AppKit
import SwiftTreeSitter

internal extension STTextViewController {

    /// Setup the `tree-sitter` parser and get queries.
    func setupTreeSitter() {
        DispatchQueue.global(qos: .userInitiated).async {
            self.parser = Parser()
            guard let lang = self.language.language else { return }
            try? self.parser?.setLanguage(lang)

            let start = CFAbsoluteTimeGetCurrent()
            self.query = TreeSitterModel.shared.query(for: self.language.id)
            let end = CFAbsoluteTimeGetCurrent()
            print("Fetching Query for \(self.language.id.rawValue): \(end-start) seconds")
            DispatchQueue.main.async {
                self.highlight()
            }
        }
    }

    /// Execute queries and handle matches
    func highlight() {
        guard let parser = parser,
              let text = textView?.string,
              let tree = parser.parse(text),
              let cursor = query?.execute(node: tree.rootNode!, in: tree)
        else { return }

        if let expr = tree.rootNode?.sExpressionString,
           expr.contains("ERROR") { return }

        while let match = cursor.next() {
            //            print("match: ", match)
            self.highlightCaptures(match.captures)
            self.highlightCaptures(for: match.predicates, in: match)
        }
    }

    /// Highlight query captures
    func highlightCaptures(_ captures: [QueryCapture]) {
        captures.forEach { capture in
            textView?.addAttributes([
                .foregroundColor: colorForCapture(capture.name),
                .font: NSFont.monospacedSystemFont(ofSize: font.pointSize, weight: .medium),
                .baselineOffset: baselineOffset
            ], range: capture.node.range)
        }
    }

    /// Highlight query captures for predicates
    func highlightCaptures(for predicates: [Predicate], in match: QueryMatch) {
        predicates.forEach { predicate in
            predicate.captures(in: match).forEach { capture in
                //                print(capture.name, textView?.string[capture.node.range], predicate)
                textView?.addAttributes(
                    [
                        .foregroundColor: colorForCapture(capture.name?.appending("_alternate")),
                        .font: NSFont.monospacedSystemFont(ofSize: font.pointSize, weight: .medium),
                        .baselineOffset: baselineOffset
                    ],
                    range: capture.node.range
                )
            }
        }
    }

    /// Get the color from ``theme`` for the specified capture name.
    /// - Parameter capture: The capture name
    /// - Returns: A `NSColor`
    func colorForCapture(_ capture: String?) -> NSColor {
        let captureName = CaptureNames.fromString(capture)
        switch captureName {
        case .include, .constructor, .keyword, .boolean, .variableBuiltin,
                .keywordReturn, .keywordFunction, .repeat, .conditional, .tag:
            return theme.keywords
        case .comment: return theme.comments
        case .variable, .property: return theme.variables
        case .function, .method: return theme.variables
        case .number, .float: return theme.numbers
        case .string: return theme.strings
        case .type: return theme.types
        case .parameter: return theme.variables
        case .typeAlternate: return theme.attributes
        default: return theme.text
        }
    }
}
