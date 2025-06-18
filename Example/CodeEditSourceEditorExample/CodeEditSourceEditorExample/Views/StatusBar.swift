//
//  StatusBar.swift
//  CodeEditSourceEditorExample
//
//  Created by Khan Winter on 4/17/25.
//

import SwiftUI
import CodeEditSourceEditor
import CodeEditLanguages

struct StatusBar: View {
    let fileURL: URL?

    @Environment(\.colorScheme)
    var colorScheme

    @Binding var document: CodeEditSourceEditorExampleDocument
    @Binding var wrapLines: Bool
    @Binding var useSystemCursor: Bool
    @Binding var cursorPositions: [CursorPosition]
    @Binding var isInLongParse: Bool
    @Binding var language: CodeLanguage
    @Binding var theme: EditorTheme
    @Binding var showMinimap: Bool
    @Binding var indentOption: IndentOption
    @Binding var reformatAtColumn: Int
    @Binding var showReformattingGuide: Bool

    var body: some View {
        HStack {
            Menu {
                IndentPicker(indentOption: $indentOption, enabled: document.text.length == 0)
                    .buttonStyle(.borderless)
                Toggle("Wrap Lines", isOn: $wrapLines)
                Toggle("Show Minimap", isOn: $showMinimap)
                Toggle("Show Reformatting Guide", isOn: $showReformattingGuide)
                Picker("Reformat column at column", selection: $reformatAtColumn) {
                    ForEach([40, 60, 80, 100, 120, 140, 160, 180, 200], id: \.self) { column in
                        Text("\(column)").tag(column)
                    }
                }
                .onChange(of: reformatAtColumn) { _, newValue in
                    reformatAtColumn = max(1, min(200, newValue))
                }
                if #available(macOS 14, *) {
                    Toggle("Use System Cursor", isOn: $useSystemCursor)
                } else {
                    Toggle("Use System Cursor", isOn: $useSystemCursor)
                        .disabled(true)
                        .help("macOS 14 required")
                }
            } label: {}
                .background {
                    Image(systemName: "switch.2")
                        .foregroundStyle(.secondary)
                        .font(.system(size: 13.5, weight: .regular))
                }
                .menuStyle(.borderlessButton)
                .menuIndicator(.hidden)
                .frame(maxWidth: 18, alignment: .center)

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

    private func detectLanguage(fileURL: URL?) -> CodeLanguage? {
        guard let fileURL else { return nil  }
        return CodeLanguage.detectLanguageFrom(
            url: fileURL,
            prefixBuffer: document.text.string.getFirstLines(5),
            suffixBuffer: document.text.string.getLastLines(5)
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
