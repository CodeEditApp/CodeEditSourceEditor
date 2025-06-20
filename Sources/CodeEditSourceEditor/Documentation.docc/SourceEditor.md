# ``SourceEditor``

## Usage

CodeEditSourceEditor provides two APIs for creating an editor: SwiftUI and AppKit.

#### SwiftUI

```swift
import CodeEditSourceEditor

struct ContentView: View {

    @State var text = "let x = 1.0"
    // For large documents use (avoids SwiftUI inneficiency)
    // var text: NSTextStorage
    
    /// Automatically updates with cursor positions, or update the binding to set the user's cursors.
    @State var cursorPositions: [CursorPosition] = []
    
    /// Configure the editor's appearance, features, and editing behavior...
    @State var theme = EditorTheme(...)
    @State var font = NSFont.monospacedSystemFont(ofSize: 11, weight: .regular)
    @State var indentOption = .spaces(count: 4)
    @State var editorOverscroll = 0.3
    @State var showMinimap = true

    var body: some View { 
        SourceEditor(
            $text,
            language: language,
            configuration: SourceEditorConfiguration(
                appearance: .init(theme: theme, font: font),
                behavior: .init(indentOption: indentOption),
                layout: .init(editorOverscroll: editorOverscroll),
                peripherals: .init(showMinimap: showMinimap)
            ),
            cursorPositions: $cursorPositions
        )
    }
}
```

#### AppKit

```swift
var theme = EditorTheme(...)
var font = NSFont.monospacedSystemFont(ofSize: 11, weight: .regular)
var indentOption = .spaces(count: 4)
var editorOverscroll = 0.3
var showMinimap = true

let editorController = TextViewController(
    string: "let x = 10;",
    language: .swift,
    config: SourceEditorConfiguration(
        appearance: .init(theme: theme, font: font),
        behavior: .init(indentOption: indentOption),
        layout: .init(editorOverscroll: editorOverscroll),
        peripherals: .init(showMinimap: showMinimap)
    ),
    cursorPositions: [CursorPosition(line: 0, column: 0)],
    highlightProviders: [], // Use the tree-sitter syntax highlighting provider by default
    undoManager: nil,
    coordinators: [] // Optionally inject editing behavior or other plugins.
)
```

