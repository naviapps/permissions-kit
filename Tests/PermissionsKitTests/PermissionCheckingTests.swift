import XCTest

@testable import PermissionsKit

final class PermissionCheckingTests: XCTestCase {
  func testStatusOverloadUsesDefaultOptions() async {
    let checker = RecordingPermissionChecker()

    _ = await checker.status(for: .notifications)
    _ = await checker.status(for: .photos)
    _ = await checker.status(for: .camera)

    XCTAssertEqual(
      checker.statusOptions,
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
      checker.requestOptions,
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
  private(set) var statusOptions: [PermissionRequestOptions] = []
  private(set) var requestOptions: [PermissionRequestOptions] = []

  func status(for _: PermissionType, options: PermissionRequestOptions) async
    -> PermissionStatusResult
  {
    lock.withLock {
      statusOptions.append(options)
    }
    return .supported(.granted)
  }

  func requestAccess(for _: PermissionType, options: PermissionRequestOptions) async
    -> PermissionRequestResult
  {
    lock.withLock {
      requestOptions.append(options)
    }
    return .supported(.granted)
  }

  func openSystemSettings(for _: PermissionType) -> PermissionOpenSettingsResult {
    .supported(.opened)
  }
}
