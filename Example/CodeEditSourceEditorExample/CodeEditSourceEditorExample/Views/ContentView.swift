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
    @State private var font: NSFont = NSFont.monospacedSystemFont(ofSize: 12, weight: .medium)
    @AppStorage("wrapLines") private var wrapLines: Bool = true
    @State private var cursorPositions: [CursorPosition] = []
    @AppStorage("systemCursor") private var useSystemCursor: Bool = false
    @State private var isInLongParse = false

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
                if #available(macOS 14, *) {
                    Toggle("Use System Cursor", isOn: $useSystemCursor)
                } else {
                    Toggle("Use System Cursor", isOn: $useSystemCursor)
                        .disabled(true)
                        .help("macOS 14 required")
                }
                Spacer()
                Text(getLabel(cursorPositions))
            }
            .padding(4)
            .zIndex(2)
            .background(Color(NSColor.windowBackgroundColor))
            Divider()
            ZStack {
                if isInLongParse {
                    VStack {
                        HStack {
                            Spacer()
                            Text("Parsing document...")
                            Spacer()
                        }
                        .padding(4)
                        .background(Color(NSColor.windowBackgroundColor))
                        Spacer()
                    }
                    .zIndex(2)
                    .transition(.opacity)
                }
                CodeEditSourceEditor(
                    $document.text,
                    language: language,
                    theme: theme,
                    font: font,
                    tabWidth: 4,
                    lineHeight: 1.2,
                    wrapLines: wrapLines,
                    cursorPositions: $cursorPositions,
                    useSystemCursor: useSystemCursor
                )
            }
        }
        .onAppear {
            self.language = detectLanguage(fileURL: fileURL) ?? .default
        }
        .onReceive(NotificationCenter.default.publisher(for: TreeSitterClient.Constants.longParse)) { _ in
            withAnimation(.easeIn(duration: 0.1)) {
                isInLongParse = true
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: TreeSitterClient.Constants.longParseFinished)) { _ in
            withAnimation(.easeIn(duration: 0.1)) {
                isInLongParse = false
            }
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
        return "Line: \(cursorPositions[0].line)  Col: \(cursorPositions[0].column) Range: \(cursorPositions[0].range)"
    }
}

#Preview {
    ContentView(document: .constant(CodeEditSourceEditorExampleDocument()), fileURL: nil)
}
