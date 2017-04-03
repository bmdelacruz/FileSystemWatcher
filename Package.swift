import PackageDescription

let package = Package(
    name: "inotify-swift-lib",
    dependencies: [
      .Package(url: "https://github.com/bmdelacruz/inotify-swift.git", majorVersion: 1)
    ]
)
