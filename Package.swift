// swift-tools-version: 6.0
import PackageDescription

let package = Package(
  name: "PermissionsKit",
  platforms: [.macOS(.v14)],
  products: [
    .library(
      name: "PermissionsKit",
      targets: ["PermissionsKit"]
    ),
    .library(
      name: "PermissionsKitAppKit",
      targets: ["PermissionsKitAppKit"]
    ),
  ],
  targets: [
    .target(
      name: "PermissionsKit"
    ),
    .target(
      name: "PermissionsKitAppKit",
      dependencies: ["PermissionsKit"]
    ),
    .testTarget(
      name: "PermissionsKitTests",
      dependencies: ["PermissionsKit"]
    ),
    .testTarget(
      name: "PermissionsKitAppKitTests",
      dependencies: [
        "PermissionsKit",
        "PermissionsKitAppKit",
      ]
    ),
  ]
)
