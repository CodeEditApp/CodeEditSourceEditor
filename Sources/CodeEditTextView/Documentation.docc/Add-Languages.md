# Add Languages

This article is a writedown on how to add support for more languages to ``CodeLanguage``.

## Overview

First of all have a look at the corresponding [GitHub Issue](https://github.com/CodeEditApp/CodeEditTextView/issues/15) to see which languages still need implementation.

## Add SPM support

If you find one you want to add, fork and clone the linked repo and create a new branch `feature/spm`.

> In the following code samples replace `{LANG}` or `{lang}` with the language you add (e.g.: `Swift` or `CPP` and `swift` or `cpp` respectively)

### .gitignore

Edit the `.gitignore` file to exclude the `.build/` directory from git.

### Package.swift

Create a new file `Package.swift` in the `root` directory of the repository and add the following configuration.

> Make sure to remove the comment in 'sources'.

```swift
// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "TreeSitter{LANG}",
    platforms: [.macOS(.v10_13), .iOS(.v11)],
    products: [
        .library(name: "TreeSitter{LANG}", targets: ["TreeSitter{LANG}"]),
    ],
    dependencies: [],
    targets: [
        .target(name: "TreeSitter{LANG}",
                path: ".",
                exclude: [
                    "binding.gyp",
                    "bindings",
                    "Cargo.toml",
                    "corpus",
                    "examples",
                    "grammar.js",
                    "LICENSE",
                    "Makefile",
                    "package.json",
                    "README.md",
                    "src/grammar.json",
                    "src/node-types.json",
                    // any additional files to exclude 
                ],
                sources: [
                    "src/parser.c",
                    "src/scanner.cc", // this might be `scanner.c` or not present at all
                ],
                resources: [
                    .copy("queries")
                ],
                publicHeadersPath: "bindings/swift",
                cSettings: [.headerSearchPath("src")])
    ]
)
```

### Swift Bindings

Now you need to create the Swift bindings which are a `header` file exposing the `tree_sitter_{lang}()` function.

First of all create the following directories inside the `bindings/` directory:

`./bindings/swift/TreeSitter{LANG}/`

Inside that folder create a new header file called `{lang}.h`.

```cpp
#ifndef TREE_SITTER_{LANG}_H_
#define TREE_SITTER_{LANG}_H_

typedef struct TSLanguage TSLanguage;

#ifdef __cplusplus
extern "C" {
#endif

extern TSLanguage *tree_sitter_{lang}();

#ifdef __cplusplus
}
#endif

#endif // TREE_SITTER_{LANG}_H_
```

## Add it to CodeLanguage

After you added the files you can add the package to ``CodeEditTextView`` locally by adding it to the `Package.swift` file's dependecies inside ``CodeEditTextView``.

```swift
dependencies: [
    // other package dependencies
    .package(name: "TreeSitter{LANG}", path: "/PATH/TO/LOCAL/PACKAGE"),
],
targets: [
    .target(
        name: "CodeEditTextView",
        dependencies: [
            // other dependencies
            .product(name: "TreeSitter{LANG}", package: "tree-sitter-{lang}"),
        ]),
]
```

Now move over to the `CodeLanguage` folder where 3 files need to be updated.

### TreeSitterLanguage.swift

Add a case for your language to ``TreeSitterLanguage``:

```swift
public enum TreeSitterLanguage: String {
    // other cases
    case {lang}
}
```

### CodeLanguage.swift

On top add an `import` statement:

```swift
import TreeSitter{LANG}
```

Find the `tsLanguage` computed property and add a `case` to it:

```swift
private var tsLanguage: UnsafeMutablePointer<TSLanguage>? {
    switch id {
    // other cases
    case .{lang}:
        return tree_sitter_{lang}()
    }
    // other cases
}
```

On the bottom of the file add a new `static` constant:

```swift
static let {lang}: CodeLanguage = .init(id: .{lang}, tsName: {LANG}, extensions: [...])
```

> in 'extensions' add the proper file extensions your language uses.

Now find the static constant ``CodeLanguage/allLanguages`` and add your language to it:

```swift
static let allLanguages: [CodeLanguage] = [
    // other languages
    .{lang},
    // other languages
]
```

### TreeSitterModel.swift

Create a new query like so:

```swift
public private(set) lazy var {lang}Query: Query? = {
    return queryFor(.{lang})
}()
```

Find the ``TreeSitterModel/query(for:)`` method and add a `case` for your language:

```swift
public func query(for language: TreeSitterLanguage) -> Query? {
    switch language {
    // other cases
    case .{lang}:
        return {lang}Query
    // other cases
    }
}
```

## Test it!

In order to test whether is working or not, add ``CodeEditTextView`` as a local dependency to `CodeEdit`.

In order to do that close ``CodeEditTextView`` in Xcode and open `CodeEdit`. Then inside `CodeEditModules` replace the `CodeEditTextView` dependency with:

```swift
.package(name: "CodeEditTextView", path: "/PATH/TO/CodeEditTextView")
```

After that, you may need to reset packages caches but then it should compile and run.

When everything is working correctly push your `tree-sitter-{lang}` changes to `origin` and also create a Pull Request to the official repository.

> Take [this PR description](https://github.com/tree-sitter/tree-sitter-javascript/pull/223) as a template and cross-reference it with your Pull Request.

Now you can remove the local dependencies and replace it with the actual package URLs and submit a Pull Request for ``CodeEditTextView``.

## Documentation

Please make sure to add the newly created properties to the documentation `*.md` files.
