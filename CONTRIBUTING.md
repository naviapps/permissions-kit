# Contributing

Thank you for your interest in improving PermissionsKit.

## Scope

PermissionsKit focuses on macOS privacy permission metadata, status checks, request flows, System Settings links, and small app-facing helpers.

Please keep changes focused. Avoid bundling unrelated refactors, formatting-only rewrites, and behavior changes in the same pull request.

## Development

Run the test suite before opening a pull request:

```sh
swift test
```

Check formatting before opening a pull request:

```sh
swift format lint --recursive --strict Sources Tests Package.swift
```

If you have `just` installed, you can run formatting lint and tests with:

```sh
just check
```

To inspect local code coverage, run:

```sh
just coverage
```

Live system-permission tests are skipped by default. Run them only when you intentionally want to exercise real macOS permission APIs:

```sh
RUN_LIVE_TESTS=1 swift test
```

## Pull Requests

Before submitting a pull request:

- Keep the public API surface minimal and documented.
- Add or update tests for behavior changes.
- Update `README.md` or `CHANGELOG.md` when user-facing behavior changes.
- Do not commit generated build output such as `.build/` or `.swiftpm/`.
- Do not include secrets, tokens, private keys, local paths, or app-specific internal references.

## Security

Do not report vulnerabilities in public issues or pull requests. Follow [SECURITY.md](SECURITY.md) instead.
