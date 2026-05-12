import XCTest

@testable import PermissionsKit

final class PermissionCheckerOpenSettingsTests: XCTestCase {
  func testOpenSystemSettingsReturnsUnsupportedWhenURLMissing() {
    let capability = PermissionCapability(
      supportsStatusCheck: false,
      supportsRequest: false,
      systemSettingsURL: nil,
      requiresRelaunch: false,
      usageDescriptionKeys: []
    )
    let type = PermissionType.custom(.init(id: "custom.permission", capability: capability))
    let checker = PermissionChecker(environment: makeEnvironment(openURL: { _ in true }))

    let result = checker.openSystemSettings(for: type)
    XCTAssertEqual(result, .unsupported(capability))
  }

  func testOpenSystemSettingsReturnsOpenedWhenOpenURLSucceeds() {
    let checker = PermissionChecker(environment: makeEnvironment(openURL: { _ in true }))
    let result = checker.openSystemSettings(for: .accessibility)
    XCTAssertEqual(result, .supported(.opened))
  }

  func testOpenSystemSettingsReturnsOpenFailedWhenOpenURLFails() {
    let checker = PermissionChecker(environment: makeEnvironment(openURL: { _ in false }))

    let result = checker.openSystemSettings(for: .accessibility)

    XCTAssertEqual(result, .failed(.openFailed))
  }
}

private func makeEnvironment(
  openURL: @escaping @Sendable (URL) -> Bool
) -> PermissionEnvironment {
  PermissionEnvironment(
    status: { _, _ in .unknown },
    request: { _, _ in .failed(.apiUnavailable) },
    openURL: openURL
  )
}
