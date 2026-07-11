import XCTest

import PermissionsKit

final class PermissionStatusTests: XCTestCase {
  func testCasesAndRawValuesAreCanonical() {
    XCTAssertEqual(
      [
        PermissionStatus.granted,
        .limited,
        .provisional,
        .ephemeral,
        .denied,
        .restricted,
        .notDetermined,
        .unknown,
      ].map(\.rawValue),
      [
        "granted",
        "limited",
        "provisional",
        "ephemeral",
        "denied",
        "restricted",
        "notDetermined",
        "unknown",
      ]
    )
  }

  func testAllowsAccessDistinguishesUsableAuthorizationStates() {
    XCTAssertTrue(PermissionStatus.granted.allowsAccess)
    XCTAssertTrue(PermissionStatus.limited.allowsAccess)
    XCTAssertTrue(PermissionStatus.provisional.allowsAccess)
    XCTAssertTrue(PermissionStatus.ephemeral.allowsAccess)
    XCTAssertFalse(PermissionStatus.denied.allowsAccess)
    XCTAssertFalse(PermissionStatus.restricted.allowsAccess)
    XCTAssertFalse(PermissionStatus.notDetermined.allowsAccess)
    XCTAssertFalse(PermissionStatus.unknown.allowsAccess)
  }
}
