import Foundation
import AppKit
import CodeEditTextView
import CodeEditLanguages
@testable import CodeEditSourceEditor

class MockHighlightProvider: HighlightProviding {
    var onSetUp: (CodeLanguage) -> Void
    var onApplyEdit: (_ textView: TextView, _ range: NSRange, _ delta: Int) -> Result<IndexSet, any Error>
    var onQueryHighlightsFor: (_ textView: TextView, _ range: NSRange) -> Result<[HighlightRange], any Error>

    init(
        onSetUp: @escaping (CodeLanguage) -> Void,
        onApplyEdit: @escaping (_: TextView, _: NSRange, _: Int) -> Result<IndexSet, any Error>,
        onQueryHighlightsFor: @escaping (_: TextView, _: NSRange) -> Result<[HighlightRange], any Error>
    ) {
        self.onSetUp = onSetUp
        self.onApplyEdit = onApplyEdit
        self.onQueryHighlightsFor = onQueryHighlightsFor
    }

    func setUp(textView: TextView, codeLanguage: CodeLanguage) {
        self.onSetUp(codeLanguage)
    }

    func applyEdit(
        textView: TextView,
        range: NSRange,
        delta: Int,
        completion: @escaping @MainActor (Result<IndexSet, any Error>) -> Void
    ) {
        completion(self.onApplyEdit(textView, range, delta))
    }

    func queryHighlightsFor(
        textView: TextView,
        range: NSRange,
        completion: @escaping @MainActor (Result<[HighlightRange], any Error>) -> Void
    ) {
        completion(self.onQueryHighlightsFor(textView, range))
    }
}

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
            highlightProviders: [TreeSitterClient()],
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
            text: EditorTheme.Attribute(color: .textColor),
            insertionPoint: .textColor,
            invisibles: EditorTheme.Attribute(color: .gray),
            background: .textBackgroundColor,
            lineHighlight: .highlightColor,
            selection: .selectedTextColor,
            keywords: EditorTheme.Attribute(color: .systemPink),
            commands: EditorTheme.Attribute(color: .systemBlue),
            types: EditorTheme.Attribute(color: .systemMint),
            attributes: EditorTheme.Attribute(color: .systemTeal),
            variables: EditorTheme.Attribute(color: .systemCyan),
            values: EditorTheme.Attribute(color: .systemOrange),
            numbers: EditorTheme.Attribute(color: .systemYellow),
            strings: EditorTheme.Attribute(color: .systemRed),
            characters: EditorTheme.Attribute(color: .systemRed),
            comments: EditorTheme.Attribute(color: .systemGreen)
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

    static func scrollingTextView() -> (NSScrollView, TextView) {
        let scrollView = NSScrollView(frame: .init(x: 0, y: 0, width: 250, height: 250))
        scrollView.contentView.postsBoundsChangedNotifications = true
        scrollView.postsFrameChangedNotifications = true
        let textView = textView()
        scrollView.documentView = textView
        scrollView.layoutSubtreeIfNeeded()
        textView.layout()
        return (scrollView, textView)
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
        attributeProvider: ThemeAttributesProviding,
        language: CodeLanguage = .default
    ) -> Highlighter {
        Highlighter(
            textView: textView,
            providers: [highlightProvider],
            attributeProvider: attributeProvider,
            language: language
        )
    }

    static func highlightProvider(
        onSetUp: @escaping (CodeLanguage) -> Void,
        onApplyEdit: @escaping (TextView, NSRange, Int) -> Result<IndexSet, any Error>,
        onQueryHighlightsFor: @escaping (TextView, NSRange) -> Result<[HighlightRange], any Error>
    ) -> MockHighlightProvider {
        MockHighlightProvider(onSetUp: onSetUp, onApplyEdit: onApplyEdit, onQueryHighlightsFor: onQueryHighlightsFor)
    }
}
