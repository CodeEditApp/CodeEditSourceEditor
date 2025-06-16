//
//  EditorConfig+Appearance.swift
//  CodeEditSourceEditor
//
//  Created by Khan Winter on 6/16/25.
//

import AppKit

extension EditorConfig {
    public struct Appearance: Equatable {
        /// The theme for syntax highlighting.
        public var theme: EditorTheme

        /// Determines whether the editor uses the theme's background color, or a transparent background color.
        public var useThemeBackground: Bool = true

        /// The default font.
        public var font: NSFont

        /// The line height multiplier (e.g. `1.2`).
        public var lineHeight: Double

        /// The amount of space to use between letters, as a percent. Eg: `1.0` = no space, `1.5` = 1/2 a
        /// character's width between characters, etc. Defaults to `1.0`.
        public var letterSpacing: Double = 1.0

        /// Whether lines wrap to the width of the editor.
        public var wrapLines: Bool

        /// If true, uses the system cursor on `>=macOS 14`.
        public var useSystemCursor: Bool = true

        /// The visual tab width in number of spaces.
        public var tabWidth: Int

        /// The type of highlight to use to highlight bracket pairs.
        /// See ``BracketPairEmphasis`` for more information. Defaults to `.flash`.
        public var bracketPairEmphasis: BracketPairEmphasis? = .flash

        public init(
            theme: EditorTheme,
            useThemeBackground: Bool = true,
            font: NSFont,
            lineHeight: Double,
            letterSpacing: Double = 1.0,
            wrapLines: Bool,
            useSystemCursor: Bool = true,
            tabWidth: Int,
            bracketPairEmphasis: BracketPairEmphasis? = .flash
        ) {
            self.theme = theme
            self.useThemeBackground = useThemeBackground
            self.font = font
            self.lineHeight = lineHeight
            self.letterSpacing = letterSpacing
            self.wrapLines = wrapLines
            if #available(macOS 14, *) {
                self.useSystemCursor = useSystemCursor
            } else {
                self.useSystemCursor = false
            }
            self.tabWidth = tabWidth
            self.bracketPairEmphasis = bracketPairEmphasis
        }
    }
}
