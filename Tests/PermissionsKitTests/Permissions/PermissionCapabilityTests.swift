import Foundation
import XCTest

import PermissionsKit

final class PermissionCapabilityTests: XCTestCase {
  func testCodableRoundTripsPublicMetadata() throws {
    let capability = PermissionCapability(
      supportsStatusCheck: true,
      supportsRequest: false,
      systemSettingsURL: URL(string: "x-apple.systempreferences:com.apple.preference.security"),
      requiresRelaunch: true
    )

    let data = try JSONEncoder().encode(capability)

    XCTAssertEqual(try JSONDecoder().decode(PermissionCapability.self, from: data), capability)
  }
}
