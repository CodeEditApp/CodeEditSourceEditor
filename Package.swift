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
        .package(url: "https://github.com/krzyzanowskim/STTextView", branch: "main"),
        .package(url: "https://github.com/ChimeHQ/SwiftTreeSitter", from: "0.6.0"),
        .package(url: "https://github.com/mattmassicotte/tree-sitter-go.git", branch: "feature/swift"),
        .package(url: "https://github.com/camdencheek/tree-sitter-go-mod.git", branch: "main"),
        .package(url: "https://github.com/mattmassicotte/tree-sitter-html.git", branch: "feature/spm"),
        .package(url: "https://github.com/mattmassicotte/tree-sitter-json.git", branch: "feature/spm"),
        .package(url: "https://github.com/lukepistrol/tree-sitter-python.git", branch: "feature/spm"),
        .package(url: "https://github.com/mattmassicotte/tree-sitter-ruby.git", branch: "feature/swift"),
        .package(url: "https://github.com/mattmassicotte/tree-sitter-swift.git", branch: "feature/spm"),
        .package(url: "https://github.com/mattmassicotte/tree-sitter-yaml.git", branch: "feature/spm"),
    ],
    targets: [
        .target(
            name: "CodeEditTextView",
            dependencies: [
                "STTextView",
                "SwiftTreeSitter",
                .product(name: "TreeSitterGo", package: "tree-sitter-go"),
                .product(name: "TreeSitterGoMod", package: "tree-sitter-go-mod"),
                .product(name: "TreeSitterHTML", package: "tree-sitter-html"),
                .product(name: "TreeSitterJSON", package: "tree-sitter-json"),
                .product(name: "TreeSitterPython", package: "tree-sitter-python"),
                .product(name: "TreeSitterRuby", package: "tree-sitter-ruby"),
                .product(name: "TreeSitterSwift", package: "tree-sitter-swift"),
                .product(name: "TreeSitterYAML", package: "tree-sitter-yaml"),
            ]),
        .testTarget(
            name: "CodeEditTextViewTests",
            dependencies: [
                "CodeEditTextView",
            ]),
    ]
)
