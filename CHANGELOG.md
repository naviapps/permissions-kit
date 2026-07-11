# Changelog

All notable user-facing changes to PermissionsKit will be documented in this file.

Released versions follow semantic versioning.

## [Unreleased]

No changes yet.

## [2.0.0] - 2026-07-12

### Added

- Added `NotificationRequestOptions` as the package-owned notification authorization option set.
- Added `PhotoAccessLevel` as the package-owned Photos request access-level model.
- Added `Codable` conformance to `PermissionStatus`, `UsageDescriptionKey`,
  `PermissionCapability`, `PermissionType`, `PermissionOptions`, `NotificationRequestOptions`,
  `PhotoAccessLevel`, and `PermissionError`, plus `PermissionOperationResult`
  when its value is codable, using explicit case and payload keys that reject invalid payload
  shapes.
- Added `Hashable` conformance to `PermissionStatus`, `UsageDescriptionKey`,
  `PhotoAccessLevel`, `PermissionOperationResult` when its value is hashable,
  `PermissionError`, and `PermissionStatusObserver.Change`.
- Added `CustomPermission.isValidIdentifier(_:)` and reserved built-in permission identifiers from
  custom permission IDs.
- Added `CustomPermission.validationError(for:)` and
  `CustomPermission.IdentifierValidationError` so host apps can explain rejected custom permission
  identifiers without duplicating package validation rules.
- Added `CustomPermission.validateIdentifier(_:)` for callers that want throwing validation without
  constructing a permission value.
- Added `CustomPermission.init(validatingIdentifier:capability:usageDescriptionKeys:)` for callers
  that want construction to throw the package validation reason directly.
- Added README links to release notes.

### Changed

- Raised the package toolchain baseline to Swift 6.0.
- Moved DocC catalogs to module-named directories and expanded public documentation for package
  responsibility boundaries.
- Removed package-owned permission guidance dialogs, strings, and loggers from the
  public `PermissionsKitAppKit` surface; host apps own onboarding copy and UI flow.
- Replaced the fixed five-permission `SystemPermissionsStore` convenience surface with tracked
  `PermissionType` state, generic refresh/request APIs, and `isGranted(_:)`.
- Removed operation-specific result shortcuts in favor of using
  `PermissionOperationResult<PermissionStatus>` and
  `PermissionOperationResult<Bool>` directly.
- Removed `PermissionOperationResult` payload and state convenience properties; callers now switch
  on `supported`, `unsupported`, and `failed` cases directly.
- Removed the unconditional `Equatable` value constraint from `PermissionOperationResult`;
  equality and hashing are now conditional on the wrapped value type.
- Removed `PermissionStatus` case-check convenience properties; callers now compare or switch on
  status cases directly.
- Changed `PermissionEnvironment.status` to return `PermissionOperationResult<PermissionStatus>`
  so injected and live status checks can report failures without flattening them to `.unknown`.
- Removed `PermissionType` metadata convenience properties that duplicated
  `PermissionCapability`; callers now read capability fields directly.
- Removed usage-description keys from `PermissionCapability`; callers now use
  `PermissionType.usageDescriptionKeys(for:)`, `PermissionType.missingUsageDescriptions`, or
  `CustomPermission.usageDescriptionKeys`.
- Made custom permission usage-description keys deduplicate while preserving first-seen order.
- Removed the observation configuration type and logging hook; status observation now accepts a
  polling interval directly and leaves logging to host apps.
- Stopped `SystemPermissionsStore` from opening System Settings automatically for unsupported or
  failed requests; host apps now own manual recovery timing.
- Renamed the injectable `PermissionEnvironment` request closure and `SystemPermissionsStore`
  request method to `requestAccess` for consistent permission terminology.
- Replaced public `PermissionEnvironment` stored closure access with labeled status and request
  methods while keeping closure injection in the initializer.
- Removed public `PermissionError` string descriptions; host apps own logging and user-facing error
  text.
- Removed hidden Contacts/EventKit notification hooks from the core status observer; observation is
  now purely polling-based.
- Renamed `PermissionStatusObserver.Change` payloads to `previousResult` and `currentResult`, and
  renamed the observer options closure label to `options`.
- Made direct live environment requests for unsupported permission types return unsupported
  capability results instead of API-unavailable failures.
- Made `SystemPermissionsStore` distinguish untracked permission types from unknown tracked state:
  status and grant checks now return `nil` for permissions outside `trackedTypes`, and refresh or
  request calls ignore untracked types.
- Made `SystemPermissionsStore` refresh and request methods return stored results, with `nil` for
  untracked permissions, and narrowed targeted refresh to a single permission.
- Removed the public `SystemPermissionsStore.tracks(_:)` helper; callers can inspect
  `trackedTypes` or use nil-returning state and operation methods.
- Hid direct `PermissionEnvironment` status and request execution methods from the public surface;
  `PermissionChecker` is the public execution API.
- Hid the AppKit live `PermissionEnvironment` value from the public surface; live macOS behavior is
  exposed through `PermissionChecker()`.
- Removed the one-case System Settings outcome enum; successful System Settings opens now return
  `.supported(true)`.
- Removed the AppKit store protocol and type-erased wrapper; host apps own app-specific store
  abstraction and injection boundaries.
- Kept `CustomPermission.IdentifierValidationError` case names scoped to their nested type by using
  `empty`, `reserved`, `emptySegment`, `invalidSegmentBoundary`, and `invalidCharacter` instead of
  repeating identifier terminology in every case.
- Made live notification permission status and request checks return non-crashing fallback results
  outside app bundle processes such as SwiftPM tests.
- Clarified that security updates target the latest released version.

## [1.0.1] - 2026-05-13

### Changed

- Added CI validation for package checks.

## [1.0.0] - 2026-05-13

### Added

- `PermissionsKit` library with permission types, capability metadata, request/status contracts,
  and status observation.
- `PermissionsKitAppKit` library with live macOS permission integrations, System Settings deep
  links, guidance flows, and observable stores.
- Test coverage for permission metadata, request/status behavior, status observation, AppKit
  mappings, and coordinator/store behavior.
- Initial public package documentation, security policy, SwiftPM CI
  configuration, contributor templates, and local development commands.

### Changed

- Documented permission capability coverage and settings-only limitations.
- Clarified package positioning, macOS behavior caveats, and `SystemPermissionsStore` scope.
- Reported all AppKit guidance presentations through `SystemPermissionLogger`.
- Used `PermissionOptions` as the neutral option type for status checks, requests, and metadata
  lookup.
