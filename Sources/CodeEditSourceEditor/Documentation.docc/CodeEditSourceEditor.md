# ``CodeEditSourceEditor/CodeEditSourceEditor``

## Usage

```swift
import CodeEditSourceEditor

struct ContentView: View {

    @State var text = "let x = 1.0"
    @State var theme = EditorTheme(...)
    @State var font = NSFont.monospacedSystemFont(ofSize: 11, weight: .regular)
    @State var tabWidth = 4
    @State var lineHeight = 1.2
    @State var editorOverscroll = 0.3

    var body: some View { 
        CodeEditSourceEditor(
            $text,
            language: .swift,
            theme: $theme,
            font: $font,
            tabWidth: $tabWidth,
            lineHeight: $lineHeight,
            editorOverscroll: $editorOverscroll
        )
    }
}
```
