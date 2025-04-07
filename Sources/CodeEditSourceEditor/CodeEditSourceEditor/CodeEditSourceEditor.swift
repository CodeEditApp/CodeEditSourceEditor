//
//  CodeEditSourceEditor.swift
//  CodeEditSourceEditor
//
//  Created by Lukas Pistrol on 24.05.22.
//

import AppKit
import SwiftUI
import CodeEditTextView
import CodeEditLanguages

/// A SwiftUI View that provides source editing functionality.
public struct CodeEditSourceEditor: NSViewControllerRepresentable {
    package enum TextAPI {
        case binding(Binding<String>)
        case storage(NSTextStorage)
    }

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
    ///   - cursorPositions: The cursor's position in the editor, measured in `(lineNum, columnNum)`
    ///   - useThemeBackground: Determines whether the editor uses the theme's background color, or a transparent
    ///                         background color
    ///   - highlightProvider: A class you provide to perform syntax highlighting. Leave this as `nil` to use the
    ///                        built-in `TreeSitterClient` highlighter.
    ///   - contentInsets: Insets to use to offset the content in the enclosing scroll view. Leave as `nil` to let the
    ///                    scroll view automatically adjust content insets.
    ///   - additionalTextInsets: An additional amount to inset the text of the editor by.
    ///   - isEditable: A Boolean value that controls whether the text view allows the user to edit text.
    ///   - isSelectable: A Boolean value that controls whether the text view allows the user to select text. If this
    ///                   value is true, and `isEditable` is false, the editor is selectable but not editable.
    ///   - letterSpacing: The amount of space to use between letters, as a percent. Eg: `1.0` = no space, `1.5` = 1/2 a
    ///                    character's width between characters, etc. Defaults to `1.0`
    ///   - bracketPairEmphasis: The type of highlight to use to highlight bracket pairs.
    ///                           See `BracketPairHighlight` for more information. Defaults to `nil`
    ///   - useSystemCursor: If true, uses the system cursor on `>=macOS 14`.
    ///   - undoManager: The undo manager for the text view. Defaults to `nil`, which will create a new CEUndoManager
    ///   - coordinators: Any text coordinators for the view to use. See ``TextViewCoordinator`` for more information.
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
        highlightProviders: [any HighlightProviding] = [TreeSitterClient()],
        contentInsets: NSEdgeInsets? = nil,
        additionalTextInsets: NSEdgeInsets? = nil,
        isEditable: Bool = true,
        isSelectable: Bool = true,
        letterSpacing: Double = 1.0,
        bracketPairEmphasis: BracketPairEmphasis? = .flash,
        useSystemCursor: Bool = true,
        undoManager: CEUndoManager? = nil,
        coordinators: [any TextViewCoordinator] = []
    ) {
        self.text = .binding(text)
        self.language = language
        self.theme = theme
        self.useThemeBackground = useThemeBackground
        self.font = font
        self.tabWidth = tabWidth
        self.indentOption = indentOption
        self.lineHeight = lineHeight
        self.wrapLines = wrapLines
        self.editorOverscroll = editorOverscroll
        self.cursorPositions = cursorPositions
        self.highlightProviders = highlightProviders
        self.contentInsets = contentInsets
        self.additionalTextInsets = additionalTextInsets
        self.isEditable = isEditable
        self.isSelectable = isSelectable
        self.letterSpacing = letterSpacing
        self.bracketPairEmphasis = bracketPairEmphasis
        if #available(macOS 14, *) {
            self.useSystemCursor = useSystemCursor
        } else {
            self.useSystemCursor = false
        }
        self.undoManager = undoManager
        self.coordinators = coordinators
    }

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
    ///   - cursorPositions: The cursor's position in the editor, measured in `(lineNum, columnNum)`
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
    ///   - bracketPairEmphasis: The type of highlight to use to highlight bracket pairs.
    ///                           See `BracketPairEmphasis` for more information. Defaults to `nil`
    ///   - undoManager: The undo manager for the text view. Defaults to `nil`, which will create a new CEUndoManager
    ///   - coordinators: Any text coordinators for the view to use. See ``TextViewCoordinator`` for more information.
    public init(
        _ text: NSTextStorage,
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
        highlightProviders: [any HighlightProviding] = [TreeSitterClient()],
        contentInsets: NSEdgeInsets? = nil,
        additionalTextInsets: NSEdgeInsets? = nil,
        isEditable: Bool = true,
        isSelectable: Bool = true,
        letterSpacing: Double = 1.0,
        bracketPairEmphasis: BracketPairEmphasis? = .flash,
        useSystemCursor: Bool = true,
        undoManager: CEUndoManager? = nil,
        coordinators: [any TextViewCoordinator] = []
    ) {
        self.text = .storage(text)
        self.language = language
        self.theme = theme
        self.useThemeBackground = useThemeBackground
        self.font = font
        self.tabWidth = tabWidth
        self.indentOption = indentOption
        self.lineHeight = lineHeight
        self.wrapLines = wrapLines
        self.editorOverscroll = editorOverscroll
        self.cursorPositions = cursorPositions
        self.highlightProviders = highlightProviders
        self.contentInsets = contentInsets
        self.additionalTextInsets = additionalTextInsets
        self.isEditable = isEditable
        self.isSelectable = isSelectable
        self.letterSpacing = letterSpacing
        self.bracketPairEmphasis = bracketPairEmphasis
        if #available(macOS 14, *) {
            self.useSystemCursor = useSystemCursor
        } else {
            self.useSystemCursor = false
        }
        self.undoManager = undoManager
        self.coordinators = coordinators
    }

    package var text: TextAPI
    private var language: CodeLanguage
    private var theme: EditorTheme
    private var font: NSFont
    private var tabWidth: Int
    private var indentOption: IndentOption
    private var lineHeight: Double
    private var wrapLines: Bool
    private var editorOverscroll: CGFloat
    package var cursorPositions: Binding<[CursorPosition]>
    private var useThemeBackground: Bool
    private var highlightProviders: [any HighlightProviding]
    private var contentInsets: NSEdgeInsets?
    private var additionalTextInsets: NSEdgeInsets?
    private var isEditable: Bool
    private var isSelectable: Bool
    private var letterSpacing: Double
    private var bracketPairEmphasis: BracketPairEmphasis?
    private var useSystemCursor: Bool
    private var undoManager: CEUndoManager?
    package var coordinators: [any TextViewCoordinator]

    public typealias NSViewControllerType = TextViewController

    public func makeNSViewController(context: Context) -> TextViewController {
        let controller = TextViewController(
            string: "",
            language: language,
            font: font,
            theme: theme,
            tabWidth: tabWidth,
            indentOption: indentOption,
            lineHeight: lineHeight,
            wrapLines: wrapLines,
            cursorPositions: cursorPositions.wrappedValue,
            editorOverscroll: editorOverscroll,
            useThemeBackground: useThemeBackground,
            highlightProviders: highlightProviders,
            contentInsets: contentInsets,
            additionalTextInsets: additionalTextInsets,
            isEditable: isEditable,
            isSelectable: isSelectable,
            letterSpacing: letterSpacing,
            useSystemCursor: useSystemCursor,
            bracketPairEmphasis: bracketPairEmphasis,
            undoManager: undoManager,
            coordinators: coordinators
        )
        switch text {
        case .binding(let binding):
            controller.textView.setText(binding.wrappedValue)
        case .storage(let textStorage):
            controller.textView.setTextStorage(textStorage)
        }
        if controller.textView == nil {
            controller.loadView()
        }
        if !cursorPositions.isEmpty {
            controller.setCursorPositions(cursorPositions.wrappedValue)
        }

        context.coordinator.controller = controller
        return controller
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(text: text, cursorPositions: cursorPositions)
    }

    public func updateNSViewController(_ controller: TextViewController, context: Context) {
        if !context.coordinator.isUpdateFromTextView {
            // Prevent infinite loop of update notifications
            context.coordinator.isUpdatingFromRepresentable = true
            controller.setCursorPositions(cursorPositions.wrappedValue)
            context.coordinator.isUpdatingFromRepresentable = false
        } else {
            context.coordinator.isUpdateFromTextView = false
        }

        // Set this no matter what to avoid having to compare object pointers.
        controller.textCoordinators = coordinators.map { WeakCoordinator($0) }

        // Do manual diffing to reduce the amount of reloads.
        // This helps a lot in view performance, as it otherwise gets triggered on each environment change.
        guard !paramsAreEqual(controller: controller) else {
            return
        }

        updateControllerParams(controller: controller)

        controller.reloadUI()
        return
    }

    /// Update the parameters of the controller.
    /// - Parameter controller: The controller to update.
    func updateControllerParams(controller: TextViewController) {
        updateTextProperties(controller)
        updateEditorProperties(controller)
        updateThemeAndLanguage(controller)
        updateHighlighting(controller)
    }

    private func updateTextProperties(_ controller: TextViewController) {
        if controller.font != font {
            controller.font = font
        }

        if controller.isEditable != isEditable {
            controller.isEditable = isEditable
        }

        if controller.isSelectable != isSelectable {
            controller.isSelectable = isSelectable
        }
    }

    private func updateEditorProperties(_ controller: TextViewController) {
        controller.wrapLines = wrapLines
        controller.useThemeBackground = useThemeBackground
        controller.lineHeightMultiple = lineHeight
        controller.editorOverscroll = editorOverscroll
        controller.contentInsets = contentInsets
        controller.additionalTextInsets = additionalTextInsets

        if controller.indentOption != indentOption {
            controller.indentOption = indentOption
        }

        if controller.tabWidth != tabWidth {
            controller.tabWidth = tabWidth
        }

        if controller.letterSpacing != letterSpacing {
            controller.letterSpacing = letterSpacing
        }

        if controller.useSystemCursor != useSystemCursor {
            controller.useSystemCursor = useSystemCursor
        }
    }

    private func updateThemeAndLanguage(_ controller: TextViewController) {
        if controller.language.id != language.id {
            controller.language = language
        }

        if controller.theme != theme {
            controller.theme = theme
        }
    }

    private func updateHighlighting(_ controller: TextViewController) {
        if !areHighlightProvidersEqual(controller: controller) {
            controller.setHighlightProviders(highlightProviders)
        }

        if controller.bracketPairEmphasis != bracketPairEmphasis {
            controller.bracketPairEmphasis = bracketPairEmphasis
        }
    }

    /// Checks if the controller needs updating.
    /// - Parameter controller: The controller to check.
    /// - Returns: True, if the controller's parameters should be updated.
    func paramsAreEqual(controller: NSViewControllerType) -> Bool {
        controller.font == font &&
        controller.isEditable == isEditable &&
        controller.isSelectable == isSelectable &&
        controller.wrapLines == wrapLines &&
        controller.useThemeBackground == useThemeBackground &&
        controller.lineHeightMultiple == lineHeight &&
        controller.editorOverscroll == editorOverscroll &&
        controller.contentInsets == contentInsets &&
        controller.additionalTextInsets == additionalTextInsets &&
        controller.language.id == language.id &&
        controller.theme == theme &&
        controller.indentOption == indentOption &&
        controller.tabWidth == tabWidth &&
        controller.letterSpacing == letterSpacing &&
        controller.bracketPairEmphasis == bracketPairEmphasis &&
        controller.useSystemCursor == useSystemCursor &&
        areHighlightProvidersEqual(controller: controller)
    }

    private func areHighlightProvidersEqual(controller: TextViewController) -> Bool {
        controller.highlightProviders.map { ObjectIdentifier($0) } == highlightProviders.map { ObjectIdentifier($0) }
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
        bracketPairEmphasis: BracketPairEmphasis? = nil,
        undoManager: CEUndoManager? = nil,
        coordinators: [any TextViewCoordinator] = []
    ) {

    }

    public var body: some View {
        EmptyView()
    }
}
