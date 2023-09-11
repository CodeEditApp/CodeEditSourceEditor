//
//  LineEnding.swift
//  
//
//  Created by Khan Winter on 8/16/23.
//

import AppKit

public enum LineEnding: String {
    /// The default unix `\n` character
    case lineFeed = "\n"
    /// MacOS line ending `\r` character
    case carriageReturn = "\r"
    /// Windows line ending sequence `\r\n`
    case carriageReturnLineFeed = "\r\n"

    /// Initialize a line ending from a line string.
    /// - Parameter line: The line to use
    public init?(line: String) {
        var iterator = line.lazy.reversed().makeIterator()
        guard let endChar = iterator.next() else { return nil }
        if endChar == "\n" {
            if let nextEndChar = iterator.next(), nextEndChar == "\r" {
                self = .carriageReturnLineFeed
            } else {
                self = .lineFeed
            }
        } else if endChar == "\r" {
            self = .carriageReturn
        } else {
            return nil
        }
    }

    /// Attempts to detect the line ending from a line storage.
    /// - Parameter lineStorage: The line storage to enumerate.
    /// - Returns: A line ending. Defaults to `.lf` if none could be found.
    public static func detectLineEnding(
        lineStorage: TextLineStorage<TextLine>,
        textStorage: NSTextStorage
    ) -> LineEnding {
        var histogram: [LineEnding: Int] = [
            .lineFeed: 0,
            .carriageReturn: 0,
            .carriageReturnLineFeed: 0
        ]
        var shouldContinue = true
        var lineIterator = lineStorage.makeIterator()

        while let line = lineIterator.next(), shouldContinue {
            guard let lineString = textStorage.substring(from: line.range),
                  let lineEnding = LineEnding(line: lineString) else {
                continue
            }
            histogram[lineEnding] = histogram[lineEnding]! + 1
            // after finding 15 lines of a line ending we assume it's correct.
            if histogram[lineEnding]! >= 15 {
                shouldContinue = false
            }
        }

        return histogram.max(by: { $0.value < $1.value })?.key ?? .lineFeed
    }

    public var length: Int {
        rawValue.count
    }
}
