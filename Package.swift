// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "Backdoor",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(
            name: "Backdoor",
            targets: ["Backdoor"]
        )
    ],
    dependencies: [
        // ... all your dependencies here ...
    ],
    targets: [
        .target(
            name: "Backdoor",
            dependencies: [
                "AlertKit",
                "AsyncHTTPClient",
                "AsyncKit",
                "BitByteData",
                "ConsoleKit",
                "MultipartKit",
                "Nuke",
                "OpenSSL",
                "RoutingKit",
                "SWCompression",
                "Algorithms",
                "Atomics",
                "Collections",
                "Crypto",
                "HTTPTypes",
                "Logging",
                "Metrics",
                "NIO",
                "NIOExtras",
                "NIOHTTP2",
                "NIOSSL",
                "NIOTransportServices",
                "Numerics",
                "System",
                "UIOnboarding",
                "Vapor",
                "WebSocketKit",
                "ZIPFoundation",
                "Zip"
            ],
            path: "main/Backdoor" // Add this line for the custom path
        ),
        .testTarget(
            name: "BackdoorTests",
            dependencies: ["Backdoor"]
        )
    ]
)