//
//  CaptureModifiers.swift
//  CodeEditSourceEditor
//
//  Created by Khan Winter on 10/24/24.
//

// https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#semanticTokenModifiers

/// A collection of possible syntax capture modifiers. Represented by an integer for memory efficiency, and with the
/// ability to convert to and from strings for ease of use with tools.
///
/// These are useful for helping differentiate between similar types of syntax. Eg two variables may be declared like
/// ```swift
/// var a = 1
/// let b = 1
/// ```
/// ``CaptureName`` will represent both these later in code, but combined ``CaptureModifier`` themes can differentiate
/// between constants (`b` in the example) and regular variables (`a` in the example).
///
/// This is `Int8` raw representable for memory considerations. In large documents there can be *lots* of these created
/// and passed around, so representing them with a single integer is preferable to a string to save memory.
///
public enum CaptureModifier: Int8, CaseIterable, Sendable {
    case declaration
    case definition
    case readonly
    case `static`
    case deprecated
    case abstract
    case async
    case modification
    case documentation
    case defaultLibrary

    public var stringValue: String {
        switch self {
        case .declaration:
            return "declaration"
        case .definition:
            return "definition"
        case .readonly:
            return "readonly"
        case .static:
            return "static"
        case .deprecated:
            return "deprecated"
        case .abstract:
            return "abstract"
        case .async:
            return "async"
        case .modification:
            return "modification"
        case .documentation:
            return "documentation"
        case .defaultLibrary:
            return "defaultLibrary"
        }
    }

    // swiftlint:disable:next cyclomatic_complexity
    public static func fromString(_ string: String) -> CaptureModifier? {
        switch string {
        case "declaration":
            return .declaration
        case "definition":
            return .definition
        case "readonly":
            return .readonly
        case "static`":
            return .static
        case "deprecated":
            return .deprecated
        case "abstract":
            return .abstract
        case "async":
            return .async
        case "modification":
            return .modification
        case "documentation":
            return .documentation
        case "defaultLibrary":
            return .defaultLibrary
        default:
            return nil
        }
    }
}

extension CaptureModifier: CustomDebugStringConvertible {
    public var debugDescription: String { stringValue }
}

/// A set of capture modifiers, efficiently represented by a single integer.
public struct CaptureModifierSet: OptionSet, Equatable, Hashable, Sendable {
    public var rawValue: UInt

    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }

    public static let declaration = CaptureModifierSet(rawValue: 1 << CaptureModifier.declaration.rawValue)
    public static let definition = CaptureModifierSet(rawValue: 1 << CaptureModifier.definition.rawValue)
    public static let readonly = CaptureModifierSet(rawValue: 1 << CaptureModifier.readonly.rawValue)
    public static let `static` = CaptureModifierSet(rawValue: 1 << CaptureModifier.static.rawValue)
    public static let deprecated = CaptureModifierSet(rawValue: 1 << CaptureModifier.deprecated.rawValue)
    public static let abstract = CaptureModifierSet(rawValue: 1 << CaptureModifier.abstract.rawValue)
    public static let async = CaptureModifierSet(rawValue: 1 << CaptureModifier.async.rawValue)
    public static let modification = CaptureModifierSet(rawValue: 1 << CaptureModifier.modification.rawValue)
    public static let documentation = CaptureModifierSet(rawValue: 1 << CaptureModifier.documentation.rawValue)
    public static let defaultLibrary = CaptureModifierSet(rawValue: 1 << CaptureModifier.defaultLibrary.rawValue)

    /// All values in the set.
    public var values: [CaptureModifier] {
        var rawValue = self.rawValue

        // This set is represented by an integer, where each `1` in the binary number represents a value.
        // We can interpret the index of the `1` as the raw value of a ``CaptureModifier`` (the index in 0b0100 would
        // be 2). This loops through each `1` in the `rawValue`, finds the represented modifier, and 0's out the `1` so
        // we can get the next one using the binary & operator (0b0110 -> 0b0100 -> 0b0000 -> finish).
        var values: [Int8] = []
        while rawValue > 0 {
            values.append(Int8(rawValue.trailingZeroBitCount))
            // Clears the bit at the desired index (eg: 0b110 if clearing index 0)
            rawValue &= ~UInt(1 << rawValue.trailingZeroBitCount)
        }
        return values.compactMap({ CaptureModifier(rawValue: $0) })
    }

    public mutating func insert(_ value: CaptureModifier) {
        rawValue &= 1 << value.rawValue
    }
}
