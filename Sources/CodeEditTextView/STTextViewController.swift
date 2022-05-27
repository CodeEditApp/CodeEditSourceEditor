//
//  STTextViewController.swift
//
//
//  Created by Lukas Pistrol on 24.05.22.
//

import AppKit
import STTextView
import CodeLanguage
import SwiftTreeSitter

final public class STTextViewController: NSViewController {

    private var textView: STTextView!
    public var text: String { didSet {
        self.textView?.string = text
    }}
    private var language: CodeLanguage

    private var parser: Parser?
    private var query: Query?
    private var tree: Tree?

    public var font: NSFont = .monospacedSystemFont(ofSize: 14, weight: .regular) {
        didSet { update() }
    }
    public var lineHeight: Double = 1.1
    public var tabInterval: Double = 28

    init(text: String, language: CodeLanguage) {
        self.text = text
        self.language = language
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

    public override func viewDidLoad() {
        super.viewDidLoad()
        setupTreeSitter()
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

    // MARK: Key Presses
    
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

// MARK: - STTextViewDelegate

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
        highlight()
    }
}

// MARK: - Tree Sitter

extension STTextViewController {
    private func setupTreeSitter() {
        DispatchQueue.global(qos: .userInitiated).async {
            self.parser = Parser()
            guard let lang = self.language.language else { return }
            try? self.parser?.setLanguage(lang)

            let start = CFAbsoluteTimeGetCurrent()
            self.query = TreeSitterModel.shared.query(for: self.language.id)
            let end = CFAbsoluteTimeGetCurrent()
            print("Fetching Query for \(self.language.displayName): \(end-start) seconds")
            DispatchQueue.main.async {
                self.highlight()
            }
        }
    }

    private func highlight() {
        guard let parser = parser,
              let text = textView?.string,
              let tree = parser.parse(text),
              let cursor = query?.execute(node: tree.rootNode!, in: tree)
        else { return }

        if let expr = tree.rootNode?.sExpressionString,
           expr.contains("ERROR") { return }

        while let match = cursor.next() {
//            print("match: ", match)
            self.highlightCaptures(match.captures)
            self.highlightCaptures(for: match.predicates, in: match)
        }
    }

    private func highlightCaptures(_ captures: [QueryCapture]) {
        captures.forEach { capture in
            // DEBUG only:
            //            printCaptureInfo(capture)
            textView?.addAttributes([
                .foregroundColor: colorForCapture(capture.name),
                .font: NSFont.monospacedSystemFont(ofSize: 14, weight: .medium)
            ], range: capture.node.range)
        }
    }

    private func highlightCaptures(for predicates: [Predicate], in match: QueryMatch) {
        predicates.forEach { predicate in
            predicate.captures(in: match).forEach { capture in
                //                print(capture.name, string[capture.node.range])
                textView?.addAttributes(
                    [
                        .foregroundColor: colorForCapture(capture.name?.appending("_alternate")),
                        .font: NSFont.monospacedSystemFont(ofSize: 14, weight: .medium)
                    ],
                    range: capture.node.range
                )
            }
        }
    }

    private func colorForCapture(_ capture: String?) -> NSColor {
        switch capture {
        case "include", "constructor", "keyword", "boolean", "variable.builtin", "keyword.return", "keyword.function", "repeat", "conditional": return .magenta
        case "comment": return .systemGreen
        case "variable", "property": return .systemTeal
        case "function", "method": return .systemMint
        case "number", "float": return .systemYellow
        case "string": return .systemRed
        case "type": return .systemPurple
        case "parameter": return .systemTeal
        case "type_alternate": return .systemCyan
        default: return .textColor
        }
    }
}
