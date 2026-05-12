import PermissionsKitAppKit
import XCTest

@testable import PermissionsKit

final class PermissionEnvironmentUnsupportedTests: XCTestCase {
  private static let unsupportedTypes: [PermissionType] = {
    let custom = CustomPermission(
      id: "com.example.custom",
      capability: PermissionCapability(
        supportsStatusCheck: false,
        supportsRequest: false,
        systemSettingsURL: nil,
        requiresRelaunch: false,
        usageDescriptionKeys: []
      )
    )

    return [
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
      .custom(custom),
    ]
  }()

  func testLiveStatusReturnsUnknownForUnsupportedTypes() async {
    let env = PermissionEnvironment.live

    for type in Self.unsupportedTypes {
      let status = await env.status(type, .none)
      XCTAssertEqual(status, .unknown, "Expected unknown for \(type)")
    }
  }

  func testLiveRequestReturnsFailedForUnsupportedTypes() async {
    let env = PermissionEnvironment.live

    for type in Self.unsupportedTypes {
      let result = await env.request(type, .none)
      XCTAssertEqual(result, .failed(.apiUnavailable), "Expected apiUnavailable for \(type)")
    }
  }
}
