import XCTest

@testable import PermissionsKit

final class PermissionUsageDescriptionTests: XCTestCase {
  func testMissingUsageDescriptionsReturnsExpectedKeys() throws {
    let bundle = try makeBundle(info: [
      UsageDescriptionKey.camera.rawValue: "Uses camera"
    ])

    let missing = PermissionType.microphone.missingUsageDescriptions(in: bundle)
    XCTAssertEqual(missing, [.microphone])

    let noneMissing = PermissionType.camera.missingUsageDescriptions(in: bundle)
    XCTAssertEqual(noneMissing, [])
  }

  func testMissingUsageDescriptionsReturnsOnlyMissingKeysForCustomPermissions() throws {
    let bundle = try makeBundle(info: [
      UsageDescriptionKey.camera.rawValue: "Uses camera"
    ])
    let custom = makeCustomPermission(usageDescriptionKeys: [.camera, .microphone])

    XCTAssertEqual(custom.missingUsageDescriptions(in: bundle), [.microphone])
  }

  func testMissingUsageDescriptionsUsesPermissionOptions() throws {
    let readWriteBundle = try makeBundle(info: [
      UsageDescriptionKey.photos.rawValue: "Reads photos"
    ])
    let addOnlyBundle = try makeBundle(info: [
      UsageDescriptionKey.photosAddOnly.rawValue: "Adds photos"
    ])

    XCTAssertEqual(
      PermissionType.photos.missingUsageDescriptions(
        in: readWriteBundle,
        options: .photos(.addOnly)
      ),
      [.photosAddOnly]
    )
    XCTAssertEqual(
      PermissionType.photos.missingUsageDescriptions(
        in: addOnlyBundle,
        options: .photos(.addOnly)
      ),
      []
    )
    XCTAssertEqual(
      PermissionType.photos.missingUsageDescriptions(
        in: addOnlyBundle,
        options: .photos(.readWrite)
      ),
      [.photos]
    )
  }

  func testMissingUsageDescriptionsReturnsEmptyForTypesWithoutUsageKeys() throws {
    let bundle = try makeBundle(info: [:])

    XCTAssertEqual(PermissionType.accessibility.missingUsageDescriptions(in: bundle), [])
    XCTAssertEqual(PermissionType.notifications.missingUsageDescriptions(in: bundle), [])
  }

  func testMissingUsageDescriptionsReturnsAllKeysWhenInfoDictionaryIsEmpty() throws {
    let bundle = try makeBundle(info: [:])
    let custom = makeCustomPermission(usageDescriptionKeys: [.camera, .microphone])

    XCTAssertEqual(custom.missingUsageDescriptions(in: bundle), [.camera, .microphone])
  }

  private func makeCustomPermission(usageDescriptionKeys: [UsageDescriptionKey]) -> PermissionType {
    PermissionType.custom(
      .init(
        id: "custom.permission",
        capability: .init(
          supportsStatusCheck: true,
          supportsRequest: true,
          systemSettingsURL: nil,
          requiresRelaunch: false,
          usageDescriptionKeys: usageDescriptionKeys
        )))
  }

  private func makeBundle(info: [String: Any]) throws -> Bundle {
    let temporaryBundleDirectory = FileManager.default.temporaryDirectory
      .appendingPathComponent(UUID().uuidString, isDirectory: true)
    addTeardownBlock {
      try? FileManager.default.removeItem(at: temporaryBundleDirectory)
    }
    let contents = temporaryBundleDirectory.appendingPathComponent("Contents", isDirectory: true)
    let resources = contents.appendingPathComponent("Resources", isDirectory: true)
    try FileManager.default.createDirectory(at: resources, withIntermediateDirectories: true)

    let plist = contents.appendingPathComponent("Info.plist")
    let data = try PropertyListSerialization.data(fromPropertyList: info, format: .xml, options: 0)
    try data.write(to: plist)

    return try XCTUnwrap(Bundle(path: temporaryBundleDirectory.path))
  }
}
