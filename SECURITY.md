# Security Policy

## Supported Versions

Security updates are provided for the latest released version of PermissionsKit.

## Reporting a Vulnerability

Please report security issues through GitHub's private vulnerability reporting for this repository.

Do not open a public GitHub issue or pull request for vulnerabilities, suspected credential exposure, or privacy-sensitive behavior.

If private vulnerability reporting is not enabled, open a public issue asking for a private security contact channel, but do not include vulnerability details, exploit steps, logs, secrets, or personal data.

When reporting an issue, include:

- Affected package version or commit
- A clear description of the behavior
- Reproduction steps or a minimal proof of concept
- Expected impact and affected permission domains, if known

We will acknowledge valid reports as soon as practical and coordinate fixes before public disclosure.

## Scope

Security-sensitive areas include:

- macOS privacy permission checks and request flows
- System Settings deep links
- Usage-description metadata
- Permission status observation and logging hooks

PermissionsKit does not collect, transmit, or persist user permission data by itself. Host applications are responsible for their own logging, telemetry, and privacy policies.
