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
    ///   - useThemeBackground: Whether CodeEditTextView uses theme background color or is transparent
    ///   - font: The default font
    ///   - tabWidth: The tab width
    ///   - lineHeight: The line height multiplier (e.g. `1.2`)
    ///   - wrapLines: Whether lines wrap to the width of the editor
    ///   - editorOverscroll: The percentage for overscroll, between 0-1 (default: `0.0`)
    public init(
        _ text: Binding<String>,
        language: CodeLanguage,
        theme: Binding<EditorTheme>,
        font: Binding<NSFont>,
        tabWidth: Binding<Int>,
        lineHeight: Binding<Double>,
        wrapLines: Binding<Bool>,
        editorOverscroll: Binding<Double> = .constant(0.0),
        cursorPosition: Published<(Int, Int)>.Publisher? = nil,
        useThemeBackground: Bool = true
    ) {
        self._text = text
        self.language = language
        self._theme = theme
        self.useThemeBackground = useThemeBackground
        self._font = font
        self._tabWidth = tabWidth
        self._lineHeight = lineHeight
        self._wrapLines = wrapLines
        self._editorOverscroll = editorOverscroll
        self.cursorPosition = cursorPosition
    }

    @Binding private var text: String
    private var language: CodeLanguage
    @Binding private var theme: EditorTheme
    @Binding private var font: NSFont
    @Binding private var tabWidth: Int
    @Binding private var lineHeight: Double
    @Binding private var wrapLines: Bool
    @Binding private var editorOverscroll: Double
    private var cursorPosition: Published<(Int, Int)>.Publisher?
    private var useThemeBackground: Bool

    public typealias NSViewControllerType = STTextViewController

    public func makeNSViewController(context: Context) -> NSViewControllerType {
        let controller = NSViewControllerType(
            text: $text,
            language: language,
            font: font,
            theme: theme,
            tabWidth: tabWidth,
            wrapLines: wrapLines,
            cursorPosition: cursorPosition,
            editorOverscroll: editorOverscroll,
            useThemeBackground: useThemeBackground
        )
        controller.lineHeightMultiple = lineHeight
        return controller
    }

    public func updateNSViewController(_ controller: NSViewControllerType, context: Context) {
        controller.font = font
        controller.tabWidth = tabWidth
        controller.wrapLines = wrapLines
        controller.useThemeBackground = useThemeBackground
        controller.lineHeightMultiple = lineHeight
        controller.editorOverscroll = editorOverscroll

        // Updating the language and theme needlessly can cause highlights to be re-calculated.
        if controller.language.id != language.id {
            controller.language = language
        }
        if controller.theme != theme {
            controller.theme = theme
        }

        controller.reloadUI()
        return
    }
}
