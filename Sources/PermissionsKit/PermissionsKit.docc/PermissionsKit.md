# ``PermissionsKit``

Model, check, request, and observe macOS privacy permissions.

## Overview

PermissionsKit defines the platform-neutral core of the package. It provides permission
identifiers, capability metadata, result types, permission options, and a dependency-injected
checker that can be backed by live macOS APIs or by test-specific closures.

Import `PermissionsKit` when you want to:

- Describe permission domains with ``PermissionType``.
- Check whether a permission supports status checks, request APIs, or only System Settings recovery.
- Request access through a custom ``PermissionEnvironment``.
- Find required `Info.plist` usage-description keys.
- Observe permission status changes with ``PermissionStatusObserver``.

For the live macOS implementation, import `PermissionsKitAppKit`.

Use `PermissionsKit` alone for platform-neutral models, custom environments,
and tests. Add `PermissionsKitAppKit` when your app needs the built-in live
macOS implementation, System Settings opening, or SystemPermissionsStore observable state.

## Responsibility Boundary

PermissionsKit owns permission identifiers, capability metadata, result
modeling, usage-description key lookup, dependency-injected checking, and
status observation.

PermissionsKit does not own app onboarding UI, privacy copy, permission prompt
timing, analytics, persistence, or live macOS integrations. Those belong in the
host app or in `PermissionsKitAppKit`.

## Usage

Create a ``PermissionChecker`` with an environment and use the same checker for status, request,
settings, usage-description, and observation flows:

```swift
import PermissionsKit

let checker = PermissionChecker(
  environment: PermissionEnvironment(
    status: { _, _ in .supported(.granted) },
    requestAccess: { _, _ in .supported(.granted) },
    openURL: { _ in true }
  )
)

let result = await checker.status(for: .camera)
let request = await checker.requestAccess(for: .camera)
let missingKeys = PermissionType.camera.missingUsageDescriptions()
```

Switch on ``PermissionOperationResult`` to handle supported values, unsupported capabilities, and
failures explicitly. The enum does not flatten unsupported or failed operations into a synthetic
status value. Capabilities describe whether a permission supports checks, requests, System Settings
URLs, and relaunch requirements.

Each ``PermissionType`` exposes a ``PermissionCapability``:

```swift
import PermissionsKit

let capability = PermissionType.screenRecording.capability
```

``CustomPermission/init(identifier:capability:usageDescriptionKeys:)`` returns `nil` for invalid
host-defined identifiers. Custom identifiers are host-owned, namespaced values that cannot collide
with built-in ``PermissionType`` identifiers. Host apps remain responsible for providing user-facing
usage-description strings in their app target.

``PermissionStatusObserver`` provides a polling-based `AsyncStream` of status changes:

```swift
import PermissionsKit

let stream = PermissionStatusObserver.changes(
  for: [.camera, .microphone, .contacts],
  using: checker
)
```

The observer emits changes after the first observed status; it does not emit an initial snapshot.

## Topics

### Checking and Requesting

- ``PermissionChecker``
- ``PermissionChecker/init(environment:)``
- ``PermissionChecker/status(for:)``
- ``PermissionChecker/status(for:options:)``
- ``PermissionChecker/requestAccess(for:)``
- ``PermissionChecker/requestAccess(for:options:)``
- ``PermissionChecker/openSystemSettings(for:)``
- ``PermissionChecking``
- ``PermissionChecking/status(for:)``
- ``PermissionChecking/status(for:options:)``
- ``PermissionChecking/requestAccess(for:)``
- ``PermissionChecking/requestAccess(for:options:)``
- ``PermissionChecking/openSystemSettings(for:)``
- ``PermissionEnvironment``
- ``PermissionEnvironment/init(status:requestAccess:openURL:)``
- ``PermissionOptions``
- ``NotificationRequestOptions``
- ``NotificationRequestOptions/alert``
- ``NotificationRequestOptions/badge``
- ``NotificationRequestOptions/sound``
- ``NotificationRequestOptions/criticalAlert``
- ``NotificationRequestOptions/provisional``
- ``NotificationRequestOptions/providesAppNotificationSettings``
- ``NotificationRequestOptions/default``
- ``PhotoAccessLevel``
- ``PhotoAccessLevel/default``

### Permission Metadata

- ``PermissionType``
- ``PermissionType/id``
- ``PermissionType/builtIn``
- ``PermissionType/defaultOptions``
- ``PermissionType/capability``
- ``PermissionType/usageDescriptionKeys(for:)``
- ``PermissionType/missingUsageDescriptions(in:options:)``
- ``CustomPermission``
- ``CustomPermission/identifier``
- ``CustomPermission/capability``
- ``CustomPermission/usageDescriptionKeys``
- ``CustomPermission/init(identifier:capability:usageDescriptionKeys:)``
- ``CustomPermission/init(validatingIdentifier:capability:usageDescriptionKeys:)``
- ``CustomPermission/isValidIdentifier(_:)``
- ``CustomPermission/validateIdentifier(_:)``
- ``CustomPermission/IdentifierValidationError``
- ``CustomPermission/validationError(for:)``
- ``PermissionCapability``
- ``PermissionCapability/init(supportsStatusCheck:supportsRequest:systemSettingsURL:requiresRelaunch:)``
- ``PermissionCapability/supportsStatusCheck``
- ``PermissionCapability/supportsRequest``
- ``PermissionCapability/systemSettingsURL``
- ``PermissionCapability/requiresRelaunch``
- ``UsageDescriptionKey``

### Results

- ``PermissionStatus``
- ``PermissionOperationResult``
- ``PermissionError``

### Observation

- ``PermissionStatusObserver``
- ``PermissionStatusObserver/changes(for:using:pollingInterval:options:)``
- ``PermissionStatusObserver/Change``
- ``PermissionStatusObserver/Change/init(type:previousResult:currentResult:)``
- ``PermissionStatusObserver/Change/type``
- ``PermissionStatusObserver/Change/previousResult``
- ``PermissionStatusObserver/Change/currentResult``
