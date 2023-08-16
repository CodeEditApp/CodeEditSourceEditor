//
//  LineEnding.swift
//  
//
//  Created by Khan Winter on 8/16/23.
//

enum LineEnding: String {
    /// The default unix `\n` character
    case lf = "\n"
    /// MacOS Line ending `\r` character
    case cr = "\r"
    /// Windows line ending sequence `\r\n`
    case crlf = "\r\n"

    /// Initialize a line ending from a line string.
    /// - Parameter line: The line to use
    @inlinable
    init?(line: String) {
        var iterator = line.lazy.reversed().makeIterator()
        guard var endChar = iterator.next() else { return nil }
        if endChar == "\n" {
            if let nextEndChar = iterator.next(), nextEndChar == "\r" {
                self = .crlf
            } else {
                self = .lf
            }
        } else if endChar == "\r" {
            self = .cr
        } else {
            return nil
        }
    }

    /// Attempts to detect the line ending from a line storage.
    /// - Parameter lineStorage: The line storage to enumerate.
    /// - Returns: A line ending. Defaults to `.lf` if none could be found.
    static func detectLineEnding(lineStorage: TextLineStorage<TextLine>) -> LineEnding {
        var histogram: [LineEnding: Int] = [
            .lf: 0,
            .cr: 0,
            .crlf: 0
        ]
        var shouldContinue = true
        var lineIterator = lineStorage.makeIterator()

        while let line = lineIterator.next()?.node.data, shouldContinue {
            guard let lineString = line.stringRef.substring(from: line.range),
                  let lineEnding = LineEnding(line: lineString) else {
                continue
            }
            histogram[lineEnding] = histogram[lineEnding]! + 1
            // after finding 15 lines of a line ending we assume it's correct.
            if histogram[lineEnding]! >= 15 {
                shouldContinue = false
            }
        }

        return histogram.max(by: { $0.value < $1.value })?.key ?? .lf
    }

    var length: Int {
        rawValue.count
    }
}
