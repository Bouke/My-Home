import PackageDescription

let package = Package(
    name: "my-homekit",
    dependencies: [
        .Package(url: "https://github.com/Bouke/ICY.git", majorVersion: 1),
        .Package(url: "https://github.com/Bouke/HAP.git", majorVersion: 0),
        .Package(url: "https://github.com/Bouke/Evergreen.git", majorVersion: 1),
    ]
)
