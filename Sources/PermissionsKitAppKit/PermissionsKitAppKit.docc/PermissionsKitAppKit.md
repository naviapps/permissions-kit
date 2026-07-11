# ``PermissionsKitAppKit``

Live macOS permission integrations for app-selected permission state.

## Overview

PermissionsKitAppKit provides the live implementation layer for ``PermissionsKit``. It maps public
macOS privacy APIs into normalized PermissionsKit status and request results, opens Core-provided
System Settings URLs, and includes an observable store for app-selected permission state.

Import `PermissionsKitAppKit` when you want to:

- Create a live ``PermissionsKit/PermissionChecker`` with `PermissionChecker()`.
- Track app-selected permission state through ``SystemPermissionsStore``.

## Responsibility Boundary

PermissionsKitAppKit owns the live macOS permission environment, System
Settings opening, and observable permission state.

Host apps remain responsible for permission onboarding strategy, user-facing
copy, privacy disclosures, analytics, persistence, and choosing when to prompt
or refresh permission state. This keeps recovery copy and prompt flow inside
the application that owns the product experience.

## Usage

`PermissionsKitAppKit` adds a live initializer to ``PermissionsKit/PermissionChecker``:

```swift
import PermissionsKit
import PermissionsKitAppKit

let store = SystemPermissionsStore(
  trackedTypes: [.accessibility, .notifications],
  permissionChecker: PermissionChecker()
)

let refreshed = await store.refreshAll()
let accessibilityRequest = await store.requestAccess(for: .accessibility)
```

The live environment uses public macOS APIs where they exist. Permission domains without reliable
public status or request APIs remain available for capability metadata, usage-description lookup,
and System Settings URLs, while `PermissionChecker` returns unsupported results for direct status
and request operations.

## Observable Permission State

Use ``SystemPermissionsStore`` when a view model or SwiftUI/AppKit bridge needs observable state
for the permission types a host app actually presents.

The store is `@MainActor` and is designed for UI-facing state. For lower-level checking and
testing, use ``PermissionsKit/PermissionChecker`` directly.

Call ``SystemPermissionsStore/refreshAll()`` before reading initial state, or
``SystemPermissionsStore/refresh(_:)`` when a view only needs one permission. Refresh and request
methods return the stored result, or `nil` when the permission is not tracked. Use
``SystemPermissionsStore/requestAccess(for:options:)`` to start the permission flow and update
tracked state when it completes. Read ``SystemPermissionsStore/status(for:)`` when UI needs to
distinguish denied, unknown, failed, or unsupported results. Tracked permissions return
`.supported(.unknown)` until refreshed or requested. Use ``SystemPermissionsStore/isGranted(_:)``
only for simple gating. Both methods return `nil` for permission types outside
``SystemPermissionsStore/trackedTypes``.

The store does not open System Settings automatically. Call
``PermissionsKit/PermissionChecker/openSystemSettings(for:)`` directly when the host app chooses to
show a manual recovery path.

Host apps should define any app-specific store protocols or type-erased wrappers at their own
composition boundary.

## Topics

### Observable State

- ``SystemPermissionsStore``
- ``SystemPermissionsStore/init(trackedTypes:permissionChecker:)``
- ``SystemPermissionsStore/trackedTypes``
- ``SystemPermissionsStore/status(for:)``
- ``SystemPermissionsStore/isGranted(_:)``
- ``SystemPermissionsStore/refreshAll()``
- ``SystemPermissionsStore/refresh(_:)``
- ``SystemPermissionsStore/requestAccess(for:options:)``

### Live Checking

- ``PermissionsKit/PermissionChecker/init()``
