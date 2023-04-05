//
//  CodeEditTextView.swift
//  CodeEditTextView
//
//  Created by Lukas Pistrol on 24.05.22.
//

import SwiftUI
import STTextView
import CodeEditLanguages

/// A `SwiftUI` wrapper for a ``STTextViewController``.
public struct CodeEditTextView: NSViewControllerRepresentable {

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
    ///   - editorOverscroll: The percentage for overscroll, between 0-1 (default: `0.0`)
    ///   - cursorPosition: The cursor's position in the editor, measured in `(lineNum, columnNum)`
    ///   - useThemeBackground: Determines whether the editor uses the theme's background color, or a transparent
    ///                         background color
    ///   - highlightProvider: A class you provide to perform syntax highlighting. Leave this as `nil` to use the
    ///                        built-in `TreeSitterClient` highlighter.
    ///   - contentInsets: Insets to use to offset the content in the enclosing scroll view. Leave as `nil` to let the
    ///                    scroll view automatically adjust content insets.
    ///   - isEditable: A Boolean value that controls whether the text view allows the user to edit text.
    ///   - letterSpacing: The amount of space to use between letters, as a percent. Eg: `1.0` = no space, `1.5` = 1/2 a
    ///                    character's width between characters, etc. Defaults to `1.0`
    public init(
        _ text: Binding<String>,
        language: CodeLanguage,
        theme: Binding<EditorTheme>,
        font: Binding<NSFont>,
        tabWidth: Binding<Int>,
        indentOption: Binding<IndentOption> = .constant(.spaces(count: 4)),
        lineHeight: Binding<Double>,
        wrapLines: Binding<Bool>,
        editorOverscroll: Binding<Double> = .constant(0.0),
        cursorPosition: Binding<(Int, Int)>,
        useThemeBackground: Bool = true,
        highlightProvider: HighlightProviding? = nil,
        contentInsets: NSEdgeInsets? = nil,
        isEditable: Bool = true,
        letterSpacing: Double = 0.95
    ) {
        self._text = text
        self.language = language
        self._theme = theme
        self.useThemeBackground = useThemeBackground
        self._font = font
        self._tabWidth = tabWidth
        self._indentOption = indentOption
        self._lineHeight = lineHeight
        self._wrapLines = wrapLines
        self._editorOverscroll = editorOverscroll
        self._cursorPosition = cursorPosition
        self.highlightProvider = highlightProvider
        self.contentInsets = contentInsets
        self.isEditable = isEditable
        self.letterSpacing = letterSpacing
    }

    @Binding private var text: String
    private var language: CodeLanguage
    @Binding private var theme: EditorTheme
    @Binding private var font: NSFont
    @Binding private var tabWidth: Int
    @Binding private var indentOption: IndentOption
    @Binding private var lineHeight: Double
    @Binding private var wrapLines: Bool
    @Binding private var editorOverscroll: Double
    @Binding private var cursorPosition: (Int, Int)
    private var useThemeBackground: Bool
    private var highlightProvider: HighlightProviding?
    private var contentInsets: NSEdgeInsets?
    private var isEditable: Bool
    private var letterSpacing: Double

    public typealias NSViewControllerType = STTextViewController

    public func makeNSViewController(context: Context) -> NSViewControllerType {
        let controller = NSViewControllerType(
            text: $text,
            language: language,
            font: font,
            theme: theme,
            tabWidth: tabWidth,
            indentOption: indentOption,
            lineHeight: lineHeight,
            wrapLines: wrapLines,
            cursorPosition: $cursorPosition,
            editorOverscroll: editorOverscroll,
            useThemeBackground: useThemeBackground,
            highlightProvider: highlightProvider,
            contentInsets: contentInsets,
            isEditable: isEditable,
            letterSpacing: letterSpacing
        )
        return controller
    }

    public func updateNSViewController(_ controller: NSViewControllerType, context: Context) {
        controller.font = font
        controller.wrapLines = wrapLines
        controller.useThemeBackground = useThemeBackground
        controller.lineHeightMultiple = lineHeight
        controller.editorOverscroll = editorOverscroll
        controller.contentInsets = contentInsets

        // Updating the language, theme, tab width and indent option needlessly can cause highlights to be re-calculated
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

        controller.reloadUI()
        return
    }
}
