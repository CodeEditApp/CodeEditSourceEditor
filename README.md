<p align="center">
  <img src="https://github.com/CodeEditApp/CodeEditTextView/blob/main/.github/CodeEditSourceEditor-Icon-128@2x.png?raw=true" height="128">
  <h1 align="center">CodeEditSourceEditor</h1>
</p>


<p align="center">
  <a aria-label="Follow CodeEdit on Twitter" href="https://twitter.com/CodeEditApp" target="_blank">
    <img alt="" src="https://img.shields.io/badge/Follow%20@CodeEditApp-black.svg?style=for-the-badge&logo=Twitter">
  </a>
  <a aria-label="Join the community on Discord" href="https://discord.gg/vChUXVf9Em" target="_blank">
    <img alt="" src="https://img.shields.io/badge/Join%20the%20community-black.svg?style=for-the-badge&logo=Discord">
  </a>
  <a aria-label="Read the Documentation" href="https://codeeditapp.github.io/CodeEditSourceEditor/documentation/codeeditsourceeditor/" target="_blank">
    <img alt="" src="https://img.shields.io/badge/Documentation-black.svg?style=for-the-badge&logo=readthedocs&logoColor=blue">
  </a>
</p>

An Xcode-inspired code editor view written in Swift powered by tree-sitter for [CodeEdit](https://github.com/CodeEditApp/CodeEdit). Features include syntax highlighting (based on the provided theme), code completion, find and replace, text diff, validation, current line highlighting, minimap, inline messages (warnings and errors), bracket matching, and more.

<img width="1012" alt="social-cover-textview" src="https://user-images.githubusercontent.com/806104/194083584-91555dce-ad4c-4066-922e-1eab889134be.png">

![GitHub release](https://img.shields.io/github/v/release/CodeEditApp/CodeEditSourceEditor?color=orange&label=latest%20release&sort=semver&style=flat-square)
![Github Tests](https://img.shields.io/github/actions/workflow/status/CodeEditApp/CodeEditSourceEditor/tests.yml?branch=main&label=tests&style=flat-square)
![Documentation](https://img.shields.io/github/actions/workflow/status/CodeEditApp/CodeEditSourceEditor/build-documentation.yml?branch=main&label=docs&style=flat-square)
![GitHub Repo stars](https://img.shields.io/github/stars/CodeEditApp/CodeEditSourceEditor?style=flat-square)
![GitHub forks](https://img.shields.io/github/forks/CodeEditApp/CodeEditSourceEditor?style=flat-square)
[![Discord Badge](https://img.shields.io/discord/951544472238444645?color=5865F2&label=Discord&logo=discord&logoColor=white&style=flat-square)](https://discord.gg/vChUXVf9Em)

> [!IMPORTANT]
> **CodeEditSourceEditor is currently in development and it is not ready for production use.** <br> Please check back later for updates on this project. Contributors are welcome as we build out the features mentioned above!

## Documentation

This package is fully documented [here](https://codeeditapp.github.io/CodeEditSourceEditor/documentation/codeeditsourceeditor/).

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

## Currently Supported Languages

See this issue https://github.com/CodeEditApp/CodeEditLanguages/issues/10 on `CodeEditLanguages` for more information on supported languages.

## Dependencies

Special thanks to [Matt Massicotte](https://twitter.com/mattie) for the great work he's done!

| Package | Source | Author |
| :- | :- | :- |
| `SwiftTreeSitter` | [GitHub](https://github.com/ChimeHQ/SwiftTreeSitter) | [Matt Massicotte](https://twitter.com/mattie) |

## License

Licensed under the [MIT license](https://github.com/CodeEditApp/CodeEdit/blob/main/LICENSE.md).

## Related Repositories

<table>
  <tr>
    <td align="center">
      <a href="https://github.com/CodeEditApp/CodeEdit">
        <img src="https://github.com/CodeEditApp/CodeEdit/blob/main/.github/CodeEdit-Icon-128@2x.png?raw=true" width="128" height="128">
        <p>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;CodeEdit&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</p>
      </a>
    </td>
    <td align="center">
      <a href="https://github.com/CodeEditApp/CodeEditSourceEditor">
        <img src="https://github.com/CodeEditApp/CodeEditTextView/blob/main/.github/CodeEditTextView-Icon-128@2x.png?raw=true" width="128" height="128">
        <p>CodeEditTextView</p>
      </a>
    </td>
    <td align="center">
      <a href="https://github.com/CodeEditApp/CodeEditLanguages">
        <img src="https://github.com/CodeEditApp/CodeEditLanguages/blob/main/.github/CodeEditLanguages-Icon-128@2x.png?raw=true" height="128">
        <p>CodeEditLanguages</p>
      </a>
    </td>
        <td align="center">
      <a href="https://github.com/CodeEditApp/CodeEditCLI">
        <img src="https://github.com/CodeEditApp/CodeEditCLI/blob/main/.github/CodeEditCLI-Icon-128@2x.png?raw=true" width="128" height="128">
        <p>CodeEditCLI</p>
      </a>
    </td>
    <td align="center">
      <a href="https://github.com/CodeEditApp/CodeEditKit">
        <img src="https://github.com/CodeEditApp/CodeEditKit/blob/main/.github/CodeEditKit-Icon-128@2x.png?raw=true" width="128" height="128">
        <p>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;CodeEditKit&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</p>
      </a>
    </td>
  </tr>
</table>
