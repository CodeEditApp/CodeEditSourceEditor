# ``CodeEditTextView/CodeEditTextView``

## Usage

```swift
import CodeEditTextView

struct ContentView: View {

    @State var text = "let x = 1.0"
    @State var theme = Theme(...)
    @State var font = NSFont.monospacedSystemFont(ofSize: 11, weight: .regular)
    @State var tabWidth = 4
    @State var lineHeight = 1.2

    var body: some View { 
        CodeEditTextView(
            $text,
            language: .swift,
            theme: $theme,
            font: $font,
            tabWidth: $tabWidth,
            lineHeight: $lineHeight
        )
    }
}
```

## Topics

### <!--@START_MENU_TOKEN@-->Group<!--@END_MENU_TOKEN@-->

- <!--@START_MENU_TOKEN@-->``Symbol``<!--@END_MENU_TOKEN@-->
