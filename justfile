default:
    just --list

format:
    swift format format --recursive --in-place Sources Tests Package.swift

lint:
    swift format lint --recursive --strict Sources Tests Package.swift

test:
    swift test

coverage:
    swift test --enable-code-coverage
    xcrun llvm-cov report .build/debug/PermissionsKitPackageTests.xctest/Contents/MacOS/PermissionsKitPackageTests -instr-profile .build/debug/codecov/default.profdata -ignore-filename-regex='Tests|\.build'

live-test:
    RUN_LIVE_TESTS=1 swift test

check: lint test

clean:
    swift package clean
    rm -rf .build .swiftpm
