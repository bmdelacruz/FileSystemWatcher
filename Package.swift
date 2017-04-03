import PackageDescription

let package = Package(
    name: "FileSystemWatcher",
    dependencies: [
      .Package(url: "https://github.com/bmdelacruz/inotify-swift.git", majorVersion: 1)
    ]
)
