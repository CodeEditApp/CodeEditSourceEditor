//
//  STTextViewController.swift
//  CodeEditTextView
//
//  Created by Lukas Pistrol on 24.05.22.
//

import AppKit
import SwiftUI
import Combine
import STTextView
import CodeEditLanguages
import TextFormation

/// A View Controller managing and displaying a `STTextView`
public class STTextViewController: NSViewController, STTextViewDelegate, ThemeAttributesProviding {

    internal var textView: STTextView!

    internal var rulerView: STLineNumberRulerView!

    /// Binding for the `textView`s string
    public var text: Binding<String>

    /// The associated `CodeLanguage`
    public var language: CodeLanguage { didSet {
        // TODO: Decide how to handle errors thrown here
        highlighter?.setLanguage(language: language)
    }}

    /// The associated `Theme` used for highlighting.
    public var theme: EditorTheme { didSet {
        highlighter?.invalidate()
    }}

    /// Whether the code editor should use the theme background color or be transparent
    public var useThemeBackground: Bool

    /// The visual width of tab characters in the text view measured in number of spaces.
    public var tabWidth: Int {
        didSet {
            paragraphStyle = generateParagraphStyle()
            reloadUI()
        }
    }

    /// The behavior to use when the tab key is pressed.
    public var indentOption: IndentOption {
        didSet {
            setUpTextFormation()
        }
    }

    /// A multiplier for setting the line height. Defaults to `1.0`
    public var lineHeightMultiple: Double = 1.0

    /// The font to use in the `textView`
    public var font: NSFont

    /// The current cursor position e.g. (1, 1)
    public var cursorPosition: Binding<(Int, Int)>

    /// The editorOverscroll to use for the textView over scroll
    public var editorOverscroll: Double

    /// Whether lines wrap to the width of the editor
    public var wrapLines: Bool

    /// Whether or not text view is editable by user
    public var isEditable: Bool

    /// Filters used when applying edits..
    internal var textFilters: [TextFormation.Filter] = []

    /// Optional insets to offset the text view in the scroll view by.
    public var contentInsets: NSEdgeInsets?

    /// A multiplier that determines the amount of space between characters. `1.0` indicates no space,
    /// `2.0` indicates one character of space between other characters.
    public var letterSpacing: Double = 1.0 {
        didSet {
            kern = fontCharWidth * (letterSpacing - 1.0)
            reloadUI()
        }
    }

    /// The kern to use for characters. Defaults to `0.0` and is updated when `letterSpacing` is set.
    private var kern: CGFloat = 0.0

    private var fontCharWidth: CGFloat {
        (" " as NSString).size(withAttributes: [.font: font]).width
    }

    // MARK: - Highlighting

    internal var highlighter: Highlighter?

    /// The provided highlight provider.
    internal var highlightProvider: HighlightProviding?

    // MARK: Init

    public init(
        text: Binding<String>,
        language: CodeLanguage,
        font: NSFont,
        theme: EditorTheme,
        tabWidth: Int,
        indentOption: IndentOption,
        lineHeight: Double,
        wrapLines: Bool,
        cursorPosition: Binding<(Int, Int)>,
        editorOverscroll: Double,
        useThemeBackground: Bool,
        highlightProvider: HighlightProviding? = nil,
        contentInsets: NSEdgeInsets? = nil,
        isEditable: Bool,
        letterSpacing: Double
    ) {
        self.text = text
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
        super.init(nibName: nil, bundle: nil)
    }

    required init(coder: NSCoder) {
        fatalError()
    }

    // MARK: VC Lifecycle

    // swiftlint:disable:next function_body_length
    public override func loadView() {
        textView = STTextView()

        let scrollView = CEScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.hasVerticalScroller = true
        scrollView.documentView = textView
        scrollView.drawsBackground = useThemeBackground
        scrollView.automaticallyAdjustsContentInsets = contentInsets == nil
        if let contentInsets = contentInsets {
            scrollView.contentInsets = contentInsets
        }

        rulerView = STLineNumberRulerView(textView: textView, scrollView: scrollView)
        rulerView.backgroundColor = useThemeBackground ? theme.background : .clear
        rulerView.textColor = .secondaryLabelColor
        rulerView.drawSeparator = false
        rulerView.baselineOffset = baselineOffset
        rulerView.font = rulerFont
        rulerView.selectedLineHighlightColor = theme.lineHighlight
        rulerView.rulerInsets = STRulerInsets(leading: rulerFont.pointSize * 1.6, trailing: 8)

        if self.isEditable == false {
            rulerView.selectedLineTextColor = nil
            rulerView.selectedLineHighlightColor = theme.background
        }

        scrollView.verticalRulerView = rulerView
        scrollView.rulersVisible = true

        textView.typingAttributes = attributesFor(nil)
        textView.defaultParagraphStyle = self.paragraphStyle
        textView.font = self.font
        textView.textColor = theme.text
        textView.backgroundColor = useThemeBackground ? theme.background : .clear
        textView.insertionPointColor = theme.insertionPoint
        textView.insertionPointWidth = 1.0
        textView.selectionBackgroundColor = theme.selection
        textView.selectedLineHighlightColor = theme.lineHighlight
        textView.string = self.text.wrappedValue
        textView.isEditable = self.isEditable
        textView.highlightSelectedLine = true
        textView.allowsUndo = true
        textView.setupMenus()
        textView.delegate = self
        textView.highlightSelectedLine = self.isEditable

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

        setUpHighlighter()
        setHighlightProvider(self.highlightProvider)
        setUpTextFormation()

        self.setCursorPosition(self.cursorPosition.wrappedValue)
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        NotificationCenter.default.addObserver(forName: NSWindow.didResizeNotification,
                                               object: nil,
                                               queue: .main) { [weak self] _ in
            guard let self = self else { return }
            (self.view as? NSScrollView)?.contentView.contentInsets.bottom = self.bottomContentInsets
            self.updateTextContainerWidthIfNeeded()
        }

        NotificationCenter.default.addObserver(
            forName: STTextView.didChangeSelectionNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.updateCursorPosition()
        }

        NotificationCenter.default.addObserver(
            forName: NSView.frameDidChangeNotification,
            object: (self.view as? NSScrollView)?.verticalRulerView,
            queue: .main
        ) { [weak self] _ in
            self?.updateTextContainerWidthIfNeeded()
        }
    }

    public override func viewWillAppear() {
        super.viewWillAppear()
        updateTextContainerWidthIfNeeded()
    }

    public func textViewDidChangeText(_ notification: Notification) {
        self.text.wrappedValue = textView.string
    }

    // MARK: UI

    /// A default `NSParagraphStyle` with a set `lineHeight`
    private lazy var paragraphStyle: NSMutableParagraphStyle = generateParagraphStyle()

    private func generateParagraphStyle() -> NSMutableParagraphStyle {
        // swiftlint:disable:next force_cast
        let paragraph = NSParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle
        paragraph.minimumLineHeight = lineHeight
        paragraph.maximumLineHeight = lineHeight
        paragraph.tabStops.removeAll()
        paragraph.defaultTabInterval = CGFloat(tabWidth) * fontCharWidth
        return paragraph
    }

    /// ScrollView's bottom inset using as editor overscroll
    private var bottomContentInsets: CGFloat {
        let height = view.frame.height
        var inset = editorOverscroll * height

        if height - inset < lineHeight {
            inset = height - lineHeight
        }

        return max(inset, .zero)
    }

    /// Reloads the UI to apply changes to ``STTextViewController/font``, ``STTextViewController/theme``, ...
    internal func reloadUI() {
        textView?.textColor = theme.text
        textView.backgroundColor = useThemeBackground ? theme.background : .clear
        textView?.insertionPointColor = theme.insertionPoint
        textView?.selectionBackgroundColor = theme.selection
        textView?.selectedLineHighlightColor = theme.lineHighlight
        textView?.isEditable = isEditable
        textView.highlightSelectedLine = isEditable
        textView?.typingAttributes = attributesFor(nil)
        textView?.defaultParagraphStyle = paragraphStyle

        rulerView?.backgroundColor = useThemeBackground ? theme.background : .clear
        rulerView?.separatorColor = theme.invisibles
        rulerView?.selectedLineHighlightColor = theme.lineHighlight
        rulerView?.baselineOffset = baselineOffset
        rulerView.highlightSelectedLine = isEditable
        rulerView?.rulerInsets = STRulerInsets(leading: rulerFont.pointSize * 1.6, trailing: 8)
        rulerView?.font = rulerFont

        if let scrollView = view as? NSScrollView {
            scrollView.drawsBackground = useThemeBackground
            scrollView.backgroundColor = useThemeBackground ? theme.background : .clear
            if let contentInsets = contentInsets {
                scrollView.contentInsets = contentInsets
            }
            scrollView.contentInsets.bottom = bottomContentInsets + (contentInsets?.bottom ?? 0)
        }

        highlighter?.invalidate()
        updateTextContainerWidthIfNeeded()
    }

    /// Gets all attributes for the given capture including the line height, background color, and text color.
    /// - Parameter capture: The capture to use for syntax highlighting.
    /// - Returns: All attributes to be applied.
    public func attributesFor(_ capture: CaptureName?) -> [NSAttributedString.Key: Any] {
        return [
            .font: font,
            .foregroundColor: theme.colorFor(capture),
            .baselineOffset: baselineOffset,
            .paragraphStyle: paragraphStyle,
            .kern: kern
        ]
    }

    /// Calculated line height depending on ``STTextViewController/lineHeightMultiple``
    internal var lineHeight: Double {
        font.lineHeight * lineHeightMultiple
    }

    /// Calculated baseline offset depending on `lineHeight`.
    internal var baselineOffset: Double {
        ((self.lineHeight) - font.lineHeight) / 2
    }

    // MARK: Selectors

    override public func keyDown(with event: NSEvent) {
        // This should be uneccessary but if removed STTextView receives some `keydown`s twice.
    }

    public override func insertTab(_ sender: Any?) {
        textView.insertText("\t", replacementRange: textView.selectedRange)
    }

    deinit {
        textView = nil
        highlighter = nil
    }
}
