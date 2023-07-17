//
//  TextViewController.swift
//  
//
//  Created by Khan Winter on 6/25/23.
//

import AppKit

public class TextViewController: NSViewController {
    var scrollView: NSScrollView!
    var textView: TextView!

    public var string: String
    public var font: NSFont
    public var theme: EditorTheme
    public var lineHeight: CGFloat
    public var wrapLines: Bool
    public var editorOverscroll: CGFloat
    public var useThemeBackground: Bool
    public var contentInsets: NSEdgeInsets?
    public var isEditable: Bool
    public var letterSpacing: Double

    init(
        string: String,
        font: NSFont,
        theme: EditorTheme,
        lineHeight: CGFloat,
        wrapLines: Bool,
        editorOverscroll: CGFloat,
        useThemeBackground: Bool,
        contentInsets: NSEdgeInsets?,
        isEditable: Bool,
        letterSpacing: Double
    ) {
        self.string = string
        self.font = font
        self.theme = theme
        self.lineHeight = lineHeight
        self.wrapLines = wrapLines
        self.editorOverscroll = editorOverscroll
        self.useThemeBackground = useThemeBackground
        self.contentInsets = contentInsets
        self.isEditable = isEditable
        self.letterSpacing = letterSpacing
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func loadView() {
        scrollView = NSScrollView()
        textView = TextView(
            string: string,
            font: font,
            theme: theme,
            lineHeight: lineHeight,
            wrapLines: wrapLines,
            editorOverscroll: editorOverscroll,
            useThemeBackground: useThemeBackground,
            contentInsets: contentInsets,
            isEditable: isEditable,
            letterSpacing: letterSpacing
        )
        textView.translatesAutoresizingMaskIntoConstraints = false

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.contentView.postsFrameChangedNotifications = true
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalRuler = true
        scrollView.documentView = textView
        if let contentInsets {
            scrollView.automaticallyAdjustsContentInsets = false
            scrollView.contentInsets = contentInsets
        }

        self.view = scrollView

        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        NotificationCenter.default.addObserver(
            forName: NSView.frameDidChangeNotification,
            object: scrollView.contentView,
            queue: .main
        ) { _ in
            self.textView.updateFrameIfNeeded()
        }
    }
}
