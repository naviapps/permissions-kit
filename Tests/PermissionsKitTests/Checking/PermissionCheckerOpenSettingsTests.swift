import XCTest

import PermissionsKit

final class PermissionCheckerOpenSettingsTests: XCTestCase {
  func testOpenSystemSettingsReturnsUnsupportedWhenURLMissing() throws {
    let capability = PermissionCapability(
      supportsStatusCheck: false,
      supportsRequest: false,
      systemSettingsURL: nil,
      requiresRelaunch: false
    )
    let type = PermissionType.custom(
      try CustomPermission(identifier: "custom.permission", capability: capability)
    )
    let checker = PermissionChecker(environment: makeEnvironment(openURL: { _ in true }))

    let result = checker.openSystemSettings(for: type)
    XCTAssertEqual(result, .unsupported(capability))
  }

  func testOpenSystemSettingsReturnsOpenedWhenOpenURLSucceeds() {
    let checker = PermissionChecker(environment: makeEnvironment(openURL: { _ in true }))
    let result = checker.openSystemSettings(for: .accessibility)
    XCTAssertEqual(result, .supported(true))
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
    status: { _, _ in .supported(.unknown) },
    requestAccess: { _, _ in .failed(.apiUnavailable) },
    openURL: openURL
  )
}
