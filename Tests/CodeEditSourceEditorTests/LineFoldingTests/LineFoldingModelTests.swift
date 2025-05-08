//
//  LineFoldingModelTests.swift
//  CodeEditSourceEditor
//
//  Created by Khan Winter on 5/8/25.
//

import Testing
import AppKit
import CodeEditTextView
@testable import CodeEditSourceEditor

@Suite
@MainActor
struct LineFoldingModelTests {
    /// Makes a fold pattern that increases until halfway through the document then goes back to zero.
    class HillPatternFoldProvider: LineFoldProvider {
        func foldLevelAtLine(_ lineNumber: Int, layoutManager: TextLayoutManager, textStorage: NSTextStorage) -> Int? {
            let halfLineCount = (layoutManager.lineCount / 2) - 1

            return if lineNumber > halfLineCount {
                layoutManager.lineCount - 2 - lineNumber
            } else {
                lineNumber
            }
        }
    }

    let textView: TextView
    let model: LineFoldingModel

    init() {
        textView = TextView(string: "A\nB\nC\nD\nE\nF\n")
        textView.frame = NSRect(x: 0, y: 0, width: 1000, height: 1000)
        textView.updatedViewport(NSRect(x: 0, y: 0, width: 1000, height: 1000))
        model = LineFoldingModel(textView: textView, foldProvider: nil)
    }

    /// A little unintuitive but we only expect two folds with this. Our provider goes 0-1-2-2-1-0, but we don't
    /// make folds for indent level 0. We also expect folds to start on the lines *before* the indent increases and
    /// after it decreases, so the fold covers the start/end of the region being folded.
    @Test
    func buildFoldsForDocument() throws {
        let provider = HillPatternFoldProvider()
        model.foldProvider = provider

        model.buildFoldsForDocument()

        let fold = try #require(model.getFolds(in: 0...5).first)
        #expect(fold.lineRange == 0...5)

        let innerFold = try #require(fold.subFolds.first)
        #expect(innerFold.lineRange == 1...4)
    }
}
