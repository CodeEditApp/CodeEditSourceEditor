// swift-tools-version: 5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "CodeEditTextView",
    platforms: [.macOS(.v12)],
    products: [
        .library(
            name: "CodeEditTextView",
            targets: ["CodeEditTextView"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.0.0"),
        .package(url: "https://github.com/krzyzanowskim/STTextView", exact: "0.0.20"),
        .package(url: "https://github.com/ChimeHQ/SwiftTreeSitter", exact: "0.6.1"),
        .package(url: "https://github.com/lukepistrol/tree-sitter-bash.git", branch: "feature/spm"),
        .package(url: "https://github.com/tree-sitter/tree-sitter-c.git", branch: "master"),
        .package(url: "https://github.com/tree-sitter/tree-sitter-cpp.git", branch: "master"),
        .package(url: "https://github.com/tree-sitter/tree-sitter-c-sharp.git", branch: "master"),
        .package(url: "https://github.com/lukepistrol/tree-sitter-css.git", branch: "feature/spm"),
        .package(url: "https://github.com/elixir-lang/tree-sitter-elixir.git", branch: "main"),
        .package(url: "https://github.com/tree-sitter/tree-sitter-go.git", branch: "master"),
        .package(url: "https://github.com/camdencheek/tree-sitter-go-mod.git", branch: "main"),
        .package(url: "https://github.com/tree-sitter/tree-sitter-haskell.git", branch: "master"),
        .package(url: "https://github.com/mattmassicotte/tree-sitter-html.git", branch: "feature/spm"),
        .package(url: "https://github.com/tree-sitter/tree-sitter-java.git", branch: "master"),
        .package(url: "https://github.com/tree-sitter/tree-sitter-javascript.git", branch: "master"),
        .package(url: "https://github.com/mattmassicotte/tree-sitter-json.git", branch: "feature/spm"),
        .package(url: "https://github.com/tree-sitter/tree-sitter-php.git", branch: "master"),
        .package(url: "https://github.com/lukepistrol/tree-sitter-python.git", branch: "feature/spm"),
        .package(url: "https://github.com/mattmassicotte/tree-sitter-ruby.git", branch: "feature/swift"),
        .package(url: "https://github.com/tree-sitter/tree-sitter-rust.git", branch: "master"),
        .package(url: "https://github.com/alex-pinkus/tree-sitter-swift", branch: "with-generated-files"),
        .package(url: "https://github.com/mattmassicotte/tree-sitter-yaml.git", branch: "feature/spm"),
        .package(url: "https://github.com/maxxnino/tree-sitter-zig.git", branch: "main"),
    ],
    targets: [
        .target(
            name: "CodeEditTextView",
            dependencies: [
                "STTextView",
                "SwiftTreeSitter",
                .product(name: "TreeSitterBash", package: "tree-sitter-bash"),
                .product(name: "TreeSitterC", package: "tree-sitter-c"),
                .product(name: "TreeSitterCPP", package: "tree-sitter-cpp"),
                .product(name: "TreeSitterCSharp", package: "tree-sitter-c-sharp"),
                .product(name: "TreeSitterCSS", package: "tree-sitter-css"),
                .product(name: "TreeSitterElixir", package: "tree-sitter-elixir"),
                .product(name: "TreeSitterGo", package: "tree-sitter-go"),
                .product(name: "TreeSitterGoMod", package: "tree-sitter-go-mod"),
                .product(name: "TreeSitterHaskell", package: "tree-sitter-haskell"),
                .product(name: "TreeSitterHTML", package: "tree-sitter-html"),
                .product(name: "TreeSitterJava", package: "tree-sitter-java"),
                .product(name: "TreeSitterJS", package: "tree-sitter-javascript"),
                .product(name: "TreeSitterJSON", package: "tree-sitter-json"),
                .product(name: "TreeSitterPHP", package: "tree-sitter-php"),
                .product(name: "TreeSitterPython", package: "tree-sitter-python"),
                .product(name: "TreeSitterRuby", package: "tree-sitter-ruby"),
                .product(name: "TreeSitterRust", package: "tree-sitter-rust"),
                .product(name: "TreeSitterSwift", package: "tree-sitter-swift"),
                .product(name: "TreeSitterYAML", package: "tree-sitter-yaml"),
                .product(name: "TreeSitterZig", package: "tree-sitter-zig"),
            ]),
        .testTarget(
            name: "CodeEditTextViewTests",
            dependencies: [
                "CodeEditTextView",
            ]),
    ]
)
