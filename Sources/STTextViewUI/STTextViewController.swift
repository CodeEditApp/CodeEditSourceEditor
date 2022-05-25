//
//  STTextViewController.swift
//
//
//  Created by Lukas Pistrol on 24.05.22.
//

import AppKit
import STTextView

final public class STTextViewController: NSViewController {

    private var textView: STTextView!
    private var text: String

    public var font: NSFont = .monospacedSystemFont(ofSize: 14, weight: .regular) {
        didSet { update() }
    }
    public var lineHeight: Double = 1.1
    public var tabInterval: Double = 28

    init(text: String) {
        self.text = text
        super.init(nibName: nil, bundle: nil)
    }
    
    required init(coder: NSCoder) {
        fatalError()
    }

    public override func loadView() {
        let scrollView = STTextView.scrollableTextView()
        textView = scrollView.documentView as? STTextView
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.hasVerticalScroller = true
        scrollView.verticalRulerView = STLineNumberRulerView(textView: textView, scrollView: scrollView)
        scrollView.rulersVisible = true

        textView.defaultParagraphStyle = paragraphStyle()
        textView.font = self.font
        textView.textColor = .textColor
        textView.backgroundColor = .textBackgroundColor
        textView.string = self.text
        textView.widthTracksTextView = true
        textView.highlightSelectedLine = true
        textView.allowsUndo = true
        textView.setupMenus()
        textView.delegate = self

        scrollView.documentView = textView

        self.view = scrollView

        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            self.keyDown(with: event)
            return event
        }

        NSEvent.addLocalMonitorForEvents(matching: .keyUp) { event in
            self.keyUp(with: event)
            return event
        }
    }

    private func paragraphStyle() -> NSMutableParagraphStyle {
        let paragraph = NSParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle
        paragraph.lineHeightMultiple = self.lineHeight
        paragraph.defaultTabInterval = self.tabInterval
        return paragraph
    }

    private func update() {
        textView?.font = font
//        textView?.textColor = .textColor
//        textView?.backgroundColor = .textBackgroundColor

        textView?.addAttributes([
            .font: font
        ], range: .init(0..<text.count))
    }

    public func setFontSize(_ size: Double) {
        self.font = .monospacedSystemFont(ofSize: size, weight: .regular)
    }


    private var keyIsDown: Bool = false

    override public func keyDown(with event: NSEvent) {
        if keyIsDown { return }
        keyIsDown = true

        // handle tab insertation
        if event.specialKey == .tab {
            textView?.insertText(String(repeating: " ", count: 4))
        }
        print(event.keyCode)
    }

    override public func keyUp(with event: NSEvent) {
        keyIsDown = false
    }
}

extension STTextViewController: STTextViewDelegate {
    
    public func textDidChange(_ notification: Notification) {
        print("Text did change")
    }

    public func textView(_ textView: STTextView, shouldChangeTextIn affectedCharRange: NSTextRange, replacementString: String?) -> Bool {
        // Don't add '\t' characters
        if replacementString == "\t" {
            return false
        }
        return true
    }

    public func textView(_ textView: STTextView, didChangeTextIn affectedCharRange: NSTextRange, replacementString: String) {
        textView.autocompleteSymbols(replacementString)
        print("Did change text in \(affectedCharRange) | \(replacementString)")
    }
}
