//
//  TextViewController.swift
//  
//
//  Created by Khan Winter on 6/25/23.
//

import AppKit
import CodeEditInputView
import CodeEditLanguages
import SwiftUI
import Common
import Combine
import TextFormation

public class TextViewController: NSViewController {
    var scrollView: NSScrollView!
    var textView: TextView!
    var gutterView: GutterView!
    /// Internal reference to any injected layers in the text view.
    internal var highlightLayers: [CALayer] = []
    private var systemAppearance: NSAppearance.Name?

    /// Binding for the `textView`s string
    public var string: Binding<String>

    /// The associated `CodeLanguage`
    public var language: CodeLanguage {
        didSet {
            highlighter?.setLanguage(language: language)
        }
    }

    /// The font to use in the `textView`
    public var font: NSFont {
        didSet {
            textView.font = font
        }
    }

    /// The associated `Theme` used for highlighting.
    public var theme: EditorTheme {
        didSet {
            highlighter?.invalidate()
        }
    }

    /// The visual width of tab characters in the text view measured in number of spaces.
    public var tabWidth: Int {
        didSet {
            paragraphStyle = generateParagraphStyle()
        }
    }

    /// The behavior to use when the tab key is pressed.
    public var indentOption: IndentOption {
        didSet {
            setUpTextFormation()
        }
    }

    /// A multiplier for setting the line height. Defaults to `1.0`
    public var lineHeightMultiple: CGFloat {
        didSet {
            textView.layoutManager.lineHeightMultiplier = lineHeightMultiple
        }
    }

    /// Whether lines wrap to the width of the editor
    public var wrapLines: Bool {
        didSet {
            textView.layoutManager.wrapLines = wrapLines
        }
    }

    /// The current cursor position e.g. (1, 1)
    public var cursorPosition: Binding<(Int, Int)>

    /// The height to overscroll the textview by.
    public var editorOverscroll: CGFloat {
        didSet {
            textView.editorOverscroll = editorOverscroll
        }
    }

    /// Whether the code editor should use the theme background color or be transparent
    public var useThemeBackground: Bool

    /// The provided highlight provider.
    public var highlightProvider: HighlightProviding?

    /// Optional insets to offset the text view in the scroll view by.
    public var contentInsets: NSEdgeInsets?

    /// Whether or not text view is editable by user
    public var isEditable: Bool {
        didSet {
            textView.isEditable = isEditable
        }
    }

    /// A multiplier that determines the amount of space between characters. `1.0` indicates no space,
    /// `2.0` indicates one character of space between other characters.
    public var letterSpacing: Double = 1.0 {
        didSet {
            textView.letterSpacing = letterSpacing
        }
    }

    /// The type of highlight to use when highlighting bracket pairs. Leave as `nil` to disable highlighting.
    public var bracketPairHighlight: BracketPairHighlight? {
        didSet {
            highlightSelectionPairs()
        }
    }

    internal var storageDelegate: MultiStorageDelegate!
    internal var highlighter: Highlighter?

    private var fontCharWidth: CGFloat { (" " as NSString).size(withAttributes: [.font: font]).width }

    /// Filters used when applying edits..
    internal var textFilters: [TextFormation.Filter] = []

    /// The pixel value to overscroll the bottom of the editor.
    /// Calculated as the line height \* ``TextViewController/editorOverscroll``.
    /// Does not include ``TextViewController/contentInsets``.
    private var bottomContentInset: CGFloat { (textView?.estimatedLineHeight() ?? 0) * CGFloat(editorOverscroll) }

    private var cancellables = Set<AnyCancellable>()

    // MARK: Init

    init(
        string: Binding<String>,
        language: CodeLanguage,
        font: NSFont,
        theme: EditorTheme,
        tabWidth: Int,
        indentOption: IndentOption,
        lineHeight: CGFloat,
        wrapLines: Bool,
        cursorPosition: Binding<(Int, Int)>,
        editorOverscroll: CGFloat,
        useThemeBackground: Bool,
        highlightProvider: HighlightProviding?,
        contentInsets: NSEdgeInsets?,
        isEditable: Bool,
        letterSpacing: Double,
        bracketPairHighlight: BracketPairHighlight?
    ) {
        self.string = string
        self.language = language
        self.font = font
        self.theme = theme
        self.tabWidth = tabWidth
        self.indentOption = indentOption
        self.lineHeightMultiple = lineHeight
        self.wrapLines = wrapLines
        self.cursorPosition = cursorPosition
        self.editorOverscroll = editorOverscroll
        self.useThemeBackground = useThemeBackground
        self.highlightProvider = highlightProvider
        self.contentInsets = contentInsets
        self.isEditable = isEditable
        self.letterSpacing = letterSpacing
        self.bracketPairHighlight = bracketPairHighlight

        self.storageDelegate = MultiStorageDelegate()

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Paragraph Style

    /// A default `NSParagraphStyle` with a set `lineHeight`
    internal lazy var paragraphStyle: NSMutableParagraphStyle = generateParagraphStyle()

    private func generateParagraphStyle() -> NSMutableParagraphStyle {
        // swiftlint:disable:next force_cast
        let paragraph = NSParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle
        paragraph.tabStops.removeAll()
        paragraph.defaultTabInterval = CGFloat(tabWidth) * fontCharWidth
        return paragraph
    }

    // MARK: Load View

    // swiftlint:disable:next function_body_length
    override public func loadView() {
        scrollView = NSScrollView()
        textView = TextView(
            string: string.wrappedValue,
            font: font,
            textColor: theme.text,
            lineHeight: lineHeightMultiple,
            wrapLines: wrapLines,
            editorOverscroll: bottomContentInset,
            isEditable: isEditable,
            letterSpacing: letterSpacing,
            delegate: self,
            storageDelegate: storageDelegate
        )
        textView.postsFrameChangedNotifications = true
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.selectionManager.insertionPointColor = theme.insertionPoint

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.contentView.postsFrameChangedNotifications = true
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = true
        scrollView.documentView = textView
        scrollView.contentView.postsBoundsChangedNotifications = true
        if let contentInsets {
            scrollView.automaticallyAdjustsContentInsets = false
            scrollView.contentInsets = contentInsets
        }

        gutterView = GutterView(
            font: font.rulerFont,
            textColor: .secondaryLabelColor,
            textView: textView,
            delegate: self
        )
        gutterView.frame.origin.y = -scrollView.contentInsets.top
        gutterView.updateWidthIfNeeded()
        scrollView.addFloatingSubview(
            gutterView,
            for: .horizontal
        )

        self.view = scrollView
        setUpHighlighter()

        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        // Layout on scroll change
        NotificationCenter.default.addObserver(
            forName: NSView.boundsDidChangeNotification,
            object: scrollView.contentView,
            queue: .main
        ) { [weak self] _ in
            self?.textView.updatedViewport(self?.scrollView.documentVisibleRect ?? .zero)
            self?.gutterView.needsDisplay = true
        }

        // Layout on frame change
        NotificationCenter.default.addObserver(
            forName: NSView.frameDidChangeNotification,
            object: scrollView.contentView,
            queue: .main
        ) { [weak self] _ in
            self?.textView.updatedViewport(self?.scrollView.documentVisibleRect ?? .zero)
            self?.gutterView.needsDisplay = true
            if self?.bracketPairHighlight == .flash {
                self?.removeHighlightLayers()
            }
        }

        NotificationCenter.default.addObserver(
            forName: NSView.frameDidChangeNotification,
            object: textView,
            queue: .main
        ) { [weak self] _ in
            self?.gutterView.frame.size.height = (self?.textView.frame.height ?? 0) + 10
            self?.gutterView.needsDisplay = true
        }

        NotificationCenter.default.addObserver(
            forName: TextSelectionManager.selectionChangedNotification,
            object: textView.selectionManager,
            queue: .main
        ) { [weak self] _ in
            self?.updateCursorPosition()
            self?.highlightSelectionPairs()
        }

        textView.updateFrameIfNeeded()

        NSApp.publisher(for: \.effectiveAppearance)
            .receive(on: RunLoop.main)
            .sink { [weak self] newValue in
                guard let self = self else { return }

                if self.systemAppearance != newValue.name {
                    self.systemAppearance = newValue.name
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Reload UI

    func reloadUI() {
        textView.isEditable = isEditable
        textView.editorOverscroll = bottomContentInset

        textView.selectionManager.selectionBackgroundColor = theme.selection
        textView.selectionManager.selectedLineBackgroundColor = useThemeBackground
        ? theme.lineHighlight
        : systemAppearance == .darkAqua
        ? NSColor.quaternaryLabelColor : NSColor.selectedTextBackgroundColor.withSystemEffect(.disabled)
        textView.selectionManager.highlightSelectedLine = isEditable
        textView.selectionManager.insertionPointColor = theme.insertionPoint
        paragraphStyle = generateParagraphStyle()
        textView.typingAttributes = attributesFor(nil)

        gutterView.selectedLineColor = useThemeBackground ? theme.lineHighlight : systemAppearance == .darkAqua
        ? NSColor.quaternaryLabelColor
        : NSColor.selectedTextBackgroundColor.withSystemEffect(.disabled)
        gutterView.highlightSelectedLines = isEditable
        gutterView.font = font.rulerFont
        gutterView.backgroundColor = theme.background
        if self.isEditable == false {
            gutterView.selectedLineTextColor = nil
            gutterView.selectedLineColor = .clear
        }

        if let scrollView = view as? NSScrollView {
            scrollView.drawsBackground = useThemeBackground
            scrollView.backgroundColor = useThemeBackground ? theme.background : .clear
            if let contentInsets = contentInsets {
                scrollView.contentInsets = contentInsets
            }
            scrollView.contentInsets.bottom = bottomContentInset + (contentInsets?.bottom ?? 0)
        }

        highlighter?.invalidate()
    }

    deinit {
        highlighter = nil
        highlightProvider = nil
        storageDelegate = nil
        NotificationCenter.default.removeObserver(self)
        cancellables.forEach { $0.cancel() }
    }
}

extension TextViewController: TextViewDelegate {
    public func textView(_ textView: TextView, didReplaceContentsIn range: NSRange, with: String) {
        gutterView.needsDisplay = true
    }
}

extension TextViewController: GutterViewDelegate {
    public func gutterViewWidthDidUpdate(newWidth: CGFloat) {
        gutterView?.frame.size.width = newWidth
        textView?.edgeInsets.left = newWidth
    }
}
