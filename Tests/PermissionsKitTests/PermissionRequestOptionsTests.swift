import XCTest

@testable import PermissionsKit

final class PermissionRequestOptionsTests: XCTestCase {
  func testNotificationDefaults() {
    XCTAssertTrue(NotificationRequestOptions.default.contains(.alert))
    XCTAssertTrue(NotificationRequestOptions.default.contains(.badge))
    XCTAssertTrue(NotificationRequestOptions.default.contains(.sound))
    XCTAssertFalse(NotificationRequestOptions.default.contains(.criticalAlert))
    XCTAssertFalse(NotificationRequestOptions.default.contains(.provisional))
    XCTAssertFalse(NotificationRequestOptions.default.contains(.providesAppNotificationSettings))
  }

  func testNotificationOptionsRawValuesAreStable() {
    XCTAssertEqual(NotificationRequestOptions.alert.rawValue, 1 << 0)
    XCTAssertEqual(NotificationRequestOptions.badge.rawValue, 1 << 1)
    XCTAssertEqual(NotificationRequestOptions.sound.rawValue, 1 << 2)
    XCTAssertEqual(NotificationRequestOptions.criticalAlert.rawValue, 1 << 3)
    XCTAssertEqual(NotificationRequestOptions.provisional.rawValue, 1 << 4)
    XCTAssertEqual(NotificationRequestOptions.providesAppNotificationSettings.rawValue, 1 << 5)
  }

  func testPhotoAccessDefault() {
    XCTAssertEqual(PhotoAccessLevel.default, .readWrite)
  }

  func testPhotoAccessRawValuesAreStable() {
    XCTAssertEqual(PhotoAccessLevel.readWrite.rawValue, "readWrite")
    XCTAssertEqual(PhotoAccessLevel.addOnly.rawValue, "addOnly")
  }

  func testPermissionRequestOptionsEquality() {
    XCTAssertEqual(PermissionRequestOptions.none, .none)
    XCTAssertEqual(
      PermissionRequestOptions.notifications([.alert, .badge]),
      .notifications([.alert, .badge])
    )
    XCTAssertEqual(PermissionRequestOptions.photos(.addOnly), .photos(.addOnly))
    XCTAssertNotEqual(PermissionRequestOptions.none, .notifications([]))
    XCTAssertNotEqual(
      PermissionRequestOptions.notifications([.alert]),
      .notifications([.sound])
    )
    XCTAssertNotEqual(PermissionRequestOptions.photos(.addOnly), .photos(.readWrite))
  }
}
