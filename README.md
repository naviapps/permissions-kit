# PermissionsKit

[![CI](https://github.com/naviapps/permissions-kit/actions/workflows/ci.yml/badge.svg)](https://github.com/naviapps/permissions-kit/actions/workflows/ci.yml)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-macOS%2014%2B-lightgrey.svg)](Package.swift)
[![Swift Package Index](https://img.shields.io/badge/Swift%20Package%20Index-PermissionsKit-orange.svg)](https://swiftpackageindex.com/naviapps/permissions-kit)

PermissionsKit is a Swift Package for checking, requesting, and guiding users through macOS privacy permissions.

The package is split into two libraries:

- `PermissionsKit`: core permission types, request/status contracts, usage-description metadata, and status observation.
- `PermissionsKitAppKit`: live AppKit-backed implementations for macOS system APIs, System Settings deep links, and observable stores for app UI.

## Requirements

- macOS 14 or later
- Swift 5.10 or later

## Installation

Add this package to your Swift Package dependencies:

```swift
.package(url: "https://github.com/naviapps/permissions-kit.git", from: "0.1.0")
```

Then add one or both products to your target:

```swift
.product(name: "PermissionsKit", package: "permissions-kit"),
.product(name: "PermissionsKitAppKit", package: "permissions-kit"),
```

## Basic Usage

Use `PermissionsKitAppKit` when you want the live macOS implementation:

```swift
import PermissionsKit
import PermissionsKitAppKit

let checker = PermissionChecker()

let cameraStatus = await checker.status(for: .camera)
if cameraStatus.status == .notDetermined {
  _ = await checker.requestAccess(for: .camera)
}

_ = checker.openSystemSettings(for: .screenRecording)
```

Use `PermissionsKit` alone when you want to inject your own environment, for example in tests:

```swift
import PermissionsKit

let checker = PermissionChecker(
  environment: PermissionEnvironment(
    status: { _, _ in .granted },
    request: { _, _ in .supported(.granted) },
    openURL: { _ in true }
  )
)
```

## Permission Model

`PermissionType.builtIn` includes common macOS privacy domains such as camera, microphone, contacts, calendars, reminders, photos, speech recognition, notifications, accessibility, input monitoring, screen recording, full disk access, files and folders, automation, and related settings-only permissions.

Some macOS permissions can be checked and requested through public APIs. Others are settings-only: the package exposes capability metadata and System Settings URLs, but `status` and `requestAccess` return unsupported or failed results when macOS does not provide a reliable public API.

## Usage Descriptions

Permissions that require `Info.plist` usage descriptions expose their required keys:

```swift
let missingKeys = PermissionType.camera.missingUsageDescriptions()
```

Host apps are responsible for adding user-facing usage-description strings to their app target. The package does not inject or generate `Info.plist` values.

## Observing Changes

`PermissionStatusObserver` can poll permission status and emit changes through `AsyncStream`:

```swift
let stream = PermissionStatusObserver.changes(
  for: [.camera, .microphone, .contacts],
  using: checker
)

for await change in stream {
  handlePermissionChange(change)
}
```

## UI Integration

`PermissionsKitAppKit` includes `SystemPermissionsStore`, an `ObservableObject` for common app-facing permission state:

```swift
import PermissionsKitAppKit

@MainActor
let store = SystemPermissionsStore()

store.refreshAll()
store.requestAccessibilityPermission()
store.requestScreenRecordingPermission()
```

The AppKit product also includes `SystemPermissionCoordinator` for user-initiated Accessibility, Automation, and Screen Recording guidance flows.

## Live Tests

The default test suite avoids prompting for system permissions. Live environment tests are skipped unless explicitly enabled:

```sh
RUN_LIVE_TESTS=1 swift test
```

Run the normal validation with:

```sh
swift test
```

If you have `just` installed, the common development commands are also available:

```sh
just check
just format
just coverage
just live-test
```

## License

PermissionsKit is released under the MIT License. See [LICENSE](LICENSE).
