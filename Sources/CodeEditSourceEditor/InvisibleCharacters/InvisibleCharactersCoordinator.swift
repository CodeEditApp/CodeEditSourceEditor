//
//  InvisibleCharactersCoordinator.swift
//  CodeEditSourceEditor
//
//  Created by Khan Winter on 6/9/25.
//

import AppKit
import CodeEditTextView

/// Object that tells the text view how to draw invisible characters.
///
/// Takes a few parameters for contextual drawing such as the current editor theme, font, and indent option.
///
/// To keep lookups fast, does not use a computed property for ``InvisibleCharactersConfig/triggerCharacters``.
/// Instead, this type keeps that internal property up-to-date whenever config is updated.
///
/// Another performance optimization is a cache mechanism in CodeEditTextView. Whenever the config, indent option,
/// theme, or font are updated, this object will tell the text view to clear it's cache. Keep updates to a minimum to
/// retain as much cached data as possible.
final class InvisibleCharactersCoordinator: InvisibleCharactersDelegate {
    var config: InvisibleCharactersConfig {
        didSet {
            triggerCharacters = config.triggerCharacters()
        }
    }
    var indentOption: IndentOption
    var theme: EditorTheme {
        didSet {
            invisibleColor = theme.invisibles.color
            needsCacheClear = true
        }
    }
    var font: NSFont {
        didSet {
            emphasizedFont = NSFontManager.shared.font(
                withFamily: font.familyName ?? "",
                traits: .unboldFontMask,
                weight: 15, // Condensed
                size: font.pointSize
            ) ?? font
            needsCacheClear = true
        }
    }

    private var needsCacheClear = false
    private var invisibleColor: NSColor
    private var emphasizedFont: NSFont

    /// The set of characters the text view should trigger a call to ``invisibleStyle`` for.
    var triggerCharacters: Set<UInt16>

    init(config: InvisibleCharactersConfig, indentOption: IndentOption, theme: EditorTheme, font: NSFont) {
        self.config = config
        self.indentOption = indentOption
        self.theme = theme
        self.font = font
        triggerCharacters = config.triggerCharacters()
        invisibleColor = theme.invisibles.color
        emphasizedFont = NSFontManager.shared.font(
            withFamily: font.familyName ?? "",
            traits: .unboldFontMask,
            weight: 15, // Condensed
            size: font.pointSize
        ) ?? font
    }

    /// Determines if the textview should clear cached styles.
    func invisibleStyleShouldClearCache() -> Bool {
        if needsCacheClear {
            needsCacheClear = false
            return true
        }
        return false
    }

    /// Determines the replacement style for a character found in a line fragment. Returns the style the text view
    /// should use to emphasize or replace the character.
    ///
    /// Input is a unichar character (UInt16), and is compared to known characters. This method also emphasizes spaces
    /// that appear on the same column user's selected indent width. The required font is expensive to compute
    /// often and is cached in ``emphasizedFont``.
    func invisibleStyle(for character: UInt16, at range: NSRange, lineRange: NSRange) -> InvisibleCharacterStyle? {
        switch character {
        case InvisibleCharactersConfig.Symbols.space:
            guard config.showSpaces else { return nil }
            let locationInLine = range.location - lineRange.location
            let shouldBold = locationInLine % indentOption.charCount == indentOption.charCount - 1
            return .replace(replacementCharacter: "·", color: invisibleColor, font: shouldBold ? emphasizedFont : font)
        case InvisibleCharactersConfig.Symbols.tab:
            guard config.showTabs else { return nil }
            return .replace(replacementCharacter: "→", color: invisibleColor, font: font)
        case InvisibleCharactersConfig.Symbols.carriageReturn, InvisibleCharactersConfig.Symbols.lineFeed:
            guard config.showLineEndings else { return nil }
            return .replace(replacementCharacter: "¬", color: invisibleColor, font: font)
        default:
            guard config.warningCharacters.contains(character) else {
                return nil
            }
            return .emphasize(color: .systemRed.withAlphaComponent(0.3))
        }
    }
}
