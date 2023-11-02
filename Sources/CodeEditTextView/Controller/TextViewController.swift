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
    internal var _undoManager: CEUndoManager?
    /// Internal reference to any injected layers in the text view.
    internal var highlightLayers: [CALayer] = []
    internal var systemAppearance: NSAppearance.Name?

    /// The string contents.
    public var string: String {
        textStorage.string
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
        }
    }

    /// The associated `Theme` used for highlighting.
    public var theme: EditorTheme {
        didSet {
            textView.layoutManager.setNeedsLayout()
            textStorage.setAttributes(attributesFor(nil), range: NSRange(location: 0, length: textStorage.length))
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
        }
    }

    /// The type of highlight to use when highlighting bracket pairs. Leave as `nil` to disable highlighting.
    public var bracketPairHighlight: BracketPairHighlight? {
        didSet {
            highlightSelectionPairs()
        }
    }

    internal var textStorage: NSTextStorage
    internal var storageDelegate: MultiStorageDelegate!
    internal var highlighter: Highlighter?

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
        cursorPosition: Binding<(Int, Int)>,
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
        self.textStorage = NSTextStorage(string: string)
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
        self.isSelectable = isSelectable
        self.letterSpacing = letterSpacing
        self.bracketPairHighlight = bracketPairHighlight
        self._undoManager = undoManager

        self.storageDelegate = MultiStorageDelegate()

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Set the contents of the editor.
    /// - Parameter text: The new contents of the editor.
    public func setText(_ text: String) {
        self.textView.setText(text)
        self.setUpHighlighter()
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
        gutterView.backgroundColor = useThemeBackground ? theme.background : .textBackgroundColor
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
            scrollView.contentInsets.bottom = (contentInsets?.bottom ?? 0) + bottomContentInsets
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

extension TextViewController: GutterViewDelegate {
    public func gutterViewWidthDidUpdate(newWidth: CGFloat) {
        gutterView?.frame.size.width = newWidth
        textView?.edgeInsets = HorizontalEdgeInsets(left: newWidth, right: 0)
    }
}
