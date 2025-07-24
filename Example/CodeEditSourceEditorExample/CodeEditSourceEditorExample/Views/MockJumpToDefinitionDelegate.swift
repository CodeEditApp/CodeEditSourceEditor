//
//  MockJumpToDefinitionDelegate.swift
//  CodeEditSourceEditorExample
//
//  Created by Khan Winter on 7/24/25.
//

import AppKit
import CodeEditSourceEditor

final class MockJumpToDefinitionDelegate: JumpToDefinitionDelegate, ObservableObject {
    func queryLinks(forRange range: NSRange) async -> [JumpToDefinitionLink]? {
        Bool.random() ? [
            JumpToDefinitionLink(
                url: nil,
                targetPosition: CursorPosition(line: 0, column: 0),
                targetRange: NSRange(start: 0, end: 10),
                typeName: "Start of Document",
                sourcePreview: "// Comment at start"
            ),
            JumpToDefinitionLink(
                url: URL(string: "https://codeedit.app/"),
                targetPosition: CursorPosition(line: 1024, column: 10),
                targetRange: NSRange(location: 30, length: 100),
                typeName: "CodeEdit Website",
                sourcePreview: "https://codeedit.app/"
            )
        ] : nil
    }
    
    func openLink(url: URL, targetRange: NSRange) {
        NSWorkspace.shared.open(url)
    }
}
