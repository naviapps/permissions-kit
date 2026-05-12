import XCTest

@testable import PermissionsKit

final class PermissionCheckerRequestAccessTests: XCTestCase {
  func testRequestAccessUsesDefaultOptionsForNotifications() async {
    let checker = PermissionChecker(
      environment: makeEnvironment(request: { type, options in
        XCTAssertEqual(type, .notifications)
        XCTAssertEqual(options, .notifications(.default))
        return .supported(.granted)
      }))

    let result = await checker.requestAccess(for: .notifications)
    XCTAssertEqual(result, .supported(.granted))
  }

  func testRequestAccessUsesDefaultOptionsForPhotos() async {
    let checker = PermissionChecker(
      environment: makeEnvironment(request: { type, options in
        XCTAssertEqual(type, .photos)
        XCTAssertEqual(options, .photos(.default))
        return .supported(.granted)
      }))

    let result = await checker.requestAccess(for: .photos)
    XCTAssertEqual(result, .supported(.granted))
  }

  func testRequestAccessUsesExplicitNotificationOptions() async {
    let customOptions: NotificationRequestOptions = [.alert]
    let checker = PermissionChecker(
      environment: makeEnvironment(request: { type, options in
        XCTAssertEqual(type, .notifications)
        XCTAssertEqual(options, .notifications(customOptions))
        return .supported(.granted)
      }))

    let result = await checker.requestAccess(
      for: .notifications, options: .notifications(customOptions))
    XCTAssertEqual(result, .supported(.granted))
  }

  func testRequestAccessUsesExplicitPhotoOptions() async {
    let checker = PermissionChecker(
      environment: makeEnvironment(request: { type, options in
        XCTAssertEqual(type, .photos)
        XCTAssertEqual(options, .photos(.addOnly))
        return .supported(.granted)
      }))

    let result = await checker.requestAccess(for: .photos, options: .photos(.addOnly))
    XCTAssertEqual(result, .supported(.granted))
  }

  func testRequestAccessUnsupportedReturnsUnsupported() async {
    let checker = PermissionChecker(
      environment: makeEnvironment(request: { _, _ in
        .supported(.granted)
      }))

    let result = await checker.requestAccess(for: .automation)
    XCTAssertEqual(result, .unsupported(PermissionType.automation.capability))
  }

  func testCustomRequestAccessUnsupportedReturnsCustomCapability() async {
    let capability = PermissionCapability(
      supportsStatusCheck: true,
      supportsRequest: false,
      systemSettingsURL: URL(string: "x-test:settings"),
      requiresRelaunch: true,
      usageDescriptionKeys: []
    )
    let type = PermissionType.custom(.init(id: "custom.request", capability: capability))
    let checker = PermissionChecker(
      environment: makeEnvironment(request: { _, _ in
        .supported(.granted)
      }))

    let result = await checker.requestAccess(for: type)

    XCTAssertEqual(result, .unsupported(capability))
  }

  func testCustomRequestAccessSupportedUsesEnvironment() async {
    let capability = PermissionCapability(
      supportsStatusCheck: false,
      supportsRequest: true,
      systemSettingsURL: nil,
      requiresRelaunch: false,
      usageDescriptionKeys: []
    )
    let type = PermissionType.custom(.init(id: "custom.request", capability: capability))
    let checker = PermissionChecker(
      environment: makeEnvironment(request: { receivedType, options in
        XCTAssertEqual(receivedType, type)
        XCTAssertEqual(options, .none)
        return .supported(.granted)
      }))

    let result = await checker.requestAccess(for: type)

    XCTAssertEqual(result, .supported(.granted))
  }
}

private func makeEnvironment(
  status: @escaping @Sendable (PermissionType, PermissionOptions) async -> PermissionStatus =
    { _, _ in
      .notDetermined
    },
  request:
    @escaping @Sendable (
      PermissionType,
      PermissionOptions
    ) async -> PermissionRequestResult =
    { _, _ in
      .failed(.apiUnavailable)
    }
) -> PermissionEnvironment {
  PermissionEnvironment(
    status: status,
    request: request,
    openURL: { _ in true }
  )
}
