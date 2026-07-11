import PermissionsKitAppKit
import XCTest

import PermissionsKit

final class PermissionEnvironmentUnsupportedTests: XCTestCase {
  private static func unsupportedTypes() throws -> [PermissionType] {
    let custom = try CustomPermission(
      identifier: "com.example.custom",
      capability: PermissionCapability(
        supportsStatusCheck: false,
        supportsRequest: false,
        systemSettingsURL: nil,
        requiresRelaunch: false
      )
    )

    return [
      .fullDiskAccess,
      .automation,
      .custom(custom),
    ]
  }

  func testLiveStatusReturnsUnsupportedForRepresentativeUnsupportedTypes() async throws {
    let checker = PermissionChecker()

    for type in try Self.unsupportedTypes() {
      let result = await checker.status(for: type)
      XCTAssertEqual(result, .unsupported(type.capability), "Expected unsupported for \(type)")
    }
  }

  func testLiveRequestReturnsUnsupportedForRepresentativeUnsupportedTypes() async throws {
    let checker = PermissionChecker()

    for type in try Self.unsupportedTypes() {
      let result = await checker.requestAccess(for: type)
      XCTAssertEqual(result, .unsupported(type.capability), "Expected unsupported for \(type)")
    }
  }
}
