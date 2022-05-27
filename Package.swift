// swift-tools-version: 5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "CodeEditTextView",
    platforms: [.macOS(.v12)],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "CodeEditTextView",
            targets: ["CodeEditTextView"]),
        .library(
            name: "CodeLanguage",
            targets: ["CodeLanguage"]),
        .library(
            name: "Theme",
            targets: ["Theme"])
    ],
    dependencies: [
        .package(url: "https://github.com/krzyzanowskim/STTextView", branch: "main"),
        .package(url: "https://github.com/ChimeHQ/SwiftTreeSitter", from: "0.6.0"),
        .package(url: "https://github.com/mattmassicotte/tree-sitter-swift.git", branch: "feature/spm"),
        .package(url: "https://github.com/mattmassicotte/tree-sitter-go.git", branch: "feature/swift"),
        .package(url: "https://github.com/camdencheek/tree-sitter-go-mod.git", branch: "main"),
        .package(url: "https://github.com/mattmassicotte/tree-sitter-html.git", branch: "feature/spm"),
        .package(url: "https://github.com/mattmassicotte/tree-sitter-json.git", branch: "feature/spm"),
        .package(url: "https://github.com/mattmassicotte/tree-sitter-ruby.git", branch: "feature/swift"),
        .package(url: "https://github.com/mattmassicotte/tree-sitter-yaml.git", branch: "feature/spm"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "CodeEditTextView",
            dependencies: [
                "STTextView",
                "CodeLanguage",
                "Theme"
            ]),
        .target(
            name: "CodeLanguage",
            dependencies: [
                "SwiftTreeSitter",
                .product(name: "TreeSitterSwift", package: "tree-sitter-swift"),
                .product(name: "TreeSitterGo", package: "tree-sitter-go"),
                .product(name: "TreeSitterGoMod", package: "tree-sitter-go-mod"),
                .product(name: "TreeSitterHTML", package: "tree-sitter-html"),
                .product(name: "TreeSitterJSON", package: "tree-sitter-json"),
                .product(name: "TreeSitterRuby", package: "tree-sitter-ruby"),
                .product(name: "TreeSitterYAML", package: "tree-sitter-yaml"),
            ]
        ),
        .target(
            name: "Theme"
        ),
        .testTarget(
            name: "CodeEditTextViewTests",
            dependencies: ["CodeEditTextView"]),
    ]
)
