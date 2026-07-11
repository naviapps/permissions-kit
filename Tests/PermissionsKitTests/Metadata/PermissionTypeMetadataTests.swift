import XCTest

import PermissionsKit

final class PermissionTypeMetadataTests: XCTestCase {
  func testBuiltInPermissionsExposeSystemSettingsURLs() {
    for type in PermissionType.builtIn {
      XCTAssertEqual(type.capability.systemSettingsURL?.scheme, "x-apple.systempreferences")
    }
  }

  func testRepresentativeSystemSettingsURLDestinations() {
    XCTAssertEqual(
      PermissionType.accessibility.capability.systemSettingsURL?.absoluteString,
      "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
    )
    XCTAssertEqual(
      PermissionType.notifications.capability.systemSettingsURL?.absoluteString,
      "x-apple.systempreferences:com.apple.preference.notifications?Notifications"
    )
    XCTAssertEqual(
      PermissionType.documentsFolder.capability.systemSettingsURL?.absoluteString,
      "x-apple.systempreferences:com.apple.preference.security?Privacy_FilesAndFolders"
    )
  }

  func testRepresentativeRelaunchRequirements() {
    XCTAssertTrue(PermissionType.screenRecording.capability.requiresRelaunch)
    XCTAssertTrue(PermissionType.fullDiskAccess.capability.requiresRelaunch)
    XCTAssertFalse(PermissionType.camera.capability.requiresRelaunch)
  }
}
