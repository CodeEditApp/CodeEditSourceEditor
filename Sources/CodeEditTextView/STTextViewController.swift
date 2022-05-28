//
//  STTextViewController.swift
//  CodeEditTextView
//
//  Created by Lukas Pistrol on 24.05.22.
//

import AppKit
import SwiftUI
import STTextView
import CodeLanguage
import SwiftTreeSitter
import Theme

public class STTextViewController: NSViewController, STTextViewDelegate {

    internal var textView: STTextView!

    internal var rulerView: STLineNumberRulerView!

    public var text: Binding<String>

    public var language: CodeLanguage { didSet {
        self.setupTreeSitter()
    }}

    public var theme: Theme { didSet {
        highlight()
    }}

    public var tabWidth: Int

    public var lineHeightMultiple: Double = 1.0

    public var font: NSFont

    // MARK: Tree-Sitter

    internal var parser: Parser?
    internal var query: Query?
    internal var tree: Tree?

    // MARK: Init

    init(text: Binding<String>, language: CodeLanguage, font: NSFont, theme: Theme, tabWidth: Int) {
        self.text = text
        self.language = language
        self.font = font
        self.theme = theme
        self.tabWidth = tabWidth
        super.init(nibName: nil, bundle: nil)
    }
    
    required init(coder: NSCoder) {
        fatalError()
    }

    // MARK: VC Lifecycle

    public override func loadView() {
        let scrollView = STTextView.scrollableTextView()
        textView = scrollView.documentView as? STTextView

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.hasVerticalScroller = true

        rulerView = STLineNumberRulerView(textView: textView, scrollView: scrollView)
        rulerView.backgroundColor = theme.editor.background.nsColor
        rulerView.textColor = .systemGray
        rulerView.separatorColor = theme.editor.invisibles.nsColor
        rulerView.baselineOffset = baselineOffset

        scrollView.verticalRulerView = rulerView
        scrollView.rulersVisible = true

        textView.defaultParagraphStyle = self.paragraphStyle
        textView.font = self.font
        textView.textColor = theme.editor.text.nsColor
        textView.backgroundColor = theme.editor.background.nsColor
        textView.insertionPointColor = theme.editor.insertionPoint.nsColor
        textView.selectionBackgroundColor = theme.editor.selection.nsColor
        textView.selectedLineHighlightColor = theme.editor.lineHighlight.nsColor
        textView.string = self.text.wrappedValue
        textView.widthTracksTextView = true
        textView.highlightSelectedLine = true
        textView.allowsUndo = true
        textView.setupMenus()
        textView.delegate = self

        scrollView.documentView = textView

        scrollView.translatesAutoresizingMaskIntoConstraints = false

        self.view = scrollView

        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

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

    // MARK: UI

    private var paragraphStyle: NSMutableParagraphStyle {
        let paragraph = NSParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle
        paragraph.minimumLineHeight = lineHeight
        return paragraph
    }

    internal func reloadUI() {
        textView?.font = font
        textView?.textColor = theme.editor.text.nsColor
        textView?.backgroundColor = theme.editor.background.nsColor
        textView?.insertionPointColor = theme.editor.insertionPoint.nsColor
        textView?.selectionBackgroundColor = theme.editor.selection.nsColor
        textView?.selectedLineHighlightColor = theme.editor.lineHighlight.nsColor

        rulerView?.backgroundColor = theme.editor.background.nsColor
        rulerView?.separatorColor = theme.editor.invisibles.nsColor
        rulerView?.baselineOffset = baselineOffset

        setStandardAttributes()
    }

    internal func setStandardAttributes() {
        guard let textView = textView else { return }
        textView.addAttributes([
            .font: font,
            .baselineOffset: baselineOffset
        ], range: .init(0..<textView.string.count))
    }

    internal var lineHeight: Double {
        font.lineHeight * 1.5
    }

    internal var baselineOffset: Double {
        ((self.lineHeight) - font.lineHeight) / 2
    }

    // MARK: Key Presses
    
    private var keyIsDown: Bool = false

    override public func keyDown(with event: NSEvent) {
        if keyIsDown { return }
        keyIsDown = true

        // handle tab insertation
        if event.specialKey == .tab {
            textView?.insertText(String(repeating: " ", count: tabWidth))
        }
//        print(event.keyCode)
    }

    override public func keyUp(with event: NSEvent) {
        keyIsDown = false
    }
}
