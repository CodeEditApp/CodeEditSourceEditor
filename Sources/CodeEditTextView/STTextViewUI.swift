//
//  STTextViewUI.swift
//  CodeEditTextView
//
//  Created by Lukas Pistrol on 24.05.22.
//

import SwiftUI
import STTextView
import CodeLanguage
import Theme

/// A `SwiftUI` wrapper for a `STTextView`.
public struct STTextViewUI: NSViewControllerRepresentable {

    public init(
        _ text: Binding<String>,
        language: CodeLanguage,
        theme: Binding<Theme>,
        font: Binding<NSFont> = .constant(.monospacedSystemFont(ofSize: 12, weight: .regular)),
        tabWidth: Binding<Int>
    ) {
        self._text = text
        self._font = font
        self._theme = theme
        self._tabWidth = tabWidth
        self.language = language
    }

    @Binding private var tabWidth: Int
    @Binding private var text: String
    @Binding private var font: NSFont
    @Binding private var theme: Theme
    private var language: CodeLanguage


    public typealias NSViewControllerType = STTextViewController

    public func makeNSViewController(context: Context) -> STTextViewController {
        let controller = STTextViewController(
            text: $text,
            language: language,
            font: font,
            theme: theme,
            tabWidth: tabWidth
        )
        return controller
    }

    public func updateNSViewController(_ nsViewController: STTextViewController, context: Context) {
        nsViewController.font = font
        nsViewController.language = language
        nsViewController.theme = theme
        nsViewController.tabWidth = tabWidth
        nsViewController.reloadUI()
        return
    }
}
