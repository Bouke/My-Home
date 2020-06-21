// swift-tools-version:5.1

import PackageDescription

let package = Package(
    name: "my-home",
    platforms: [
        .macOS(.v10_12)
    ],
    products: [
        .executable(name: "my-home", targets: ["my-home"]),
    ],
    dependencies: [
        .package(url: "https://github.com/Bouke/ICY.git", from: "1.2.0"),
        .package(url: "https://github.com/Bouke/HAP.git", from: "0.6.0"),
        .package(url: "https://github.com/apple/swift-log.git", Version("0.0.0") ..< Version("2.0.0")),
    ], 
    targets: [
        .target(name: "my-home", dependencies: ["ICY", "HAP", "Logging"], path: "Sources"),
    ]
)
