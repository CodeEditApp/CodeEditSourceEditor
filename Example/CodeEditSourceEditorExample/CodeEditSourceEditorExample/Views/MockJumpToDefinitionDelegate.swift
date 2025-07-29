//
//  MockJumpToDefinitionDelegate.swift
//  CodeEditSourceEditorExample
//
//  Created by Khan Winter on 7/24/25.
//

import AppKit
import CodeEditSourceEditor

final class MockJumpToDefinitionDelegate: JumpToDefinitionDelegate, ObservableObject {
    func queryLinks(forRange range: NSRange, textView: TextViewController) async -> [JumpToDefinitionLink]? {
        [
            JumpToDefinitionLink(
                url: nil,
                targetRange: CursorPosition(line: 0, column: 10),
                typeName: "Start of Document",
                sourcePreview: "// Comment at start"
            ),
            JumpToDefinitionLink(
                url: URL(string: "https://codeedit.app/"),
                targetRange: CursorPosition(line: 1024, column: 10),
                typeName: "CodeEdit Website",
                sourcePreview: "https://codeedit.app/"
            )
        ]
    }

    func openLink(link: JumpToDefinitionLink) {
        if let url = link.url {
            NSWorkspace.shared.open(url)
        }
    }
}
