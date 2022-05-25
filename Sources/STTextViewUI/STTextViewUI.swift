//
//  STTextViewUI.swift
//  
//
//  Created by Lukas Pistrol on 24.05.22.
//

import SwiftUI
import STTextView

public struct STTextViewUI: NSViewControllerRepresentable {

    public init(
        _ text: Binding<String>,
        fontSize: Binding<Double> = .constant(13)
    ) {
        self._text = text
        self._fontSize = fontSize
    }

    @Binding private var text: String
    @Binding private var fontSize: Double

    public typealias NSViewControllerType = STTextViewController

    public func makeNSViewController(context: Context) -> STTextViewController {
        let controller = STTextViewController(text: text)
        controller.font = .monospacedSystemFont(ofSize: fontSize, weight: .regular)
        return controller
    }

    public func updateNSViewController(_ nsViewController: STTextViewController, context: Context) {
        nsViewController.setFontSize(fontSize)
        return
    }
}
