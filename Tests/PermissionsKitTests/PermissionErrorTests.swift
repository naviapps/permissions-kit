import XCTest

@testable import PermissionsKit

final class PermissionErrorTests: XCTestCase {
  func testDescriptions() {
    XCTAssertEqual(PermissionError.openFailed.description, "open_failed")
    XCTAssertEqual(PermissionError.apiUnavailable.description, "api_unavailable")
  }
}
