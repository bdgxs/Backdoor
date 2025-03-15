// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "Backdoor",
    platforms: [
        .iOS(.v15) // Adjust this to your minimum deployment target
    ],
    dependencies: [
        // SwiftZip
        .package(url: "https://github.com/marmelroy/Zip.git", from: "2.1.2") // Use the latest version here
    ],
    targets: [
        .target(
            name: "Backdoor",
            dependencies: [
                .product(name: "Zip", package: "Zip")
            ]
        ),
        .testTarget(
            name: "BackdoorTests",
            dependencies: ["Backdoor"]
        )
    ]
)