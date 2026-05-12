import XCTest

@testable import PermissionsKit

final class PermissionTypeMetadataTests: XCTestCase {
  func testSystemSettingsURLMapping() {
    let expectedURLs: [PermissionType: String] = [
      .accessibility:
        "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility",
      .inputMonitoring:
        "x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent",
      .screenRecording:
        "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture",
      .camera: "x-apple.systempreferences:com.apple.preference.security?Privacy_Camera",
      .microphone: "x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone",
      .contacts: "x-apple.systempreferences:com.apple.preference.security?Privacy_Contacts",
      .calendars: "x-apple.systempreferences:com.apple.preference.security?Privacy_Calendars",
      .reminders: "x-apple.systempreferences:com.apple.preference.security?Privacy_Reminders",
      .photos: "x-apple.systempreferences:com.apple.preference.security?Privacy_Photos",
      .speechRecognition:
        "x-apple.systempreferences:com.apple.preference.security?Privacy_SpeechRecognition",
      .notifications: "x-apple.systempreferences:com.apple.preference.notifications?Notifications",
      .location:
        "x-apple.systempreferences:com.apple.preference.security?Privacy_LocationServices",
      .bluetooth: "x-apple.systempreferences:com.apple.preference.security?Privacy_Bluetooth",
      .localNetwork:
        "x-apple.systempreferences:com.apple.preference.security?Privacy_LocalNetwork",
      .mediaLibrary: "x-apple.systempreferences:com.apple.preference.security?Privacy_Media",
      .systemAudioCapture:
        "x-apple.systempreferences:com.apple.preference.security?Privacy_SystemAudioRecording",
      .desktopFolder:
        "x-apple.systempreferences:com.apple.preference.security?Privacy_FilesAndFolders",
      .documentsFolder:
        "x-apple.systempreferences:com.apple.preference.security?Privacy_FilesAndFolders",
      .downloadsFolder:
        "x-apple.systempreferences:com.apple.preference.security?Privacy_FilesAndFolders",
      .networkVolumes:
        "x-apple.systempreferences:com.apple.preference.security?Privacy_FilesAndFolders",
      .removableVolumes:
        "x-apple.systempreferences:com.apple.preference.security?Privacy_FilesAndFolders",
      .fileProviderDomain:
        "x-apple.systempreferences:com.apple.preference.security?Privacy_FilesAndFolders",
      .fullDiskAccess:
        "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles",
      .automation: "x-apple.systempreferences:com.apple.preference.security?Privacy_Automation",
    ]

    XCTAssertEqual(Set(expectedURLs.keys), Set(PermissionType.builtIn))
    for type in PermissionType.builtIn {
      XCTAssertEqual(type.systemSettingsURL?.absoluteString, expectedURLs[type])
    }
  }

  func testRequiresRelaunchMapping() {
    let requiresRelaunch: Set<PermissionType> = [
      .inputMonitoring, .screenRecording, .fullDiskAccess,
    ]
    for type in PermissionType.builtIn {
      XCTAssertEqual(type.requiresRelaunch, requiresRelaunch.contains(type))
    }
  }
}
