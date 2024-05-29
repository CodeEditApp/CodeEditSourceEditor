//
//  TagFilter.swift
//  CodeEditSourceEditor
//
//  Created by Roscoe Rubin-Rottenberg on 5/18/24.
//

import Foundation
import TextFormation
import TextStory
import CodeEditTextView
import CodeEditLanguages
import SwiftTreeSitter

struct TagFilter: Filter {
    var language: CodeLanguage
    var indentOption: IndentOption
    var lineEnding: LineEnding
    var treeSitterClient: TreeSitterClient

    // HTML, JSX, TSX
    private static let openingElementTags = ["start_tag", "jsx_opening_element", "tsx_opening_element"]
    private static let closingElementTags = ["end_tag", "jsx_closing_element", "tsx_closing_element"]
    // HTML & JSX, TSX
    private static let tagContents = ["tag_name", "identifier"]

    func processMutation(
        _ mutation: TextMutation,
        in interface: TextInterface,
        with whitespaceProvider: WhitespaceProviders
    ) -> FilterAction {
        let prevCharRange = NSRange(location: mutation.range.location - 1, length: 1)
        if mutation.delta > 0 && mutation.range.location > 0 && interface.substring(from: prevCharRange) == ">" {
            handleInsertionAfterTag(mutation, in: interface, with: whitespaceProvider)
        }

        // If this is a newline, we do some extra processing!

        

        return .none
    }

    private func handleInsertionAfterTag(
        _ mutation: TextMutation,
        in interface: TextInterface,
        with whitespaceProvider: WhitespaceProviders
    ) {
        let prevCharRange = NSRange(location: mutation.range.location - 1, length: 1)
        var foundStartTag: String?
        var foundEndNode: Bool = false

        do {
            let pairs = try treeSitterClient.nodesAt(location: mutation.range.location)

            for (_, node) in pairs {
                node.enumerateChildren { node in
                    guard node.isNamed else { return }

                    if node.byteRange.upperBound == UInt32(prevCharRange.max * 2),
                       Self.openingElementTags.contains(node.nodeType ?? ""),
                       let tagNameNode = node.namedChild(at: 0),
                       Self.tagContents.contains(tagNameNode.nodeType ?? "") {
                        // Got the tag name for the opening tag
                        foundStartTag = interface.substring(from: tagNameNode.range)
                    }

                    // After the start node, in the same tree level we'll either find a `element` tag or a `end_tag`
                    // tag.
                    // If we find the end_tag, we're over.
                    if foundStartTag != nil && (Self.closingElementTags.contains(node.nodeType ?? "")) {
                        foundEndNode = true
                    }
                }
            }

            guard let startTag = foundStartTag, !foundEndNode else { return }

            let closingTag = TextMutation(
                string: "</\(startTag)>",
                range: NSRange(location: mutation.range.max, length: 0),
                limit: interface.length
            )
            interface.applyMutation(closingTag)
            interface.selectedRange = NSRange(location: mutation.range.max, length: 0)
        } catch {
            return
        }
    }
}
