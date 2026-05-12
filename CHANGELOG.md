# Changelog

All notable changes to PermissionsKit will be documented in this file.

This project follows semantic versioning.

## [Unreleased]

No unreleased changes.

## [1.0.0] - 2026-05-13

### Added

- `PermissionsKit` library with permission types, capability metadata, request/status contracts, and status observation.
- `PermissionsKitAppKit` library with live macOS permission integrations, System Settings deep links, guidance flows, and observable stores.
- Test coverage for permission metadata, request/status behavior, status observation, AppKit mappings, and coordinator/store behavior.
- Initial public package documentation, security policy, SwiftPM CI, Swift Package Index DocC configuration, contributor templates, and local development commands.

### Changed

- Document permission capability coverage and settings-only limitations.
- Clarify package positioning, macOS behavior caveats, and `SystemPermissionsStore` scope.
- Report all AppKit guidance presentations through `SystemPermissionLogger`.
- Use `PermissionOptions` as the neutral option type for status checks, requests, and metadata lookup.
