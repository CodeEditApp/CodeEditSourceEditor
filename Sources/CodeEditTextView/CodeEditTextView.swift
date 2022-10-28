//
//  CodeEditTextView.swift
//  CodeEditTextView
//
//  Created by Lukas Pistrol on 24.05.22.
//

import SwiftUI
import STTextView

/// A `SwiftUI` wrapper for a ``STTextViewController``.
public struct CodeEditTextView: NSViewControllerRepresentable {

    /// Initializes a Text Editor
    /// - Parameters:
    ///   - text: The text content
    ///   - language: The language for syntax highlighting
    ///   - theme: The theme for syntax highlighting
    ///   - font: The default font
    ///   - tabWidth: The tab width
    ///   - lineHeight: The line height multiplier (e.g. `1.2`)
    public init(
        _ text: Binding<String>,
        language: CodeLanguage,
        theme: Binding<EditorTheme>,
        font: Binding<NSFont>,
        tabWidth: Binding<Int>,
        lineHeight: Binding<Double>,
        cursorPosition: Published<(Int, Int)>.Publisher? = nil
    ) {
        self._text = text
        self.language = language
        self._theme = theme
        self._font = font
        self._tabWidth = tabWidth
        self._lineHeight = lineHeight
        self.cursorPosition = cursorPosition
    }

    @Binding private var text: String
    private var language: CodeLanguage
    @Binding private var theme: EditorTheme
    @Binding private var font: NSFont
    @Binding private var tabWidth: Int
    @Binding private var lineHeight: Double
    private var cursorPosition: Published<(Int, Int)>.Publisher?

    public typealias NSViewControllerType = STTextViewController

    public func makeNSViewController(context: Context) -> NSViewControllerType {
        let controller = NSViewControllerType(
            text: $text,
            language: language,
            font: font,
            theme: theme,
            tabWidth: tabWidth,
            cursorPosition: cursorPosition
        )
        controller.lineHeightMultiple = lineHeight
        return controller
    }

    public func updateNSViewController(_ controller: NSViewControllerType, context: Context) {
        controller.font = font
        controller.language = language
        controller.theme = theme
        controller.tabWidth = tabWidth
        controller.lineHeightMultiple = lineHeight
        controller.reloadUI()
        return
    }
}
