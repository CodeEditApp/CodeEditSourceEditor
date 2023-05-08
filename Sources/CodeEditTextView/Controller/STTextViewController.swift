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

    /// Internal reference to any injected layers in the text view.
    internal var highlightLayers: [CALayer] = []

    /// Tracks the last text selections. Used to debounce `STTextView.didChangeSelectionNotification` being sent twice
    /// for every new selection.
    internal var lastTextSelections: [NSTextRange] = []

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

    public var systemAppearance: NSAppearance.Name?

    var cancellables = Set<AnyCancellable>()

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

    /// The type of highlight to use when highlighting bracket pairs. Leave as `nil` to disable highlighting.
    public var bracketPairHighlight: BracketPairHighlight? {
        didSet {
            removeHighlightLayers()
            // Update selection highlights if needed.
            highlightSelectionPairs()
        }
    }

    /// The kern to use for characters. Defaults to `0.0` and is updated when `letterSpacing` is set.
    internal var kern: CGFloat = 0.0

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
        letterSpacing: Double,
        bracketPairHighlight: BracketPairHighlight? = nil
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
        self.bracketPairHighlight = bracketPairHighlight
        super.init(nibName: nil, bundle: nil)
    }

    required init(coder: NSCoder) {
        fatalError()
    }

    public func textViewDidChangeText(_ notification: Notification) {
        self.text.wrappedValue = textView.string
    }

    // MARK: UI

    /// A default `NSParagraphStyle` with a set `lineHeight`
    internal lazy var paragraphStyle: NSMutableParagraphStyle = generateParagraphStyle()

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
    internal var bottomContentInsets: CGFloat {
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
        textView?.selectedLineHighlightColor = useThemeBackground ? theme.lineHighlight : systemAppearance == .darkAqua
            ? NSColor.quaternaryLabelColor
            : NSColor.selectedTextBackgroundColor.withSystemEffect(.disabled)
        textView?.isEditable = isEditable
        textView.highlightSelectedLine = isEditable
        textView?.typingAttributes = attributesFor(nil)
        paragraphStyle = generateParagraphStyle()
        textView?.defaultParagraphStyle = paragraphStyle

        rulerView?.backgroundColor = useThemeBackground ? theme.background : .clear
        rulerView?.separatorColor = theme.invisibles
        rulerView?.selectedLineHighlightColor = useThemeBackground ? theme.lineHighlight : systemAppearance == .darkAqua
            ? NSColor.quaternaryLabelColor
            : NSColor.selectedTextBackgroundColor.withSystemEffect(.disabled)
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

    /// Calculated line height depending on ``STTextViewController/lineHeightMultiple``
    internal var lineHeight: Double {
        font.lineHeight * lineHeightMultiple
    }

    /// Calculated baseline offset depending on `lineHeight`.
    internal var baselineOffset: Double {
        ((self.lineHeight) - font.lineHeight) / 2 + 2
    }

    // MARK: Selectors

    override public func keyDown(with event: NSEvent) {
        if !highlightLayers.isEmpty {
            removeHighlightLayers()
        }
    }

    public override func insertTab(_ sender: Any?) {
        textView.insertText("\t", replacementRange: textView.selectedRange)
    }

    deinit {
        removeHighlightLayers()
        textView = nil
        highlighter = nil
        cancellables.forEach { $0.cancel() }
    }
}
