import PackageDescription

let package = Package(
    name: "FileSystemWatcher",
    dependencies: [
      .Package(url: "https://github.com/bmdelacruz/INotify.git", majorVersion: 1)
    ]
)
