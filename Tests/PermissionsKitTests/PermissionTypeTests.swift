import XCTest

@testable import PermissionsKit

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

  func testSettingsOnlyFlags() {
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
      XCTAssertEqual(type.isSettingsOnly, settingsOnlyTypes.contains(type))
    }
  }

  func testSupportsRequestMatchesSettingsOnly() {
    for type in PermissionType.builtIn {
      XCTAssertEqual(type.supportsRequest, type.isSettingsOnly == false)
    }
  }

  func testSupportsStatusMatchesSettingsOnly() {
    for type in PermissionType.builtIn {
      XCTAssertEqual(type.supportsStatusCheck, type.isSettingsOnly == false)
    }
  }

  func testCapabilityMatchesTypeFlags() {
    for type in PermissionType.builtIn {
      let capability = type.capability
      XCTAssertEqual(capability.supportsStatusCheck, type.supportsStatusCheck)
      XCTAssertEqual(capability.supportsRequest, type.supportsRequest)
      XCTAssertEqual(capability.systemSettingsURL, type.systemSettingsURL)
      XCTAssertEqual(capability.requiresRelaunch, type.requiresRelaunch)
      XCTAssertEqual(capability.usageDescriptionKeys, type.usageDescriptionKeys)
    }
  }

  func testUsageDescriptionKeysMapping() {
    XCTAssertEqual(PermissionType.camera.usageDescriptionKeys, [.camera])
    XCTAssertEqual(PermissionType.microphone.usageDescriptionKeys, [.microphone])
    XCTAssertEqual(PermissionType.contacts.usageDescriptionKeys, [.contacts])
    XCTAssertEqual(PermissionType.calendars.usageDescriptionKeys, [.calendarsFullAccess])
    XCTAssertEqual(PermissionType.reminders.usageDescriptionKeys, [.remindersFullAccess])
    XCTAssertEqual(PermissionType.photos.usageDescriptionKeys, [.photos])
    XCTAssertEqual(PermissionType.speechRecognition.usageDescriptionKeys, [.speechRecognition])
    XCTAssertEqual(PermissionType.location.usageDescriptionKeys, [.location])
    XCTAssertEqual(PermissionType.bluetooth.usageDescriptionKeys, [.bluetooth])
    XCTAssertEqual(PermissionType.localNetwork.usageDescriptionKeys, [.localNetwork])
    XCTAssertEqual(PermissionType.mediaLibrary.usageDescriptionKeys, [.mediaLibrary])
    XCTAssertEqual(PermissionType.systemAudioCapture.usageDescriptionKeys, [.systemAudioCapture])
    XCTAssertEqual(PermissionType.desktopFolder.usageDescriptionKeys, [.desktopFolder])
    XCTAssertEqual(PermissionType.documentsFolder.usageDescriptionKeys, [.documentsFolder])
    XCTAssertEqual(PermissionType.downloadsFolder.usageDescriptionKeys, [.downloadsFolder])
    XCTAssertEqual(PermissionType.networkVolumes.usageDescriptionKeys, [.networkVolumes])
    XCTAssertEqual(PermissionType.removableVolumes.usageDescriptionKeys, [.removableVolumes])
    XCTAssertEqual(PermissionType.fileProviderDomain.usageDescriptionKeys, [.fileProviderDomain])
    XCTAssertEqual(PermissionType.automation.usageDescriptionKeys, [.appleEvents])
    XCTAssertEqual(PermissionType.accessibility.usageDescriptionKeys, [])
    XCTAssertEqual(PermissionType.screenRecording.usageDescriptionKeys, [])
    XCTAssertEqual(PermissionType.notifications.usageDescriptionKeys, [])
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

  func testCustomPermissionUsesCapability() {
    let capability = PermissionCapability(
      supportsStatusCheck: true,
      supportsRequest: true,
      systemSettingsURL: URL(
        string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Automation"),
      requiresRelaunch: true,
      usageDescriptionKeys: [.camera]
    )
    let custom = PermissionType.custom(.init(id: "custom.permission", capability: capability))

    XCTAssertFalse(custom.isSettingsOnly)
    XCTAssertEqual(custom.supportsStatusCheck, capability.supportsStatusCheck)
    XCTAssertEqual(custom.supportsRequest, capability.supportsRequest)
    XCTAssertEqual(custom.systemSettingsURL, capability.systemSettingsURL)
    XCTAssertEqual(custom.requiresRelaunch, capability.requiresRelaunch)
    XCTAssertEqual(custom.usageDescriptionKeys, capability.usageDescriptionKeys)
    XCTAssertEqual(custom.capability, capability)
  }

  func testCustomPermissionSettingsOnlyReflectsCapabilities() {
    let statusOnly = PermissionType.custom(
      .init(
        id: "custom.status",
        capability: .init(
          supportsStatusCheck: true,
          supportsRequest: false,
          systemSettingsURL: nil,
          requiresRelaunch: false,
          usageDescriptionKeys: []
        )))
    let requestOnly = PermissionType.custom(
      .init(
        id: "custom.request",
        capability: .init(
          supportsStatusCheck: false,
          supportsRequest: true,
          systemSettingsURL: nil,
          requiresRelaunch: false,
          usageDescriptionKeys: []
        )))
    let settingsOnly = PermissionType.custom(
      .init(
        id: "custom.settings",
        capability: .init(
          supportsStatusCheck: false,
          supportsRequest: false,
          systemSettingsURL: nil,
          requiresRelaunch: false,
          usageDescriptionKeys: []
        )))

    XCTAssertFalse(statusOnly.isSettingsOnly)
    XCTAssertTrue(statusOnly.supportsStatusCheck)
    XCTAssertFalse(statusOnly.supportsRequest)
    XCTAssertFalse(requestOnly.isSettingsOnly)
    XCTAssertFalse(requestOnly.supportsStatusCheck)
    XCTAssertTrue(requestOnly.supportsRequest)
    XCTAssertTrue(settingsOnly.isSettingsOnly)
    XCTAssertFalse(settingsOnly.supportsStatusCheck)
    XCTAssertFalse(settingsOnly.supportsRequest)
  }

  func testCustomPermissionEqualityAndHashUseAllCapabilityFields() {
    let url = URL(
      string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Automation")
    let capability = PermissionCapability(
      supportsStatusCheck: false,
      supportsRequest: false,
      systemSettingsURL: url,
      requiresRelaunch: true,
      usageDescriptionKeys: [.camera, .microphone]
    )
    let first = CustomPermission(id: "custom.permission", capability: capability)
    let second = CustomPermission(id: "custom.permission", capability: capability)
    let different = CustomPermission(
      id: "custom.permission",
      capability: .init(
        supportsStatusCheck: false,
        supportsRequest: false,
        systemSettingsURL: url,
        requiresRelaunch: false,
        usageDescriptionKeys: [.camera]
      )
    )

    XCTAssertEqual(first, second)
    XCTAssertEqual(first.hashValue, second.hashValue)
    XCTAssertNotEqual(first, different)
  }

  func testRequiresUsageDescriptionReflectsUsageKeys() {
    for type in PermissionType.builtIn {
      XCTAssertEqual(type.requiresUsageDescription, type.usageDescriptionKeys.isEmpty == false)
    }
  }
}
