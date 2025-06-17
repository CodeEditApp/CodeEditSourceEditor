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

    // MARK: - Views and Child VCs

    weak var findViewController: FindViewController?

    var scrollView: NSScrollView!
    var textView: TextView!
    var gutterView: GutterView!
    var minimapView: MinimapView!

    /// The reformatting guide view
    var reformattingGuideView: ReformattingGuideView!

    var minimapXConstraint: NSLayoutConstraint?

    var _undoManager: CEUndoManager!
    var systemAppearance: NSAppearance.Name?

    var localEvenMonitor: Any?
    var isPostingCursorNotification: Bool = false

    // MARK: - Public Variables

    /// Passthrough value for the `textView`s string
    public var text: String {
        get {
            textView.string
        }
        set {
            self.setText(newValue)
        }
    }

    /// The associated `CodeLanguage`
    public var language: CodeLanguage {
        didSet {
            highlighter?.setLanguage(language: language)
            setUpTextFormation()
        }
    }

    /// The configuration for the editor, when updated will automatically update the controller to reflect the new
    /// configuration.
    public var config: EditorConfig {
        didSet {
            config.didSetOnController(controller: self, oldConfig: oldValue)
        }
    }

    /// The current cursors' positions ordered by the location of the cursor.
    internal(set) public var cursorPositions: [CursorPosition] = []

    /// The provided highlight provider.
    public var highlightProviders: [HighlightProviding]

    // MARK: - Config Helpers

    /// The font to use in the `textView`
    public var font: NSFont { config.appearance.font }

    /// The  ``EditorTheme`` used for highlighting.
    public var theme: EditorTheme { config.appearance.theme }

    /// The visual width of tab characters in the text view measured in number of spaces.
    public var tabWidth: Int { config.appearance.tabWidth }

    /// The behavior to use when the tab key is pressed.
    public var indentOption: IndentOption { config.behavior.indentOption }

    /// A multiplier for setting the line height. Defaults to `1.0`
    public var lineHeightMultiple: CGFloat { config.appearance.lineHeightMultiple }

    /// Whether lines wrap to the width of the editor
    public var wrapLines: Bool { config.appearance.wrapLines }

    /// The editorOverscroll to use for the textView over scroll
    ///
    /// Measured in a percentage of the view's total height, meaning a `0.3` value will result in overscroll
    /// of 1/3 of the view.
    public var editorOverscroll: CGFloat { config.layout.editorOverscroll }

    /// Whether the code editor should use the theme background color or be transparent
    public var useThemeBackground: Bool { config.appearance.useThemeBackground }

    /// Optional insets to offset the text view and find panel in the scroll view by.
    public var contentInsets: NSEdgeInsets? { config.layout.contentInsets }

    /// An additional amount to inset text by. Horizontal values are ignored.
    ///
    /// This value does not affect decorations like the find panel, but affects things that are relative to text, such
    /// as line numbers and of course the text itself.
    public var additionalTextInsets: NSEdgeInsets? { config.layout.additionalTextInsets }

    /// Whether or not text view is editable by user
    public var isEditable: Bool { config.behavior.isEditable }

    /// Whether or not text view is selectable by user
    public var isSelectable: Bool { config.behavior.isSelectable }

    /// A multiplier that determines the amount of space between characters. `1.0` indicates no space,
    /// `2.0` indicates one character of space between other characters.
    public var letterSpacing: Double { config.appearance.letterSpacing }

    /// The type of highlight to use when highlighting bracket pairs. Leave as `nil` to disable highlighting.
    public var bracketPairEmphasis: BracketPairEmphasis? { config.appearance.bracketPairEmphasis }

    /// The column at which to show the reformatting guide
    public var reformatAtColumn: Int { config.behavior.reformatAtColumn }

    /// If true, uses the system cursor on macOS 14 or greater.
    public var useSystemCursor: Bool { config.appearance.useSystemCursor }

    /// Toggle the visibility of the gutter view in the editor.
    public var showGutter: Bool { config.peripherals.showGutter }

    /// Toggle the visibility of the minimap view in the editor.
    public var showMinimap: Bool { config.peripherals.showMinimap }

    /// Toggle the visibility of the reformatting guide in the editor.
    public var showReformattingGuide: Bool { config.peripherals.showReformattingGuide }

    // MARK: - Internal Variables

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

    /// The trailing inset for the editor. Grows when line wrapping is disabled or when the minimap is shown.
    package var textViewTrailingInset: CGFloat {
        // See https://github.com/CodeEditApp/CodeEditTextView/issues/66
        // wrapLines ? 1 : 48
        (minimapView?.isHidden ?? false) ? 0 : (minimapView?.frame.width ?? 0.0)
    }

    package var textViewInsets: HorizontalEdgeInsets {
        HorizontalEdgeInsets(
            left: showGutter ? gutterView.gutterWidth : 0.0,
            right: textViewTrailingInset
        )
    }

    // MARK: Init

    init(
        string: String,
        language: CodeLanguage,
        config: EditorConfig,
        cursorPositions: [CursorPosition],
        highlightProviders: [HighlightProviding] = [TreeSitterClient()],
        undoManager: CEUndoManager? = nil,
        coordinators: [TextViewCoordinator] = [],
    ) {
        self.language = language
        self.config = config
        self.cursorPositions = cursorPositions
        self.highlightProviders = highlightProviders
        self._undoManager = undoManager

        super.init(nibName: nil, bundle: nil)

        if let idx = highlightProviders.firstIndex(where: { $0 is TreeSitterClient }),
           let client = highlightProviders[idx] as? TreeSitterClient {
            self.treeSitterClient = client
        }

        self.textView = TextView(
            string: string,
            font: font,
            textColor: theme.text.color,
            lineHeightMultiplier: lineHeightMultiple,
            wrapLines: wrapLines,
            isEditable: isEditable,
            isSelectable: isSelectable,
            letterSpacing: letterSpacing,
            useSystemCursor: useSystemCursor,
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

    override public func viewWillAppear() {
        super.viewWillAppear()
        // The calculation this causes cannot be done until the view knows it's final position
        updateTextInsets()
        minimapView.layout()
    }

    deinit {
        if let highlighter {
            textView.removeStorageDelegate(highlighter)
        }
        highlighter = nil
        highlightProviders.removeAll()
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
