# ``PermissionsKitAppKit``

Live macOS permission integrations for app-facing UI flows.

## Overview

PermissionsKitAppKit provides the live implementation layer for ``PermissionsKit``. It maps public macOS privacy APIs into normalized PermissionsKit status and request results, opens System Settings deep links, and includes helpers for common app-facing permission UI flows.

Import `PermissionsKitAppKit` when you want to:

- Use ``PermissionsKit/PermissionEnvironment/live`` with system frameworks.
- Create a live ``PermissionsKit/PermissionChecker`` with `PermissionChecker()`.
- Track common permission state through ``SystemPermissionsStore``.
- Pass permission state across type-erased UI boundaries with ``AnySystemPermissionsStore``.
- Present Accessibility, Automation, and Screen Recording guidance through ``SystemPermissionCoordinator``.
- Customize guidance strings through ``SystemPermissionGuidanceStrings``.

## Live Checker

`PermissionsKitAppKit` adds a live initializer to ``PermissionsKit/PermissionChecker``:

```swift
import PermissionsKit
import PermissionsKitAppKit

let checker = PermissionChecker()
let status = await checker.status(for: .camera)
```

The live environment uses public macOS APIs where they exist. Permission domains without reliable public status or request APIs remain available for capability metadata and System Settings links, while unsupported operations return unsupported or failed results.

## Observable Permission State

Use ``SystemPermissionsStore`` when a view model or SwiftUI/AppKit bridge needs simple published permission flags:

```swift
@MainActor
let store = SystemPermissionsStore()

await store.refreshAll()
await store.requestAccessibilityPermission()
await store.requestScreenRecordingPermission()
```

The store is `@MainActor` and is designed for UI-facing state. For lower-level checking and testing, use ``PermissionsKit/PermissionChecker`` directly.

Call ``SystemPermissionsStore/refreshAll()`` before reading initial state. Request methods such as ``SystemPermissionsStore/requestAccessibilityPermission()`` start the system flow and update the published state when they complete.

Input Monitoring is settings-only in the core permission model. With the default live checker, ``SystemPermissionsStore/inputMonitoringGranted`` stays false unless you inject a checker that can report a trusted app-specific signal.

Use ``AnySystemPermissionsStore`` when you need to pass any ``SystemPermissionsStoreProviding`` implementation through a type-erased boundary such as a SwiftUI environment.

## Guided System Permissions

``SystemPermissionCoordinator`` centralizes user-initiated guidance for permissions that often require System Settings or app relaunch behavior:

- Accessibility
- Automation
- Screen Recording

Customize user-facing copy with ``SystemPermissionGuidanceStrings`` and provide a ``SystemPermissionLogger`` when you want to capture warning-level guidance events.

## Topics

### Live Environment

- ``PermissionsKit/PermissionEnvironment/live``
- ``PermissionsKit/PermissionChecker/init()``

### Observable State

- ``SystemPermissionsStore``
- ``SystemPermissionsStoreProviding``
- ``AnySystemPermissionsStore``

### Guided Permission Flows

- ``SystemPermissionCoordinator``
- ``SystemPermissionGuidanceStrings``
- ``SystemPermissionLogger``
- ``NoopSystemPermissionLogger``
