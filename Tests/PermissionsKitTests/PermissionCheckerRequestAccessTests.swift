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

  func testRequestAccessUnsupportedReturnsUnsupported() async {
    let checker = PermissionChecker(
      environment: makeEnvironment(request: { _, _ in
        .supported(.granted)
      }))

    let result = await checker.requestAccess(for: .automation)
    XCTAssertEqual(result, .unsupported(PermissionType.automation.capability))
  }
}

private func makeEnvironment(
  status: @escaping @Sendable (PermissionType, PermissionRequestOptions) async -> PermissionStatus =
    { _, _ in
      .notDetermined
    },
  request:
    @escaping @Sendable (PermissionType, PermissionRequestOptions) async -> PermissionRequestResult =
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
