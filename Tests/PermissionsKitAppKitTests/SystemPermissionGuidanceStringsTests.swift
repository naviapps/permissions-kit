import PermissionsKitAppKit
import XCTest

final class SystemPermissionGuidanceStringsTests: XCTestCase {
  func testEnglishDefaultsAreStable() {
    let strings = SystemPermissionGuidanceStrings.english

    XCTAssertEqual(
      strings,
      SystemPermissionGuidanceStrings(
        accessibility: .init(
          title: "Accessibility permission required",
          message: "Enable Accessibility in System Settings to continue."
        ),
        automation: .init(
          title: "Automation permission required",
          message: "Allow automation in System Settings to continue."
        ),
        screenRecording: .init(
          title: "Screen Recording permission required",
          message: "Enable Screen Recording in System Settings to continue."
        ),
        openSettingsLabel: "Open Settings",
        cancelLabel: "Cancel"
      )
    )
  }

  func testCustomGuidanceInitializes() {
    let custom = SystemPermissionGuidanceStrings(
      accessibility: .init(title: "A", message: "B"),
      automation: .init(title: "C", message: "D"),
      screenRecording: .init(title: "E", message: "F"),
      openSettingsLabel: "Open",
      cancelLabel: "Close"
    )

    XCTAssertEqual(
      custom,
      SystemPermissionGuidanceStrings(
        accessibility: .init(title: "A", message: "B"),
        automation: .init(title: "C", message: "D"),
        screenRecording: .init(title: "E", message: "F"),
        openSettingsLabel: "Open",
        cancelLabel: "Close"
      )
    )
  }
}
