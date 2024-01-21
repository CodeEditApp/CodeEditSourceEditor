//
//  CodeEditSourceEditor.swift
//  CodeEditSourceEditor
//
//  Created by Lukas Pistrol on 24.05.22.
//

import SwiftUI
import CodeEditTextView
import CodeEditLanguages

public struct CodeEditSourceEditor: NSViewControllerRepresentable {

    /// Initializes a Text Editor
    /// - Parameters:
    ///   - text: The text content
    ///   - language: The language for syntax highlighting
    ///   - theme: The theme for syntax highlighting
    ///   - font: The default font
    ///   - tabWidth: The visual tab width in number of spaces
    ///   - indentOption: The behavior to use when the tab key is pressed. Defaults to 4 spaces.
    ///   - lineHeight: The line height multiplier (e.g. `1.2`)
    ///   - wrapLines: Whether lines wrap to the width of the editor
    ///   - editorOverscroll: The distance to overscroll the editor by.
    ///   - cursorPosition: The cursor's position in the editor, measured in `(lineNum, columnNum)`
    ///   - useThemeBackground: Determines whether the editor uses the theme's background color, or a transparent
    ///                         background color
    ///   - highlightProvider: A class you provide to perform syntax highlighting. Leave this as `nil` to use the
    ///                        built-in `TreeSitterClient` highlighter.
    ///   - contentInsets: Insets to use to offset the content in the enclosing scroll view. Leave as `nil` to let the
    ///                    scroll view automatically adjust content insets.
    ///   - isEditable: A Boolean value that controls whether the text view allows the user to edit text.
    ///   - isSelectable: A Boolean value that controls whether the text view allows the user to select text. If this
    ///                   value is true, and `isEditable` is false, the editor is selectable but not editable.
    ///   - letterSpacing: The amount of space to use between letters, as a percent. Eg: `1.0` = no space, `1.5` = 1/2 a
    ///                    character's width between characters, etc. Defaults to `1.0`
    ///   - bracketPairHighlight: The type of highlight to use to highlight bracket pairs.
    ///                           See `BracketPairHighlight` for more information. Defaults to `nil`
    ///   - undoManager: The undo manager for the text view. Defaults to `nil`, which will create a new CEUndoManager
    public init(
        _ text: Binding<String>,
        language: CodeLanguage,
        theme: EditorTheme,
        font: NSFont,
        tabWidth: Int,
        indentOption: IndentOption = .spaces(count: 4),
        lineHeight: Double,
        wrapLines: Bool,
        editorOverscroll: CGFloat = 0,
        cursorPositions: Binding<[CursorPosition]>,
        useThemeBackground: Bool = true,
        highlightProvider: HighlightProviding? = nil,
        contentInsets: NSEdgeInsets? = nil,
        isEditable: Bool = true,
        isSelectable: Bool = true,
        letterSpacing: Double = 1.0,
        bracketPairHighlight: BracketPairHighlight? = nil,
        undoManager: CEUndoManager? = nil,
        coordinators: [any TextViewCoordinator] = []
    ) {
        self._text = text
        self.language = language
        self.theme = theme
        self.useThemeBackground = useThemeBackground
        self.font = font
        self.tabWidth = tabWidth
        self.indentOption = indentOption
        self.lineHeight = lineHeight
        self.wrapLines = wrapLines
        self.editorOverscroll = editorOverscroll
        self._cursorPositions = cursorPositions
        self.highlightProvider = highlightProvider
        self.contentInsets = contentInsets
        self.isEditable = isEditable
        self.isSelectable = isSelectable
        self.letterSpacing = letterSpacing
        self.bracketPairHighlight = bracketPairHighlight
        self.undoManager = undoManager
        self.coordinators = coordinators
    }

    @Binding private var text: String
    private var language: CodeLanguage
    private var theme: EditorTheme
    private var font: NSFont
    private var tabWidth: Int
    private var indentOption: IndentOption
    private var lineHeight: Double
    private var wrapLines: Bool
    private var editorOverscroll: CGFloat
    @Binding private var cursorPositions: [CursorPosition]
    private var useThemeBackground: Bool
    private var highlightProvider: HighlightProviding?
    private var contentInsets: NSEdgeInsets?
    private var isEditable: Bool
    private var isSelectable: Bool
    private var letterSpacing: Double
    private var bracketPairHighlight: BracketPairHighlight?
    private var undoManager: CEUndoManager?
    private var coordinators: [any TextViewCoordinator]

    public typealias NSViewControllerType = TextViewController

    public func makeNSViewController(context: Context) -> TextViewController {
        let controller = TextViewController(
            string: text,
            language: language,
            font: font,
            theme: theme,
            tabWidth: tabWidth,
            indentOption: indentOption,
            lineHeight: lineHeight,
            wrapLines: wrapLines,
            cursorPositions: cursorPositions,
            editorOverscroll: editorOverscroll,
            useThemeBackground: useThemeBackground,
            highlightProvider: highlightProvider,
            contentInsets: contentInsets,
            isEditable: isEditable,
            isSelectable: isSelectable,
            letterSpacing: letterSpacing,
            bracketPairHighlight: bracketPairHighlight,
            undoManager: undoManager
        )
        if controller.textView == nil {
            controller.loadView()
        }
        if !cursorPositions.isEmpty {
            controller.setCursorPositions(cursorPositions)
        }

        context.coordinator.controller = controller
        coordinators.forEach {
            $0.prepareCoordinator(controller: controller)
        }
        return controller
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    public func updateNSViewController(_ controller: TextViewController, context: Context) {
        if !context.coordinator.isUpdateFromTextView {
            // Prevent infinite loop of update notifications
            context.coordinator.isUpdatingFromRepresentable = true
            controller.setCursorPositions(cursorPositions)
            context.coordinator.isUpdatingFromRepresentable = false
        } else {
            context.coordinator.isUpdateFromTextView = false
        }

        // Do manual diffing to reduce the amount of reloads.
        // This helps a lot in view performance, as it otherwise gets triggered on each environment change.
        guard !paramsAreEqual(controller: controller) else {
            return
        }

        controller.font = font
        controller.wrapLines = wrapLines
        controller.useThemeBackground = useThemeBackground
        controller.lineHeightMultiple = lineHeight
        controller.editorOverscroll = editorOverscroll
        controller.contentInsets = contentInsets
        if controller.isEditable != isEditable {
            controller.isEditable = isEditable
        }

        if controller.isSelectable != isSelectable {
            controller.isSelectable = isSelectable
        }

        if controller.language.id != language.id {
            controller.language = language
        }
        if controller.theme != theme {
            controller.theme = theme
        }
        if controller.indentOption != indentOption {
            controller.indentOption = indentOption
        }
        if controller.tabWidth != tabWidth {
            controller.tabWidth = tabWidth
        }
        if controller.letterSpacing != letterSpacing {
            controller.letterSpacing = letterSpacing
        }

        controller.bracketPairHighlight = bracketPairHighlight

        controller.reloadUI()
        return
    }

    func paramsAreEqual(controller: NSViewControllerType) -> Bool {
        controller.font == font &&
        controller.isEditable == isEditable &&
        controller.isSelectable == isSelectable &&
        controller.wrapLines == wrapLines &&
        controller.useThemeBackground == useThemeBackground &&
        controller.lineHeightMultiple == lineHeight &&
        controller.editorOverscroll == editorOverscroll &&
        controller.contentInsets == contentInsets &&
        controller.language.id == language.id &&
        controller.theme == theme &&
        controller.indentOption == indentOption &&
        controller.tabWidth == tabWidth &&
        controller.letterSpacing == letterSpacing &&
        controller.bracketPairHighlight == bracketPairHighlight
    }

    @MainActor
    public class Coordinator: NSObject {
        var parent: CodeEditSourceEditor
        weak var controller: TextViewController?
        var isUpdatingFromRepresentable: Bool = false
        var isUpdateFromTextView: Bool = false

        init(parent: CodeEditSourceEditor) {
            self.parent = parent
            super.init()

            NotificationCenter.default.addObserver(
                self,
                selector: #selector(textViewDidChangeText(_:)),
                name: TextView.textDidChangeNotification,
                object: nil
            )

            NotificationCenter.default.addObserver(
                self,
                selector: #selector(textControllerCursorsDidUpdate(_:)),
                name: TextViewController.cursorPositionUpdatedNotification,
                object: nil
            )
        }

        @objc func textViewDidChangeText(_ notification: Notification) {
            guard let textView = notification.object as? TextView,
                  let controller,
                  controller.textView === textView else {
                return
            }
            parent.text = textView.string
            parent.coordinators.forEach {
                $0.textViewDidChangeText(controller: controller)
            }
        }

        @objc func textControllerCursorsDidUpdate(_ notification: Notification) {
            guard !isUpdatingFromRepresentable else { return }
            self.isUpdateFromTextView = true
            self.parent._cursorPositions.wrappedValue = self.controller?.cursorPositions ?? []
            if self.controller != nil {
                self.parent.coordinators.forEach {
                    $0.textViewDidChangeSelection(
                        controller: self.controller!,
                        newPositions: self.controller!.cursorPositions
                    )
                }
            }
        }

        deinit {
            parent.coordinators.forEach {
                $0.destroy()
            }
            parent.coordinators.removeAll()
            NotificationCenter.default.removeObserver(self)
        }
    }
}

// swiftlint:disable:next line_length
@available(*, unavailable, renamed: "CodeEditSourceEditor", message: "CodeEditTextView has been renamed to CodeEditSourceEditor.")
public struct CodeEditTextView: View {
    public init(
        _ text: Binding<String>,
        language: CodeLanguage,
        theme: EditorTheme,
        font: NSFont,
        tabWidth: Int,
        indentOption: IndentOption = .spaces(count: 4),
        lineHeight: Double,
        wrapLines: Bool,
        editorOverscroll: CGFloat = 0,
        cursorPositions: Binding<[CursorPosition]>,
        useThemeBackground: Bool = true,
        highlightProvider: HighlightProviding? = nil,
        contentInsets: NSEdgeInsets? = nil,
        isEditable: Bool = true,
        isSelectable: Bool = true,
        letterSpacing: Double = 1.0,
        bracketPairHighlight: BracketPairHighlight? = nil,
        undoManager: CEUndoManager? = nil,
        coordinators: [any TextViewCoordinator] = []
    ) {

    }

    public var body: some View {
        EmptyView()
    }
}
