# Security Policy

## Supported Versions

Security updates are provided for the latest released version.

## Reporting a Vulnerability

Report security issues through GitHub private vulnerability reporting for this repository.

Do not open a public issue, pull request, or discussion for vulnerabilities, suspected credential
exposure, privacy-sensitive behavior, or issues that could expose private user data.

If private vulnerability reporting is unavailable, open a public issue asking for a private
security contact channel. Do not include vulnerability details, exploit steps, private logs, secrets,
tokens, private keys, personal data, local paths, private app metadata, or app-specific internal
references.

For private reports, include:

- Affected package version or commit
- Affected dependency versions if relevant
- A clear description of the behavior
- Reproduction steps or a minimal proof of concept
- Expected impact
- Affected public API, target, or subsystem

Use placeholders instead of secrets, tokens, private keys, personal data, private logs, local paths,
private app metadata, or app-specific internal references.

We will acknowledge valid reports as soon as practical and coordinate fixes before public
disclosure.

## Scope

Security-sensitive areas include:

- macOS privacy permission checks and request flows
- System Settings URLs and opening flows
- Usage-description metadata
- Permission status observation
- `SystemPermissionsStore` observable state and injected live `PermissionChecking` providers

PermissionsKit does not collect, transmit, or persist user permission data by itself. Host
applications are responsible for permission prompts, logging, telemetry, privacy disclosures, and
any app-specific permission state storage.
