# ``PermissionsKit``

Model, check, request, and observe macOS privacy permissions.

## Overview

PermissionsKit defines the platform-neutral core of the package. It provides stable permission identifiers, capability metadata, result types, request options, and a dependency-injected checker that can be backed by live macOS APIs or by test-specific closures.

Import `PermissionsKit` when you want to:

- Describe permission domains with ``PermissionType``.
- Check whether a permission supports status checks, request APIs, or only System Settings guidance.
- Request access through a custom ``PermissionEnvironment``.
- Find required `Info.plist` usage-description keys.
- Observe permission status changes with ``PermissionStatusObserver``.

For the live macOS implementation, import `PermissionsKitAppKit`.

## Checking Permission Status

Create a ``PermissionChecker`` with an environment and ask for a status result:

```swift
let checker = PermissionChecker(
  environment: PermissionEnvironment(
    status: { _, _ in .granted },
    request: { _, _ in .supported(.granted) },
    openURL: { _ in true }
  )
)

let result = await checker.status(for: .camera)
```

Use ``PermissionOperationResult/status`` when you only need the normalized status value. Check ``PermissionOperationResult/isUnsupported`` when the system does not expose a reliable API for the permission.

Request access with ``PermissionChecker/requestAccess(for:options:)`` and open manual settings flows with ``PermissionChecker/openSystemSettings(for:)``:

```swift
let request = await checker.requestAccess(for: .camera)
let settings = checker.openSystemSettings(for: .screenRecording)
```

## Permission Capabilities

Each ``PermissionType`` exposes a ``PermissionCapability``:

```swift
let capability = PermissionType.screenRecording.capability
```

Capabilities tell host apps whether a permission supports status checks, request APIs, System Settings links, relaunch guidance, and usage-description requirements.

Some macOS permission domains are settings-only. For those domains, PermissionsKit exposes metadata and System Settings links, but ``PermissionChecker/status(for:options:)`` and ``PermissionChecker/requestAccess(for:options:)`` return unsupported results instead of pretending that the status is known.

## Usage Descriptions

Use ``PermissionType/missingUsageDescriptions(in:)`` to detect missing `Info.plist` keys:

```swift
let missingKeys = PermissionType.camera.missingUsageDescriptions()
```

Pass request options when the required key depends on the request shape, such as add-only Photos access:

```swift
let missingKeys = PermissionType.photos.missingUsageDescriptions(options: .photos(.addOnly))
```

Host apps are responsible for providing user-facing usage-description strings in their app target. PermissionsKit only reports the keys that apply to each permission type.

## Observing Changes

``PermissionStatusObserver`` provides an `AsyncStream` of status changes:

```swift
let stream = PermissionStatusObserver.changes(
  for: [.camera, .microphone, .contacts],
  using: checker
)
```

The observer combines polling with selected system notifications where available.
It emits changes after the first observed status; it does not emit an initial snapshot.

## Topics

### Checking and Requesting

- ``PermissionChecker``
- ``PermissionChecking``
- ``PermissionEnvironment``
- ``PermissionRequestOptions``
- ``NotificationRequestOptions``
- ``PhotoAccessLevel``

### Permission Metadata

- ``PermissionType``
- ``CustomPermission``
- ``PermissionCapability``
- ``UsageDescriptionKey``

### Results

- ``PermissionStatus``
- ``PermissionOperationResult``
- ``PermissionStatusResult``
- ``PermissionRequestResult``
- ``PermissionOpenSettingsResult``
- ``PermissionOpenSettingsOutcome``
- ``PermissionError``

### Observation

- ``PermissionStatusObserver``
- ``PermissionStatusObserver/Change``
- ``PermissionObservationConfiguration``
