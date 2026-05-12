import XCTest

@testable import PermissionsKit

final class PermissionOperationResultTests: XCTestCase {
  private let capability = PermissionCapability(
    supportsStatusCheck: false,
    supportsRequest: false,
    systemSettingsURL: nil,
    requiresRelaunch: false,
    usageDescriptionKeys: []
  )

  func testSupportedResultExposesValue() {
    let supported = PermissionOperationResult.supported(PermissionStatus.granted)

    XCTAssertEqual(supported.value, .granted)
    XCTAssertNil(supported.capability)
    XCTAssertNil(supported.error)
    XCTAssertTrue(supported.isSupported)
    XCTAssertFalse(supported.isUnsupported)
    XCTAssertFalse(supported.isFailed)
    XCTAssertEqual(supported.status, .granted)
  }

  func testUnsupportedResultExposesCapability() {
    let unsupported = PermissionOperationResult<PermissionStatus>.unsupported(capability)

    XCTAssertNil(unsupported.value)
    XCTAssertEqual(unsupported.capability, capability)
    XCTAssertNil(unsupported.error)
    XCTAssertFalse(unsupported.isSupported)
    XCTAssertTrue(unsupported.isUnsupported)
    XCTAssertFalse(unsupported.isFailed)
    XCTAssertNil(unsupported.status)
  }

  func testFailedResultExposesError() {
    let failed = PermissionOperationResult<PermissionStatus>.failed(.openFailed)

    XCTAssertNil(failed.value)
    XCTAssertNil(failed.capability)
    XCTAssertEqual(failed.error, .openFailed)
    XCTAssertFalse(failed.isSupported)
    XCTAssertFalse(failed.isUnsupported)
    XCTAssertTrue(failed.isFailed)
    XCTAssertNil(failed.status)
  }
}
