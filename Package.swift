// swift-tools-version: 6.0

import PackageDescription

let package = Package(
  name: "LockScreen",
  platforms: [
    .macOS(.v14)
  ],
  products: [
    .executable(name: "LockScreen", targets: ["LockScreenApp"])
  ],
  targets: [
    .target(name: "LockScreenCore"),
    .executableTarget(
      name: "LockScreenApp",
      dependencies: ["LockScreenCore"]
    ),
    .testTarget(
      name: "LockScreenCoreTests",
      dependencies: ["LockScreenCore"]
    ),
  ]
)
