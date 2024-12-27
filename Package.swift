// swift-tools-version:6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "BBCode",
  platforms: [.macOS(.v13), .iOS(.v16), .tvOS(.v13), .watchOS(.v6), .visionOS(.v1)],
  products: [
    .library(name: "BBCode", targets: ["BBCode"])
  ],
  dependencies: [
    .package(url: "https://github.com/onevcat/Kingfisher.git", from: "7.0.0")
  ],
  targets: [
    .target(name: "BBCode", dependencies: ["Kingfisher"]),
    .testTarget(name: "BBCodeTests", dependencies: ["BBCode"]),
  ]
)
