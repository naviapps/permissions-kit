import XCTest

@testable import PermissionsKit

final class PermissionStatusTests: XCTestCase {
  func testAllCasesAreStable() {
    XCTAssertEqual(
      PermissionStatus.allCases,
      [
        .granted,
        .denied,
        .restricted,
        .notDetermined,
        .unknown,
      ]
    )
  }

  func testRawValuesAreStable() {
    XCTAssertEqual(PermissionStatus.granted.rawValue, "granted")
    XCTAssertEqual(PermissionStatus.denied.rawValue, "denied")
    XCTAssertEqual(PermissionStatus.restricted.rawValue, "restricted")
    XCTAssertEqual(PermissionStatus.notDetermined.rawValue, "notDetermined")
    XCTAssertEqual(PermissionStatus.unknown.rawValue, "unknown")
  }

  func testConvenienceFlags() {
    let expectations: [(PermissionStatus, Bool, Bool, Bool, Bool, Bool)] = [
      (.granted, true, false, false, false, false),
      (.denied, false, true, false, false, false),
      (.restricted, false, false, true, false, false),
      (.notDetermined, false, false, false, true, false),
      (.unknown, false, false, false, false, true),
    ]

    for (
      status, isGranted, isDenied, isRestricted, isNotDetermined, isUnknown
    ) in expectations {
      XCTAssertEqual(status.isGranted, isGranted)
      XCTAssertEqual(status.isDenied, isDenied)
      XCTAssertEqual(status.isRestricted, isRestricted)
      XCTAssertEqual(status.isNotDetermined, isNotDetermined)
      XCTAssertEqual(status.isUnknown, isUnknown)
    }
  }
}
