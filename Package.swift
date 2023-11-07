// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "CodeEditTextView",
    platforms: [.macOS(.v13)],
    products: [
        // A source editor with useful features for code editing.
        .library(
            name: "CodeEditTextView",
            targets: ["CodeEditTextView"]
        ),
        // A Fast, Efficient text view for code.
        .library(
            name: "CodeEditInputView",
            targets: ["CodeEditInputView"]
        )
    ],
    dependencies: [
        // tree-sitter languages
        .package(
            url: "https://github.com/CodeEditApp/CodeEditLanguages.git",
            exact: "0.1.17"
        ),
        // SwiftLint
        .package(
            url: "https://github.com/lukepistrol/SwiftLintPlugin",
            from: "0.2.2"
        ),
        // Filters for indentation, pair completion, whitespace
        .package(
            url: "https://github.com/ChimeHQ/TextFormation",
            from: "0.7.0"
        ),
        // Useful data structures
        .package(
            url: "https://github.com/apple/swift-collections.git",
            .upToNextMajor(from: "1.0.0")
        )
    ],
    targets: [
        // A source editor with useful features for code editing.
        .target(
            name: "CodeEditTextView",
            dependencies: [
                "Common",
                "CodeEditInputView",
                "CodeEditLanguages",
                "TextFormation",
            ],
            plugins: [
                .plugin(name: "SwiftLint", package: "SwiftLintPlugin")
            ]
        ),

        // The underlying text rendering view for CodeEditTextView
        .target(
            name: "CodeEditInputView",
            dependencies: [
                "Common",
                "TextFormation"
            ],
            plugins: [
                .plugin(name: "SwiftLint", package: "SwiftLintPlugin")
            ]
        ),

        // Common classes and extensions used in both CodeEditTextView and CodeEditInputView
        .target(
            name: "Common",
            dependencies: [
                .product(name: "Collections", package: "swift-collections")
            ],
            plugins: [
                .plugin(name: "SwiftLint", package: "SwiftLintPlugin")
            ]
        ),

        // Tests for the source editor
        .testTarget(
            name: "CodeEditTextViewTests",
            dependencies: [
                "CodeEditTextView",
                "CodeEditLanguages",
            ],
            plugins: [
                .plugin(name: "SwiftLint", package: "SwiftLintPlugin")
            ]
        ),

        // Tests for the input view
        .testTarget(
            name: "CodeEditInputViewTests",
            dependencies: [
                "CodeEditInputView",
            ],
            plugins: [
                .plugin(name: "SwiftLint", package: "SwiftLintPlugin")
            ]
        ),
    ]
)
