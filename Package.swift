// swift-tools-version:5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Feather",
    platforms: [
        .iOS(.v15) // Matches IPHONEOS_DEPLOYMENT_TARGET = 15.0
    ],
    products: [
        .library(
            name: "Feather",
            targets: ["Feather"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/kean/Nuke", from: "12.7.0"),
        .package(url: "https://github.com/weichsel/ZIPFoundation", from: "0.9.19"),
        .package(url: "https://github.com/khcrysalis/UIOnboarding-18", branch: "main"),
        .package(url: "https://github.com/vapor/vapor", from: "4.104.0"),
        .package(url: "https://github.com/tsolomko/SWCompression", from: "4.8.6"),
        .package(url: "https://github.com/sparrowcode/AlertKit", from: "5.1.9"),
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
            path: "iOS", // Main source directory from Makefile and INFOPLIST_FILE
            sources: [
                // Explicitly include all Swift files; adjust if more exist
                "../Shared/Localizations/Foundation.swift",
                "../Shared/Localizations/Language.swift",
                "Views/Home/HomeViewTableHandlers.swift" // Assuming this is in iOS/Views/Home/
            ],
            resources: [
                .process("../Shared/Localizations/Localizable.strings"),
                .process("../Shared/Resources/SWCompression.md"),
                .process("../Shared/Resources/Zsign.md"),
                .process("../Shared/Resources/Nuke.md"),
                .process("../Shared/Resources/HttpSwift_RequestSwift_SocketSwift.md"),
                .process("../Shared/Resources/UIOnboarding.md"),
                .process("../Shared/Resources/Ellekit.md"),
                .process("../Shared/Resources/Asspp.md"),
                .process("../Shared/Resources/Antoine.md"),
                .copy("Info.plist") // From INFOPLIST_FILE = iOS/Info.plist
            ],
            swiftSettings: [
                .define("DEBUG", .when(configuration: .debug)),
                .unsafeFlags(["-Xfrontend", "-warn-long-function-bodies=500"])
            ]
        )
    ]
)