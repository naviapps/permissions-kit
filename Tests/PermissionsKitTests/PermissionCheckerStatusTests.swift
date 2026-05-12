import XCTest

@testable import PermissionsKit

final class PermissionCheckerStatusTests: XCTestCase {
  func testStatusMapsEnvironmentValues() async {
    let statuses: [PermissionType: PermissionStatus] = [
      .accessibility: .granted,
      .screenRecording: .denied,
      .camera: .granted,
      .microphone: .denied,
      .contacts: .restricted,
      .calendars: .granted,
      .reminders: .denied,
      .photos: .granted,
      .speechRecognition: .notDetermined,
      .notifications: .granted,
    ]

    let checker = PermissionChecker(environment: makeEnvironment(statuses: statuses))

    for (type, status) in statuses {
      let result = await checker.status(for: type)
      XCTAssertEqual(result, .supported(status))
    }
  }

  func testStatusUsesDefaultOptionsForNotifications() async {
    let checker = PermissionChecker(
      environment: makeEnvironment(status: { type, options in
        XCTAssertEqual(type, .notifications)
        XCTAssertEqual(options, .notifications(.default))
        return .granted
      }))

    let result = await checker.status(for: .notifications)
    XCTAssertEqual(result, .supported(.granted))
  }

  func testStatusUsesDefaultOptionsForPhotos() async {
    let checker = PermissionChecker(
      environment: makeEnvironment(status: { type, options in
        XCTAssertEqual(type, .photos)
        XCTAssertEqual(options, .photos(.default))
        return .granted
      }))

    let result = await checker.status(for: .photos)
    XCTAssertEqual(result, .supported(.granted))
  }

  func testStatusUsesExplicitNotificationOptions() async {
    let customOptions: NotificationRequestOptions = [.alert]
    let checker = PermissionChecker(
      environment: makeEnvironment(status: { type, options in
        XCTAssertEqual(type, .notifications)
        XCTAssertEqual(options, .notifications(customOptions))
        return .granted
      }))

    let result = await checker.status(for: .notifications, options: .notifications(customOptions))
    XCTAssertEqual(result, .supported(.granted))
  }

  func testSettingsOnlyStatusesAreUnsupported() async {
    let checker = PermissionChecker(environment: makeEnvironment(statuses: [:]))

    let settingsOnly: [PermissionType] = [
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

    for type in settingsOnly {
      let status = await checker.status(for: type)
      XCTAssertEqual(status, .unsupported(type.capability), "\(type) should be unsupported")
    }
  }

  func testCustomStatusUnsupportedReturnsCustomCapability() async {
    let capability = PermissionCapability(
      supportsStatusCheck: false,
      supportsRequest: true,
      systemSettingsURL: URL(string: "x-test:settings"),
      requiresRelaunch: true,
      usageDescriptionKeys: []
    )
    let type = PermissionType.custom(.init(id: "custom.status", capability: capability))
    let checker = PermissionChecker(environment: makeEnvironment(statuses: [:]))

    let status = await checker.status(for: type)

    XCTAssertEqual(status, .unsupported(capability))
  }
}

private func makeEnvironment(
  status: @escaping @Sendable (PermissionType, PermissionRequestOptions) async -> PermissionStatus
) -> PermissionEnvironment {
  PermissionEnvironment(
    status: status,
    request: { _, _ in .failed(.apiUnavailable) },
    openURL: { _ in true }
  )
}

private func makeEnvironment(statuses: [PermissionType: PermissionStatus]) -> PermissionEnvironment
{
  PermissionEnvironment(
    status: { type, _ in statuses[type] ?? .unknown },
    request: { _, _ in .failed(.apiUnavailable) },
    openURL: { _ in true }
  )
}
