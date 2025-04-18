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
    @Environment(\.colorScheme)
    var colorScheme

    @Binding var document: CodeEditSourceEditorExampleDocument
    let fileURL: URL?

    @State private var language: CodeLanguage = .default
    @State private var theme: EditorTheme = .light
    @State private var font: NSFont = NSFont.monospacedSystemFont(ofSize: 12, weight: .medium)
    @AppStorage("wrapLines") private var wrapLines: Bool = true
    @State private var cursorPositions: [CursorPosition] = [.init(line: 1, column: 1)]
    @AppStorage("systemCursor") private var useSystemCursor: Bool = false
    @State private var isInLongParse = false
    @State private var settingsIsPresented: Bool = false
    @State private var treeSitterClient = TreeSitterClient()
    @AppStorage("showMinimap") private var showMinimap: Bool = true
    @State private var indentOption: IndentOption = .spaces(count: 4)

    init(document: Binding<CodeEditSourceEditorExampleDocument>, fileURL: URL?) {
        self._document = document
        self.fileURL = fileURL
    }

    var body: some View {
        GeometryReader { proxy in
            CodeEditSourceEditor(
                $document.text,
                language: language,
                theme: theme,
                font: font,
                tabWidth: 4,
                indentOption: indentOption,
                lineHeight: 1.2,
                wrapLines: wrapLines,
                editorOverscroll: 0.3,
                cursorPositions: $cursorPositions,
                useThemeBackground: true,
                highlightProviders: [treeSitterClient],
                contentInsets: NSEdgeInsets(top: proxy.safeAreaInsets.top, left: 0, bottom: 28.0, right: 0),
                additionalTextInsets: NSEdgeInsets(top: 1, left: 0, bottom: 1, right: 0),
                useSystemCursor: useSystemCursor,
                showMinimap: showMinimap
            )
            .overlay(alignment: .bottom) {
                Toolbar(
                    fileURL: fileURL,
                    document: $document,
                    wrapLines: $wrapLines,
                    useSystemCursor: $useSystemCursor,
                    cursorPositions: $cursorPositions,
                    isInLongParse: $isInLongParse,
                    language: $language,
                    theme: $theme,
                    showMinimap: $showMinimap,
                    indentOption: $indentOption
                )
            }
            .ignoresSafeArea()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
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
            .onChange(of: colorScheme) { _, newValue in
                if newValue == .dark {
                    theme = .dark
                } else {
                    theme = .light
                }
            }
        }
    }
}

#Preview {
    ContentView(document: .constant(CodeEditSourceEditorExampleDocument()), fileURL: nil)
}
