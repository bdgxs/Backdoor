// swift-tools-version:5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Feather",
    platforms: [
        .iOS(.v15) // Matches IPHONEOS_DEPLOYMENT_TARGET = 15.0
    ],
    products: [
        // Define a library product since SPM doesn't directly support app bundles
        .library(
            name: "Feather",
            targets: ["Feather"]
        )
    ],
    dependencies: [
        // Nuke (includes Nuke, NukeExtensions, NukeUI, NukeVideo)
        .package(url: "https://github.com/kean/Nuke", from: "12.7.0"),
        
        // ZIPFoundation
        .package(url: "https://github.com/weichsel/ZIPFoundation", from: "0.9.19"),
        
        // UIOnboarding-18 (product name: UIOnboarding, using main branch)
        .package(url: "https://github.com/khcrysalis/UIOnboarding-18", branch: "main"),
        
        // Vapor
        .package(url: "https://github.com/vapor/vapor", from: "4.104.0"),
        
        // SWCompression
        .package(url: "https://github.com/tsolomko/SWCompression", from: "4.8.6"),
        
        // AlertKit
        .package(url: "https://github.com/sparrowcode/AlertKit", from: "5.1.9"),
        
        // OpenSSL-Swift-Package (product name: OpenSSL, using main branch)
        .package(url: "https://github.com/HAHALOSAH/OpenSSL-Swift-Package", branch: "main")
    ],
    targets: [
        .target(
            name: "Feather",
            dependencies: [
                .product(name: "Nuke", package: "Nuke"),
                .product(name: "NukeExtensions", package: "Nuke"),
                .product(name: "NukeUI", package: "Nuke"),
                .product(name: "NukeVideo", package: "Nuke"),
                .product(name: "ZIPFoundation", package: "ZIPFoundation"),
                .product(name: "UIOnboarding", package: "UIOnboarding-18"),
                .product(name: "Vapor", package: "vapor"),
                .product(name: "SWCompression", package: "SWCompression"),
                .product(name: "AlertKit", package: "AlertKit"),
                .product(name: "OpenSSL", package: "OpenSSL-Swift-Package")
            ],
            path: "iOS", // Assuming source files are under iOS directory
            exclude: [
                // Exclude non-source files if needed; adjust based on your structure
            ],
            resources: [
                // Localizable.strings for multiple languages
                .process("Shared/Localizations/Localizable.strings"),
                // Markdown files as resources
                .process("Shared/Resources/SWCompression.md"),
                .process("Shared/Resources/Zsign.md"),
                .process("Shared/Resources/Nuke.md"),
                .process("Shared/Resources/HttpSwift_RequestSwift_SocketSwift.md"),
                .process("Shared/Resources/UIOnboarding.md"),
                .process("Shared/Resources/Ellekit.md"),
                .process("Shared/Resources/Asspp.md"),
                .process("Shared/Resources/Antoine.md")
            ],
            swiftSettings: [
                .define("DEBUG", .when(configuration: .debug))
            ]
        )
    ]
)