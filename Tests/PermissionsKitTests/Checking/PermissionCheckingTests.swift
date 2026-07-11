import XCTest

import PermissionsKit

final class PermissionCheckingTests: XCTestCase {
  func testStatusOverloadUsesDefaultOptions() async {
    let checker = RecordingPermissionChecker()

    _ = await checker.status(for: .notifications)
    _ = await checker.status(for: .photos)
    _ = await checker.status(for: .camera)

    XCTAssertEqual(
      checker.observedOptions,
      [
        .notifications(.default),
        .photos(.default),
        .none,
      ]
    )
  }

  func testRequestAccessOverloadUsesDefaultOptions() async {
    let checker = RecordingPermissionChecker()

    _ = await checker.requestAccess(for: .notifications)
    _ = await checker.requestAccess(for: .photos)
    _ = await checker.requestAccess(for: .camera)

    XCTAssertEqual(
      checker.permissionOptions,
      [
        .notifications(.default),
        .photos(.default),
        .none,
      ]
    )
  }
}

private final class RecordingPermissionChecker: PermissionChecking, @unchecked Sendable {
  private let lock = NSLock()
  private(set) var observedOptions: [PermissionOptions] = []
  private(set) var permissionOptions: [PermissionOptions] = []

  func status(for _: PermissionType, options: PermissionOptions) async
    -> PermissionOperationResult<PermissionStatus>
  {
    lock.withLock {
      observedOptions.append(options)
    }
    return .supported(.granted)
  }

  func requestAccess(for _: PermissionType, options: PermissionOptions) async
    -> PermissionOperationResult<PermissionStatus>
  {
    lock.withLock {
      permissionOptions.append(options)
    }
    return .supported(.granted)
  }

  func openSystemSettings(for _: PermissionType) -> PermissionOperationResult<Bool> {
    .supported(true)
  }
}
