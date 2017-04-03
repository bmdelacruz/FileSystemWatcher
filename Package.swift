import PackageDescription

let package = Package(
    name: "inotify-swift-lib",
    dependencies: [
      .Package(url: "../", majorVersion: 0)
    ]
)
