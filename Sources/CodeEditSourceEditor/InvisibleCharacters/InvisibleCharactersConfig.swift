//
//  InvisibleCharactersConfig.swift
//  CodeEditSourceEditor
//
//  Created by Khan Winter on 6/11/25.
//

/// Configuration for how the editor draws invisible characters.
public struct InvisibleCharactersConfig: Equatable, Hashable, Sendable, Codable {
    /// An empty configuration.
    public static var empty: InvisibleCharactersConfig {
        InvisibleCharactersConfig(showSpaces: false, showTabs: false, showLineEndings: false, warningCharacters: [])
    }

    /// Set to true to draw spaces with a dot.
    public var showSpaces: Bool
    /// Set to true to draw tabs with a small arrow.
    public var showTabs: Bool
    /// Set to true to draw line endings.
    public var showLineEndings: Bool
    /// A set of characters the editor should draw with a small red border.
    ///
    /// Indicates characters that the user may not have meant to insert, such as a zero-width space: `(0x200D)` or a
    /// non-standard quote character: `“ (0x201C)`.
    public var warningCharacters: Set<UInt16>

    public init(showSpaces: Bool, showTabs: Bool, showLineEndings: Bool, warningCharacters: Set<UInt16>) {
        self.showSpaces = showSpaces
        self.showTabs = showTabs
        self.showLineEndings = showLineEndings
        self.warningCharacters = warningCharacters
    }
    
    /// Determines what characters should trigger a custom drawing action.
    func triggerCharacters() -> Set<UInt16> {
        var set = Set<UInt16>()

        if showSpaces {
            set.insert(Symbols.space)
        }

        if showTabs {
            set.insert(Symbols.tab)
        }

        if showLineEndings {
            set.insert(Symbols.lineFeed)
            set.insert(Symbols.carriageReturn)
        }

        set.formUnion(warningCharacters)

        return set
    }
    
    /// Some commonly used whitespace symbols in their unichar representation.
    public enum Symbols {
        public static let space: UInt16 = 0x20
        public static let tab: UInt16 = 0x9
        public static let lineFeed: UInt16 = 0xA // \n
        public static let carriageReturn: UInt16 = 0xD // \r
    }
}
