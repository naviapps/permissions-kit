import Foundation
import XCTest

import PermissionsKit

final class PermissionOptionsTests: XCTestCase {
  func testNotificationDefaultsAndRawValues() {
    XCTAssertTrue(NotificationRequestOptions.default.contains(.alert))
    XCTAssertTrue(NotificationRequestOptions.default.contains(.badge))
    XCTAssertTrue(NotificationRequestOptions.default.contains(.sound))
    XCTAssertFalse(NotificationRequestOptions.default.contains(.criticalAlert))
    XCTAssertFalse(NotificationRequestOptions.default.contains(.provisional))
    XCTAssertFalse(NotificationRequestOptions.default.contains(.providesAppNotificationSettings))

    XCTAssertEqual(NotificationRequestOptions.alert.rawValue, 1 << 0)
    XCTAssertEqual(NotificationRequestOptions.badge.rawValue, 1 << 1)
    XCTAssertEqual(NotificationRequestOptions.sound.rawValue, 1 << 2)
    XCTAssertEqual(NotificationRequestOptions.criticalAlert.rawValue, 1 << 3)
    XCTAssertEqual(NotificationRequestOptions.provisional.rawValue, 1 << 4)
    XCTAssertEqual(NotificationRequestOptions.providesAppNotificationSettings.rawValue, 1 << 5)
  }

  func testNotificationOptionsCodableRoundTripsRawValues() throws {
    let options: NotificationRequestOptions = [.alert, .sound, .provisional]
    let data = try JSONEncoder().encode(options)

    XCTAssertEqual(String(data: data, encoding: .utf8), "\(options.rawValue)")
    XCTAssertEqual(try JSONDecoder().decode(NotificationRequestOptions.self, from: data), options)
  }

  func testPhotoAccessCasesAndRawValues() {
    XCTAssertEqual(PhotoAccessLevel.default, .readWrite)
    XCTAssertEqual(PhotoAccessLevel.readWrite.rawValue, "readWrite")
    XCTAssertEqual(PhotoAccessLevel.addOnly.rawValue, "addOnly")
  }

  func testOptionsApplyOnlyToTheirPermissionType() {
    XCTAssertTrue(PermissionOptions.none.applies(to: .camera))
    XCTAssertTrue(PermissionOptions.notifications(.default).applies(to: .notifications))
    XCTAssertTrue(PermissionOptions.photos(.addOnly).applies(to: .photos))
    XCTAssertFalse(PermissionOptions.notifications(.default).applies(to: .photos))
    XCTAssertFalse(PermissionOptions.photos(.addOnly).applies(to: .notifications))
  }

  func testPermissionOptionsCodableUsesExplicitCaseAndPayloadKeys() throws {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys]

    XCTAssertEqual(
      String(data: try encoder.encode(PermissionOptions.none), encoding: .utf8),
      #"{"kind":"none"}"#
    )
    XCTAssertEqual(
      String(
        data: try encoder.encode(PermissionOptions.notifications([.alert, .sound])),
        encoding: .utf8
      ),
      #"{"kind":"notifications","notificationOptions":5}"#
    )
    XCTAssertEqual(
      String(data: try encoder.encode(PermissionOptions.photos(.addOnly)), encoding: .utf8),
      #"{"kind":"photos","photoAccessLevel":"addOnly"}"#
    )

    XCTAssertEqual(
      try JSONDecoder().decode(
        PermissionOptions.self,
        from: Data(#"{"kind":"notifications","notificationOptions":7}"#.utf8)
      ),
      .notifications([.alert, .badge, .sound])
    )
    XCTAssertEqual(
      try JSONDecoder().decode(
        PermissionOptions.self,
        from: Data(#"{"kind":"photos","photoAccessLevel":"readWrite"}"#.utf8)
      ),
      .photos(.readWrite)
    )
  }

  func testPermissionOptionsCodableRejectsInvalidPayloadShapes() {
    assertPermissionOptionsDecodeFails(#"{"kind":"unknown"}"#)
    assertPermissionOptionsDecodeFails(#"{"kind":"none","notificationOptions":1}"#)
    assertPermissionOptionsDecodeFails(#"{"kind":"notifications"}"#)
    assertPermissionOptionsDecodeFails(#"{"kind":"notifications","photoAccessLevel":"addOnly"}"#)
    assertPermissionOptionsDecodeFails(#"{"kind":"photos"}"#)
    assertPermissionOptionsDecodeFails(#"{"kind":"photos","notificationOptions":1}"#)
    assertPermissionOptionsDecodeFails(
      #"{"kind":"photos","photoAccessLevel":"addOnly","extra":true}"#)
  }

  private func assertPermissionOptionsDecodeFails(
    _ json: String,
    file: StaticString = #filePath,
    line: UInt = #line
  ) {
    XCTAssertThrowsError(
      try JSONDecoder().decode(PermissionOptions.self, from: Data(json.utf8)),
      file: file,
      line: line
    )
  }
}
