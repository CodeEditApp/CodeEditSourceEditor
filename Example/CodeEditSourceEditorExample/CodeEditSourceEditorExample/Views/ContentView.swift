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
    @State private var font: NSFont = NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
    @AppStorage("wrapLines") private var wrapLines: Bool = true
    @State private var cursorPositions: [CursorPosition] = []
    @AppStorage("systemCursor") private var useSystemCursor: Bool = false
    @State private var isInLongParse = false
    @State private var treeSitterClient = TreeSitterClient()

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
                lineHeight: 1.2,
                wrapLines: wrapLines,
                cursorPositions: $cursorPositions,
                useThemeBackground: true,
                highlightProviders: [treeSitterClient],
                contentInsets: NSEdgeInsets(top: proxy.safeAreaInsets.top, left: 0, bottom: 28.0, right: 0),
                useSystemCursor: useSystemCursor
            )
            .overlay(alignment: .bottom) {
                HStack {
                    Toggle("Wrap Lines", isOn: $wrapLines)
                        .toggleStyle(.button)
                        .buttonStyle(.accessoryBar)
                    if #available(macOS 14, *) {
                        Toggle("Use System Cursor", isOn: $useSystemCursor)
                            .toggleStyle(.button)
                            .buttonStyle(.accessoryBar)
                    } else {
                        Toggle("Use System Cursor", isOn: $useSystemCursor)
                            .disabled(true)
                            .help("macOS 14 required")
                            .toggleStyle(.button)
                            .buttonStyle(.accessoryBar)
                    }

                    Spacer()
                    Group {
                        if isInLongParse {
                            HStack(spacing: 5) {
                                ProgressView()
                                    .controlSize(.small)
                                Text("Parsing Document")
                            }
                        } else {
                            Text(getLabel(cursorPositions))
                        }
                    }
                    .foregroundStyle(.secondary)
                    Divider()
                        .frame(height: 12)
                    LanguagePicker(language: $language)
                        .buttonStyle(.borderless)
                }
                .font(.subheadline)
                .fontWeight(.medium)
                .controlSize(.small)
                .padding(.horizontal, 8)
                .frame(height: 28)
                .background(.bar)
                .overlay(alignment: .top) {
                    VStack {
                        Divider()
                            .overlay {
                                if colorScheme == .dark {
                                    Color.black
                                }
                            }
                    }
                }
                .zIndex(2)
                .onAppear {
                    self.language = detectLanguage(fileURL: fileURL) ?? .default
                    self.theme = colorScheme == .dark ? .dark : .light
                }
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
            return "No cursor"
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
