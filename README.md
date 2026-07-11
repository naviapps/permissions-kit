# PermissionsKit

[![CI](https://github.com/naviapps/permissions-kit/actions/workflows/ci.yml/badge.svg)](https://github.com/naviapps/permissions-kit/actions/workflows/ci.yml)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Swift versions](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fnaviapps%2Fpermissions-kit%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/naviapps/permissions-kit)
[![Supported platforms](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fnaviapps%2Fpermissions-kit%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/naviapps/permissions-kit)

PermissionsKit is a Swift package for checking and requesting macOS privacy permissions.

It focuses on macOS privacy APIs where system behavior is uneven: supported permissions can be
checked and requested directly, settings-only permissions expose metadata and System Settings URLs
without pretending grant state is reliable, and permission side effects are injectable for tests
and custom app flows.

The package is split into two libraries:

- `PermissionsKit`: core permission types, request/status contracts, usage-description metadata,
  and status observation.
- `PermissionsKitAppKit`: live AppKit-backed implementations for macOS system APIs, System
  Settings opening, and an observable store for app-selected permission state.

## Requirements

- macOS 14 or later
- Swift 6.0 or later

## Installation

Add this package to your Swift Package dependencies:

```swift
.package(url: "https://github.com/naviapps/permissions-kit.git", from: "2.0.0")
```

Then add one or both products to your target:

```swift
.product(name: "PermissionsKit", package: "permissions-kit"),
.product(name: "PermissionsKitAppKit", package: "permissions-kit"),
```

## Documentation

- [PermissionsKit API reference](https://swiftpackageindex.com/naviapps/permissions-kit/documentation/permissionskit)
- [PermissionsKitAppKit API reference](https://swiftpackageindex.com/naviapps/permissions-kit/documentation/permissionskitappkit)

## Basic Usage

Use `PermissionsKitAppKit` when you want the live macOS implementation:

```swift
import PermissionsKit
import PermissionsKitAppKit

let checker = PermissionChecker()

let cameraStatus = await checker.status(for: .camera)
if case .supported(.notDetermined) = cameraStatus {
  _ = await checker.requestAccess(for: .camera)
}

_ = checker.openSystemSettings(for: .screenRecording)
```

Use `PermissionsKit` alone when you want to inject your own environment, for example in tests:

```swift
import PermissionsKit

let checker = PermissionChecker(
  environment: PermissionEnvironment(
    status: { _, _ in .supported(.granted) },
    requestAccess: { _, _ in .supported(.granted) },
    openURL: { _ in true }
  )
)
```

## Permission Model

`PermissionType.builtIn` includes common macOS privacy domains such as camera, microphone,
contacts, calendars, reminders, photos, speech recognition, notifications, accessibility, input
monitoring, screen recording, full disk access, files and folders, automation, and related
settings-only permissions.

Some macOS permissions can be checked and requested through public APIs. Others are settings-only:
the package exposes capability metadata and System Settings URLs, but `status` and `requestAccess`
return unsupported results when macOS does not provide a reliable public API.

Settings-only permissions are intentionally modeled as unsupported for status checks and direct
requests. For example, Input Monitoring, Full Disk Access, and Automation can expose useful System
Settings URLs and metadata, but the standard live implementation cannot reliably report them as
granted through `PermissionChecker.status(for:)`. If your app has a trusted external signal for one
of these permissions, inject it in your own environment or UI state.

Permission behavior and System Settings URLs can vary across macOS releases. Prefer the
capability metadata and operation results over assuming every permission behaves the same on every
supported macOS version.
Live notification status and request checks require an app bundle process; command-line and SwiftPM
test processes return `.failed(.apiUnavailable)` instead of touching `UNUserNotificationCenter`.

| Permission type | Status check | Request | Settings URL | Info.plist key | Relaunch |
| --- | --- | --- | --- | --- | --- |
| `accessibility` | Yes | Yes | Yes | None | No |
| `inputMonitoring` | Settings-only | Settings-only | Yes | None | Yes |
| `screenRecording` | Yes | Yes | Yes | None | Yes |
| `camera` | Yes | Yes | Yes | `NSCameraUsageDescription` | No |
| `microphone` | Yes | Yes | Yes | `NSMicrophoneUsageDescription` | No |
| `contacts` | Yes | Yes | Yes | `NSContactsUsageDescription` | No |
| `calendars` | Yes | Yes | Yes | `NSCalendarsFullAccessUsageDescription` | No |
| `reminders` | Yes | Yes | Yes | `NSRemindersFullAccessUsageDescription` | No |
| `photos` | Yes | Yes | Yes | `NSPhotoLibraryUsageDescription` or `NSPhotoLibraryAddUsageDescription` | No |
| `speechRecognition` | Yes | Yes | Yes | `NSSpeechRecognitionUsageDescription` | No |
| `notifications` | Yes | Yes | Yes | None | No |
| `location` | Settings-only | Settings-only | Yes | `NSLocationUsageDescription` | No |
| `bluetooth` | Settings-only | Settings-only | Yes | `NSBluetoothAlwaysUsageDescription` | No |
| `localNetwork` | Settings-only | Settings-only | Yes | `NSLocalNetworkUsageDescription` | No |
| `mediaLibrary` | Settings-only | Settings-only | Yes | `NSAppleMusicUsageDescription` | No |
| `systemAudioCapture` | Settings-only | Settings-only | Yes | `NSAudioCaptureUsageDescription` | No |
| `desktopFolder` / `documentsFolder` / `downloadsFolder` | Settings-only | Settings-only | Yes | `NSDesktopFolderUsageDescription`, `NSDocumentsFolderUsageDescription`, `NSDownloadsFolderUsageDescription` | No |
| `networkVolumes` / `removableVolumes` / `fileProviderDomain` | Settings-only | Settings-only | Yes | `NSNetworkVolumesUsageDescription`, `NSRemovableVolumesUsageDescription`, `NSFileProviderDomainUsageDescription` | No |
| `fullDiskAccess` | Settings-only | Settings-only | Yes | None | Yes |
| `automation` | Settings-only | Settings-only | Yes | `NSAppleEventsUsageDescription` | No |

Custom permissions use host-supplied capability metadata and optional usage-description keys. Their
identifiers must be host-owned, namespaced lowercase ASCII IDs with at least two `.`-separated
segments. Each segment must start and end with a lowercase letter or digit and may contain lowercase
letters, digits, `_`, or `-`. Identifiers cannot collide with built-in IDs.
`CustomPermission.init(identifier:capability:usageDescriptionKeys:)` returns `nil` for invalid
identifiers; use `CustomPermission.validationError(for:)` when user- or
configuration-supplied IDs need an explanation, or `CustomPermission.isValidIdentifier(_:)` when a
Boolean gate is enough. Use `CustomPermission.validateIdentifier(_:)` when validation should throw
`CustomPermission.IdentifierValidationError` without constructing a permission, or
`CustomPermission.init(validatingIdentifier:capability:usageDescriptionKeys:)` when construction
should throw `CustomPermission.IdentifierValidationError` directly.

## Responsibility Boundary

Host apps own permission onboarding, usage-description copy, recovery dialogs,
analytics, and app-specific permission recovery flows. PermissionsKit exposes
reusable status checks, request actions, usage-description key requirements,
and status observation. PermissionsKitAppKit exposes live macOS permission integrations, System
Settings opening, and SystemPermissionsStore observable state.

## Usage Descriptions

Permissions that require `Info.plist` usage descriptions expose their required keys:

```swift
import PermissionsKit

let missingKeys = PermissionType.camera.missingUsageDescriptions()
```

Host apps are responsible for adding user-facing usage-description strings to their app target. The
package does not inject or generate `Info.plist` values, and usage-description keys are intentionally
kept separate from capability metadata because Photos and custom permissions can depend on request
shape or host-defined policy. Custom permission keys are deduplicated while preserving their
first-seen order.

## Observing Changes

`PermissionStatusObserver` can poll permission status and emit changes through `AsyncStream`:

```swift
import PermissionsKit

let stream = PermissionStatusObserver.changes(
  for: [.camera, .microphone, .contacts],
  using: checker
)

for await change in stream {
  print("\(change.type.id): \(change.previousResult) -> \(change.currentResult)")
}
```

The observer emits changes after the first observed status; it does not emit an initial snapshot.
Each change carries the permission type plus the previous and current status-check results. Polling
intervals below 250 milliseconds are clamped to 250 milliseconds.

## UI Integration

`PermissionsKitAppKit` includes `SystemPermissionsStore`, an `ObservableObject` for app-selected
permission state. Pass the permission types your host UI actually presents, then read
`status(for:)` when UI needs to distinguish denied, unknown, failed, unsupported, or granted
results. Use `isGranted(_:)` only for simple Boolean gating. Both methods return `nil` for
permission types outside `trackedTypes`. Tracked permissions return `.supported(.unknown)` until
they are refreshed or requested.

```swift
import PermissionsKit
import PermissionsKitAppKit

@MainActor
func updatePermissionState() async {
  let store = SystemPermissionsStore(
    trackedTypes: [.accessibility, .screenRecording]
  )

  await store.refreshAll()
  _ = store.status(for: .screenRecording)
  _ = await store.requestAccess(for: .accessibility)
  _ = await store.refresh(.screenRecording)
}
```

Call `refreshAll()` before reading initial state from the system, or `refresh(_:)` when a view only
needs one permission. Refresh and request methods return the stored result, or `nil` when the
permission is not tracked, so UI actions do not have to re-read state just to know what happened.
Host apps should own permission onboarding strategy, user-facing copy, analytics, store injection,
and the exact moment a manual recovery path is presented. Call
`PermissionChecker.openSystemSettings(for:)` explicitly when the app wants to send a user to
System Settings.

## Live Tests

The default test suite includes live status smoke tests that avoid prompting for system
permissions. Request and settings-opening flows remain covered by deterministic test doubles:

```sh
make test
```

## Development

Run the package check with:

```sh
make check
```

GitHub Actions runs the same check on pull requests and pushes to `main`.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). Release notes are in [CHANGELOG.md](CHANGELOG.md).

## Security

Report vulnerabilities privately. See [SECURITY.md](SECURITY.md).

## License

PermissionsKit is released under the MIT License. See [LICENSE](LICENSE).
