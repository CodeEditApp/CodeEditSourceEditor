<p align="center">
  <img src="https://user-images.githubusercontent.com/806104/175655252-d77cef62-31f5-4f40-a2ad-c1406a6dd1b9.png" height="128">
  <h1 align="center">CodeEditTextView</h1>
</p>

<p align="center">
  <a aria-label="Follow CodeEdit on Twitter" href="https://twitter.com/CodeEditApp" target="_blank">
    <img alt="" src="https://img.shields.io/badge/Follow%20@CodeEditApp-black.svg?style=for-the-badge&logo=Twitter">
  </a>
  <a aria-label="Join the community on Discord" href="https://discord.gg/vChUXVf9Em" target="_blank">
    <img alt="" src="https://img.shields.io/badge/Join%20the%20community-black.svg?style=for-the-badge&logo=Discord">
  </a>
  <a aria-label="Read the Documentation" href="https://codeeditapp.github.io/CodeEditTextView/documentation/codeedittextview/" target="_blank">
    <img alt="" src="https://img.shields.io/badge/Documentation-black.svg?style=for-the-badge&logo=readthedocs&logoColor=blue">
  </a>
</p>

An Xcode-inspired code editor view written in Swift powered by tree-sitter for [CodeEdit](https://github.com/CodeEditApp/CodeEdit). Features include syntax highlighting (based on the provided theme), code completion, find and replace, text diff, validation, current line highlighting, minimap, inline messages (warnings and errors), bracket matching, and more.

<img width="1012" alt="social-cover-textview" src="https://user-images.githubusercontent.com/806104/194083584-91555dce-ad4c-4066-922e-1eab889134be.png">

![GitHub release](https://img.shields.io/github/v/release/CodeEditApp/CodeEditTextView?color=orange&label=latest%20release&sort=semver&style=flat-square)
![Github Tests](https://img.shields.io/github/actions/workflow/status/CodeEditApp/CodeEditTextView/tests.yml?branch=main&label=tests&style=flat-square)
![Documentation](https://img.shields.io/github/actions/workflow/status/CodeEditApp/CodeEditTextView/build-documentation.yml?branch=main&label=docs&style=flat-square)
![GitHub Repo stars](https://img.shields.io/github/stars/CodeEditApp/CodeEditTextView?style=flat-square)
![GitHub forks](https://img.shields.io/github/forks/CodeEditApp/CodeEditTextView?style=flat-square)
[![Discord Badge](https://img.shields.io/discord/951544472238444645?color=5865F2&label=Discord&logo=discord&logoColor=white&style=flat-square)](https://discord.gg/vChUXVf9Em)

| :warning: | **CodeEditTextView is currently in development and it is not ready for production use.** <br> Please check back later for updates on this project. Contributors are welcome as we build out the features mentioned above! |
| - |:-|

## Documentation

This package is fully documented [here](https://codeeditapp.github.io/CodeEditTextView/documentation/codeedittextview/).

## Usage

```swift
import CodeEditTextView

struct ContentView: View {

    @State var text = "let x = 1.0"
    @State var theme = EditorTheme(...)
    @State var font = NSFont.monospacedSystemFont(ofSize: 11, weight: .regular)
    @State var tabWidth = 4
    @State var lineHeight = 1.2
    @State var editorOverscroll = 0.3

    var body: some View { 
        CodeEditTextView(
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

Special thanks to both [Marcin Krzyzanowski](https://twitter.com/krzyzanowskim) & [Matt Massicotte](https://twitter.com/mattie) for the great work they've done!

| Package | Source | Author |
| :- | :- | :- |
| `STTextView` | [GitHub](https://github.com/krzyzanowskim/STTextView) | [Marcin Krzyzanowski](https://twitter.com/krzyzanowskim) |
| `SwiftTreeSitter` | [GitHub](https://github.com/ChimeHQ/SwiftTreeSitter) | [Matt Massicotte](https://twitter.com/mattie) |

## License

Licensed under the [MIT license](https://github.com/CodeEditApp/CodeEdit/blob/main/LICENSE.md).

## Related Repositories

<table>
  <tr>
    <td align="center">
      <a href="https://github.com/CodeEditApp/CodeEdit">
        <img src="https://user-images.githubusercontent.com/806104/163099605-4eaedd33-8441-4125-9ca1-a7ccb2f62a74.png" height="128">
        <p>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;CodeEdit&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</p>
      </a>
    </td>
    <td align="center">
      <a href="https://github.com/CodeEditApp/CodeEditKit">
        <img src="https://user-images.githubusercontent.com/806104/193877051-c60d255d-0b6a-408c-bb21-6fabc5e0e60c.png" height="128">
        <p>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;CodeEditKit&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</p>
      </a>
    </td>
    <td align="center">
      <a href="https://github.com/CodeEditApp/CodeEditLanguages">
        <img src="https://user-images.githubusercontent.com/806104/201497920-d6aace8d-f0dc-49f6-bcd7-6a3b64cc384c.png" height="128">
        <p>CodeEditLanguages</p>
      </a>
    </td>
    <td align="center">
      <a href="https://github.com/CodeEditApp/CodeEditCLI">
        <img src="https://user-images.githubusercontent.com/806104/205848006-f2654778-21f1-4f97-b292-32849cc1eff6.png" height="128">
        <p>&nbsp;&nbsp;&nbsp;&nbsp;CodeEdit&nbsp;CLI&nbsp;&nbsp;&nbsp;&nbsp;</p>
      </a>
    </td>
  </tr>
</table>

