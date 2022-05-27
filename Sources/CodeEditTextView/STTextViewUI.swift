//
//  STTextViewUI.swift
//  
//
//  Created by Lukas Pistrol on 24.05.22.
//

import SwiftUI
import STTextView
import CodeLanguage

public struct STTextViewUI: NSViewControllerRepresentable {

    public init(
        _ text: Binding<String>,
        language: CodeLanguage,
        fontSize: Binding<Double> = .constant(13)
    ) {
        self._text = text
        self._fontSize = fontSize
        self.language = language
    }

    @Binding private var text: String
    @Binding private var fontSize: Double
    private var language: CodeLanguage


    public typealias NSViewControllerType = STTextViewController

    public func makeNSViewController(context: Context) -> STTextViewController {
        let controller = STTextViewController(text: text, language: language)
        controller.font = .monospacedSystemFont(ofSize: fontSize, weight: .regular)
        return controller
    }

    public func updateNSViewController(_ nsViewController: STTextViewController, context: Context) {
        nsViewController.setFontSize(fontSize)
        nsViewController.text = text
        nsViewController.
        return
    }
}
