//
//  TextViewController.swift
//  CodeEditSourceEditor
//
//  Created by Khan Winter on 6/25/23.
//

import AppKit
import CodeEditTextView
import CodeEditLanguages
import SwiftUI
import Combine
import TextFormation

/// # TextViewController
///
/// A view controller class for managing a source editor. Uses ``CodeEditTextView/TextView`` for input and rendering,
/// tree-sitter for syntax highlighting, and TextFormation for live editing completions.
public class TextViewController: NSViewController {
    // swiftlint:disable:next line_length
    public static let cursorPositionUpdatedNotification: Notification.Name = .init("TextViewController.cursorPositionNotification")

    var scrollView: NSScrollView!
    private(set) public var textView: TextView!
    var gutterView: GutterView!
    internal var _undoManager: CEUndoManager?
    /// Internal reference to any injected layers in the text view.
    internal var highlightLayers: [CALayer] = []
    internal var systemAppearance: NSAppearance.Name?

    package var localEvenMonitor: Any?
    package var isPostingCursorNotification: Bool = false

    /// The string contents.
    public var string: String {
        textView.string
    }

    /// The associated `CodeLanguage`
    public var language: CodeLanguage {
        didSet {
            highlighter?.setLanguage(language: language)
            setUpTextFormation()
        }
    }

    /// The font to use in the `textView`
    public var font: NSFont {
        didSet {
            textView.font = font
            highlighter?.invalidate()
        }
    }

    /// The associated `Theme` used for highlighting.
    public var theme: EditorTheme {
        didSet {
            textView.layoutManager.setNeedsLayout()
            textView.textStorage.setAttributes(
                attributesFor(nil),
                range: NSRange(location: 0, length: textView.textStorage.length)
            )
            textView.selectionManager.selectedLineBackgroundColor = theme.selection
            highlighter?.invalidate()
        }
    }

    /// The visual width of tab characters in the text view measured in number of spaces.
    public var tabWidth: Int {
        didSet {
            paragraphStyle = generateParagraphStyle()
            textView.layoutManager.setNeedsLayout()
            highlighter?.invalidate()
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
            scrollView.hasHorizontalScroller = !wrapLines
        }
    }

    /// The current cursors' positions ordered by the location of the cursor.
    internal(set) public var cursorPositions: [CursorPosition] = []

    /// The editorOverscroll to use for the textView over scroll
    ///
    /// Measured in a percentage of the view's total height, meaning a `0.3` value will result in overscroll
    /// of 1/3 of the view.
    public var editorOverscroll: CGFloat

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

    /// Whether or not text view is selectable by user
    public var isSelectable: Bool {
        didSet {
            textView.isSelectable = isSelectable
        }
    }

    /// A multiplier that determines the amount of space between characters. `1.0` indicates no space,
    /// `2.0` indicates one character of space between other characters.
    public var letterSpacing: Double = 1.0 {
        didSet {
            textView.letterSpacing = letterSpacing
            highlighter?.invalidate()
        }
    }

    /// The type of highlight to use when highlighting bracket pairs. Leave as `nil` to disable highlighting.
    public var bracketPairHighlight: BracketPairHighlight? {
        didSet {
            highlightSelectionPairs()
        }
    }

    /// Passthrough value for the `textView`s string
    public var text: String {
        get {
            textView.string
        }
        set {
            self.setText(newValue)
        }
    }

    /// If true, uses the system cursor on macOS 14 or greater.
    public var useSystemCursor: Bool {
        get {
            textView.useSystemCursor
        }
        set {
            if #available(macOS 14, *) {
                textView.useSystemCursor = newValue
            }
        }
    }

    var textCoordinators: [WeakCoordinator] = []

    var highlighter: Highlighter?

    /// The tree sitter client managed by the source editor.
    ///
    /// This will be `nil` if another highlighter provider is passed to the source editor.
    internal(set) public var treeSitterClient: TreeSitterClient?

    package var fontCharWidth: CGFloat { (" " as NSString).size(withAttributes: [.font: font]).width }

    /// Filters used when applying edits..
    internal var textFilters: [TextFormation.Filter] = []

    internal var cancellables = Set<AnyCancellable>()

    /// ScrollView's bottom inset using as editor overscroll
    package var bottomContentInsets: CGFloat {
        let height = view.frame.height
        var inset = editorOverscroll * height

        if height - inset < font.lineHeight * lineHeightMultiple {
            inset = height - font.lineHeight * lineHeightMultiple
        }

        return max(inset, .zero)
    }

    // MARK: Init

    init(
        string: String,
        language: CodeLanguage,
        font: NSFont,
        theme: EditorTheme,
        tabWidth: Int,
        indentOption: IndentOption,
        lineHeight: CGFloat,
        wrapLines: Bool,
        cursorPositions: [CursorPosition],
        editorOverscroll: CGFloat,
        useThemeBackground: Bool,
        highlightProvider: HighlightProviding?,
        contentInsets: NSEdgeInsets?,
        isEditable: Bool,
        isSelectable: Bool,
        letterSpacing: Double,
        useSystemCursor: Bool,
        bracketPairHighlight: BracketPairHighlight?,
        undoManager: CEUndoManager? = nil,
        coordinators: [TextViewCoordinator] = []
    ) {
        self.language = language
        self.font = font
        self.theme = theme
        self.tabWidth = tabWidth
        self.indentOption = indentOption
        self.lineHeightMultiple = lineHeight
        self.wrapLines = wrapLines
        self.cursorPositions = cursorPositions
        self.editorOverscroll = editorOverscroll
        self.useThemeBackground = useThemeBackground
        self.highlightProvider = highlightProvider
        self.contentInsets = contentInsets
        self.isEditable = isEditable
        self.isSelectable = isSelectable
        self.letterSpacing = letterSpacing
        self.bracketPairHighlight = bracketPairHighlight
        self._undoManager = undoManager

        super.init(nibName: nil, bundle: nil)

        let platformGuardedSystemCursor: Bool
        if #available(macOS 14, *) {
            platformGuardedSystemCursor = useSystemCursor
        } else {
            platformGuardedSystemCursor = false
        }

        self.textView = TextView(
            string: string,
            font: font,
            textColor: theme.text,
            lineHeightMultiplier: lineHeightMultiple,
            wrapLines: wrapLines,
            isEditable: isEditable,
            isSelectable: isSelectable,
            letterSpacing: letterSpacing,
            useSystemCursor: platformGuardedSystemCursor,
            delegate: self
        )

        coordinators.forEach {
            $0.prepareCoordinator(controller: self)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Set the contents of the editor.
    /// - Parameter text: The new contents of the editor.
    public func setText(_ text: String) {
        self.textView.setText(text)
        self.setUpHighlighter()
        self.gutterView.setNeedsDisplay(self.gutterView.frame)
    }

    // MARK: Paragraph Style

    /// A default `NSParagraphStyle` with a set `lineHeight`
    package lazy var paragraphStyle: NSMutableParagraphStyle = generateParagraphStyle()

    // MARK: - Reload UI

    func reloadUI() {
        textView.isEditable = isEditable
        textView.isSelectable = isSelectable

        styleScrollView()
        styleTextView()
        styleGutterView()

        highlighter?.invalidate()
    }

    deinit {
        if let highlighter {
//            textView.removeStorageDelegate(highlighter)
        }
        highlighter = nil
        highlightProvider = nil
        textCoordinators.values().forEach {
            $0.destroy()
        }
        textCoordinators.removeAll()
        NotificationCenter.default.removeObserver(self)
        cancellables.forEach { $0.cancel() }
        if let localEvenMonitor {
            NSEvent.removeMonitor(localEvenMonitor)
        }
        localEvenMonitor = nil
    }
}

extension TextViewController: GutterViewDelegate {
    public func gutterViewWidthDidUpdate(newWidth: CGFloat) {
        gutterView?.frame.size.width = newWidth
        textView?.edgeInsets = HorizontalEdgeInsets(left: newWidth, right: 0)
    }
}
