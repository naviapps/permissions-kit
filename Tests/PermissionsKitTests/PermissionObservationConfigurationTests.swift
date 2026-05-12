import XCTest

@testable import PermissionsKit

final class PermissionObservationConfigurationTests: XCTestCase {
  func testDefaultValues() {
    let configuration = PermissionObservationConfiguration()
    XCTAssertEqual(configuration.pollingInterval, .seconds(2))
    XCTAssertNil(configuration.logHandler)
  }

  func testCustomValuesArePreserved() {
    let configuration = PermissionObservationConfiguration(
      pollingInterval: .seconds(1),
      logHandler: { _ in }
    )

    XCTAssertEqual(configuration.pollingInterval, .seconds(1))
    XCTAssertNotNil(configuration.logHandler)
  }

  func testPollingIntervalClampsToMinimum() {
    let configuration = PermissionObservationConfiguration(pollingInterval: .milliseconds(10))
    XCTAssertEqual(configuration.pollingInterval, .milliseconds(250))
  }

  func testPollingIntervalClampsOnAssignment() {
    var configuration = PermissionObservationConfiguration()
    configuration.pollingInterval = .milliseconds(1)
    XCTAssertEqual(configuration.pollingInterval, .milliseconds(250))
  }
}
