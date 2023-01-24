// swift-tools-version: 5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "CodeEditTextView",
    platforms: [.macOS(.v12)],
    products: [
        .library(
            name: "CodeEditTextView",
            targets: ["CodeEditTextView"]
        ),
    ],
    dependencies: [
        .package(
            url: "https://github.com/krzyzanowskim/STTextView.git",
            exact: "0.1.2"
        ),
        .package(
            url: "https://github.com/CodeEditApp/CodeEditLanguages.git",
            exact: "0.1.9"
        ),
        .package(
            url: "https://github.com/lukepistrol/SwiftLintPlugin",
            from: "0.2.2"
        ),
    ],
    targets: [
        .target(
            name: "CodeEditTextView",
            dependencies: [
                "STTextView",
                "CodeEditLanguages",
            ],
            plugins: [
                .plugin(name: "SwiftLint", package: "SwiftLintPlugin")
            ]
        ),

        .testTarget(
            name: "CodeEditTextViewTests",
            dependencies: [
                "CodeEditTextView",
                "CodeEditLanguages",
            ]
        ),
    ]
)
