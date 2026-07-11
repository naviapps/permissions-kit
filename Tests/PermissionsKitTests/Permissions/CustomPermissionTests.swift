import Foundation
import XCTest

import PermissionsKit

final class CustomPermissionTests: XCTestCase {
  func testConstructionUsesCapabilityAndDeduplicatesUsageDescriptionKeys() throws {
    let capability = PermissionCapability(
      supportsStatusCheck: true,
      supportsRequest: true,
      systemSettingsURL: URL(
        string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Automation"),
      requiresRelaunch: true
    )
    let descriptor = try CustomPermission(
      identifier: "custom.permission",
      capability: capability,
      usageDescriptionKeys: [.camera, .microphone, .camera]
    )
    let type = PermissionType.custom(descriptor)

    XCTAssertEqual(descriptor.usageDescriptionKeys, [.camera, .microphone])
    XCTAssertEqual(type.capability, capability)
    XCTAssertEqual(type.usageDescriptionKeys(for: .none), [.camera, .microphone])
  }

  func testEqualityAndHashUseStableIdentifierIdentity() throws {
    let capability = PermissionCapability(
      supportsStatusCheck: false,
      supportsRequest: false,
      systemSettingsURL: nil,
      requiresRelaunch: true
    )
    let first = try CustomPermission(
      identifier: "custom.permission",
      capability: capability,
      usageDescriptionKeys: [.camera, .microphone]
    )
    let second = try CustomPermission(
      identifier: "custom.permission",
      capability: capability,
      usageDescriptionKeys: [.camera, .microphone]
    )
    let sameIdentityWithDifferentMetadata = try CustomPermission(
      identifier: "custom.permission",
      capability: .init(
        supportsStatusCheck: true,
        supportsRequest: true,
        systemSettingsURL: URL(string: "x-test:settings"),
        requiresRelaunch: false
      ),
      usageDescriptionKeys: [.camera]
    )
    let differentIdentity = try CustomPermission(
      identifier: "custom.other-permission",
      capability: capability,
      usageDescriptionKeys: [.camera, .microphone]
    )

    XCTAssertEqual(first, second)
    XCTAssertEqual(first.hashValue, second.hashValue)
    XCTAssertEqual(first, sameIdentityWithDifferentMetadata)
    XCTAssertEqual(first.hashValue, sameIdentityWithDifferentMetadata.hashValue)
    XCTAssertNotEqual(first, differentIdentity)
  }

  func testValidationReportsSpecificErrors() {
    XCTAssertNil(CustomPermission.validationError(for: "com.example.permission"))
    XCTAssertNil(CustomPermission.validationError(for: "custom.permission_1-alpha"))
    XCTAssertEqual(CustomPermission.validationError(for: ""), .empty)
    XCTAssertEqual(CustomPermission.validationError(for: "custom"), .missingNamespace)
    XCTAssertEqual(CustomPermission.validationError(for: "custom."), .emptySegment)
    XCTAssertEqual(CustomPermission.validationError(for: "custom..permission"), .emptySegment)
    XCTAssertEqual(
      CustomPermission.validationError(for: "custom.-permission"), .invalidSegmentBoundary)
    XCTAssertEqual(
      CustomPermission.validationError(for: "custom.permission-"), .invalidSegmentBoundary)
    XCTAssertEqual(
      CustomPermission.validationError(for: "Com.Example.Permission"), .invalidCharacter)
    XCTAssertEqual(CustomPermission.validationError(for: "custom/permission"), .invalidCharacter)

    for type in PermissionType.builtIn {
      XCTAssertEqual(
        CustomPermission.validationError(for: type.id),
        .reserved,
        "\(type.id) should be reserved"
      )
    }
  }

  func testInitializerThrowsConcreteValidationError() {
    XCTAssertThrowsError(
      try CustomPermission(identifier: "custom permission", capability: testCapability)
    ) { error in
      XCTAssertEqual(error as? CustomPermission.IdentifierValidationError, .invalidCharacter)
    }

    for type in PermissionType.builtIn {
      XCTAssertThrowsError(
        try CustomPermission(identifier: type.id, capability: testCapability),
        "\(type.id) should be reserved"
      ) { error in
        XCTAssertEqual(error as? CustomPermission.IdentifierValidationError, .reserved)
      }
    }
  }
}

private let testCapability = PermissionCapability(
  supportsStatusCheck: false,
  supportsRequest: false,
  systemSettingsURL: nil,
  requiresRelaunch: false
)
