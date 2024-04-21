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
/// 
public class TextViewController: NSViewController {

    // swiftlint:disable:next line_length
    public static let cursorPositionUpdatedNotification: Notification.Name = .init("TextViewController.cursorPositionNotification")

    var scrollView: NSScrollView!
    var textView: TextView!
    var gutterView: GutterView!
    internal var _undoManager: CEUndoManager?
    /// Internal reference to any injected layers in the text view.
    internal var highlightLayers: [CALayer] = []
    internal var systemAppearance: NSAppearance.Name?

    package var isPostingCursorNotification: Bool = false

    /// The string contents.
    public var string: String {
        textView.string
    }

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

    var highlighter: Highlighter?

    /// The tree sitter client managed by the source editor.
    ///
    /// This will be `nil` if another highlighter provider is passed to the source editor.
    internal(set) public var treeSitterClient: TreeSitterClient?

    private var fontCharWidth: CGFloat { (" " as NSString).size(withAttributes: [.font: font]).width }

    /// Filters used when applying edits..
    internal var textFilters: [TextFormation.Filter] = []

    internal var cancellables = Set<AnyCancellable>()

    /// ScrollView's bottom inset using as editor overscroll
    private var bottomContentInsets: CGFloat {
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
        bracketPairHighlight: BracketPairHighlight?,
        undoManager: CEUndoManager? = nil
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

        self.textView = TextView(
            string: string,
            font: font,
            textColor: theme.text,
            lineHeightMultiplier: lineHeightMultiple,
            wrapLines: wrapLines,
            isEditable: isEditable,
            isSelectable: isSelectable,
            letterSpacing: letterSpacing,
            delegate: self
        )
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: Keyboard Shortcuts
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            guard self.view.window?.firstResponder == self.textView else { return event }
            let charactersIgnoringModifiers = event.charactersIgnoringModifiers
            let commandKey = NSEvent.ModifierFlags.command.rawValue
            let modifierFlags = event.modifierFlags.intersection(.deviceIndependentFlagsMask).rawValue
            if modifierFlags == commandKey && event.charactersIgnoringModifiers == "/" {
                self.commandSlashCalled()
                return nil
            } else {
                super.keyDown(with: event)
                return event
            }
        }
    }
    
    /// Method called when CMD + / key sequence recognized, comments cursor's current line of code
    func commandSlashCalled() {
        guard let cursorPosition = cursorPositions.first else {
            print("There is no cursor \(#function)")
            return
        }
        // Many languages require a character sequence at the beginning of the line to comment the line.
        // (ex. python #, C++ //)
        // If such a sequence exists, we will insert that sequence at the beginning of the line
        if !language.lineCommentString.isEmpty {
            toggleCharsAtBeginningOfLine(chars: language.lineCommentString, lineNumber: cursorPosition.line)
        }
        // In other cases, there are languages that require a character sequence at both the beginning and end of a line, aka a range comment
        // (Ex. HTML <!--line here -->)
        // We can treat the line as a one-line range to comment it out using the language's rangeCommentStrings on both sides of the line
        else {
            let (openComment,closeComment) = language.rangeCommentStrings
            toggleCharsAtEndOfLine(chars: closeComment, lineNumber: cursorPosition.line)
            toggleCharsAtBeginningOfLine(chars: openComment, lineNumber: cursorPosition.line)
        }
    }
    
    ///  Toggles a specific string of characters at the beginning of a specified line in the textView's text storage. (lineNumber is 1-indexed)
    private func toggleCharsAtBeginningOfLine(chars: String, lineNumber: Int){
        guard let lineInfo = textView.layoutManager.textLineForIndex(lineNumber - 1) else {
            print("There are no characters/lineInfo \(#function)")
            return
        }
        guard let lineString = textView.textStorage.substring(from: lineInfo.range) else {
            print("There are no characters/lineString \(#function)")
            return
        }
        let firstNonWhiteSpaceCharIndex = lineString.firstIndex(where: {!$0.isWhitespace}) ?? lineString.startIndex
        let numWhitespaceChars = lineString.distance(from: lineString.startIndex, to: firstNonWhiteSpaceCharIndex)
        let firstCharsInLine = lineString.suffix(from: firstNonWhiteSpaceCharIndex).prefix(chars.count)
        // toggle comment off
        if firstCharsInLine == chars {
            textView.replaceCharacters(in:NSRange(location: lineInfo.range.location + numWhitespaceChars, length: chars.count), with: "")
        }
        // toggle comment on
        else {
            textView.replaceCharacters(in:NSRange(location: lineInfo.range.location + numWhitespaceChars, length: 0), with: chars)
        }
    }
    
    ///  Toggles a specific string of characters at the end of a specified line in the textView's text storage. (lineNumber is 1-indexed)
    private func toggleCharsAtEndOfLine(chars: String, lineNumber: Int){
        guard let lineInfo = textView.layoutManager.textLineForIndex(lineNumber - 1) else {
            print("There are no characters/lineInfo \(#function)")
            return
        }
        guard let lineString = textView.textStorage.substring(from: lineInfo.range) else {
            print("There are no characters/lineString \(#function)")
            return
        }
        let lineLastCharIndex = lineInfo.range.location + lineInfo.range.length - 1
        let closeCommentLength = chars.count
        let closeCommentRange = NSRange(location: lineLastCharIndex - closeCommentLength, length: closeCommentLength)
        let lastCharsInLine = textView.textStorage.substring(from: closeCommentRange)
        // toggle comment off
        if lastCharsInLine == chars {
            textView.replaceCharacters(in:NSRange(location: lineLastCharIndex - closeCommentLength, length: closeCommentLength), with: "")
        }
        // toggle comment on
        else {
            textView.replaceCharacters(in:NSRange(location: lineLastCharIndex, length: 0), with: chars)
        }
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
    internal lazy var paragraphStyle: NSMutableParagraphStyle = generateParagraphStyle()

    private func generateParagraphStyle() -> NSMutableParagraphStyle {
        // swiftlint:disable:next force_cast
        let paragraph = NSParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle
        paragraph.tabStops.removeAll()
        paragraph.defaultTabInterval = CGFloat(tabWidth) * fontCharWidth
        return paragraph
    }

    // MARK: - Reload UI

    func reloadUI() {
        textView.isEditable = isEditable
        textView.isSelectable = isSelectable

        styleScrollView()
        styleTextView()
        styleGutterView()

        highlighter?.invalidate()
    }

    /// Style the text view.
    package func styleTextView() {
        textView.selectionManager.selectionBackgroundColor = theme.selection
        textView.selectionManager.selectedLineBackgroundColor = getThemeBackground()
        textView.selectionManager.highlightSelectedLine = isEditable
        textView.selectionManager.insertionPointColor = theme.insertionPoint
        paragraphStyle = generateParagraphStyle()
        textView.typingAttributes = attributesFor(nil)
    }

    /// Finds the preferred use theme background.
    /// - Returns: The background color to use.
    private func getThemeBackground() -> NSColor {
        if useThemeBackground {
            return theme.lineHighlight
        }

        if systemAppearance == .darkAqua {
            return NSColor.quaternaryLabelColor
        }

        return NSColor.selectedTextBackgroundColor.withSystemEffect(.disabled)
    }

    /// Style the gutter view.
    package func styleGutterView() {
        gutterView.frame.origin.y = -scrollView.contentInsets.top
        gutterView.selectedLineColor = useThemeBackground ? theme.lineHighlight : systemAppearance == .darkAqua
        ? NSColor.quaternaryLabelColor
        : NSColor.selectedTextBackgroundColor.withSystemEffect(.disabled)
        gutterView.highlightSelectedLines = isEditable
        gutterView.font = font.rulerFont
        gutterView.backgroundColor = useThemeBackground ? theme.background : .textBackgroundColor
        if self.isEditable == false {
            gutterView.selectedLineTextColor = nil
            gutterView.selectedLineColor = .clear
        }
    }

    /// Style the scroll view.
    package func styleScrollView() {
        guard let scrollView = view as? NSScrollView else { return }
        scrollView.drawsBackground = useThemeBackground
        scrollView.backgroundColor = useThemeBackground ? theme.background : .clear
        if let contentInsets {
            scrollView.automaticallyAdjustsContentInsets = false
            scrollView.contentInsets = contentInsets
        } else {
            scrollView.automaticallyAdjustsContentInsets = true
        }
        scrollView.contentInsets.bottom = (contentInsets?.bottom ?? 0) + bottomContentInsets
    }

    deinit {
        if let highlighter {
            textView.removeStorageDelegate(highlighter)
        }
        highlighter = nil
        highlightProvider = nil
        NotificationCenter.default.removeObserver(self)
        cancellables.forEach { $0.cancel() }
    }
}

extension TextViewController: GutterViewDelegate {
    public func gutterViewWidthDidUpdate(newWidth: CGFloat) {
        gutterView?.frame.size.width = newWidth
        textView?.edgeInsets = HorizontalEdgeInsets(left: newWidth, right: 0)
    }
}
