// swift-tools-version:4.0

import PackageDescription

let package = Package(
    name: "my-home",
    dependencies: [
        .package(url: "https://github.com/Bouke/ICY.git", from: "1.1.0"),
        .package(url: "https://github.com/Bouke/HAP.git", .branch("fix/decrypt-incomplete-frames")),
        .package(url: "https://github.com/knly/Evergreen.git", .branch("swift4"))
    ], 
    targets: [
        .target(name: "my-home", dependencies: ["ICY", "HAP", "Evergreen"], path: "Sources"),
    ]
)
