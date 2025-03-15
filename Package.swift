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
        .package(url: "https://github.com/huri000/SwiftUIOnboarding", from: "2.0.0"),
        .package(url: "https://github.com/kean/Nuke", from: "12.0.0"),
        .package(url: "https://github.com/vapor/vapor", from: "4.0.0"),
        .package(url: "https://github.com/vapor/websocket-kit", from: "1.0.0"),
        .package(url: "https://github.com/vapor/async-kit", from: "1.0.0"),
        .package(url: "https://github.com/vapor/console-kit", from: "4.0.0"),
        .package(url: "https://github.com/vapor/routing-kit", from: "4.0.0"),
        .package(url: "https://github.com/vapor/multipart-kit", from: "4.0.0"),
        .package(url: "https://github.com/vapor/http", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-algorithms", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-collections", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-numerics", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-nio", from: "2.0.0"),
        .package(url: "https://github.com/apple/swift-nio-extras", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-nio-transport-services", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-nio-ssl", from: "2.0.0"),
        .package(url: "https://github.com/swift-server/async-http-client", from: "1.0.0"),
        .package(url: "https://github.com/swift-server/swift-backtrace", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-metrics", from: "2.0.0"),
        .package(url: "https://github.com/apple/swift-log", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-crypto", from: "2.0.0"),
        .package(url: "https://github.com/apple/swift-system", from: "1.0.0"),
        .package(url: "https://github.com/ZipArchive/ZipArchive", from: "2.0.0"),
        .package(url: "https://github.com/marmelroy/Zip", from: "2.1.2"), // Updated to 2.1.2
        .package(url: "https://github.com/SammySmallman/BitByteData", from: "2.0.0"),
        .package(url: "https://github.com/alexsteinerde/SwiftLMDB", from: "0.9.7"),
        .package(url: "https://github.com/tsolomko/SWCompression", from: "4.6.0"),
        .package(url: "https://github.com/Kitura/OpenSSL", from: "2.0.0"),
        .package(url: "https://github.com/sparrowcode/AlertKit", from: "2.0.0"),
        .package(url: "https://github.com/Flight-School/AnyCodable", from: "0.6.0")
    ],
    targets: [
        .target(
            name: "Backdoor",
            dependencies: [
                .product(name: "AlertKit", package: "AlertKit"),
                .product(name: "AsyncHTTPClient", package: "async-http-client"),
                .product(name: "AsyncKit", package: "async-kit"),
                .product(name: "BitByteData", package: "BitByteData"),
                .product(name: "ConsoleKit", package: "console-kit"),
                .product(name: "MultipartKit", package: "multipart-kit"),
                .product(name: "Nuke", package: "Nuke"),
                .product(name: "OpenSSL", package: "OpenSSL"),
                .product(name: "RoutingKit", package: "routing-kit"),
                .product(name: "SWCompression", package: "SWCompression"),
                .product(name: "Algorithms", package: "swift-algorithms"),
                .product(name: "Atomics", package: "swift-backtrace"), // Note: This might not be correct; 'Atomics' is typically from 'swift-atomics'
                .product(name: "Collections", package: "swift-collections"),
                .product(name: "Crypto", package: "swift-crypto"),
                .product(name: "HTTPTypes", package: "http"),
                .product(name: "Logging", package: "swift-log"),
                .product(name: "Metrics", package: "swift-metrics"),
                .product(name: "NIO", package: "swift-nio"),
                .product(name: "NIOExtras", package: "swift-nio-extras"),
                .product(name: "NIOHTTP2", package: "swift-nio"),
                .product(name: "NIOSSL", package: "swift-nio-ssl"),
                .product(name: "NIOTransportServices", package: "swift-nio-transport-services"),
                .product(name: "Numerics", package: "swift-numerics"),
                .product(name: "System", package: "swift-system"),
                .product(name: "SwiftUIOnboarding", package: "SwiftUIOnboarding"),
                .product(name: "Vapor", package: "vapor"),
                .product(name: "WebSocketKit", package: "websocket-kit"),
                .product(name: "ZIPFoundation", package: "ZipArchive"),
                .product(name: "Zip", package: "Zip"),
            ],
            path: "main/Backdoor"
        ),
        .testTarget(
            name: "BackdoorTests",
            dependencies: ["Backdoor"]
        )
    ]
)