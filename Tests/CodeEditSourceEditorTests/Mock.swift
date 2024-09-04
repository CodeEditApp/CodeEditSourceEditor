import Foundation
import CodeEditTextView
import CodeEditLanguages
@testable import CodeEditSourceEditor

enum Mock {
    class Delegate: TextViewDelegate { }

    static func textViewController(theme: EditorTheme) -> TextViewController {
        TextViewController(
            string: "",
            language: .html,
            font: .monospacedSystemFont(ofSize: 11, weight: .medium),
            theme: theme,
            tabWidth: 4,
            indentOption: .spaces(count: 4),
            lineHeight: 1.0,
            wrapLines: true,
            cursorPositions: [],
            editorOverscroll: 0.5,
            useThemeBackground: true,
            highlightProvider: nil,
            contentInsets: NSEdgeInsets(top: 0, left: 0, bottom: 0, right: 0),
            isEditable: true,
            isSelectable: true,
            letterSpacing: 1.0,
            useSystemCursor: false,
            bracketPairHighlight: .flash
        )
    }

    static func theme() -> EditorTheme {
        EditorTheme(
            text: .textColor,
            insertionPoint: .textColor,
            invisibles: .gray,
            background: .textBackgroundColor,
            lineHighlight: .highlightColor,
            selection: .selectedTextColor,
            keywords: .systemPink,
            commands: .systemBlue,
            types: .systemMint,
            attributes: .systemTeal,
            variables: .systemCyan,
            values: .systemOrange,
            numbers: .systemYellow,
            strings: .systemRed,
            characters: .systemRed,
            comments: .systemGreen
        )
    }

    static func textView() -> TextView {
        TextView(
            string: "func testSwiftFunc() -> Int {\n\tprint(\"\")\n}",
            font: .monospacedSystemFont(ofSize: 12, weight: .regular),
            textColor: .labelColor,
            lineHeightMultiplier: 1.0,
            wrapLines: true,
            isEditable: true,
            isSelectable: true,
            letterSpacing: 1.0,
            delegate: Delegate()
        )
    }

    static func treeSitterClient(forceSync: Bool = false) -> TreeSitterClient {
        let client = TreeSitterClient()
        client.forceSyncOperation = forceSync
        return client
    }

    @MainActor
    static func highlighter(
        textView: TextView,
        highlightProvider: HighlightProviding,
        theme: EditorTheme,
        attributeProvider: ThemeAttributesProviding,
        language: CodeLanguage = .default
    ) -> Highlighter {
        Highlighter(
            textView: textView,
            highlightProvider: highlightProvider,
            theme: theme,
            attributeProvider: attributeProvider,
            language: language
        )
    }
}
