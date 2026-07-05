// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "nosleep",
    platforms: [.macOS(.v14)], // Set your minimum macOS version
    products: [
        // The product is an executable, which will become your .app bundle
        .executable(name: "nosleep", targets: ["nosleep"]),
    ],
    targets: [
        .executableTarget(
            name: "nosleep",
            dependencies: [],
            path: "Sources",
            // Add AppKit and SwiftUI as linked frameworks
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("SwiftUI"),
            ]
        )
    ]
)
