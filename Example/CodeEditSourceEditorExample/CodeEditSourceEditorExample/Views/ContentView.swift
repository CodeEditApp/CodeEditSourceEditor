//
//  ContentView.swift
//  CodeEditSourceEditorExample
//
//  Created by Khan Winter on 2/24/24.
//

import SwiftUI
import CodeEditSourceEditor
import CodeEditLanguages
import CodeEditTextView

struct ContentView: View {
    @Binding var document: CodeEditSourceEditorExampleDocument
    let fileURL: URL?

    @State private var language: CodeLanguage = .default
    @State private var theme: EditorTheme = .standard
    @State private var font: NSFont = NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
    @AppStorage("wrapLines") private var wrapLines: Bool = true
    @State private var cursorPositions: [CursorPosition] = []

    init(document: Binding<CodeEditSourceEditorExampleDocument>, fileURL: URL?) {
        self._document = document
        self.fileURL = fileURL
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Language")
                LanguagePicker(language: $language)
                    .frame(maxWidth: 100)
                Toggle("Wrap Lines", isOn: $wrapLines)
                Spacer()
                Text(getLabel(cursorPositions))
            }
            .padding(4)
            .zIndex(2)
            .background(Color(NSColor.windowBackgroundColor))
            Divider()
            CodeEditSourceEditor(
                $document.text,
                language: language,
                theme: theme,
                font: font,
                tabWidth: 4,
                lineHeight: 1.2,
                wrapLines: wrapLines,
                cursorPositions: $cursorPositions
            )
        }
        .onAppear {
            self.language = detectLanguage(fileURL: fileURL) ?? .default
        }
    }

    private func detectLanguage(fileURL: URL?) -> CodeLanguage? {
        guard let fileURL else { return nil  }
        return CodeLanguage.detectLanguageFrom(
            url: fileURL,
            prefixBuffer: document.text.getFirstLines(5),
            suffixBuffer: document.text.getLastLines(5)
        )
    }

    /// Create a label string for cursor positions.
    /// - Parameter cursorPositions: The cursor positions to create the label for.
    /// - Returns: A string describing the user's location in a document.
    func getLabel(_ cursorPositions: [CursorPosition]) -> String {
        if cursorPositions.isEmpty {
            return ""
        }

        // More than one selection, display the number of selections.
        if cursorPositions.count > 1 {
            return "\(cursorPositions.count) selected ranges"
        }

        // When there's a single cursor, display the line and column.
        return "Line: \(cursorPositions[0].line)  Col: \(cursorPositions[0].column)"
    }
}

#Preview {
    ContentView(document: .constant(CodeEditSourceEditorExampleDocument()), fileURL: nil)
}
