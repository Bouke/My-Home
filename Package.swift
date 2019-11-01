// swift-tools-version:4.2

import PackageDescription

let package = Package(
    name: "my-home",
    products: [
        .executable(name: "my-home", targets: ["my-home"]),
    ],
    dependencies: [
        .package(url: "https://github.com/Bouke/ICY.git", from: "1.2.0"),
        .package(url: "https://github.com/Bouke/HAP.git", from: "0.6.0"),
		.package(url: "https://github.com/Bouke/Evergreen.git", from: "2.0.0"),
    ], 
    targets: [
        .target(name: "my-home", dependencies: ["ICY", "HAP", "Evergreen"], path: "Sources"),
    ]
)
