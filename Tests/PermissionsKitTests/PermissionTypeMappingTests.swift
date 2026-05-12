import XCTest

@testable import PermissionsKit

final class PermissionTypeMappingTests: XCTestCase {
  func testDefaultOptions() {
    let custom = PermissionType.custom(
      .init(
        id: "custom.permission",
        capability: .init(
          supportsStatusCheck: true,
          supportsRequest: true,
          systemSettingsURL: nil,
          requiresRelaunch: false,
          usageDescriptionKeys: []
        )))

    for type in PermissionType.builtIn + [custom] {
      switch type {
      case .notifications:
        XCTAssertEqual(type.defaultOptions, .notifications(.default))
      case .photos:
        XCTAssertEqual(type.defaultOptions, .photos(.default))
      default:
        XCTAssertEqual(type.defaultOptions, .none, "\(type) should not define defaults")
      }
    }
  }

  func testIDUsesCustomID() {
    let custom = PermissionType.custom(
      .init(
        id: "custom.permission",
        capability: .init(
          supportsStatusCheck: false,
          supportsRequest: false,
          systemSettingsURL: nil,
          requiresRelaunch: false,
          usageDescriptionKeys: []
        )))
    XCTAssertEqual(custom.id, "custom.permission")
  }
}
