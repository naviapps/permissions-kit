// swift-tools-version: 5.10
import PackageDescription

let package = Package(
  name: "PermissionsKit",
  defaultLocalization: "en",
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
      name: "PermissionsKit",
      path: "Sources/PermissionsKit"
    ),
    .target(
      name: "PermissionsKitAppKit",
      dependencies: ["PermissionsKit"],
      path: "Sources/PermissionsKitAppKit"
    ),
    .testTarget(
      name: "PermissionsKitTests",
      dependencies: ["PermissionsKit"],
      path: "Tests/PermissionsKitTests"
    ),
    .testTarget(
      name: "PermissionsKitAppKitTests",
      dependencies: ["PermissionsKitAppKit"],
      path: "Tests/PermissionsKitAppKitTests"
    ),
  ],
  swiftLanguageVersions: [.v5]
)
