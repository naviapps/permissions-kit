import Foundation
import XCTest

import PermissionsKit

final class PermissionTypeTests: XCTestCase {
  func testBuiltInPermissionsExposeIDsInExpectedOrder() {
    XCTAssertEqual(
      PermissionType.builtIn.map(\.id),
      [
        "accessibility",
        "input_monitoring",
        "screen_recording",
        "camera",
        "microphone",
        "contacts",
        "calendars",
        "reminders",
        "photos",
        "speech_recognition",
        "notifications",
        "location",
        "bluetooth",
        "local_network",
        "media_library",
        "system_audio_capture",
        "desktop_folder",
        "documents_folder",
        "downloads_folder",
        "network_volumes",
        "removable_volumes",
        "file_provider_domain",
        "full_disk_access",
        "automation",
      ]
    )
  }

  func testCapabilityMarksSettingsOnlyTypesAsUnsupportedForDirectChecks() {
    let settingsOnlyTypes: Set<PermissionType> = [
      .inputMonitoring,
      .location,
      .bluetooth,
      .localNetwork,
      .mediaLibrary,
      .systemAudioCapture,
      .desktopFolder,
      .documentsFolder,
      .downloadsFolder,
      .networkVolumes,
      .removableVolumes,
      .fileProviderDomain,
      .fullDiskAccess,
      .automation,
    ]

    for type in PermissionType.builtIn {
      let supportsDirectChecks = settingsOnlyTypes.contains(type) == false
      XCTAssertEqual(type.capability.supportsStatusCheck, supportsDirectChecks)
      XCTAssertEqual(type.capability.supportsRequest, supportsDirectChecks)
    }
  }

  func testUsageDescriptionKeysMapping() {
    XCTAssertEqual(PermissionType.camera.usageDescriptionKeys(for: .none), [.camera])
    XCTAssertEqual(
      PermissionType.calendars.usageDescriptionKeys(for: .none), [.calendarsFullAccess])
    XCTAssertEqual(PermissionType.automation.usageDescriptionKeys(for: .none), [.appleEvents])
    XCTAssertEqual(PermissionType.accessibility.usageDescriptionKeys(for: .none), [])
  }

  func testUsageDescriptionKeysUsePermissionOptions() {
    XCTAssertEqual(PermissionType.photos.usageDescriptionKeys(for: .none), [.photos])
    XCTAssertEqual(PermissionType.photos.usageDescriptionKeys(for: .photos(.readWrite)), [.photos])
    XCTAssertEqual(
      PermissionType.photos.usageDescriptionKeys(for: .photos(.addOnly)),
      [.photosAddOnly]
    )
    XCTAssertEqual(PermissionType.camera.usageDescriptionKeys(for: .photos(.addOnly)), [.camera])
  }

  func testPermissionTypeCodableUsesExplicitCaseAndPayloadKeys() throws {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys]
    let custom = PermissionType.custom(
      try CustomPermission(
        identifier: "custom.permission",
        capability: invalidIDTestCapability,
        usageDescriptionKeys: [.camera, .microphone]
      )
    )

    XCTAssertEqual(
      String(data: try encoder.encode(PermissionType.camera), encoding: .utf8),
      #"{"id":"camera","kind":"builtIn"}"#
    )
    XCTAssertEqual(
      String(data: try encoder.encode(custom), encoding: .utf8),
      #"{"custom":{"capability":{"requiresRelaunch":false,"supportsRequest":false,"supportsStatusCheck":false},"identifier":"custom.permission","usageDescriptionKeys":["NSCameraUsageDescription","NSMicrophoneUsageDescription"]},"kind":"custom"}"#
    )
    XCTAssertEqual(
      try JSONDecoder().decode(
        PermissionType.self,
        from: Data(#"{"id":"screen_recording","kind":"builtIn"}"#.utf8)
      ),
      .screenRecording
    )
    XCTAssertEqual(
      try JSONDecoder().decode(
        PermissionType.self,
        from: Data(
          #"{"custom":{"identifier":"custom.permission","capability":{"supportsStatusCheck":false,"supportsRequest":false,"requiresRelaunch":false},"usageDescriptionKeys":["NSCameraUsageDescription","NSMicrophoneUsageDescription"]},"kind":"custom"}"#
            .utf8)
      ),
      custom
    )
  }

  func testPermissionTypeCodableRejectsInvalidPayloadShapes() {
    assertPermissionTypeDecodeFails(#"{"kind":"unknown","id":"camera"}"#)
    assertPermissionTypeDecodeFails(#"{"kind":"builtIn"}"#)
    assertPermissionTypeDecodeFails(#"{"kind":"builtIn","id":"missing"}"#)
    assertPermissionTypeDecodeFails(
      #"{"kind":"builtIn","id":"camera","custom":{"identifier":"custom.permission","capability":{"supportsStatusCheck":false,"supportsRequest":false,"requiresRelaunch":false},"usageDescriptionKeys":[]}}"#
    )
    assertPermissionTypeDecodeFails(#"{"kind":"builtIn","id":"camera","custom":null}"#)
    assertPermissionTypeDecodeFails(#"{"kind":"custom"}"#)
    assertPermissionTypeDecodeFails(
      #"{"kind":"custom","custom":{"identifier":"camera","capability":{"supportsStatusCheck":false,"supportsRequest":false,"requiresRelaunch":false},"usageDescriptionKeys":[]}}"#
    )
    assertPermissionTypeDecodeFails(
      #"{"kind":"custom","id":null,"custom":{"identifier":"custom.permission","capability":{"supportsStatusCheck":false,"supportsRequest":false,"requiresRelaunch":false},"usageDescriptionKeys":[]}}"#
    )
    assertPermissionTypeDecodeFails(
      #"{"kind":"custom","custom":{"identifier":"custom.permission","capability":{"supportsStatusCheck":false,"supportsRequest":false,"requiresRelaunch":false},"usageDescriptionKeys":[]},"extra":true}"#
    )
    assertPermissionTypeDecodeFails(
      #"{"kind":"custom","custom":{"identifier":"custom.permission","capability":{"supportsStatusCheck":false,"supportsRequest":false,"requiresRelaunch":false},"usageDescriptionKeys":[],"extra":true}}"#
    )
    assertPermissionTypeDecodeFails(
      #"{"kind":"custom","custom":{"identifier":"custom.permission","capability":{"supportsStatusCheck":false,"supportsRequest":false,"requiresRelaunch":false,"extra":true},"usageDescriptionKeys":[]}}"#
    )
    assertPermissionTypeDecodeFails(
      #"{"kind":"custom","custom":{"identifier":"custom.permission","capability":{"supportsStatusCheck":false,"supportsRequest":false,"systemSettingsURL":null,"requiresRelaunch":false},"usageDescriptionKeys":[]}}"#
    )
    assertPermissionTypeDecodeFails(
      #"{"kind":"custom","custom":{"identifier":"custom.permission","capability":{"supportsStatusCheck":false,"supportsRequest":false,"requiresRelaunch":false},"usageDescriptionKeys":["NSCameraUsageDescription","NSCameraUsageDescription"]}}"#
    )
  }

  private func assertPermissionTypeDecodeFails(
    _ json: String,
    file: StaticString = #filePath,
    line: UInt = #line
  ) {
    XCTAssertThrowsError(
      try JSONDecoder().decode(PermissionType.self, from: Data(json.utf8)),
      file: file,
      line: line
    )
  }

  func testDefaultOptionsAreProvidedOnlyForOptionBackedPermissions() throws {
    let custom = PermissionType.custom(try makeCustomPermission())

    XCTAssertEqual(PermissionType.notifications.defaultOptions, .notifications(.default))
    XCTAssertEqual(PermissionType.photos.defaultOptions, .photos(.default))
    XCTAssertEqual(PermissionType.camera.defaultOptions, .none)
    XCTAssertEqual(custom.defaultOptions, .none)
  }

  func testCustomPermissionIdentifierMapsToPermissionTypeID() throws {
    let customPermission = try makeCustomPermission()
    let custom = PermissionType.custom(customPermission)

    XCTAssertEqual(customPermission.identifier, "custom.permission")
    XCTAssertEqual(custom.id, "custom.permission")
  }

  private func makeCustomPermission() throws -> CustomPermission {
    try CustomPermission(
      identifier: "custom.permission",
      capability: invalidIDTestCapability
    )
  }
}

private let invalidIDTestCapability = PermissionCapability(
  supportsStatusCheck: false,
  supportsRequest: false,
  systemSettingsURL: nil,
  requiresRelaunch: false
)
