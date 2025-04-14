// swift-tools-version:6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "BBCode",
  platforms: [.macOS(.v14), .iOS(.v17), .tvOS(.v17), .watchOS(.v10), .visionOS(.v1)],
  products: [
    .library(name: "BBCode", targets: ["BBCode"])
  ],
  dependencies: [
    .package(url: "https://github.com/onevcat/Kingfisher.git", .upToNextMajor(from: "8.3.2"))
  ],
  targets: [
    .target(name: "BBCode", dependencies: ["Kingfisher"], resources: [.process("Resources")]),
    .testTarget(name: "BBCodeTests", dependencies: ["BBCode"]),
  ]
)
