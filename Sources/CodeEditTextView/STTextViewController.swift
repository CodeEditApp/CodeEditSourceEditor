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
import SwiftTreeSitter
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

    /// The number of spaces to use for a `tab '\t'` character
    public var tabWidth: Int

    /// A multiplier for setting the line height. Defaults to `1.0`
    public var lineHeightMultiple: Double = 1.0

    /// The font to use in the `textView`
    public var font: NSFont

    /// The editorOverscroll to use for the textView over scroll
    public var editorOverscroll: Double

    /// Whether lines wrap to the width of the editor
    public var wrapLines: Bool

    /// Filters used when applying edits..
    internal var textFilters: [TextFormation.Filter] = []

    /// Optional insets to offset the text view in the scroll view by.
    public var contentInsets: NSEdgeInsets?

    // MARK: - Highlighting

    internal var highlighter: Highlighter?

    /// Internal variable for tracking whether or not the textView has the correct standard attributes.
    private var hasSetStandardAttributes: Bool = false

    /// The provided highlight provider.
    private var highlightProvider: HighlightProviding?

    // MARK: Init

    public init(
        text: Binding<String>,
        language: CodeLanguage,
        font: NSFont,
        theme: EditorTheme,
        tabWidth: Int,
        wrapLines: Bool,
        cursorPosition: Published<(Int, Int)>.Publisher? = nil,
        editorOverscroll: Double,
        useThemeBackground: Bool,
        highlightProvider: HighlightProviding? = nil,
        contentInsets: NSEdgeInsets? = nil
    ) {
        self.text = text
        self.language = language
        self.font = font
        self.theme = theme
        self.tabWidth = tabWidth
        self.wrapLines = wrapLines
        self.cursorPosition = cursorPosition
        self.editorOverscroll = editorOverscroll
        self.useThemeBackground = useThemeBackground
        self.highlightProvider = highlightProvider
        self.contentInsets = contentInsets
        super.init(nibName: nil, bundle: nil)
    }

    required init(coder: NSCoder) {
        fatalError()
    }

    // MARK: VC Lifecycle

    // swiftlint:disable function_body_length
    public override func loadView() {
        textView = STTextView()

        let scrollView = NSScrollView()
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
        rulerView.textColor = .systemGray
        rulerView.drawSeparator = false
        rulerView.baselineOffset = baselineOffset
        rulerView.font = NSFont.monospacedDigitSystemFont(ofSize: 9.5, weight: .regular)
        scrollView.verticalRulerView = rulerView
        scrollView.rulersVisible = true

        textView.defaultParagraphStyle = self.paragraphStyle
        textView.font = self.font
        textView.textColor = theme.text
        textView.backgroundColor = useThemeBackground ? theme.background : .clear
        textView.insertionPointColor = theme.insertionPoint
        textView.insertionPointWidth = 1.0
        textView.selectionBackgroundColor = theme.selection
        textView.selectedLineHighlightColor = theme.lineHighlight
        textView.string = self.text.wrappedValue
        textView.widthTracksTextView = self.wrapLines
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

        setUpHighlighter()
        setHighlightProvider(self.highlightProvider)
        setUpTextFormation()

        self.cursorPositionCancellable = self.cursorPosition?.sink(receiveValue: { value in
            self.setCursorPosition(value)
        })
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        NotificationCenter.default.addObserver(forName: NSWindow.didResizeNotification,
                                               object: nil,
                                               queue: .main) { [weak self] _ in
            guard let self = self else { return }
            (self.view as? NSScrollView)?.contentView.contentInsets.bottom = self.bottomContentInsets
        }
    }

    public override func viewDidAppear() {
        super.viewDidAppear()
    }

    public func textDidChange(_ notification: Notification) {
        self.text.wrappedValue = textView.string
    }

    // MARK: UI

    /// A default `NSParagraphStyle` with a set `lineHeight`
    private var paragraphStyle: NSMutableParagraphStyle {
        // swiftlint:disable:next force_cast
        let paragraph = NSParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle
        paragraph.minimumLineHeight = lineHeight
        paragraph.maximumLineHeight = lineHeight
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
        // if font or baseline has been modified, set the hasSetStandardAttributesFlag
        // to false to ensure attributes are updated. This allows live UI updates when changing preferences.
        if textView?.font != font || rulerView.baselineOffset != baselineOffset {
            hasSetStandardAttributes = false
        }

        textView?.textColor = theme.text
        textView.backgroundColor = useThemeBackground ? theme.background : .clear
        textView?.insertionPointColor = theme.insertionPoint
        textView?.selectionBackgroundColor = theme.selection
        textView?.selectedLineHighlightColor = theme.lineHighlight

        rulerView?.backgroundColor = useThemeBackground ? theme.background : .clear
        rulerView?.separatorColor = theme.invisibles
        rulerView?.baselineOffset = baselineOffset

        if let view = view as? NSScrollView {
            view.drawsBackground = useThemeBackground
            view.backgroundColor = useThemeBackground ? theme.background : .clear
            if let contentInsets = contentInsets {
                view.contentInsets = contentInsets
            }
            view.contentView.contentInsets.bottom = bottomContentInsets + (contentInsets?.bottom ?? 0)
        }

        setStandardAttributes()
    }

    /// Sets the standard attributes (`font`, `baselineOffset`) to the whole text
    internal func setStandardAttributes() {
        guard let textView = textView else { return }
        guard !hasSetStandardAttributes else { return }
        hasSetStandardAttributes = true
        textView.addAttributes(attributesFor(nil), range: .init(0..<textView.string.count))
        highlighter?.invalidate()
    }

    /// Gets all attributes for the given capture including the line height, background color, and text color.
    /// - Parameter capture: The capture to use for syntax highlighting.
    /// - Returns: All attributes to be applied.
    public func attributesFor(_ capture: CaptureName?) -> [NSAttributedString.Key: Any] {
        return [
            .font: font,
            .foregroundColor: theme.colorFor(capture),
            .baselineOffset: baselineOffset
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

    // MARK: - Highlighting

    /// Configures the `Highlighter` object
    private func setUpHighlighter() {
        self.highlighter = Highlighter(textView: textView,
                                       highlightProvider: highlightProvider,
                                       theme: theme,
                                       attributeProvider: self,
                                       language: language)
    }

    /// Sets the highlight provider and re-highlights all text. This method should be used sparingly.
    public func setHighlightProvider(_ highlightProvider: HighlightProviding? = nil) {
        var provider: HighlightProviding?

        if let highlightProvider = highlightProvider {
            provider = highlightProvider
        } else {
            let textProvider: ResolvingQueryCursor.TextProvider = { [weak self] range, _ -> String? in
                return self?.textView.textContentStorage.textStorage?.mutableString.substring(with: range)
            }

            provider = try? TreeSitterClient(codeLanguage: language, textProvider: textProvider)
        }

        if let provider = provider {
            self.highlightProvider = provider
            highlighter?.setHighlightProvider(provider)
        }
    }

    // MARK: Key Presses

    /// Handles `keyDown` events in the `textView`
    override public func keyDown(with event: NSEvent) {
        // TODO: - This should be uncessecary
    }

    // MARK: Cursor Position

    private var cursorPosition: Published<(Int, Int)>.Publisher?
    private var cursorPositionCancellable: AnyCancellable?

    private func setCursorPosition(_ position: (Int, Int)) {
        guard let provider = textView.textLayoutManager.textContentManager else {
            return
        }

        var (line, column) = position
        let string = textView.string
        if line > 0 {
            string.enumerateSubstrings(in: string.startIndex..<string.endIndex) { _, lineRange, _, done in
                line -= 1
                if line < 1 {
                    // If `column` exceeds the line length, set cursor to the end of the line.
                    let index = min(lineRange.upperBound, string.index(lineRange.lowerBound, offsetBy: column - 1))
                    if let newRange = NSTextRange(NSRange(index..<index, in: string), provider: provider) {
                        self.textView.setSelectedRange(newRange)
                    }
                    done = true
                } else {
                    done = false
                }
            }
        }
    }

    deinit {
        textView = nil
        highlighter = nil
    }
}
